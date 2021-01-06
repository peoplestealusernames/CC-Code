os.loadAPI("GPSAPI.lua")
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

function DirectMSG(Tab)
	if Tab.op == "RunFNC" then
		local Data = {["op"] = "reply FNC", ["d"] = TestFNC(Tab.d), ["Dest"] = Tab.SID,["SID"] = MYID}
		Modem.transmit(QuarryFreq,QuarryFreq,textutils.serialise(Data))
	elseif Tab.op == "QuarryBlocks" then
		print(textutils.serialise(Tab))
		return QuarryBlocks(Tab.d)
	end
end

--local Data = {["op"] = "QuarryBlocks", ["d"] = Blocks, ["Dest"] = ID, ["SID"] = MYID}

function PublicMSG(Tab)
	if (Tab.op == "SignIn") then
		local Data = {["op"] = "reply SignIn", ["d"] = MYID, ["Dest"] = Tab.SID,["SID"] = MYID}
		Modem.transmit(QuarryFreq,QuarryFreq,textutils.serialise(Data))
	end
end

function QuarryBlocks(Blocks)
	--{["x"] = x+XO,["y"] = y+YO,["z"] = z+ZO}
	for k,v in pairs(Blocks) do
		if(TurtleAPI.GoToRaw(v["x"],v["y"],v["z"])) then
			turtle.digDown()
			--INV check
			--do a thing for false
		end
	end
	return true
end

--End controller

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

TurtleAPI.Init(Modem,GPSFreq)

local Data = {["op"] = "Ready", ["d"] = -1, ["Dest"] = -1, ["SID"] = MYID}
Modem.transmit(QuarryFreq,QuarryFreq,textutils.serialise(Data))

while true do
	local _,side,sender,reply,msg,distance = os.pullEvent()
	if (_ == "modem_message") then
		--print(msg)
		local Tab = textutils.unserialise(msg)
		if Tab.Dest == MYID then
			DirectMSG(Tab)
		elseif Tab.Dest == -1 then
			PublicMSG(Tab)
		end
	elseif (side == MyTimer) then
		return nil,"No gps response"
	end
end

