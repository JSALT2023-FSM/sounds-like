### A Pluto.jl notebook ###
# v0.19.27

using Markdown
using InteractiveUtils

# ╔═╡ 28b11c64-2d42-11ee-36c3-333eb7dd36a0
begin
	using Pkg
	Pkg.add(path="../../../OpenFst.jl/")
	Pkg.add(path="../../../TensorFSTs.jl/")
	include("../../src/openfst/convert.jl")

end

# ╔═╡ 295b8832-8283-4837-b915-d69a72ee1ae0
#Create fsts with raw gmm liklihoods of "ashraf" utterances 
#25 instances of Ashraf in TRAIN
#Creates G, L, H, Y for each
#Composition, best path, and shortest distance for each
#Extract Ashraf pronunciations into single FST with weights
#Unionize and Determinize 

# ╔═╡ 54c0f4a6-7d60-49f7-a49a-50568ef63757
function mydraw(fst, isym, osym)
	TF.draw(fst; isymbols = isym, osymbols=osym)  |> TF.dot(:svg) |> HTML
end

# ╔═╡ c0e7ea8f-d186-497b-b030-e5681f8ae71a
function compose(a,b)
	TF.VectorFST(OF.compose(OF.VectorFst(a), OF.VectorFst(b)))
end

# ╔═╡ ed48ac3a-e75e-44b8-981c-8c46ce1909ce
function mydraw2(fst, isym, osym)
	print(TF.draw(fst; isymbols = isym, osymbols=osym)  |> TF.dot(:svg))
end

# ╔═╡ a51bbff5-6a3f-4b7d-b7df-f92ecc2d7ec0
#gets desh ipa 
begin
	deshipa_rgmm = open(TF.loadsymbols, "/Users/meonak/Desktop/JSALT/ashraf_matrices_rawgmm/phones.txt")
	deshipa_rgmm = sort(collect(deshipa_rgmm))
	deshipa_rgmm = Dict(deshipa_rgmm)
end

# ╔═╡ 8f6af47a-558c-46e3-9b03-69c0dc8b4223
#loads first sentence with ashraf matrices in txt file 
function formatMatrix(filename::AbstractString)
	path = "/Users/meonak/Desktop/JSALT/ashraf_matrices_rawgmm/" * string(filename)
	completematrix = []
	matrixstring = ""
	for line in eachline(path)	
		matrixstring = line
	end
	timeframestr = [] 
	timeframestr = split(matrixstring, "], [")
	timeframestr[1] = chop(timeframestr[1], head = 2 )
	timeframestr[lastindex(timeframestr)] = chop(timeframestr[lastindex(timeframestr)], tail = 2)
	
	for frame in timeframestr 
		timeframe = []
		phonemesinframe = []
		phonemesinframe = split(frame, ", ")
		for phoneme in phonemesinframe 
			phoneme = parse(Float64, phoneme)
			push!(timeframe, phoneme)
		end
		push!(completematrix, timeframe)
	end
	len = length(completematrix)
	for state in completematrix 
		deleteat!(state, 43)
	end
	return completematrix, len
end

# ╔═╡ 23ee656d-3029-4d59-a468-9b7a81718e24
#function that creates Y, an FST with weights from matrix for given utterance

function createY(frames, matrix)
	structure = ""
	stateindex = 1
	for state in 1:frames
		eachstate = matrix[stateindex]
		arcindex = 1
		for num in 2:43
			structure = structure * string(state) * " " * string(state + 1) * " " * string(num) * " " * string(num) * " " * string(eachstate[arcindex]) * "\n"
			arcindex = arcindex + 1
		end
		stateindex = stateindex+1
	end
	structure = structure * string(frames+1)
	Y = TF.compile(structure, semiring = TF.TropicalSemiring{Float32})
	return Y
end 

# ╔═╡ 80e8708b-e41c-471a-b2cf-d9fb94fe5c9f
#gets cmu dict words
begin
	words = open(TF.loadsymbols, "/Users/meonak/Desktop/JSALT/openfst-1.8.2/isyms.txt")
	words[125596] = "ashraf"
	words[125597] = "SIL"
	newwords = Dict()
	for (key,val) in words
		newwords[key+1] = val
	end
end

