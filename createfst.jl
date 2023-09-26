### A Pluto.jl notebook ###
# v0.19.27

using Markdown
using InteractiveUtils

# ╔═╡ 68fa42c2-27bc-11ee-0dff-97d1cc549763
#contains the methods for constructing an fst

begin
	using Pkg
	Pkg.add(path="../../../OpenFst.jl/")
	Pkg.add(path="../../../TensorFSTs.jl/")
	include("../../src/openfst/convert.jl")

end

# ╔═╡ e3b11382-a9d7-426c-b389-dbc97c4cd704
function mydraw(fst, isym, osym)
	TF.draw(fst; isymbols = isym, osymbols=osym)  |> TF.dot(:svg) |> HTML
end

# ╔═╡ 90e2472e-d2f9-4fdc-a296-1537f1a4f95c
function compose(a,b)
	TF.VectorFST(OF.compose(OF.VectorFst(a), OF.VectorFst(b)))
end

# ╔═╡ 55d821d1-4f11-4c9e-90f5-1a346c9b35ac
function mydraw2(fst, isym, osym)
	print(TF.draw(fst; isymbols = isym, osymbols=osym)  |> TF.dot(:svg))
end

# ╔═╡ 82e7f4ea-ccc7-40e3-8eca-d75775273658
#gets desh's ipa symbol list - CTC
begin
	deshipa = open(TF.loadsymbols, "/Users/meonak/Desktop/JSALT/openfst-1.8.2/tokens.txt")
	deshipa = sort(collect(deshipa))
	deshipa = Dict(deshipa)
end

# ╔═╡ 08c74c08-3047-4df1-a4c2-15ce574a4ba8
#gets desh's ipa list - GMM
begin
	deshipagmm = open(TF.loadsymbols, "/Users/meonak/Desktop/JSALT/ashraf_matrices_gmm/phones.txt")
	deshipagmm = sort(collect(deshipagmm))
	deshipagmm = Dict(deshipagmm)
end

# ╔═╡ 29991f69-b863-4d0d-ada3-fd11f53cf82b
length(deshipagmm)

# ╔═╡ e813af9a-5e15-4c32-8e86-56295d6c9acc
#function that creates an FST with weights from matrix for given utterance (y)

function createY(frames, matrix, model)
	structure = ""
	stateindex = 1
	for state in 1:frames
		eachstate = matrix[stateindex]
		arcindex = 1
		if (cmp(model, "gmm") == 0)
			for num in 2:43
				structure = structure * string(state) * " " * string(state + 1) * " " * string(num) * " " * string(num) * " " * string(eachstate[arcindex]) * "\n"
				arcindex = arcindex + 1
			end
		else
			for num in 2:42
				structure = structure * string(state) * " " * string(state + 1) * " " * string(num) * " " * string(num) * " " * string(eachstate[arcindex]) * "\n"
				arcindex = arcindex + 1	
			end
		end
		stateindex = stateindex+1
	end
	structure = structure * string(frames+1)
	Y = TF.compile(structure, semiring = TF.TropicalSemiring{Float32})
	return Y
end 

# ╔═╡ 52be30e8-4d08-43d8-bf62-d15c05b47b1e
#loads first sentence with ashraf matrices in txt file 
function formatMatrix(filename::AbstractString, model)
	path = "/Users/meonak/Desktop/JSALT/ashraf_matrices_gmm/" * string(filename)
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
	if (cmp(model, "gmm") == 0)
		for state in completematrix 
			deleteat!(state, 43)
		end
	else
		for state in completematrix 
			deleteat!(state, 2)
		end
	end
	return completematrix, len
end


# ╔═╡ d433dce4-669c-4190-bb4f-f3285928b896
#Y: Iraqi troops have been preventing entry of families of Ashraf residents, parliamentary delegations, human rights organisations, lawyers, journalists and even doctors to the camp, and do not allow many logistical materials to get into Ashraf. 20090424-0900-PLENARY-9-en_20090424-11:51:55_6 (not updated)

