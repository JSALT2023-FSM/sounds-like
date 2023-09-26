### A Pluto.jl notebook ###
# v0.19.27

using Markdown
using InteractiveUtils

# ╔═╡ b963a1e8-3047-11ee-04db-8b32f79fd027
#create fsts for CTC liklihoods of "ashraf" utterances 
begin
	using Pkg
	Pkg.add(path="../../../OpenFst.jl/")
	Pkg.add(path="../../../TensorFSTs.jl/")
	include("../../src/openfst/convert.jl")

end

# ╔═╡ 55808de1-0644-47df-be40-34debaf545d3
function mydraw(fst, isym, osym)
	TF.draw(fst; isymbols = isym, osymbols=osym)  |> TF.dot(:svg) |> HTML
end

# ╔═╡ 4255e8d0-f3f2-4f89-ba80-d70d43445e66
function compose(a,b)
	TF.VectorFST(OF.compose(OF.VectorFst(a), OF.VectorFst(b)))
end

# ╔═╡ 8b9d34c1-2ecf-42a1-870e-b1239836cd10
#gets desh's ipa symbol list - CTC
begin
	deshipa = open(TF.loadsymbols, "/Users/meonak/Desktop/JSALT/openfst-1.8.2/tokens.txt")
	deshipa = sort(collect(deshipa))
	deshipa = Dict(deshipa)
end

# ╔═╡ 4be1de9e-56a3-4f03-bd06-f8adff3b920a
#loads first sentence with ashraf matrices in txt file 
function formatMatrix(filename::AbstractString)
	path = "/Users/meonak/Desktop/JSALT/ashraf_matrices_ctc1/" * string(filename)
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
			deleteat!(state, 2)
	end
	return completematrix, len
end

# ╔═╡ 52c02d7b-e071-40d4-8522-d29e89c0fe47
#function that creates Y, an FST with weights from matrix for given utterance

function createY(frames, matrix)
	structure = ""
	stateindex = 1
	for state in 1:frames
		eachstate = matrix[stateindex]
		arcindex = 1
		for num in 2:42
				structure = structure * string(state) * " " * string(state + 1) * " " * string(num) * " " * string(num) * " " * string(eachstate[arcindex]) * "\n"
				arcindex = arcindex + 1	
		end
		stateindex = stateindex+1
	end
	structure = structure * string(frames+1)
	Y = TF.compile(structure, semiring = TF.TropicalSemiring{Float32})
	return Y
end 

# ╔═╡ a907d976-1a35-4bbb-af96-02106b5441cc
#gets cmu dict words
begin
	words = open(TF.loadsymbols, "/Users/meonak/Desktop/JSALT/openfst-1.8.2/isyms.txt")
	words[125596] = "ashraf"
	words[125597] = "SIL"
	newwords = Dict()
	for (key,val) in words
		newwords[key+1] = val
	end
	newwords
end

# ╔═╡ 7bee54a9-f85d-41af-beae-691c7becc2f5
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

# ╔═╡ 8720a988-d7d1-4bce-b4bc-af5cdc501c17
#function to create H
function createH()
	phonestruct = ""
	state = 2
	for (ipanum, ipalet) in deshipa
		if (ipanum == 1)
			continue
		end
		phonestruct = phonestruct * "1 " * string(state) * " "* string(ipanum) * " " * string(ipanum) * "\n"
		phonestruct = phonestruct * string(state) * " " * string(state) * " " * " 1 " * string(ipanum) * " \n"
		phonestruct = phonestruct * string(state) * " 1 1 1\n"
		state = state + 1
	end
	phonestruct = phonestruct * "1"
	#print(phonestruct)
	H = TF.compile(phonestruct, semiring = TF.TropicalSemiring{Float32})
	#mydraw(H, deshipa, deshipa)	
	return H
end

# ╔═╡ abba4994-aae8-4213-985e-993a7e1b8f4b
#function that creates generic FST for oov of k length

function genericFST(startstate::Int, k::Int, oov::Int)
	structure = ""
	finalstate = 0
	structure = structure * "1 " * string(startstate+1) * " 1 1\n"
	for state in startstate+1:k+startstate-1
		for (num, ipa) in deshipa
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

# ╔═╡ d41efc41-289b-4d86-a0de-2ee6e819b774
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

# ╔═╡ 21257af0-7e53-4ee0-820e-3d7a60238232
#checks if a word is oov and if yes returns its key
function isoov(word::AbstractString)
	for (key, val) in cmuwithallipa
		if (cmp(word, key) == 0)
			return false
		end
	end
	return true
end

# ╔═╡ 58d6d2b4-8320-4ec2-9867-2ad493689867
#counts phonemes in given word
function cntphone(word::AbstractString)
	count = 0
	for i in 1:length(word)
		count = count + 1
	end
	return count
