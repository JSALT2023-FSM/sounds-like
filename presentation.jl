### A Pluto.jl notebook ###
# v0.19.27

using Markdown
using InteractiveUtils

# ╔═╡ beebec3d-a6b1-4623-a54f-df7d6235209d
#for presentation purposes, simple script for "hi ashraf" composition
begin
	using Pkg
	Pkg.add(path="../../../OpenFst.jl/")
	Pkg.add(path="../../../TensorFSTs.jl/")
end

# ╔═╡ 0fcad8d4-254a-11ee-3f4f-f904c5cdd31b
include("../../src/openfst/convert.jl")

# ╔═╡ 62b13db7-d78f-4ed4-84a7-fd62fc24cf60
HTML("""
<!-- the wrapper span -->
<div>
    <button id="myrestart" href="#">Restart</button>
    <script>
        const div = currentScript.parentElement
        const button = div.querySelector("button#myrestart")
        const cell= div.closest('pluto-cell')
        console.log(button);
        button.onclick = function() { restart_nb() };
        function restart_nb() {
            console.log("Restarting Notebook");
                cell._internal_pluto_actions.send(
                    "restart_process",
                            {},
                            {
                                notebook_id: editor_state.notebook.notebook_id,
                            }
                        )
        };
    </script>
</div>""")

# ╔═╡ fedccb6f-f6a6-436c-bd83-6877b4f1cf10
function mydraw(fst, isym, osym)
	TF.draw(fst; isymbols = isym, osymbols=osym)  |> TF.dot(:svg) |> HTML
end

# ╔═╡ 9b1bc8f1-659f-4372-8a98-d57773df1f3d
function mydraw2(fst, isym, osym)
	print(TF.draw(fst; isymbols = isym, osymbols=osym)  |> TF.dot(:svg))
end

# ╔═╡ 1bd7b45e-13e8-44ef-be22-c10db80a477e
function compose(a,b)
	TF.VectorFST(OF.compose(OF.VectorFst(a), OF.VectorFst(b)))
end

# ╔═╡ 323945e6-4a9d-446e-b678-8139e1424bc1
begin
	structure = "1 2 1 0\n 2 3 1 0\n 3"
	fst = TF.compile(structure)
	mydraw(fst)
end

# ╔═╡ 584e7982-7de1-4201-acd4-c940429e5bce
begin
	mydraw(TF.VectorFST(OF.VectorFst(TF.compile(structure; openfst_compat=false))))
end

# ╔═╡ ef5f7926-6f32-406e-8abb-9d6a742199d5
#draws fst for universal phonemes
# mydraw(listoftablesphoneme[4], genipa, genipa)

# ╔═╡ ff15d01f-4595-46c5-a5ea-659d735c108a
#gets cmu dict symbol table
begin
	words = open(TF.loadsymbols, "/Users/meonak/Desktop/JSALT/openfst-1.8.2/isyms.txt")
end

# ╔═╡ 357504ca-1c06-4394-86f3-ddf418a7697b
words[125596] = "ashraf"

# ╔═╡ 06b06426-d831-4699-9ae6-8c88092b6335
#add 1 to all the words
begin
	newwords = Dict()
	for (key,val) in words
		newwords[key+1] = val
	end
end

# ╔═╡ 1d7fa834-bff8-4f1b-9e04-92666903aef4
newwords[1]

# ╔═╡ 36cc4314-7423-44dd-8c0a-6997860c5795
begin
	maxkey = 0
	for (key,val) in words
		#if (cmp(val, "ashraf") == 0)
			#print(key)
		#end
		if (key > maxkey)
			maxkey = key
		end
	end
	print(maxkey)
end

# ╔═╡ 31dc6a97-2e34-47cd-8957-e1e0c1b1ab26
begin 
	local struc = """
	1 2 50927 50927
	2
	"""
	G2 = TF.compile(struc)
	TF.draw(G2; isymbols = newwords, osymbols=newwords)  |> TF.dot(:svg) |> HTML
end

# ╔═╡ d450794e-63f1-40bc-a738-22c47a15e2a6
begin 
	struc = """
	1 2 50927 50927
	2 3 125597 125597
	3
	"""
	G = TF.compile(struc)
	TF.draw(G; isymbols = newwords, osymbols=newwords)  |> TF.dot(:svg) |> HTML
	#print(TF.draw(G; isymbols = newwords, osymbols=newwords)  |> TF.dot(:svg))
	#G Get this Image
	
end

# ╔═╡ 66e5a34a-f9ff-44a0-a709-23e44eddba2e
S = TF.Semirings.LogSemiring{Float32,-Inf}

# ╔═╡ 59de4f52-df10-4c1c-9ff0-c728ab3664b0


# ╔═╡ ee87d962-f2af-49b2-a951-00c086a9a322
G

# ╔═╡ cd5d56e3-54af-4677-af73-1d22755b0602
function rmeps(a)
	TF.VectorFST(OF.rmepsilon(OF.VectorFst(a)))
end

