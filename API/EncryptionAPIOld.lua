--An old version that works for latter editing for optimization

--Keys

local Primes = {2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97,101,103,107,109,113,127,131,137,139,149,151,157,163,167,173,179,181,191,193,197,199,211,223,227,229,233,239,241,251,257,263,269,271,277,281,283,293,307,311,313,317,331,337,347,349,353,359,367,373,379,383,389,397,401,409,419,421,431,433,439,443,449,457,461,463,467,479,487,491,499,503,509,521,523,541,547,557,563,569,571,577,587,593,599,601,607,613,617,619,631,641,643,647,653,659,661,673,677,683,691,701,709,719,727,733,739,743,751,757,761,769,773,787,797,809,811,821,823,827,829,839,853,857,859,863,877,881,883,887,907,911,919,929,937,941,947,953,967,971,977,983,991,997,1009,1013,1019,1021,1031,1033,1039,1049,1051,1061,1063,1069,1087,1091,1093,1097,1103,1109,1117,1123,1129,1151,1153,1163,1171,1181,1187,1193,1201,1213,1217,1223}
local SecurityFactor = 2

function GetKeys(Length)
	local Keys = {NT = "",ET = "",DT = ""}
	
	for x=1,Length do
		local N,E,D = GetKeyNum()
		
		for k,v in pairs({NT = N, ET = E, DT = D}) do
			Keys[k] = Keys[k]..ByteToString(v)
		end
	end
	
	local Public = Keys.NT.."ÿ"..Keys.ET
	local Private = Keys.NT.."ÿ"..Keys.DT
	return Public,Private
end

function GetKeyNum()
	local P,Q,N = GetPrimes()
	local V = (P-1)*(Q-1)
	local E = GetCoPrime(V)
	local D = modInverse(E,V)
	return N,E,D
end

function GetPrimes()
	local Min
	local Max
	local MinValue = 1
	local SecPower = 1
	local Power1 = 255^SecurityFactor
	if (SecurityFactor>1) then
		SecPower = 255^(SecurityFactor-(.2*SecurityFactor))
	end
	for k,v in pairs(Primes) do
		if not Min and (v*v>=SecPower) then
			Min = k
			MinValue = v
		elseif not Max and (v*MinValue)>Power1 then
			Max = k-1
		end
	end
	
	local P = Primes[math.random(Min,Max)]
	local Q = Primes[math.random(Min,Max)]
	while ((P==Q) or (Q*P>Power1)) do
		Q = Primes[math.random(Min,Max)]
	end
	return P,Q,Q*P
end

--Keys
--Encryption

function DecryptStri(Stri,Private)
	--Decypts the msg with a private key
	local Tab = SplitStri(Private,"ÿ") --1=N 2=D
	return table.unpack({EncryptStriInner(Stri,Tab[2],Tab[1])})
end

function EncryptStri(Stri,Public)
	--Encrypts the msg with a public key
	local Tab = SplitStri(Public,"ÿ") --1=N 2=E
	return table.unpack({EncryptStriInner(Stri,Tab[2],Tab[1],true)})
end

function EncryptStriInner(Stri1,EStri1,NStri1,Encrypting)
	--Encryption MSG, E:key, N:key
	--Decryption MSG, D:key, N:key
	local Stri = {} 
	Stri.Stri = Stri1 
	Stri.At = 0
	local NStri = {} 
	NStri.Stri = NStri1 
	NStri.At = 0
	local EStri = {} 
	EStri.Stri = EStri1 
	EStri.At = 0
	local Ret = ""
	
	local ReadIn = 1
	if not(Encrypting) then
		ReadIn = SecurityFactor
	end
	
	while #Stri.Stri>Stri.At do
		Ret = Ret..EncryptChar(Encrypting,ReadCharters(Stri,ReadIn),ReadCharters(EStri,SecurityFactor),ReadCharters(NStri,SecurityFactor))
	end
	return Ret
end

function EncryptChar(Encrypting,Stri,EStri,NStri)
	local M = ""
	if not Encrypting then
		M = StriToByte(Stri)
	else
		M = string.byte(Stri)
	end
	local E = StriToByte(EStri)
	local N = StriToByte(NStri)
	local Byte = EncryptMod(M,E,N)
	
	if (Byte>=255^SecurityFactor) then
		error("Byte>="..tostring(255^SecurityFactor))
	end
	if Encrypting then
		return ByteToString(Byte)
	else
		return string.char(Byte)
	end
end

function ReadCharter(File)
	--Reads a string charater by charater
	local Grab = Clamp(File.At+1,1,#File.Stri)
	File.At = File.At+1
	return File.Stri:sub(Grab,Grab)
end

function ReadCharters(File,Amount)
	--Reads a string charaters at a time defined by Amount
	local Ret = ""
	for i=1,Amount do
		Ret=Ret..ReadCharter(File)
	end
	
	return Ret
end

--Encyption
--Stri-Number handers

---

--
--READ THEEE CALCULATOR ME BOY MAKE EQUATION
--

function StriToByte(Stri)
	local Ret = 0
	for i=1,SecurityFactor do
		local Power = 255^-(i-SecurityFactor)
		Ret = Ret+(string.byte(Stri:sub(i,i))*Power)
	end
	return Ret
end

function ByteToString(Byte)
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

function Test()
	Public,Private = EncryptionAPI.GetKeys(1)
	Sending = "A"
	Msg = EncryptionAPI.EncryptStri(Sending,Public)
end
-- function Test()
	-- print("Start",os.clock())
	-- Public,Private = EncryptionAPI.GetKeys(20)
	-- print("Key",os.clock())
	-- Sending = ""
	-- for i=1,1000 do
		-- Sending=Sending..string.char(Clamp(i,0,254))
	-- end
	-- print("Sending",os.clock())
	-- --Sending = "A"
	
	-- Msg = EncryptionAPI.EncryptStri(Sending,Public)
	-- print("Encrypt",os.clock())
	-- Msg1 = EncryptionAPI.DecryptStri(Msg,Private)
	-- print("Decrypt",os.clock())
	-- Worked = Sending==Msg1
	-- printError("OUT",Worked)
	-- -- for k,v in pairs({Public,Private,Msg,Msg1,Sending}) do
		-- -- print(v)
	-- -- end
-- end

--Stri-Number handers
--Extra FNC

function SplitStri(In,Sep)
	local Ret={}
	for Stri in string.gmatch(In, "([^"..Sep.."]+)") do
		table.insert(Ret, Stri)
	end
	return Ret
end

--Extra FNC
--Math functions

function Clamp(x,min1,max1)
	return ((x-min1)%(max1-min1+1))+min1
end

function GetCoPrime(n)
	local r = 0
	while (not(gcd_two_numbers(r,n) == 1) or (r == 1)) do
		r = Round(math.random(1,10000)*n/10000)
	end
	return r
end

function gcd_two_numbers(x, y)
	if ((x==0) or (y==0)) then
		return -1
	end
	x = math.abs(x)
	y = math.abs(y)
	while not(y==0) do
		local t = y
		y = x % y
		x = t
	end
	return x
end

function Round(x)
	return x + 0.5 - (x + 0.5) % 1
end

function modInverse(a, m)
	a = a%m; 
	for x=1,m do
		if ((a*x) % m == 1) then
			return x;
		end
	end
end

function EncryptMod(m, e, n)
	local r = 1
	for x=1,e do
		r = ((r*m) % n)
	end
	return r
end

--Math functions
--EncryptionAPI.mod2(100,13,77)