end

# ╔═╡ ec9f8557-1035-41af-b2ad-928d8db98372
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
		for (k, v) in deshipa
			if (cmp(eachipaletter, v) == 0)
				structure = structure * " " * string(k) * "\n"
				break
			end
		end
		finstate += 1
	end
	return structure, finstate
end

# ╔═╡ a1452bbc-b07c-4ac4-9abd-c2c9074b8f6f
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
			break
		end
	end	
	return structure, finalstatelist
end

# ╔═╡ 30f08a17-db83-4b53-bf34-7f01024983bd
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

# ╔═╡ 8a1759fd-3f1d-421f-adfb-ae6784dbeb92
function concat(a, b)
	TF.VectorFST(OF.concat(OF.VectorFst(a), OF.VectorFst(b)))
end

# ╔═╡ 0f523cb6-f2ac-43aa-848a-a2673af2a2a5
function minimize(a)
	TF.VectorFST(OF.minimize(OF.VectorFst(a)))
end

# ╔═╡ 157fb5aa-0ade-47e8-878c-01585e7c6a2c
function rmeps(a)
	TF.VectorFST(OF.rmepsilon(OF.VectorFst(a)))
end

# ╔═╡ 367fcf81-fa3d-4cbb-bf48-098251a1c306
function invert(a)
	TF.VectorFST(OF.invert(OF.VectorFst(a)))
end

# ╔═╡ 525f63ff-fb7d-40b2-82f7-4798a10995ce
function determinize(a)
	TF.VectorFST(OF.determinize(OF.VectorFst(a)))
end

# ╔═╡ 04abdf36-d87b-4fb4-b51f-c234296b790e
function arcsort(a)
	TF.VectorFST(OF.arcsort(OF.VectorFst(a), OF.ilabel))
end

# ╔═╡ e932b1f9-7695-4e9f-8436-b62300a35292
function bestpath(a)
	TF.VectorFST(OF.shortestpath(OF.VectorFst(a)))
end

# ╔═╡ e4820341-1d04-4af2-9bf2-573b85be0441
function shortestdistance(a)
	S = TF.semiring(a)
	sum(a.finalweights .* S.(OF.shortestdistance(OF.VectorFst(a))))
end

# ╔═╡ 92a4a286-042e-488b-8bc8-a088301d424b
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

# ╔═╡ 10851ea5-6a63-4974-9ca4-e8dcfda56287
#20140310-0900-PLENARY-11-en_20140310-20:11:43_7 
begin
	c1 = compositionHLGy("and whilst we talk about humanity lets not forget the fifty two refugees murdered on september the first two thousand and thirteen protecting camp ashraf and the missing seven innocent refugees including six women who were taken hostage", "20140310-0900-PLENARY-11-en_20140310-20_11_43_7.txt")
	mydraw(rmeps(bestpath(c1)), newwords, deshipa)
end


# ╔═╡ 2c455350-f226-4005-b172-46f2314a9d7e
shortestdistance(c1)

# ╔═╡ 740de96c-18de-49fb-8d23-0cb3981b9127
#20120201-0900-PLENARY-10-en_20120201-17:50:30_3
begin
	c3 = compositionHLGy("yesterday he issued a press release saying that camp liberty is ready for the displacement of the three thousand three hundred people from ashraf when in fact there is no freedom of movement they will not be allowed to take their personal possessions they will be surrounded by thousands of military and police you know this is", "20120201-0900-PLENARY-10-en_20120201-17_50_30_3.txt")
	mydraw(rmeps(bestpath(c3)), newwords, deshipa)
end

# ╔═╡ 91018f49-85e3-4704-b634-9d6d438bbb53
shortestdistance(c3)

# ╔═╡ c3781de7-5fc5-44f0-82db-5ffa26e89a59
#20090424-0900-PLENARY-11-en_20090424-12:12:47_1
begin
	c4 = compositionHLGy("its incorrectly worded and inconsistent with the text which was actually tabled in the joint resolution by my group and others i don't know whether you have been informed of this and whether you can take it into account but the text should read in paragraph two respecting the individual wishes of anyone living in camp ashraf as regards to their future", "20090424-0900-PLENARY-11-en_20090424-12_12_47_1.txt")
	mydraw(rmeps(bestpath(c4)), newwords, deshipa)
end

# ╔═╡ d4cc9823-9aaf-4f41-adf2-593d18e43bad
#20130909-0900-PLENARY-13-en_20130909-17:32:23_6
begin
	c5 = compositionHLGy("between ashraf or the decision of the conference of presidents", "20130909-0900-PLENARY-13-en_20130909-17_32_23_6.txt")
	mydraw(rmeps(bestpath(c5)), newwords, deshipa)