# ╔═╡ 5f5c30ea-f3ad-4a35-b76d-842ac229c4e8
function invert(a)
	TF.VectorFST(OF.invert(OF.VectorFst(a)))
end

# ╔═╡ 4372ef4b-f6e3-465e-9dc3-d54430c71792
function determinize(a)
	TF.VectorFST(OF.determinize(OF.VectorFst(a)))
end

# ╔═╡ c5c726b1-3316-4ab9-a8bf-b0b708eda089
function minimize(a)
	TF.VectorFST(OF.minimize(OF.VectorFst(a)))
end

# ╔═╡ b0030b95-1817-4d8b-97e0-6ec40eb44c0f
function reverse(a)
	TF.VectorFST(OF.reverse(OF.VectorFst(a)))
end

# ╔═╡ a61cd541-6b51-435a-9037-6d03b73780ef
function arcsort(a, arc_sort)
	TF.VectorFST(OF.arcsort(OF.VectorFst(a),arc_sort))
end

# ╔═╡ 493e4d4c-bcc6-40ae-8dfa-e3d96742d148
#gets universal ipa symbol table 
begin
	genipa = open(TF.loadsymbols, "/Users/meonak/Desktop/JSALT/openfst-1.8.2/isymsipa.txt")
end

# ╔═╡ ba0d7aad-f53c-402c-b9bc-df1880e2ad35
begin 
	hiashraf = """
	1 2 9 9 
	2 3 9 9 
	3 4 2 2 
	4 5 2 2
	5 6 2 2 
	6 7 2 2 
	7 8 28 28
	8 9 28 28
	9 10 38 38
	10 11 38 38
	11 12 37 37
	12 13 37 37
	13 14 28 28
	14 15 28 28
	15 16 8 8
	16 17 8 8
	17
	"""
	y = TF.compile(hiashraf)
	mydraw(y,genipa,genipa)
end

# ╔═╡ 36436801-081c-4c39-94d0-b8742e18e811
TF.VectorFST(OF.compose(OF.VectorFst(h), OF.VectorFst(y)))

# ╔═╡ b5f68249-6f43-4b70-be8b-7c36128f3581
#creates fst tables for universal phoneme level 
begin
	fsttablephoneme = []
	for (ipanum, ipalet) in genipa
		structure = ""
		structure = structure * "0 1 " * string(ipanum) * " " * string(ipanum) * "\n"
		structure = structure * "1 1 " * string(ipanum) * " 0\n"
		structure = structure * "1"
		push!(fsttablephoneme, structure)
	end
	print(fsttablephoneme)
end

# ╔═╡ 8440b6e9-a3cf-4de3-8a56-33929f5d172c
#creates fst from tables for universal phonemes
begin
	listoftablesphoneme = []
	for table in fsttablephoneme
		push!(listoftablesphoneme, OF.VectorFst(TF.compile(table; openfst_compat = true)))
		
	end
end

# ╔═╡ 233a160f-1ef3-4cca-966f-46124ab46a8b
mydraw(TF.VectorFST(OF.union(listoftablesphoneme[2],listoftablesphoneme[3])), genipa, genipa)

# ╔═╡ 47d628f2-9ce6-400d-b713-7dcd20e1e06f
begin
	ps = ""
	for (ipanum, ipalet) in genipa
		if (ipanum == 1)
			continue
		end
		ps = ps * "1 2 " * string(ipanum) * " " * string(ipanum) * "\n"
		ps = ps * "2 2 " * " 1 " * string(ipanum) * " \n"
	end
	ps = ps * "2 1 1 1\n 2"	
end 

# ╔═╡ 9284b804-0b48-4ac8-a8d9-9ad4183516ef
begin
	H = TF.compile(ps)
	#mydraw(H, genipa, genipa)
	mydraw(H,genipa,genipa)
	#H Get this Image
end

# ╔═╡ 6155e3d4-a7eb-4dd4-b145-a9ebcdb8b1e1
mydraw(TF.VectorFST(OF.compose(OF.VectorFst(h), OF.VectorFst(y))), genipa, genipa)

# ╔═╡ cceb6df6-0904-48c5-8952-7d419f90c6a4
mydraw(TF.VectorFST(OF.compose(OF.VectorFst(y), OF.VectorFst(h))), genipa, genipa)

# ╔═╡ aad5eea8-6a38-4ed4-9739-861601544818
begin 
	lstruc = """
	1 2 50927 9
	2 3 1 2
	3
	"""
	L1 = TF.compile(lstruc)
	TF.draw(L1; isymbols = newwords, osymbols=genipa)  |> TF.dot(:svg) |> HTML
end 

# ╔═╡ e05cbcd8-070f-433c-a9c0-f1ed71034f8c
#function that creates generic FST for oov of k length