# ╔═╡ 72a8b109-4eec-4dbd-867b-305d2d5bef6b
#function to create G
function createG(utterance::AbstractString)
	uttlist = split(utterance, " ")
	sentlen = length(uttlist)
	structure = ""
	structure = "1 2 125598 125598\n"
	firstw = uttlist[1]
	for (key, val) in newwords
		if (cmp(firstw, val) == 0)
			structure = structure * "2 3 " * string(key) * " " * string(key) *"\n"
			break
		end
	end
	#gets matching val for each word in utterance
	first = true
	wordind = 1
	for i in 2:sentlen+1
		if (first)
			structure = structure * "1 " * string(i+1)
			first = false
		else
			structure = structure * string(i) * " " * string(i+1)
		end
		eachword = uttlist[wordind]
		for (key, val) in newwords
			if (cmp(eachword, val) == 0)
				structure = structure * " " * string(key) * " " * string(key) * "\n"
				break
			end
		end
		wordind = wordind + 1
	end
	structure = structure * string((sentlen+2)) * " " * string((sentlen+3)) * " 125598 125598\n" * string((sentlen+3)) * "\n"
	structure = structure * string((sentlen+2))
	G = TF.compile(structure, semiring = TF.TropicalSemiring{Float32})
	#mydraw(G, newwords, newwords)
	return G
end

# ╔═╡ 73f5c288-863b-48aa-a29f-4f1122f0f094
#function to create H
function createH()
	phonestruct = ""
	state = 2
	for (ipanum, ipalet) in deshipa_rgmm
		if (ipanum == 1)
			continue
		end
		phonestruct = phonestruct * "1 " * string(state) * " "* string(ipanum) * " " * string(ipanum) * "\n"
		phonestruct = phonestruct * string(state) * " " * string(state) * " " * " 1 " * string(ipanum) * "\n"
		phonestruct = phonestruct * string(state) * " " * string(state+1) * " " * " 1 " * string(ipanum) * "\n"
		phonestruct = phonestruct * string(state+1) * " " * string(state+1) * " 1 " * string(ipanum) * "\n"
		phonestruct = phonestruct * string(state+1) * " 1 1 1\n"
		state = state + 2
	end
	phonestruct = phonestruct * "1"
	#print(phonestruct)
	H = TF.compile(phonestruct, semiring = TF.TropicalSemiring{Float32})
	#mydraw(H, deshipa_rgmm, deshipa_rgmm)	
	return H
end

# ╔═╡ 70488038-6fcf-4c2a-a231-54e6eb1504cd
createH()

# ╔═╡ 92aeea10-e378-417d-a6ce-6684e7f569c8
#function that creates generic FST for oov of k length

function genericFST(startstate::Int, k::Int, oov::Int)
	structure = ""
	finalstate = 0
	structure = structure * "1 " * string(startstate+1) * " 1 1\n"
	for state in startstate+1:k+startstate-1
		for (num, ipa) in deshipa_rgmm
			if (num == 1)
				continue
			end
			if (state == startstate+1)
				structure = structure * string(state) * " " * string(state+1) * " " * string(oov) * " " * string(num) * " -1.643\n"
			else
				structure = structure * string(state) * " " * string(state+1) * " " * "1 " * string(num) * " -1.643\n"
			end
		end
		if ((state != startstate+1) && (state != k+startstate-1))
			structure = structure * string(state) * " " * string(k+startstate) * " " * "1 1\n"
		end
	end
	finalstate = string(k+startstate)
	return structure, finalstate
end

# ╔═╡ efb50caa-31ff-40ae-946b-0cd9ee6b0b1c
#counts phonemes in given word
function cntphone(word::AbstractString)
	count = 0
	for i in 1:length(word)
		count = count + 1
	end
	return count
end

# ╔═╡ 62a08270-23ab-421f-9dbe-47fed1ca552b
#createpath
#function that takes in a word and its ipa value and returns the fst table 
function createpathipa(word::AbstractString, ipa::AbstractString, finstate::Int)
	structure = ""
	wordsymbolnum = 0
	for (numkey, wordval) in newwords 
		if (cmp(word, wordval) == 0)
			wordsymbolnum = numkey
			break
		end
	end
	ipalist = split(ipa, " ")
	len = length(ipalist)
	firstline = true
	for i in 1:len
		eachipaletter = ipalist[i]
		if (firstline)
			structure = structure * "1 " *  string(finstate+1) * " " * string(wordsymbolnum)
			firstline = false
		else
			structure = structure * string(finstate) * " " * string(finstate+1) * " 1"
		end
		for (k, v) in deshipa_rgmm
			if (cmp(eachipaletter, v) == 0)
				structure = structure * " " * string(k) * "\n"
				break
			end
		end
		finstate += 1
	end
	return structure, finstate
end