end

# ╔═╡ 959e9b5f-c895-4446-94f5-16bb7ece0ab1
#20130909-0900-PLENARY-13-en_20130909-17:32:23_0
begin
	c6 = compositionHLGy("thank you mr president can i just endorse my colleague's comments about procedure but also on the situation in camp ashraf", "20130909-0900-PLENARY-13-en_20130909-17_32_23_0.txt")
	mydraw(rmeps(bestpath(c6)), newwords, deshipa)
end


# ╔═╡ 2017c685-5e9a-467d-8517-92efc2c42ecc
#20130116-0900-PLENARY-12-en_20130116-15:55:28_32
begin
	c7 = compositionHLGy("camp ashraf remains an important and sensitive issue", "20130116-0900-PLENARY-12-en_20130116-15_55_28_32.txt")
	mydraw(rmeps(bestpath(c7)), newwords, deshipa)
end

# ╔═╡ 4f2f39ef-3462-4dd3-8277-03ae0d7f8d58
#20110511-0900-PLENARY-2-en_20110511-11:25:39_4
begin
	c8 = compositionHLGy("this is the only option that can avoid another humanitarian catastrophe and it has been agreed by the people of ashraf themselves", "20110511-0900-PLENARY-2-en_20110511-11_25_39_4.txt")
	mydraw(rmeps(bestpath(c8)), newwords, deshipa)
end

# ╔═╡ 19a27b76-fe75-43cf-8cae-452f1e764239
#20131010-0900-PLENARY-24-en_20131010-16:10:58_4
begin
	c9 = compositionHLGy("we have seen recently the appalling massacre in camp ashraf people with their hands handcuffed behind their back shot brutally in the back of the head executed", "20131010-0900-PLENARY-24-en_20131010-16_10_58_4.txt")
	mydraw(rmeps(bestpath(c9)), newwords, deshipa)
end

# ╔═╡ e9bcfb44-fda2-4c0b-94b7-42bf3da1a21b
#20090424-0900-PLENARY-9-en_20090424-11:40:24_13
begin
	c10 = compositionHLGy("in short this is about the individual human rights of the people in camp ashraf", "20090424-0900-PLENARY-9-en_20090424-11_40_24_13.txt")
	mydraw(rmeps(bestpath(c10)), newwords, deshipa)
end

# ╔═╡ 60ddc429-70b8-45a4-a66d-7295c7edfb9f
#create human pronunciation FSTs
begin
	humanpronlist = ["æ ʃ ɹ æ f", "ɑ ʃ ɹ ɑ f", "ɑ ʃ ɹ ɑ f", "æ ʃ ɹ æ f", "æ ʃ ɹ æ f", "æ ʃ ɹ æ", "æ ʃ ɹ æ f", "æ ʃ ɹ æ f", "æ ʃ ɹ æ", "æ ʃ ɹ æ f"]
	humanpron = Dict() 
	for i in 1:10
		humanpron[i] = humanpronlist[i]
	end
	structure = ""
	index = 1
	finalstates = []
	for (key, value) in humanpron
		ipalist = []
		ipalist = split(value, " ")
		first = true
		for eachipa in ipalist
			if (first == true)
				structure = structure * "1 " * string(index +1) * " 125597 "
				first = false
			else
				structure = structure * string(index) * " " * string(index + 1)
				structure = structure * " 1 "
			end
			for (k, v) in deshipa
				if (cmp(eachipa, v) == 0)
					structure = structure * string(k) * "\n"
					break
				end 
			end
			index = index + 1
		end
		push!(finalstates, index)
	end
	for s in finalstates
		structure = structure * string(s) * "\n"
	end
	#print(structure)
end

# ╔═╡ 249cc9f2-62ba-41ae-9f9c-ac344a98976f
function mydraw2(fst, isym, osym)
	print(TF.draw(fst; isymbols = isym, osymbols=osym)  |> TF.dot(:svg))
end

# ╔═╡ b8308dd2-29fe-47e2-bf29-fb3b850d912b
begin
	humanpronfst = TF.compile(structure, semiring = TF.TropicalSemiring{Float32})
	structu = "1\n"
	st = TF.compile(structu, semiring = TF.TropicalSemiring{Float32})
	mydraw(invert(minimize(determinize(invert(concat(humanpronfst, st))))), newwords, deshipa) 
end

