--Intro

--Adds common network calls into one place

--Intro
--Declarations

os.loadAPI("SerialiseAPI.lua")
os.loadAPI("TurtleAPI.lua")

local FNCS = {}

--Declarations
--Setup

function Init(A,B)
	--Does not open port but saves Modem and DefaultPort
	--That is used for sending this FNC is required to run
	Modem = A GPSFreq = B
end

--Setup
--Calling

function CheckCall(Op,Payload,Dest)
	--Checks to see if the function is valid and in this library then gives it the payload
	local Call = FNCS[Op]
	if Call then
		local work, err = pcall(Call,Payload)
		return work, err --Return value (may be nil) or error
	end
	return false,"Not in lib"
end

--Calling
--Debug only calls

function SetDiskLoc()
	local Loc = {}
	Loc.Pos = TurtleAPI.GetPos()
	Loc.Dir = TurtleAPI.GetDir()
	SerialiseAPI.serialiseFile("DebugDiskLoc.txt",Loc,true)
end
FNCS.SetDiskLoc=SetDiskLoc

function BackToDisk()
	local Loc,err = SerialiseAPI.unserialiseFile("DebugDiskLoc.txt")
	if not Loc then
		printError(err)
		return false,err
	end
	print(textutils.serialise(Loc.Pos))
	TurtleAPI.GoTo(Loc.Pos.x,Loc.Pos.y,Loc.Pos.z)
	TurtleAPI.TurnTo(Loc.Dir)
	os.shutdown()
end
FNCS.BackToDisk=BackToDisk

--Debug only calls
--Emergency calls

FNCS.SHUTDOWN=os.shutdown
FNCS.REBOOT=os.reboot

--Emergency calls
--Extra FNC local

function TestFNC(FNCS) 
	local FNC,err = load("return "..FNCS)
	if not (FNC) then
		FNC,err = load(FNCS)
	end
	
	if not(FNC == nil) then
		local work, err = pcall(FNC)
		return err --Return value (may be nil) or error
	else
		return err --compile error (not valid function)
	end
end
FNCS.RunStri=TestFNC

--Extra FNC local