# ╔═╡ 40c25a2d-e71c-42c7-9f97-869a67863c9e
#gets cmu dict word and ipa and loads it into a dictionary with pronunciation(values) clustered together per word(key)

begin 
	cmuwithallipa = Dict{String, Array{String}}()
	for line in eachline("/Users/meonak/Desktop/JSALT/openfst-1.8.2/cmuipa.txt")
		found = false
		currdef = []
		currdef = split(line, " "; limit = 2)
		currword = currdef[1]
		currpron = currdef[2]
		if (occursin("(1)", currword) || occursin("(2)", currword) || occursin("(3)", currword))
			currword = SubString(currword, 1, length(currword)-3)
			push!(cmuwithallipa[currword], currpron)
		else 
			cmuwithallipa[currword] = [currpron]
		end
	end
	cmuwithallipa["SIL"] = ["SIL"]

	#removes duplicate pronunciations
	for (word, ipalist) in cmuwithallipa
		ipalist = unique!(ipalist)
	end
	print(cmuwithallipa)	
end

# ╔═╡ b15c7e7e-0e79-4c7c-8870-dbc5f8d85508
#checks if a word is oov and if yes returns its key
function isoov(word::AbstractString)
	for (key, val) in cmuwithallipa
		if (cmp(word, key) == 0)
			return false
		end
	end
	return true
end

# ╔═╡ 1b47fcd8-4b86-4a70-840a-8589372c7a0c
#creates fst for word in cmudict
function cmudictwordfst(word::AbstractString, startstate::Int)
	structure = ""
	finalstatelist = [startstate]
	for (wordkey, ipalist) in cmuwithallipa
		if (cmp(word, wordkey) == 0)
			for i in 1:length(ipalist)
				wordstructure, finalstate = createpathipa(wordkey, ipalist[i], last(finalstatelist))
				structure = structure * wordstructure
				push!(finalstatelist, finalstate)
			end
			#popfirst!(finalstatelist)
			#for each in finalstatelist
				#wordstructure = wordstructure * string(each) * "\n"
			#end
			#push!(fsttableipa, wordstructure)
			break
		end
	end	
	#print(finalstatelist)
	return structure, finalstatelist
end

# ╔═╡ 19ca642d-285b-4ff5-8f2f-fedcc677584a
#function to create L 
function createL(utterance::AbstractString)
	uttlist = split(utterance, " ")
	uttlist = unique(uttlist)
	sentlen = length(uttlist)
	structure = ""
	finalstates = [1]
	for i in 1:sentlen
		eachword = uttlist[i]
		if (isoov(eachword) == true)
			#usegenericFST for oov 
			gstructure, finst = genericFST(last(finalstates), cntphone(eachword), 125597)
			#print(gstructure)
			structure = structure * gstructure
			structure = structure * string(finst) * " 1 1 1\n"
			push!(finalstates, parse(Int64, finst))
		else
			finstw = []
			wstructure, finstw = cmudictwordfst(eachword, last(finalstates))
			structure = structure * wstructure
			finstwlen = length(finstw)
			#print(finstw, "\n")
			popfirst!(finstw)
			for i in 1:length(finstw)
				structure = structure * string(finstw[i]) * " 1 1 1\n" 
			end
			#print(structure)
			push!(finalstates, last(finstw))
			#print(finalstates)
		end
	end
	#structure= structure * string(pop!(finalstates)) * " 1 0 1\n"
	structure = structure * "1\n"
	#print(structure)
	L = TF.compile(structure, semiring = TF.TropicalSemiring{Float32})
	#mydraw(L, newwords, deshipagmm)
	return L
end

# ╔═╡ 87fdd8ab-eb8b-4c00-9685-266a1e914251
function rmeps(a)
	TF.VectorFST(OF.rmepsilon(OF.VectorFst(a)))
end

# ╔═╡ e1329f58-b77a-47d9-a73d-599bbaed0812
function invert(a)
	TF.VectorFST(OF.invert(OF.VectorFst(a)))
end

# ╔═╡ 16ba07c6-a905-429d-a3ba-c10de1516fba
function determinize(a)
	TF.VectorFST(OF.determinize(OF.VectorFst(a)))
end

# ╔═╡ 841877e6-986e-44fd-a787-3f5f65ea668d
function arcsort(a)
	TF.VectorFST(OF.arcsort(OF.VectorFst(a), OF.ilabel))
end

# ╔═╡ 81ebcd53-9aa9-4358-bb6b-59bd0ae3c717
function bestpath(a)
	TF.VectorFST(OF.shortestpath(OF.VectorFst(a)))