function genericFST(startstate::Int, k::Int, oov::Int)
	structure = ""
	finalstate = 0
	for state in startstate:k+startstate-1
		for (num, ipa) in genipa
			if (num == 1)
				continue
			end
			if (state == startstate)
				structure = structure * string(state) * " " * string(state+1) * " " * string(oov) * " " * string(num) * "\n"
			else
				structure = structure * string(state) * " " * string(state+1) * " " * "1 " * string(num) * "\n"
			end
		end
		if ((state != startstate) && (state != k+startstate-1))
			structure = structure * string(state) * " " * string(k+startstate) * " " * "1 1\n"
		end
	end
	structure = structure * string(k+startstate)
	return structure
end 


# ╔═╡ b764bf92-bbd1-46e7-b458-e7875330b346
begin
	s = genericFST(1,5, 125597 )
	L2 = TF. compile(s)
	mydraw(L2, newwords, genipa)
end

# ╔═╡ 30ddf048-33cb-4edf-8327-95d9b2769b00
OF.VectorFst(L2)

# ╔═╡ 662a6268-7181-4a93-a1c5-84dd0bf06739
begin
	L = TF.VectorFST(OF.union(OF.VectorFst(L1), OF.VectorFst(L2)))
	arc = TF.Arc{S}(1,1,0,1)
	TF.addarc!(L,3,arc)
	TF.addarc!(L,9,arc)
	# TF.setfinal!(L,1)
	L.finalweights = zeros(S,9)
	L.finalweights[1]=0
	mydraw(L, newwords, genipa)
	#mydraw2(L, newwords, genipa)
	#L Get this Image
end

# ╔═╡ 2dde771e-efa1-458d-b733-c1f7b648a001
L

# ╔═╡ 129b7589-2230-4321-809b-b708e6e7053d
mydraw((compose(G,L)), newwords, genipa)
#GL Get this Image

# ╔═╡ efe2f3f6-c864-46ec-9a2e-b9af00ff3018
mydraw(rmeps(compose(H, y)), genipa, genipa)
#HY Get this Image

# ╔═╡ 9939faec-b60f-47cf-b214-ec7cc88aa9b3
begin 
	GL = compose(G,L)
	# GL = rmeps(GL)
	#mydraw(GL, newwords, genipa)
	HY = compose(H, y)
	GLHY = compose(GL, HY)
	# GLHY = rmeps(GLHY)
	mydraw(GLHY, newwords, genipa)
	#mydraw2(GLHY, newwords, genipa)
	#GLHY Get Image
end

# ╔═╡ ec83cd7a-8908-4461-898b-f188740da029
begin 
	mydraw(invert(determinize(GLHY)),  newwords, genipa)
end

# ╔═╡ 2036f4c3-4b17-4956-8cda-60ea1a8cc7ea
begin 
	mydraw((invert(determinize(rmeps(GLHY)))),  genipa, newwords)
	#FINAL Get IMAGE
end

# ╔═╡ f385d490-cfde-4eb9-8d9e-b2fd84bc9eb6
begin 
	LG = compose(invert(L),G)
	LG = rmeps(LG)
	#mydraw(GL, newwords, genipa)
	YH = compose(y, invert(arcsort(reverse(H),OF.ilabel)))
	YHLG = compose(YH, LG)
	mydraw(YHLG, genipa, newwords)
end

# ╔═╡ aaa86817-466e-4e51-bd1e-7a888bd2a87a
begin 
	mydraw(rmeps(determinize(YHLG)), genipa, newwords)
end

# ╔═╡ 6bbcf423-efb5-4377-82c5-92b03c282f45
begin 
	mydraw(determinize(rmeps(YHLG)), genipa, newwords)
end

# ╔═╡ 8a0395cb-09ca-4456-8775-7b61ad3fba89
#gets desh's ipa symbol list 
begin
	deshipa = open(TF.loadsymbols, "/Users/meonak/Desktop/JSALT/openfst-1.8.2/tokens.txt")
	deshipa = sort(collect(deshipa))
	deshipa = Dict(deshipa)
end

# ╔═╡ ac1218fa-7770-47c7-a1a0-f2abb691f11e
#function that creates an FST with weights from matrix for given utterance 

function WFSTy(frames, matrix)
	structure = ""
	stateindex = 1
	for state in 1:frames
		eachstate = matrix[stateindex]
		arcindex = 1
		for num in 1:43
				structure = structure * string(state) * " " * string(state + 1) * " " * string(num) * " " * string(num) * " " * string(eachstate[arcindex]) * "\n"
				arcindex = arcindex + 1
		end
		stateindex = stateindex+1
	end
	structure = structure * string(frames+1)
	return structure
end 