# ╔═╡ 7595cf38-db5e-4a20-a951-d46719b99e45
#create a2p pronunciation FSTs
begin
	a2ppronlist = ["h æ h ʃ", "æ ʃ ɹ ʌ f", "ɚ t͡ʃ ɚ v", "æ s æ s", "t i æ s", "æ ʃ f æ", "æ ʃ æ f", "æ t͡ʃ ɹ ʌ f", "æ ʃ ɹ ɚ", "æ s æ θ"]
	a2ppron = Dict() 
	for i in 1:10
		a2ppron[i] = a2ppronlist[i]
	end
	structurea2p = ""
	indexa2p = 1
	finalstatesa2p = []
	for (key, value) in a2ppron
		ipalista2p = []
		ipalista2p = split(value, " ")
		first = true
		for eachipa in ipalista2p
			if (first == true)
				structurea2p = structurea2p * "1 " * string(indexa2p +1) * " 125597 "
				first = false
			else
				structurea2p = structurea2p * string(indexa2p) * " " * string(indexa2p + 1)
				structurea2p = structurea2p * " 1 "
			end
			for (k, v) in deshipa
				if (cmp(eachipa, v) == 0)
					structurea2p = structurea2p * string(k) * "\n"
					break
				end 
			end
			indexa2p = indexa2p + 1
		end
		push!(finalstatesa2p, indexa2p)
	end
	for s in finalstatesa2p
		structurea2p = structurea2p * string(s) * "\n"
	end
	#print(structurea2p)
end

# ╔═╡ 667e0f26-25ec-4b7c-88b9-56817758a5df
begin
	a2ppronfst = TF.compile(structurea2p, semiring = TF.TropicalSemiring{Float32})
	mydraw(rmeps(invert(minimize(determinize(invert(concat(a2ppronfst, st)))))), newwords, deshipa) 
end

# ╔═╡ Cell order:
# ╠═b963a1e8-3047-11ee-04db-8b32f79fd027
# ╠═55808de1-0644-47df-be40-34debaf545d3
# ╠═4255e8d0-f3f2-4f89-ba80-d70d43445e66
# ╠═8b9d34c1-2ecf-42a1-870e-b1239836cd10
# ╠═4be1de9e-56a3-4f03-bd06-f8adff3b920a
# ╠═52c02d7b-e071-40d4-8522-d29e89c0fe47
# ╠═a907d976-1a35-4bbb-af96-02106b5441cc
# ╠═7bee54a9-f85d-41af-beae-691c7becc2f5
# ╠═8720a988-d7d1-4bce-b4bc-af5cdc501c17
# ╠═abba4994-aae8-4213-985e-993a7e1b8f4b
# ╠═d41efc41-289b-4d86-a0de-2ee6e819b774
# ╠═21257af0-7e53-4ee0-820e-3d7a60238232
# ╠═58d6d2b4-8320-4ec2-9867-2ad493689867
# ╠═ec9f8557-1035-41af-b2ad-928d8db98372
# ╠═a1452bbc-b07c-4ac4-9abd-c2c9074b8f6f
# ╠═30f08a17-db83-4b53-bf34-7f01024983bd
# ╠═8a1759fd-3f1d-421f-adfb-ae6784dbeb92
# ╠═0f523cb6-f2ac-43aa-848a-a2673af2a2a5
# ╠═157fb5aa-0ade-47e8-878c-01585e7c6a2c
# ╠═367fcf81-fa3d-4cbb-bf48-098251a1c306
# ╠═525f63ff-fb7d-40b2-82f7-4798a10995ce
# ╠═04abdf36-d87b-4fb4-b51f-c234296b790e
# ╠═e932b1f9-7695-4e9f-8436-b62300a35292
# ╠═e4820341-1d04-4af2-9bf2-573b85be0441
# ╠═92a4a286-042e-488b-8bc8-a088301d424b
# ╠═10851ea5-6a63-4974-9ca4-e8dcfda56287
# ╠═2c455350-f226-4005-b172-46f2314a9d7e
# ╠═740de96c-18de-49fb-8d23-0cb3981b9127
# ╠═91018f49-85e3-4704-b634-9d6d438bbb53
# ╠═c3781de7-5fc5-44f0-82db-5ffa26e89a59
# ╠═d4cc9823-9aaf-4f41-adf2-593d18e43bad
# ╠═959e9b5f-c895-4446-94f5-16bb7ece0ab1
# ╠═2017c685-5e9a-467d-8517-92efc2c42ecc
# ╠═4f2f39ef-3462-4dd3-8277-03ae0d7f8d58
# ╠═19a27b76-fe75-43cf-8cae-452f1e764239
# ╠═e9bcfb44-fda2-4c0b-94b7-42bf3da1a21b
# ╠═60ddc429-70b8-45a4-a66d-7295c7edfb9f
# ╠═249cc9f2-62ba-41ae-9f9c-ac344a98976f
# ╠═b8308dd2-29fe-47e2-bf29-fb3b850d912b
# ╠═7595cf38-db5e-4a20-a951-d46719b99e45
# ╠═667e0f26-25ec-4b7c-88b9-56817758a5df
