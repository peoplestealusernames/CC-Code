os.loadAPI("GPSAPI.lua")
os.loadAPI("NetworkAPI.lua")
os.loadAPI("NetworkLib.lua")
os.loadAPI("TurtleAPI.lua")

local MYID = os.getComputerID()

local Dir,Pos
local Modem,QuarryFreq,GPSFreq

local function FindOrEnterVar(FileName,Stri)
	local file = fs.open(FileName, "r")
	if not file then
		printError("No "..Stri.." found please enter "..Stri)
		Return = read()
		local file = fs.open(FileName, "w")
		file.write(Return)
		file.close()
	else
		Return = file.readAll()
		file.close()
	end
	return Return
end

function GetInventory()
	local SlotRet = {}
	for i=1,16 do
		SlotRet[i] = turtle.getItemDetail(i) 
	end
	return SlotRet
end

--function decs end
--Controller function

function DirectMSG(Op,Payload,SID)
	if Op == "RunFNC" then
		NetworkAPI.Send("reply FNC",TestFNC(Payload),SID)
	elseif Op == "QuarryBlocks" then
		local Fails = QuarryBlocks(Payload)
		TurtleAPI.GoTo("~",70,"~")
		NetworkAPI.Send("FinishedQuarry",Fails,SID)
	end
end

function PublicMSG(Op,Payload,SID)
	if (Op == "SignIn") then
		NetworkAPI.Send("reply SignIn",MYID,SID)
	end
end

function QuarryBlocks(Blocks)
	local Fails = {}
	for k,v in pairs(Blocks) do
		if(TurtleAPI.GoTo(v.x,v.y,v.z)) then
			turtle.digDown()--do a thing for false
			--INV check
			--Fuel check
		else
			table.insert(Fails,v)
		end
	end
	return Fails
end

--End controller
--execution

GPSFreq = textutils.unserialise(FindOrEnterVar("GPSFreq.txt","GPS frequency 0-65535"))
QuarryFreq = textutils.unserialise(FindOrEnterVar("QuarryFreq.txt","Local quarry frequency 0-65535"))

Modem = peripheral.find("modem")
if not Modem then
	printError("No modem found")
	return false
end

Modem.open(QuarryFreq)
if not Modem.isOpen(QuarryFreq) then
	return nil,"Cound not open quarry freq"
end

local Pos,err = GPSAPI.GetPos(Modem,GPSFreq)
if not Pos then
	printError(err)
	return false
end

NetworkAPI.Init(Modem,QuarryFreq)
TurtleAPI.Init(Modem,GPSFreq)

NetworkAPI.Send("Ready",-1,-1)

while true do
	local _,side,sender,reply,msg,distance = os.pullEvent()
	if (_ == "modem_message") then
		local Op,Payload,Dest,SID,ToUs = NetworkAPI.Unpack(msg)
		local Ret,Data = NetworkLib.CheckCall(Op,Payload,Dest)
		
		if Ret then
			
		elseif ToUs then
			DirectMSG(Op,Payload,SID)
		elseif Dest == -1 then
			PublicMSG(Op,Payload,SID)
		end
	end
end

