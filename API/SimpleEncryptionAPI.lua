
--string.byte("string")
--string.char(number)
--Number cannot be >255
--Primes cannot be the same
--Because of mod if keys < 255 then the numbers will be to as such only need to fit key into string

--Keys

local Primes = {2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97,101,103,107,109,113,127}

function GetKeys(Length)
	local NT = ""
	local ET = ""
	local DT = ""
	
	for x=1,Length do
		local N,E,D = GetKeyNum()
		NT = NT..string.char(N)
		ET = ET..string.char(E)
		DT = DT..string.char(D)
	end
	
	local Public = NT.."ÿ"..ET
	local Private = NT.."ÿ"..DT
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
	local P = Primes[math.random(1,#Primes)]
	local Q = Primes[math.random(1,#Primes)]
	while ((P==Q) or (Q*P>255)) do
		Q = Primes[math.random(1,#Primes)]
	end
	return P,Q,Q*P
end

--EncryptionAPI.GetCoPrime(31)

--Keys
--Encryption

-- Msg = EncryptionAPI.EncryptStri("HELLO ECHO 123 AAAA","ABCDÿ1234")

function Test()
	Public,Private = EncryptionAPI.GetKeys(10)
	print(Public,Private)
	Sending = "ABCDE1234"
	Msg = EncryptionAPI.EncryptStri(Sending,Public)
	Msg1 = EncryptionAPI.DecryptStri(Msg,Private)
	Worked = Sending==Msg1
	return Worked,Public,Private,Msg,Msg1,Sending
end

function DecryptStri(Stri,Private)
	--Decypts the msg with a private key
	local Tab = SplitStri(Private,"ÿ") --1=N 2=D
	print("DE",Tab[1],Tab[2])
	return table.unpack({EncryptStriInner(Stri,Tab[2],Tab[1])})
end

function EncryptStri(Stri,Public)
	--Encrypts the msg with a public key
	local Tab = SplitStri(Public,"ÿ") --1=N 2=E
	print("En",Tab[1],Tab[2])
	return table.unpack({EncryptStriInner(Stri,Tab[2],Tab[1])})
end

function EncryptStriInner(Stri1,EStri1,NStri1)
	--Encryption MSG, E:key, N:key
	--Decryption MSG, N:key, D:key
	printError("FNC",Stri1,EStri1,NStri1)
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
	
	while true do
		local Char,Err = ReadCharter(Stri)
		if Err then
			return Ret,Err
		end
		Ret = Ret..EncryptChar(Char,ReadCharter(EStri),ReadCharter(NStri))
	end
end

function EncryptChar(Stri,EStri,NStri)
	local M = string.byte(Stri)
	local E = string.byte(EStri)
	local N = string.byte(NStri)
	local Stri = EncryptMod(M,E,N)
	if (Stri>255) then
		error("EncryptSingle() EncryptionAPI |Stri>255")
	end
	return string.char(Stri)
end

function ReadCharter(File)
	--Reads a string line by line
	local Extra
	if (File.At>=#File.Stri) then
		File.At = 1
		Extra = true
	else
		File.At = File.At+1
	end
	
	return File.Stri:sub(File.At,File.At),Extra
end

--Encyption
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
