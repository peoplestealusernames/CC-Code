--Intro

--Encryption and Decryption api because why not
--Uses end to end encyption meaning public and private keys
--NEVER GIVE AWAY YOUR PRIVATE KEY ITS THE ONLY THING THAT CAN DECRYPT THE MSG
--Keys are
--Public = *N String*ÿ*E String*
--Private = *N String*ÿ*D String*
--ÿ is the 255 char and this api wont use char above 254

--Encryption and Decryption could take a while depending on the size of keys and length of string given
--For example a 1000 char string took me 5-8 seconds to encypt and the same time to decrypt with SecurityFactor = 2
--Key generator however takes about a second for a very long key or SecurityFactor>2
--Key size can be limited with the Max value on GetKeys() however it will also need a min value
--Keep in mind this API turns your msg into numbers but transmits them as strings to save space
--With that said the smaller the key values(not length) the eaiser to break the encyption but longer to proccess
--Key length changes how many changes their are which means their are more values to crack if your message is longer

--Intro
--Config

local SecurityFactor = 2 --How big the blocks are
--Ex 1 means it only looks at 1 char at a time so your limit is 0-254
--2 means it looks at 2 at a time so your got 254^2 numbers and so on
--This also means the numbers used are expentialy bigger and that can lead the
--EncryptMod function to error out for taking to long

--Config
--Declarations

local GetKeyNum,GetPrimes
local ByteToString,StriToByte
local EncryptMod,modInverse,Round,gcd_two_numbers,GetRelPrime,Clamp,SplitStri

--Declarations
--Keys

local Primes = {2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97,101,103,107,109,113,127,131,137,139,149,151,157,163,167,173,179,181,191,193,197,199,211,223,227,229,233,239,241,251,257,263,269,271,277,281,283,293,307,311,313,317,331,337,347,349,353,359,367,373,379,383,389,397,401,409,419,421,431,433,439,443,449,457,461,463,467,479,487,491,499,503,509,521,523,541,547,557,563,569,571,577,587,593,599,601,607,613,617,619,631,641,643,647,653,659,661,673,677,683,691,701,709,719,727,733,739,743,751,757,761,769,773,787,797,809,811,821,823,827,829,839,853,857,859,863,877,881,883,887,907,911,919,929,937,941,947,953,967,971,977,983,991,997,1009,1013,1019,1021,1031,1033,1039,1049,1051,1061,1063,1069,1087,1091,1093,1097,1103,1109,1117,1123,1129,1151,1153,1163,1171,1181,1187,1193,1201,1213,1217,1223}

function GetKeys(Length,MaxSize,MinSize)--MaxSize,MinSize are not required but if used both are need
	--Generates public,private keys
	--MaxSize is the max value a single part of the key can hold
	--MinSize is the same for the min value
	--For min and max remember that the possible min is ~20 and possible max is ~255^SecurityFactor
	local Keys = {NT = "",ET = "",DT = ""}
	
	if MaxSize or MinSize then
		if not(MaxSize and MinSize) then
			error("Min or max given but no the other")
		end
	end
	
	if not MinSize then
		MinSize = 255^(SecurityFactor-(.2*SecurityFactor))
	end
	if not MaxSize then
		MaxSize = 255^SecurityFactor
	end
	
	local Min
	local Max = #Primes
	local MinValue = 1
	
	for k,v in pairs(Primes) do
		if not Min and (v*v>=MinSize) then
			Min = k
			MinValue = v
		elseif Max and (v*MinValue)>=MaxSize then
			Max = k-1
			break
		end
	end
	
	for x=1,Length do
		local N,E,D = GetKeyNum(MaxSize,MinSize,Min,Max)
		
		for k,v in pairs({NT = N, ET = E, DT = D}) do
			Keys[k] = Keys[k]..ByteToString(v)
		end
	end
	
	local Public = Keys.NT.."ÿ"..Keys.ET
	local Private = Keys.NT.."ÿ"..Keys.DT
	return Public,Private
end