# ╔═╡ deb01165-4576-4678-87ae-fd76178bfde8
#practice WFST for word "Just"
begin
	matx = [[-6.2363e-04, -9.8229e+00, -4.2901e+01, -1.1524e+01, -1.5052e+01,
         -1.0260e+01, -1.1113e+01, -1.2448e+01, -1.3706e+01, -1.0963e+01,
         -1.2155e+01, -1.0870e+01, -1.2808e+01, -1.1678e+01, -1.1284e+01,
         -1.1016e+01, -1.0259e+01, -1.1452e+01, -1.3598e+01, -1.1625e+01,
         -1.0759e+01, -9.9642e+00, -1.3955e+01, -1.5000e+01, -1.2343e+01,
         -9.5978e+00, -1.2047e+01, -1.1874e+01, -9.0691e+00, -1.4679e+01,
         -1.2720e+01, -1.1761e+01, -1.7201e+01, -1.0181e+01, -1.2456e+01,
         -1.3706e+01, -1.0287e+01, -1.2391e+01, -1.3562e+01, -1.5636e+01,
         -1.3778e+01, -1.7586e+01, -1.3213e+01],
        [-4.6850e-04, -1.2244e+01, -4.3404e+01, -1.1056e+01, -1.3134e+01,
         -1.2769e+01, -1.2396e+01, -1.3629e+01, -1.0994e+01, -1.2412e+01,
         -1.3081e+01, -1.2643e+01, -1.0185e+01, -1.3804e+01, -1.2726e+01,
         -1.1953e+01, -1.2161e+01, -1.0415e+01, -1.0939e+01, -1.2676e+01,
         -1.2324e+01, -1.0731e+01, -1.4786e+01, -1.1920e+01, -1.1649e+01,
         -1.1326e+01, -1.1490e+01, -1.1206e+01, -1.1913e+01, -1.4573e+01,
         -1.1785e+01, -1.1336e+01, -1.5509e+01, -9.5734e+00, -1.1028e+01,
         -1.0922e+01, -9.6234e+00, -1.2013e+01, -1.4819e+01, -1.3138e+01,
         -1.0699e+01, -1.7352e+01, -1.3609e+01],
        [-2.5901e-04, -1.1984e+01, -4.2386e+01, -1.3171e+01, -1.4270e+01,
         -1.2159e+01, -1.1143e+01, -1.4212e+01, -1.2761e+01, -1.2814e+01,
         -1.2467e+01, -1.0961e+01, -1.2935e+01, -1.3105e+01, -1.1432e+01,
         -1.1314e+01, -1.0804e+01, -1.0667e+01, -1.3896e+01, -1.2621e+01,
         -1.0912e+01, -1.0769e+01, -1.3739e+01, -1.4479e+01, -1.2103e+01,
         -1.1553e+01, -1.2066e+01, -1.3015e+01, -1.0870e+01, -1.3777e+01,
         -1.3303e+01, -1.3206e+01, -1.7032e+01, -1.1472e+01, -1.3124e+01,
         -1.2977e+01, -1.1494e+01, -1.1391e+01, -1.3373e+01, -1.5337e+01,
         -1.3640e+01, -1.5986e+01, -1.4304e+01],
        [-4.1715e-04, -1.1806e+01, -4.4126e+01, -1.2556e+01, -1.2988e+01,
         -1.2469e+01, -1.1844e+01, -1.5405e+01, -1.1205e+01, -1.3642e+01,
         -1.3418e+01, -1.2157e+01, -1.1126e+01, -1.3987e+01, -1.2176e+01,
         -1.2215e+01, -1.2419e+01, -1.1205e+01, -1.2581e+01, -1.3146e+01,
         -1.2182e+01, -1.0712e+01, -1.4619e+01, -1.2995e+01, -1.2803e+01,
         -1.1811e+01, -1.2708e+01, -1.1108e+01, -1.1263e+01, -1.3998e+01,
         -1.1458e+01, -1.1977e+01, -1.6208e+01, -8.9707e+00, -1.2013e+01,
         -1.0641e+01, -9.7573e+00, -1.2043e+01, -1.4370e+01, -1.3344e+01,
         -1.1493e+01, -1.7503e+01, -1.5645e+01],
        [-2.4089e-04, -1.0712e+01, -4.4839e+01, -1.3203e+01, -1.4222e+01,
         -1.2804e+01, -1.1542e+01, -1.4961e+01, -1.1923e+01, -1.3579e+01,
         -1.4906e+01, -1.3041e+01, -1.1620e+01, -1.5697e+01, -1.2321e+01,
         -1.1922e+01, -1.2447e+01, -1.0320e+01, -1.2983e+01, -1.4041e+01,
         -1.2874e+01, -1.1790e+01, -1.5269e+01, -1.4535e+01, -1.2094e+01,
         -1.3460e+01, -1.1441e+01, -1.2419e+01, -1.1836e+01, -1.2960e+01,
         -1.2875e+01, -1.3351e+01, -1.7758e+01, -1.0218e+01, -1.1175e+01,
         -1.1991e+01, -1.0906e+01, -1.2011e+01, -1.4907e+01, -1.4951e+01,
         -1.2360e+01, -1.7009e+01, -1.6722e+01],
        [-3.0549e-04, -8.4508e+00, -4.7886e+01, -1.3781e+01, -1.5267e+01,
         -1.2947e+01, -1.1544e+01, -1.5809e+01, -1.3048e+01, -1.3432e+01,
         -1.6592e+01, -1.3455e+01, -1.2190e+01, -1.6901e+01, -1.3935e+01,
         -1.2215e+01, -1.3934e+01, -1.1569e+01, -1.3388e+01, -1.4204e+01,
         -1.3562e+01, -1.2356e+01, -1.7189e+01, -1.6422e+01, -1.3722e+01,
         -1.4418e+01, -1.1872e+01, -1.3745e+01, -1.2408e+01, -1.4324e+01,
         -1.3790e+01, -1.3941e+01, -1.9663e+01, -1.1804e+01, -1.1764e+01,
         -1.3071e+01, -1.2057e+01, -1.2989e+01, -1.6275e+01, -1.6123e+01,
         -1.3098e+01, -1.8693e+01, -1.7300e+01],
        [-6.7616e-04, -7.4203e+00, -5.2290e+01, -1.3027e+01, -1.4388e+01,
         -1.3520e+01, -1.2491e+01, -1.4614e+01, -1.3854e+01, -1.4555e+01,
         -1.8278e+01, -1.5348e+01, -1.2328e+01, -1.7760e+01, -1.5667e+01,
         -1.1907e+01, -1.3741e+01, -1.1678e+01, -1.3296e+01, -1.6332e+01,
         -1.3072e+01, -1.3252e+01, -1.8337e+01, -1.6376e+01, -1.3741e+01,
         -1.5632e+01, -1.1338e+01, -1.3600e+01, -1.3664e+01, -1.4407e+01,
         -1.4342e+01, -1.4543e+01, -1.9946e+01, -1.2626e+01, -1.1311e+01,
         -1.3973e+01, -1.2477e+01, -1.3890e+01, -1.7380e+01, -1.6581e+01,
         -1.3115e+01, -1.9034e+01, -1.7771e+01],
        [-8.8700e-04, -7.8729e+00, -4.8109e+01, -1.0894e+01, -1.2961e+01,
         -1.1248e+01, -1.1796e+01, -9.2844e+00, -1.3135e+01, -1.2966e+01,
         -1.5907e+01, -1.4989e+01, -1.1042e+01, -1.6117e+01, -1.3549e+01,
         -1.0536e+01, -1.0536e+01, -1.0742e+01, -1.1745e+01, -1.3534e+01,
         -1.2835e+01, -1.1910e+01, -1.6994e+01, -1.5234e+01, -1.0955e+01,
         -1.5915e+01, -8.5829e+00, -1.4475e+01, -1.2583e+01, -1.1737e+01,
         -1.5547e+01, -1.4422e+01, -1.7998e+01, -1.1701e+01, -1.0812e+01,
         -1.3109e+01, -1.3154e+01, -1.2236e+01, -1.6267e+01, -1.7569e+01,
         -1.4534e+01, -1.6815e+01, -1.6031e+01],
        [-8.4329e+00, -1.2379e+01, -3.0266e+01, -1.2991e+01, -1.4129e+01,
         -1.0872e+01, -1.1139e+01, -7.4740e-04, -1.5456e+01, -1.1868e+01,
         -1.2649e+01, -1.2572e+01, -1.3480e+01, -9.5113e+00, -1.0964e+01,
         -1.0232e+01, -8.5103e+00, -1.2624e+01, -1.4190e+01, -1.2269e+01,
         -1.1268e+01, -1.1447e+01, -1.2595e+01, -1.7283e+01, -1.1821e+01,
         -1.3843e+01, -1.1497e+01, -1.6333e+01, -1.0431e+01, -1.3430e+01,
         -1.6330e+01, -1.5942e+01, -1.5940e+01, -1.5252e+01, -1.3563e+01,
         -1.4647e+01, -1.3219e+01, -1.1361e+01, -1.0893e+01, -1.8526e+01,
         -1.3241e+01, -1.0658e+01, -1.6432e+01],
        [-8.9301e+00, -1.1918e+01, -3.9115e+01, -1.0441e+01, -1.3160e+01,
         -1.5107e+01, -1.4654e+01, -1.2660e+01, -1.2362e+01, -1.5789e+01,
         -1.8085e+01, -1.7491e+01, -1.3076e+01, -1.7659e+01, -1.5848e+01,
         -1.4247e+01, -1.3700e+01, -1.3455e+01, -8.3749e+00, -1.3638e+01,
         -1.2952e+01, -1.3635e+01, -1.7297e+01, -1.0101e+01, -1.6074e+01,
         -1.5645e+01, -1.4506e+01, -1.0828e+01, -1.4723e+01, -1.5163e+01,
         -1.1168e+01, -1.0318e+01, -1.2457e+01, -1.0141e+01, -1.0843e+01,
         -8.8271e+00, -4.4581e+00, -1.5021e+01, -1.8559e+01, -1.1764e+01,
         -1.2407e-02, -1.7332e+01, -1.7645e+01],
        [-7.9957e+00, -1.3550e+01, -3.7662e+01, -1.3606e+01, -1.6385e+01,
         -1.2967e+01, -1.1898e+01, -1.2480e+01, -1.5658e+01, -1.2204e+01,
         -1.4146e+01, -1.5278e+01, -1.4837e+01, -1.5375e+01, -1.2414e+01,
         -1.1826e+01, -1.0346e+01, -8.8000e+00, -1.4418e+01, -1.1800e+01,
         -6.2923e-04, -1.3763e+01, -1.3612e+01, -1.6575e+01, -1.2488e+01,
         -1.4023e+01, -1.0256e+01, -1.6473e+01, -1.4513e+01, -1.1671e+01,
         -1.7300e+01, -1.6975e+01, -1.5934e+01, -1.4604e+01, -1.4697e+01,
         -1.6209e+01, -1.3932e+01, -1.1724e+01, -1.4169e+01, -1.7401e+01,
         -1.2195e+01, -1.6497e+01, -1.4590e+01],
        [-5.4801e+00, -1.2171e+01, -4.2502e+01, -1.3281e+01, -1.4812e+01,
         -1.2228e+01, -1.0389e+01, -1.2617e+01, -1.3390e+01, -1.2899e+01,
         -1.3200e+01, -1.4225e+01, -1.2055e+01, -1.4263e+01, -1.1230e+01,
         -9.8444e+00, -1.2408e+01, -1.2468e+01, -1.2107e+01, -1.0250e+01,
         -1.0787e+01, -4.4846e-03, -1.2011e+01, -1.4830e+01, -1.2153e+01,
         -1.2381e+01, -1.2871e+01, -1.3247e+01, -1.3044e+01, -1.3288e+01,
         -1.3457e+01, -1.3652e+01, -1.9085e+01, -9.5636e+00, -1.3227e+01,
         -1.4031e+01, -1.1953e+01, -1.3231e+01, -1.6919e+01, -1.6039e+01,
         -1.2889e+01, -1.9073e+01, -1.5005e+01],
        [-1.2561e+00, -1.2139e+01, -4.4263e+01, -1.1956e+01, -1.2965e+01,
         -9.4037e+00, -9.6462e+00, -1.1158e+01, -1.2014e+01, -1.0928e+01,
         -1.1316e+01, -1.2138e+01, -1.0404e+01, -1.2521e+01, -1.1017e+01,
         -7.1851e+00, -1.1157e+01, -1.0283e+01, -1.1670e+01, -1.0050e+01,
         -1.0654e+01, -3.3754e-01, -1.1937e+01, -1.2799e+01, -1.1682e+01,
         -9.3243e+00, -1.1304e+01, -1.0552e+01, -1.1246e+01, -1.1402e+01,
         -1.1549e+01, -9.3190e+00, -1.6815e+01, -8.3997e+00, -1.1816e+01,
         -1.2535e+01, -1.0126e+01, -1.0838e+01, -1.5965e+01, -1.4277e+01,
         -1.2242e+01, -1.7032e+01, -1.3231e+01],
        [-2.2913e-03, -1.3623e+01, -4.8261e+01, -1.1517e+01, -1.2831e+01,
         -1.0685e+01, -1.0499e+01, -1.2576e+01, -1.2816e+01, -1.1652e+01,
         -1.2339e+01, -1.1829e+01, -9.6751e+00, -1.2860e+01, -1.2608e+01,
         -7.0600e+00, -1.3242e+01, -1.0627e+01, -1.1900e+01, -1.2461e+01,
         -1.0795e+01, -6.9321e+00, -1.4085e+01, -1.3253e+01, -1.3414e+01,
         -1.0951e+01, -1.1418e+01, -1.0193e+01, -1.2407e+01, -1.3107e+01,
         -1.0972e+01, -1.1427e+01, -1.6506e+01, -9.7323e+00, -1.2603e+01,
         -1.1627e+01, -1.0163e+01, -1.1123e+01, -1.5475e+01, -1.3707e+01,
         -1.2040e+01, -1.7748e+01, -1.4201e+01],
        [-1.3065e-03, -1.2693e+01, -4.7944e+01, -1.1369e+01, -1.1487e+01,
         -1.1522e+01, -1.0439e+01, -1.3177e+01, -1.2199e+01, -1.0987e+01,
         -1.1853e+01, -1.1414e+01, -9.5631e+00, -1.2469e+01, -1.1821e+01,
         -8.0229e+00, -1.2187e+01, -9.9959e+00, -1.0907e+01, -1.2789e+01,
         -8.4332e+00, -9.3964e+00, -1.3107e+01, -1.2321e+01, -1.2678e+01,
         -1.0898e+01, -1.0884e+01, -9.7871e+00, -1.1661e+01, -1.1782e+01,
         -1.1026e+01, -1.3097e+01, -1.6069e+01, -9.4451e+00, -1.2178e+01,
         -1.0237e+01, -8.9686e+00, -1.1270e+01, -1.3029e+01, -1.2741e+01,
         -1.1220e+01, -1.8085e+01, -1.3471e+01],
        [-1.6445e-03, -1.1620e+01, -4.5216e+01, -1.1573e+01, -1.1760e+01,
         -1.0481e+01, -1.0013e+01, -1.2560e+01, -1.2398e+01, -1.0562e+01,
         -1.1980e+01, -1.0861e+01, -8.1668e+00, -1.2833e+01, -1.0883e+01,
         -8.4961e+00, -1.1888e+01, -9.5863e+00, -1.0387e+01, -1.1258e+01,
         -8.5917e+00, -8.3228e+00, -1.0686e+01, -1.1145e+01, -1.2448e+01,
         -1.0138e+01, -1.0227e+01, -1.0302e+01, -1.0713e+01, -9.6134e+00,
         -1.2343e+01, -1.4140e+01, -1.5616e+01, -9.7430e+00, -1.0565e+01,
         -1.0976e+01, -1.0076e+01, -1.1025e+01, -1.2475e+01, -1.2290e+01,
         -1.1588e+01, -1.7761e+01, -1.2220e+01],
        [-1.9836e-03, -1.2169e+01, -4.4162e+01, -1.1451e+01, -1.2580e+01,
         -1.0866e+01, -8.3658e+00, -1.1738e+01, -1.2979e+01, -1.1321e+01,
         -1.2413e+01, -1.0132e+01, -8.4654e+00, -1.0991e+01, -1.0369e+01,
         -8.6405e+00, -1.1101e+01, -1.0098e+01, -1.0684e+01, -9.9450e+00,
         -9.5106e+00, -8.3371e+00, -9.4890e+00, -1.0241e+01, -1.1331e+01,
         -9.7607e+00, -9.4419e+00, -8.0141e+00, -1.0650e+01, -1.1166e+01,
         -1.3649e+01, -1.3547e+01, -1.6564e+01, -1.1536e+01, -1.0815e+01,
         -1.0357e+01, -1.0649e+01, -1.0546e+01, -1.1425e+01, -1.3823e+01,
         -1.3051e+01, -1.6902e+01, -1.1453e+01],
        [-5.3843e+00, -1.0910e+01, -3.9253e+01, -8.8414e+00, -9.1764e+00,
         -1.1500e+01, -1.1175e+01, -1.4840e+01, -9.8428e+00, -1.2242e+01,
         -1.3544e+01, -1.3765e+01, -1.0073e+01, -1.3797e+01, -1.1163e+01,
         -1.1656e+01, -1.2136e+01, -1.1320e+01, -7.9089e+00, -1.1701e+01,
         -1.1676e+01, -1.0740e+01, -1.4498e+01, -9.9382e+00, -1.3307e+01,
         -1.2164e+01, -8.9942e+00, -2.1825e-02, -1.2371e+01, -1.3202e+01,
         -8.2992e+00, -8.1073e+00, -1.3377e+01, -8.0194e+00, -9.1594e+00,
         -4.2762e+00, -6.9319e+00, -1.2199e+01, -1.4998e+01, -1.1605e+01,
         -9.2031e+00, -1.7679e+01, -1.3026e+01],
        [-5.2630e+00, -1.2649e+01, -3.6969e+01, -1.1984e+01, -1.4445e+01,
         -8.8062e+00, -7.7129e+00, -1.1860e+01, -1.3246e+01, -8.9690e+00,
         -1.1008e+01, -1.3642e+01, -1.1185e+01, -1.3432e+01, -8.3308e+00,
         -9.1599e+00, -9.8470e+00, -7.7865e+00, -1.2780e+01, -1.0511e+01,
         -8.6956e+00, -6.6721e+00, -1.1816e+01, -1.2361e+01, -8.5199e+00,
         -1.0781e+01, -8.8999e-03, -1.1712e+01, -9.4552e+00, -9.4293e+00,
         -1.3832e+01, -1.2473e+01, -1.5258e+01, -1.0687e+01, -1.1009e+01,
         -1.1649e+01, -1.1083e+01, -9.2125e+00, -1.2595e+01, -1.5778e+01,
         -1.3333e+01, -1.2948e+01, -9.8575e+00],
        [-3.1132e-03, -1.4429e+01, -4.6430e+01, -1.0555e+01, -1.2303e+01,
         -9.9297e+00, -1.1266e+01, -1.5406e+01, -1.1490e+01, -1.0582e+01,
         -1.2453e+01, -1.3135e+01, -1.0624e+01, -1.1632e+01, -1.1007e+01,
         -1.2334e+01, -1.2006e+01, -1.1374e+01, -1.2821e+01, -1.1605e+01,
         -1.1685e+01, -8.6410e+00, -1.6909e+01, -1.1429e+01, -1.2251e+01,
         -9.5556e+00, -6.2979e+00, -1.0685e+01, -1.0989e+01, -1.4672e+01,
         -1.0756e+01, -1.0013e+01, -1.5680e+01, -8.6538e+00, -1.0267e+01,
         -1.0114e+01, -8.0490e+00, -1.0863e+01, -1.4709e+01, -1.2412e+01,
         -9.4465e+00, -1.9070e+01, -1.4702e+01]]
	pracwfst = WFSTy(20, matx)
	pracwfstcomp = TF.compile(pracwfst)
	#TF.draw(pracwfstcomp; isymbols = deshipa, osymbols = deshipa) |> TF.dot(:svg) |> HTML
	mydraw(pracwfstcomp, deshipa, deshipa)
	