begin
	matrx, len = formatMatrix("20090424-0900-PLENARY-9-en_20090424_11_51_55_1_gmm.txt", "gmm")
	matrx = -matrx
	print(length(matrx[1]))
	#print(matrx)
	#ystr = createY(len, matrx, "gmm")
	#ycomp = TF.compile(ystr; semiring = TF.TropicalSemiring{Float32})
	#mydraw(ystr, deshipagmm, deshipagmm)
	#OF.write(OF.VectorFst(ycomp),"ashrafsamplesent.fst")
end

# ╔═╡ 1e43fa40-8ef5-4068-ba1b-646e605fcae8
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

# ╔═╡ 2e4f74ed-357c-4d77-8ad7-789da8d0534b
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

# ╔═╡ 022a5e2c-a624-4704-87c3-088a4162ed1a
begin
	gg = createG("iraqi troops have been preventing entry of families of ashraf residents parliamentary delegations human rights organisations lawyers journalists and even doctors to the camp and do not allow many logistical materials to get into ashraf")
	mydraw(gg, newwords, newwords)
end

# ╔═╡ ce58446c-30d8-49e3-8e70-b747ba973997
#gets universal ipa symbol table 
begin
	genipa = open(TF.loadsymbols, "/Users/meonak/Desktop/JSALT/openfst-1.8.2/isymsipa.txt")
end

# ╔═╡ 6c757d11-26d4-4dfa-b96b-c6f9addc4094
#function to create H
function createH()
	phonestruct = ""
	state = 2
	for (ipanum, ipalet) in deshipagmm
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
	#mydraw(H, genipa, genipa)	
	return H
end
	

# ╔═╡ 0f9c424b-f374-408b-b7ae-1d4373cb939d
begin
	h = createH()
	mydraw(h, deshipagmm, deshipagmm)
end

# ╔═╡ 595d178d-cc7b-48f7-993e-d193fc99cfa9
#function that creates generic FST for oov of k length

function genericFST(startstate::Int, k::Int, oov::Int)
	structure = ""
	finalstate = 0
	structure = structure * "1 " * string(startstate+1) * " 1 1\n"
	for state in startstate+1:k+startstate-1
		for (num, ipa) in deshipagmm
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

# ╔═╡ 11dedb39-00d2-4f97-b3d3-b49fe27518cf
#counts phonemes in given word
function cntphone(word::AbstractString)
	count = 0
	for i in 1:length(word)
		count = count + 1
	end
	return count
end

# ╔═╡ 44dc81c1-c189-4b56-b58c-48c9d9ebd8d8
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
		for (k, v) in deshipagmm
			if (cmp(eachipaletter, v) == 0)
				structure = structure * " " * string(k) * "\n"
				break
			end
		end
		finstate += 1
	end
	return structure, finstate
end


# ╔═╡ 2cecb614-90fb-42d4-8503-cec12f79b48d
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
	print(cmuwithallipa)	
end

# ╔═╡ 3b64a576-74d0-4974-b965-60742058c670
#checks if a word is oov and if yes returns its key
function isoov(word::AbstractString)
	for (key, val) in cmuwithallipa
		if (cmp(word, key) == 0)
			return false
		end
	end
	return true
end

# ╔═╡ 0fff4916-3c6a-49fd-9e4f-943a5286d094
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

# ╔═╡ c7235d4e-619e-44ac-8947-a7e8ad3c776f
#removes duplicate pronunciations
begin 
	for (word, ipalist) in cmuwithallipa
		ipalist = unique!(ipalist)
	end
end

# ╔═╡ e51bc757-e40a-45ca-b536-6d653bc47ca7
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

# ╔═╡ 1620adc0-9d05-4c56-bde4-66826c51f506
begin
	l = createL("together with ashraf")
	#mydraw(l, newwords, deshipagmm)
end

# ╔═╡ 0e85b4df-df3d-4358-a30e-f794f5977049
createL("Iraqi troops have been preventing")

# ╔═╡ 56714858-5373-42f1-8420-1a12d3f52417
function rmeps(a)
	TF.VectorFST(OF.rmepsilon(OF.VectorFst(a)))
end

# ╔═╡ 0409b0f6-a713-4bf2-89d9-9cfe9601a0a3
function invert(a)
	TF.VectorFST(OF.invert(OF.VectorFst(a)))
end