function GetKeyNum(MaxSize,MinSize,Min,Max)--Local
	--Gets the numbers that will go into the keys
	local P,Q,N = GetPrimes(MaxSize,Min,Max)
	local V = (P-1)*(Q-1)
	local E = GetRelPrime(V,Min,Max)
	local D = modInverse(E,V)
	return N,E,D
end

function GetPrimes(MaxSize,Min,Max)--Local
	--Local gets prime numbers
	local P = Primes[math.random(Min,Max)]
	local Q = Primes[math.random(Min,Max)]
	while ((P==Q) or (Q*P>MaxSize)) do
		Q = Primes[math.random(Min,Max)]
	end
	return P,Q,Q*P
end

--Keys
--Encryption

function DecryptStri(Stri,Private)
	--Decrypts the msg with a private key
	local NStri,DStri = table.unpack(SplitStri(Private,"ÿ")) --1=N 2=D
	local KeyLength = #NStri
	
	local Ret = ""
	for i=1,(#Stri/SecurityFactor) do
		local Get = (i-1)*SecurityFactor+1
		local Get1 = Clamp((i-1)*SecurityFactor+1,1,KeyLength)
		Ret=Ret..string.char(EncryptMod(
			StriToByte(Stri:sub(Get,Get+SecurityFactor)),
			StriToByte(DStri:sub(Get1,Get1+SecurityFactor)),
			StriToByte(NStri:sub(Get1,Get1+SecurityFactor))
		))
	end
	return Ret
end

function EncryptStri(Stri,Public)
	--Encrypts the msg with a public key
	local NStri,EStri = table.unpack(SplitStri(Public,"ÿ")) --1=N 2=E
	local KeyLength = #NStri
	
	local Ret = ""
	for i=1,#Stri do
		local Get1 = Clamp((i-1)*SecurityFactor+1,1,KeyLength)
		Ret=Ret..ByteToString(EncryptMod(
			string.byte(Stri:sub(i,i)),
			StriToByte(EStri:sub(Get1,Get1+SecurityFactor)),
			StriToByte(NStri:sub(Get1,Get1+SecurityFactor))
		))
	end
	return Ret
end

--Encyption
--Stri-Number handers

function StriToByte(Stri)--Local
	--Truns a string back into its number version
	local Ret = 0
	for i=1,SecurityFactor do
		local Power = 255^-(i-SecurityFactor)
		Ret = Ret+(string.byte(Stri:sub(i,i))*Power)
	end
	return Ret
end

function ByteToString(Byte)--Local
	--Turns numbers into string
	local Ret = ""
	for i=1,SecurityFactor do
		local Power = 255^-(i-SecurityFactor)
		local Val = math.floor(Byte/Power)
		Byte = Byte-Val*Power
		if (Val>254) then
			error("Byte>254")
		end
		Ret = Ret..string.char(Val)
	end
	return Ret
end

--Stri-Number handers
--Extra FNC

function SplitStri(In,Sep)--Local
	local Ret={}
	for Stri in string.gmatch(In, "([^"..Sep.."]+)") do
		table.insert(Ret, Stri)
	end
	return Ret
end

--Extra FNC
--Math functions

function Clamp(x,min1,max1)--Local
	--Keeps x between min and max
	return ((x-min1)%(max1-min1+1))+min1
end

function GetRelPrime(n)--Local
	--Gets a number where the only GCD is 1
	local r = 0
	while (not(gcd_two_numbers(r,n) == 1) or (r == 1)) do
		r = Round(math.random()*n)
	end
	return r
end

function gcd_two_numbers(a, b)--Local
	--Gets the greatest common denominator
	if ((a==0) or (b==0)) then
		return -1
	end
	
	while true do
        if (a > b) then
            a = a%b
			if (a==0) then
				return b
			end
        else
            b = b%a
			if (b==0) then
				return a
			end
		end
    end
end

function Round(x)--Local
	return x + 0.5 - (x + 0.5) % 1
end

function modInverse(a, m)--Local
	--I dont know
	a = a%m
	for x=1,m do
		if ((a*x) % m == 1) then
			return x
		end
	end
end

function EncryptMod(m, e, n)--Local
	--I also dont know
	local r = 1
	for x=1,e do
		r = ((r*m) % n)
	end
	return r
end

--Math functions