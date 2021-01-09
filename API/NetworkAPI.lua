--Intro

--network/modem packet manager
--Setup(Modem,DefaultPort:number) has to be run

--If you use this often i would recommend using a common function "API"
--This will help with standerization and having universtal functions
--to rely on if something break and you cant get to it to fix it

--For the op on unpack rather than lines of if and elseif use a table ex:
--local Op,Payload,Dest,ToUs = Unpack(MSG)
--local OPS = ["Reply" = ReplyFNC,"Test" = TestFNC]
--OPS[op] --May be nil if invalid
--local Res,Err = pcall(OPS,Payload,Dest,ToUs)

--Intro
--Declarations

os.loadAPI("SerialiseAPI.lua")

local DefaultPort,Modem --SetupValues

local IsSetup,Checker,CheckTable,CheckData

local MYID = os.computerID()

--Declarations
--Functions

function Setup(A,B)
	--Does not open port but saves Modem and DefaultPort
	--That is used for sending this FNC is required to run
	Modem = A DefaultPort = B
end

function Unpack(Stri)
	--Unpacks stri from Pack function
	local Data,Err = unserialise(Stri)
	if not Data then
		return nil,Err
	end
	
	local Op = Data.op
	local Payload = Data.d
	local Dest = Data.Dest
	local SID = Data.SID
	
	local Res,Err = CheckData(Op,Payload,Dest,SID)
	if not Res then
		return nil,Err
	end
	
	local ToUs = Dest==MYID
	
	return Op,Payload,Dest,ToUs --ToUs means the Dest was this computerID
end

function Pack(Op,Payload,Dest)
	--Packs vars into sendable data
	local Res,Err = CheckData(Op,Payload,Dest)
	if not Res then
		return nil,Err
	end
	
	local Data = {op = Op, d = Payload, Dest = Dest, SID = MYID}
	local Res,Err = serialise(Data)
	if not Res then
		return nil,Err
	end
	
	return Res
end

function Send(Op,Payload,Dest,Port,ReplyPort)
	--Transmits a msg from the data
	--Op Payload and Dest are require
	local Res,Err = IsSetup()
	if not Res then
		return nil,Err
	end
	
	local Res,Err = Checker(Port,"string")
	if not Res then
		Port = DefaultPort
	end
	local Res,Err = Checker(ReplyPort,"string")
	if not Res then
		ReplyPort = Port
	end
	
	local Res,Err = Pack(Op,Payload,Dest)
	if not Res then
		return nil,Err
	end
	
	local Res,Err = pcall(Modem.transmit,Port,ReplyPort,Res)
	if not Res then
		return nil,Err
	end
	
	return true
end


function IsSetup()
	--Makes sure modem and DefaultPort is not nil
	if not Modem then
		return false,"No Modem"
	elseif not DefaultPort then
		return false,"No Port"
	end
	
	return true
end

--Functions
--Checking Functions

function Checker(Data,Type)--Local
	--Checks if data is nil and of correct type
	if not(Data) then
		return false,"Empty "..Type.." given"
	end
	if not(Type) then
		return false,"No type given"
	end
	if not(type(Data)==Type) then
		return false,"Types dont match"
	end
	return true
end

function CheckTable(Tab)--Local
	--Runs a Checker() through a table
	--Tab = {{t = "type",v = value}, ...}
	local Ret = true
	local Err
	for k,v in pairs(Tab) do
		local Res,Err1 = Checker(v.v,v.t)
		if not(Res) then
			Ret = Res
			Err = Err1
			break
		end
	end
	return Ret,Err
end

function CheckData(Op,Payload,Dest,SID)--Local
	--Checks values to make sure they are valid and useable
	local Types = {{v = Op,t = "string"},{v = Dest,t = "number"}}
	local Res,Err = CheckTable(Types)
	if not Res then
		return nil,Err
	end
	if not Payload then
		return nil,"No payload"
	end
	if SID then
		local Res,Err = Checker(SID,"number")
		if not Res then
			return nil,Err
		end
	end
	return true
end

--Checking Functions
--Just in case FNC

--These are both here in case of api change or otherwise
--They are also both public if need be to use them

function unserialise(Stri)
	return table.unpack({FileStorageAPI.unserialise(Stri)})
end

function serialise(Data)
	return table.unpack({FileStorageAPI.serialise(Data)})
end

--Just in case FNC