# ╔═╡ 5dac838a-88d2-46ca-a8ac-64d5e4e09d54
function determinize(a)
	TF.VectorFST(OF.determinize(OF.VectorFst(a)))
end

# ╔═╡ 580406df-c53c-4b3c-9829-2a039c33bed0
function arcsort(a)
	TF.VectorFST(OF.arcsort(OF.VectorFst(a), OF.ilabel))
end

# ╔═╡ 1e1858d8-eade-4753-ac25-869258045d40
function bestpath(a)
	TF.VectorFST(OF.shortestpath(OF.VectorFst(a)))
end

# ╔═╡ 8852c86e-42d1-4678-a593-8d3d2e431ad1
function shortestdistance(a)
	S = TF.semiring(a)
	sum(a.finalweights .* S.(OF.shortestdistance(OF.VectorFst(a))))
end

# ╔═╡ f0d48f2c-4f05-464f-9a00-f5b0c0c3a598
function tensor_compose(A,B)
	A = TF.convert(TF.TensorFST{TF.Semirings.TropicalSemiring{Float32}},A)
	B = TF.convert(TF.TensorFST{TF.Semirings.TropicalSemiring{Float32}},B)
	C = TF.compose(A,B)
	TF.VectorFST(C._arcs, C.initstate, C.finalweights)
end

# ╔═╡ a7375cb8-2e5f-40b0-a207-c9abe435ee49
#composition function given utterance 
function compositionHLGy(utterance::AbstractString, audiofile::AbstractString)
	priors, frames = formatMatrix(audiofile, "gmm")
	priors = -priors
	fsty = createY(frames, priors, "gmm")
	fstg = createG(utterance)
	fsth = createH()
	fstl = createL(utterance)
	#fstgl = compose(fstg, fstl)
	#mydraw(fstg, newwords, newwords)
	
	#mydraw(determinize(fstl), newwords, deshipa)

	#rmeps(fsthy)
	#rmeps(fstgl)
	#determinize()
	
	fsthy = compose(fsth, fsty)
	fstlhy = compose(fstl, arcsort(fsthy))
	fstglhy = compose(fstg, arcsort(fstlhy))
	#mydraw(fsty, deshipagmm, deshipagmm)
	#mydraw(rmeps(bestpath(fstglhy)), newwords, deshipa)
	#return rmeps(bestpath(fstglhy))
	#fstlhy
	#mydraw(fstgl, newwords, deshipa)

	#mydraw(fstlhy, newwords, deshipa)

	#tensor_compose(fsth, bestpath(fsty))
	
	#mydraw(rmeps(fsthy), deshipa, deshipa)
	#GLHY = compose(fstgl, fsthy)
	#GLHY
	#mydraw((invert(determinize(rmeps(GLHY)))), genipa, newwords)	
end

# ╔═╡ 14beb0c6-0fc7-45cf-823c-e6ba1d48866b
#Instances of Ashraf - GMM
#20090424-0900-PLENARY-9-en_20090424-11:51:55_1
#20090424-0900-PLENARY-9-en_20090424-11:51:55_6 
#20090424-0900-PLENARY-9-en_20090424-11:51:55_8
#20090424-0900-PLENARY-9-en_20090424-11:51:55_4
#20090424-0900-PLENARY-9-en_20090424-11:51:55_2
#20090424-0900-PLENARY-9-en_20090424-11:48:27_18
#20090424-0900-PLENARY-9-en_20090424-11:48:27_14
#20090424-0900-PLENARY-9-en_20090424-11:48:27_13
#20090424-0900-PLENARY-9-en_20090424-11:48:27_11

# ╔═╡ feb666f6-c07c-4078-83df-cfa9596571bf
#20090424-0900-PLENARY-9-en_20090424-11:51:55_1 GMM
begin
	s = "together with a delegation of four members of this house i visited camp ashraf in october last year and met with american iraqi and un officials there"
	c = compositionHLGy(s, "20090424-0900-PLENARY-9-en_20090424_11_51_55_1_gmm.txt")
	mydraw(rmeps(bestpath(c)), newwords, deshipagmm)
end

# ╔═╡ 0b9f3d18-ff74-4142-a7ce-791b4c78b9f2
begin
	shortestdistance(c)
end