end

# ╔═╡ 7d831429-56dd-4936-b3a2-a828b40b8f82
function shortestdistance(a)
	S = TF.semiring(a)
	sum(a.finalweights .* S.(OF.shortestdistance(OF.VectorFst(a))))
end

# ╔═╡ 715b6dbf-43d8-4b7c-9b57-976a41304b65
#composition function given utterance 
function compositionHLGy(utterance::AbstractString, audiofile::AbstractString)
	priors, frames = formatMatrix(audiofile)
	priors = -priors
	fsty = createY(frames, priors)
	fstg = createG(utterance)
	fsth = createH()
	fstl = createL(utterance)

	fsthy = compose(fsth, fsty)
	fstlhy = compose(fstl, arcsort(fsthy))
	fstglhy = compose(fstg, arcsort(fstlhy))
end

# ╔═╡ 8f62cae8-da85-4283-9d72-75d3dd30ae18
begin 
	#20140310-0900-PLENARY-11-en_20140310-20:11:43_7 
	#and whilst we talk about humanity let us not forget the fifty two refugees murdered on one september two thousand and thirteen while protecting camp ashraf and the missing seven innocent refugees including six women who were taken hostage.

	c1 = compositionHLGy("and whilst we talk about humanity lets not forget the fifty two refugees murdered on september the first two thousand and thirteen protecting camp ashraf and the missing seven innocent refugees including six women who were taken hostage", "20140310-0900-PLENARY-11-en_20140310-20_11_43_7_rgmm.txt")
	mydraw(rmeps(bestpath(c1)), newwords, deshipa_rgmm)
end



# ╔═╡ c8bf033e-d2c3-48af-9bc2-d5b0f0a826a2
shortestdistance(c1)

# ╔═╡ fccbd6e4-318d-4b38-9651-3ce06dd4ff6b
begin
	#20110309-0900-PLENARY-17-en_20110309-16:53:50_1
	#we give eur. one two billion to the rebuilding of iraq and yet every time we pass a resolution in this house every time we pass a written declaration with a big majority we are simply ignored by the iraqi government and by their iranian cohorts. they are psychologically torturing the people in camp ashraf with two hundred and ten loudspeakers blaring propaganda and threats at a high decibel level day and night for the last year. they are prohibiting access to medicines and the hospital for injured people and people dying of cancer

	c2 = compositionHLGy("we give one point two billion euros to the rebuilding of iraq and yet every time we pass a resolution in this house every time we pass a written declaration with a big majority we are simply ignored by the iraqi government and by their iranian cohorts they are torturing psychologically the people in camp ashraf with two hundred and ten loudspeakers blaring propaganda and threats at a high decibel level day and night for the last year they are prohibiting access to medicines and the hospital for injured people and people dying of cancer", "20110309-0900-PLENARY-17-en_20110309-16_53_50_1_rgmm.txt")
	mydraw(rmeps(bestpath(c2)), newwords, deshipa_rgmm)
	
end

# ╔═╡ 9f0151a0-d903-4636-b03f-044934d8286a
shortestdistance(c2)

# ╔═╡ 09f047e1-3815-46a5-8cba-ba4412e7f840
#20120201-0900-PLENARY-10-en_20120201-17:50:30_3
#yesterday he issued a press release saying that camp liberty is ready for the displacement of the three thousand three hundred people from ashraf when in fact there is no freedom of movement they will not be allowed to take their personal possessions they will be surrounded by thousands of military and police you know this is
begin
	c3 = compositionHLGy("yesterday he issued a press release saying that camp liberty is ready for the displacement of the three thousand three hundred people from ashraf when in fact there is no freedom of movement they will not be allowed to take their personal possessions they will be surrounded by thousands of military and police you know this is", "20120201-0900-PLENARY-10-en_20120201-17_50_30_3.txt")
	mydraw(rmeps(bestpath(c3)), newwords, deshipa_rgmm)
end

# ╔═╡ c20b944c-7b29-4851-af5e-71a506cf42e4
shortestdistance(c3)