end

# ╔═╡ bd7b29eb-b325-4fdb-98db-ba0d6e340560
OF

# ╔═╡ 2abf17ec-9494-47d8-81ed-e6c5534758ab


# ╔═╡ Cell order:
# ╟─62b13db7-d78f-4ed4-84a7-fd62fc24cf60
# ╠═beebec3d-a6b1-4623-a54f-df7d6235209d
# ╠═0fcad8d4-254a-11ee-3f4f-f904c5cdd31b
# ╠═fedccb6f-f6a6-436c-bd83-6877b4f1cf10
# ╠═9b1bc8f1-659f-4372-8a98-d57773df1f3d
# ╠═1bd7b45e-13e8-44ef-be22-c10db80a477e
# ╠═323945e6-4a9d-446e-b678-8139e1424bc1
# ╠═584e7982-7de1-4201-acd4-c940429e5bce
# ╠═ba0d7aad-f53c-402c-b9bc-df1880e2ad35
# ╠═b5f68249-6f43-4b70-be8b-7c36128f3581
# ╠═8440b6e9-a3cf-4de3-8a56-33929f5d172c
# ╠═ef5f7926-6f32-406e-8abb-9d6a742199d5
# ╠═233a160f-1ef3-4cca-966f-46124ab46a8b
# ╠═47d628f2-9ce6-400d-b713-7dcd20e1e06f
# ╠═9284b804-0b48-4ac8-a8d9-9ad4183516ef
# ╠═36436801-081c-4c39-94d0-b8742e18e811
# ╠═6155e3d4-a7eb-4dd4-b145-a9ebcdb8b1e1
# ╠═cceb6df6-0904-48c5-8952-7d419f90c6a4
# ╠═ff15d01f-4595-46c5-a5ea-659d735c108a
# ╠═357504ca-1c06-4394-86f3-ddf418a7697b
# ╠═06b06426-d831-4699-9ae6-8c88092b6335
# ╠═1d7fa834-bff8-4f1b-9e04-92666903aef4
# ╠═36cc4314-7423-44dd-8c0a-6997860c5795
# ╠═31dc6a97-2e34-47cd-8957-e1e0c1b1ab26
# ╠═d450794e-63f1-40bc-a738-22c47a15e2a6
# ╠═aad5eea8-6a38-4ed4-9739-861601544818
# ╠═e05cbcd8-070f-433c-a9c0-f1ed71034f8c
# ╠═b764bf92-bbd1-46e7-b458-e7875330b346
# ╠═30ddf048-33cb-4edf-8327-95d9b2769b00
# ╠═66e5a34a-f9ff-44a0-a709-23e44eddba2e
# ╠═662a6268-7181-4a93-a1c5-84dd0bf06739
# ╠═59de4f52-df10-4c1c-9ff0-c728ab3664b0
# ╠═2dde771e-efa1-458d-b733-c1f7b648a001
# ╠═ee87d962-f2af-49b2-a951-00c086a9a322
# ╠═129b7589-2230-4321-809b-b708e6e7053d
# ╠═efe2f3f6-c864-46ec-9a2e-b9af00ff3018
# ╠═9939faec-b60f-47cf-b214-ec7cc88aa9b3
# ╠═ec83cd7a-8908-4461-898b-f188740da029
# ╠═2036f4c3-4b17-4956-8cda-60ea1a8cc7ea
# ╠═cd5d56e3-54af-4677-af73-1d22755b0602
# ╠═5f5c30ea-f3ad-4a35-b76d-842ac229c4e8
# ╠═4372ef4b-f6e3-465e-9dc3-d54430c71792
# ╠═c5c726b1-3316-4ab9-a8bf-b0b708eda089
# ╠═b0030b95-1817-4d8b-97e0-6ec40eb44c0f
# ╠═a61cd541-6b51-435a-9037-6d03b73780ef
# ╠═f385d490-cfde-4eb9-8d9e-b2fd84bc9eb6
# ╠═aaa86817-466e-4e51-bd1e-7a888bd2a87a
# ╠═6bbcf423-efb5-4377-82c5-92b03c282f45
# ╠═493e4d4c-bcc6-40ae-8dfa-e3d96742d148
# ╠═8a0395cb-09ca-4456-8775-7b61ad3fba89
# ╠═ac1218fa-7770-47c7-a1a0-f2abb691f11e
# ╠═deb01165-4576-4678-87ae-fd76178bfde8
# ╠═bd7b29eb-b325-4fdb-98db-ba0d6e340560
# ╠═2abf17ec-9494-47d8-81ed-e6c5534758ab