# ╔═╡ f9c4da6d-9f92-4b05-83e3-d75f55ba51fb
#20090424-0900-PLENARY-9-en_20090424-11:51:55_6 GMM
begin
	#s2 = "iraqi troops have been preventing entry of families of ashraf residents parliamentary delegations human rights organisations lawyers journalists and even doctors to the camp and do not allow many logistical materials to get into ashraf"
	#c2 = compositionHLGy(s2, "20090424-0900-PLENARY-9-en_20090424_11_51_55_6_gmm.txt")
	#mydraw(rmeps(bestpath(c2)), newwords, deshipagmm)	
end

# ╔═╡ 85cac5c3-651c-4fb3-83c4-a89332a1a4c7
#20090424-0900-PLENARY-9-en_20090424-11:51:55_8 GMM
#begin
	#s3 = "we have now worked together with all groups and produced a common text which is well balanced and addresses all our concerns on this matter and calls on international bodies to find a long term legal status for ashraf residents"
	#c3 = compositionHLGy(s3, )

# ╔═╡ Cell order:
# ╠═68fa42c2-27bc-11ee-0dff-97d1cc549763
# ╠═e3b11382-a9d7-426c-b389-dbc97c4cd704
# ╠═90e2472e-d2f9-4fdc-a296-1537f1a4f95c
# ╠═55d821d1-4f11-4c9e-90f5-1a346c9b35ac
# ╠═82e7f4ea-ccc7-40e3-8eca-d75775273658
# ╠═08c74c08-3047-4df1-a4c2-15ce574a4ba8
# ╠═29991f69-b863-4d0d-ada3-fd11f53cf82b
# ╠═e813af9a-5e15-4c32-8e86-56295d6c9acc
# ╠═52be30e8-4d08-43d8-bf62-d15c05b47b1e
# ╠═d433dce4-669c-4190-bb4f-f3285928b896
# ╠═1e43fa40-8ef5-4068-ba1b-646e605fcae8
# ╠═2e4f74ed-357c-4d77-8ad7-789da8d0534b
# ╠═022a5e2c-a624-4704-87c3-088a4162ed1a
# ╠═ce58446c-30d8-49e3-8e70-b747ba973997
# ╠═6c757d11-26d4-4dfa-b96b-c6f9addc4094
# ╠═0f9c424b-f374-408b-b7ae-1d4373cb939d
# ╠═595d178d-cc7b-48f7-993e-d193fc99cfa9
# ╠═3b64a576-74d0-4974-b965-60742058c670
# ╠═11dedb39-00d2-4f97-b3d3-b49fe27518cf
# ╠═44dc81c1-c189-4b56-b58c-48c9d9ebd8d8
# ╠═0fff4916-3c6a-49fd-9e4f-943a5286d094
# ╠═2cecb614-90fb-42d4-8503-cec12f79b48d
# ╠═c7235d4e-619e-44ac-8947-a7e8ad3c776f
# ╠═e51bc757-e40a-45ca-b536-6d653bc47ca7
# ╠═1620adc0-9d05-4c56-bde4-66826c51f506
# ╠═0e85b4df-df3d-4358-a30e-f794f5977049
# ╠═56714858-5373-42f1-8420-1a12d3f52417
# ╠═0409b0f6-a713-4bf2-89d9-9cfe9601a0a3
# ╠═5dac838a-88d2-46ca-a8ac-64d5e4e09d54
# ╠═580406df-c53c-4b3c-9829-2a039c33bed0
# ╠═1e1858d8-eade-4753-ac25-869258045d40
# ╠═8852c86e-42d1-4678-a593-8d3d2e431ad1
# ╠═f0d48f2c-4f05-464f-9a00-f5b0c0c3a598
# ╠═a7375cb8-2e5f-40b0-a207-c9abe435ee49
# ╠═14beb0c6-0fc7-45cf-823c-e6ba1d48866b
# ╠═feb666f6-c07c-4078-83df-cfa9596571bf
# ╠═0b9f3d18-ff74-4142-a7ce-791b4c78b9f2
# ╠═f9c4da6d-9f92-4b05-83e3-d75f55ba51fb
# ╠═85cac5c3-651c-4fb3-83c4-a89332a1a4c7