# ╔═╡ 64b5d765-562e-4cfc-927f-38ba2e119bd1
#20090424-0900-PLENARY-11-en_20090424-12:12:47_1
#"it is incorrectly worded and inconsistent with the text which was actually tabled in the joint resolution by my group and others. i do not know whether you have been informed of this and whether you can take it into account but the text in paragraph two should read respecting the individual wishes of anyone living in camp ashraf as regards to their future"
begin
	c4 = compositionHLGy("its incorrectly worded and inconsistent with the text which was actually tabled in the joint resolution by my group and others i don't know whether you have been informed of this and whether you can take it into account but the text should read in paragraph two respecting the individual wishes of anyone living in camp ashraf as regards to their future", "20090424-0900-PLENARY-11-en_20090424-12_12_47_1.txt")
	mydraw(rmeps(bestpath(c4)), newwords, deshipa_rgmm)
end


# ╔═╡ 1ec54123-44cf-4530-95e6-2b752e51e5b0
	shortestdistance(c4)

# ╔═╡ 69c8178a-1306-4a38-a7a3-27dfd81d867d
#20130909-0900-PLENARY-13-en_20130909-17:32:23_6
begin
	c5 = compositionHLGy("between ashraf or the decision of the conference of presidents", "20130909-0900-PLENARY-13-en_20130909-17_32_23_6.txt")
	mydraw(rmeps(bestpath(c5)), newwords, deshipa_rgmm)
end

# ╔═╡ 508e74fa-66c7-4507-95c3-87578863aae2
	shortestdistance(c5)

# ╔═╡ 344ed0c2-93b9-4621-9d94-3874f0e242e9
#20130909-0900-PLENARY-13-en_20130909-17:32:23_0
#mr president can i just endorse my colleague's comments about procedure and also on the situation in camp ashraf
begin
	c6 = compositionHLGy("thank you mr president can i just endorse my colleague's comments about procedure but also on the situation in camp ashraf", "20130909-0900-PLENARY-13-en_20130909-17_32_23_0.txt")
	mydraw(rmeps(bestpath(c6)), newwords, deshipa_rgmm)
end

# ╔═╡ 9faa773d-325c-413a-974a-65ab7815915f
shortestdistance(c6)

# ╔═╡ 7cad3820-1d88-4df4-b305-0776b87b3e28
#20130116-0900-PLENARY-12-en_20130116-15:55:28_32
#camp ashraf remains an important and sensitive issue
begin
	c7 = compositionHLGy("camp ashraf remains an important and sensitive issue", "20130116-0900-PLENARY-12-en_20130116-15_55_28_32.txt")
	mydraw(rmeps(bestpath(c7)), newwords, deshipa_rgmm)
end

# ╔═╡ de8bc6ca-6b6c-4703-8997-48401e2a80f7
shortestdistance(c7)

# ╔═╡ fea7f3dc-be48-4643-8dae-430619955bfe
#20110511-0900-PLENARY-2-en_20110511-11:25:39_4
#this is the only option that can avoid another humanitarian catastrophe and it has been agreed by the people of ashraf themselves
begin
	c8 = compositionHLGy("this is the only option that can avoid another humanitarian catastrophe and it has been agreed by the people of ashraf themselves", "20110511-0900-PLENARY-2-en_20110511-11_25_39_4.txt")
	mydraw(rmeps(bestpath(c8)), newwords, deshipa_rgmm)
end

# ╔═╡ 36ae8a65-0e6d-4152-b47f-9302b78be927
shortestdistance(c8)

# ╔═╡ a8ed3ee3-d192-488d-88b5-68fab7b22125
#20131010-0900-PLENARY-24-en_20131010-16:10:58_4
#we have seen recently the appalling massacre in camp ashraf people with their hands handcuffed behind their back shot brutally in the back of the head executed
begin
	c9 = compositionHLGy("we have seen recently the appalling massacre in camp ashraf people with their hands handcuffed behind their back shot brutally in the back of the head executed", "20131010-0900-PLENARY-24-en_20131010-16_10_58_4.txt")
	mydraw(rmeps(bestpath(c9)), newwords, deshipa_rgmm)
end

# ╔═╡ 2ad0882c-4e0a-4e8b-8f99-5fb56e388218
shortestdistance(c9)

# ╔═╡ 686b0d39-05e2-4628-bac6-f855e4835b71
#20090424-0900-PLENARY-9-en_20090424-11:40:24_13
#in short this is about the individual human rights of the people in camp ashraf
begin
	c10 = compositionHLGy("in short this is about the individual human rights of the people in camp ashraf", "20090424-0900-PLENARY-9-en_20090424-11_40_24_13.txt")
	mydraw(rmeps(bestpath(c10)), newwords, deshipa_rgmm)
end

# ╔═╡ 6c75164a-eca0-45d8-83a9-007a8010d104
shortestdistance(c10)

# ╔═╡ 6b6837a2-e820-4ff6-87ff-b349a69d6d3d
#20110511-0900-PLENARY-2-en_20110511-11:25:39_3
#20110511-0900-PLENARY-2-en_20110511-11:25:39_2
#20100119-0900-PLENARY-7-en_20100119-19:16:00_32
#20110914-0900-PLENARY-12-en_20110914-19:17:02_4
#20090424-0900-PLENARY-9-en_20090424-11:40:24_3
#20090424-0900-PLENARY-9-en_20090424-11:40:24_10
#20090424-0900-PLENARY-9-en_20090424-11:40:24_11
#20120201-0900-PLENARY-10-en_20120201-17:51:42_2

# ╔═╡ Cell order:
# ╠═295b8832-8283-4837-b915-d69a72ee1ae0
# ╠═28b11c64-2d42-11ee-36c3-333eb7dd36a0
# ╠═54c0f4a6-7d60-49f7-a49a-50568ef63757
# ╠═c0e7ea8f-d186-497b-b030-e5681f8ae71a
# ╠═ed48ac3a-e75e-44b8-981c-8c46ce1909ce
# ╠═a51bbff5-6a3f-4b7d-b7df-f92ecc2d7ec0
# ╠═8f6af47a-558c-46e3-9b03-69c0dc8b4223
# ╠═23ee656d-3029-4d59-a468-9b7a81718e24
# ╠═80e8708b-e41c-471a-b2cf-d9fb94fe5c9f
# ╠═72a8b109-4eec-4dbd-867b-305d2d5bef6b
# ╠═73f5c288-863b-48aa-a29f-4f1122f0f094
# ╠═70488038-6fcf-4c2a-a231-54e6eb1504cd
# ╠═92aeea10-e378-417d-a6ce-6684e7f569c8
# ╠═b15c7e7e-0e79-4c7c-8870-dbc5f8d85508
# ╠═efb50caa-31ff-40ae-946b-0cd9ee6b0b1c
# ╠═62a08270-23ab-421f-9dbe-47fed1ca552b
# ╠═1b47fcd8-4b86-4a70-840a-8589372c7a0c
# ╠═40c25a2d-e71c-42c7-9f97-869a67863c9e
# ╠═19ca642d-285b-4ff5-8f2f-fedcc677584a
# ╠═87fdd8ab-eb8b-4c00-9685-266a1e914251
# ╠═e1329f58-b77a-47d9-a73d-599bbaed0812
# ╠═16ba07c6-a905-429d-a3ba-c10de1516fba
# ╠═841877e6-986e-44fd-a787-3f5f65ea668d
# ╠═81ebcd53-9aa9-4358-bb6b-59bd0ae3c717
# ╠═7d831429-56dd-4936-b3a2-a828b40b8f82
# ╠═715b6dbf-43d8-4b7c-9b57-976a41304b65
# ╠═8f62cae8-da85-4283-9d72-75d3dd30ae18
# ╠═c8bf033e-d2c3-48af-9bc2-d5b0f0a826a2
# ╠═fccbd6e4-318d-4b38-9651-3ce06dd4ff6b
# ╠═9f0151a0-d903-4636-b03f-044934d8286a
# ╠═09f047e1-3815-46a5-8cba-ba4412e7f840
# ╠═c20b944c-7b29-4851-af5e-71a506cf42e4
# ╠═64b5d765-562e-4cfc-927f-38ba2e119bd1
# ╠═1ec54123-44cf-4530-95e6-2b752e51e5b0
# ╠═69c8178a-1306-4a38-a7a3-27dfd81d867d
# ╠═508e74fa-66c7-4507-95c3-87578863aae2
# ╠═344ed0c2-93b9-4621-9d94-3874f0e242e9
# ╠═9faa773d-325c-413a-974a-65ab7815915f
# ╠═7cad3820-1d88-4df4-b305-0776b87b3e28
# ╠═de8bc6ca-6b6c-4703-8997-48401e2a80f7
# ╠═fea7f3dc-be48-4643-8dae-430619955bfe
# ╠═36ae8a65-0e6d-4152-b47f-9302b78be927
# ╠═a8ed3ee3-d192-488d-88b5-68fab7b22125
# ╠═2ad0882c-4e0a-4e8b-8f99-5fb56e388218
# ╠═686b0d39-05e2-4628-bac6-f855e4835b71
# ╠═6c75164a-eca0-45d8-83a9-007a8010d104
# ╠═6b6837a2-e820-4ff6-87ff-b349a69d6d3d
