os.loadAPI("GPSAPI.lua")

local QuarryArea = {["x"] = 16,["z"] = 16,["yTop"] = 70,["yBottem"] = 1}
QuarryArea.yDif = QuarryArea.yTop-QuarryArea.yBottem

local OnNet = {}
local Chunk = {}
local Modem, QuarryFreq, GPSFreq, Pos
local MYID = os.getComputerID()

for x=1,QuarryArea.x do
	Chunk[x] = {}
	for y=QuarryArea.yBottem,QuarryArea.yTop do
		Chunk[x][y] = {}
		for z=1,QuarryArea.z do
			Chunk[x][y][z] = "DESTROY"
		end
	end
end

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

function UpdatePos()
	Pos = GPSAPI.GetPos(Modem,GPSFreq,"Req")
end

--function decs end
--Controller function

function DirectMSG(Tab)
	if Tab.op == "reply FNC" then
		--print(textutils.serialise(Tab))
	elseif Tab.op == "reply SignIn" then
		OnNet[Tab.d] = "Ready"
		AssignChunk(Tab.SID)
	end
end

function PublicMSG(Tab)
	if Tab.op == "Ready" then
		OnNet[Tab.d] = "Ready"
		AssignChunk(Tab.SID)
	end
end

function AssignChunk(ID)
	local Blocks = ChunkAssign()
	local Data = {["op"] = "QuarryBlocks", ["d"] = Blocks, ["Dest"] = ID, ["SID"] = MYID}
	Modem.transmit(QuarryFreq,QuarryFreq,textutils.serialise(Data))
end

function MoveTo(ID,Vec)
	local Script = "TurtleAPI.GoTo("..textutils.serialise(Vec)..")"
	local Data = {["op"] = "RunFNC", ["d"] = Script, ["Dest"] = ID, ["SID"] = MYID}
	Modem.transmit(QuarryFreq,QuarryFreq,textutils.serialise(Data))
end

--End controller
--Chunk Handler

function ChunkFindUnassigned()
	for y1=1,QuarryArea.yDif do
		local y = math.abs(QuarryArea.yBottem+(QuarryArea.yTop-y1))
		for z=1,QuarryArea.z do
			for x=1,QuarryArea.x do
				if (Chunk[x][y][z] == "DESTROY") then
					return x,y,z
				end
			end
		end
	end
	return false
end

function ChunkAssign()
	local XO,YO,ZO = ChunkFindUnassigned()
	local RetTab = {}
	for y1=-2,2 do
		for z=-2,2 do
			for x=-2,2 do
				local y = -y1
				if Chunk[x+XO] then if Chunk[x+XO][y+YO] then
				if (Chunk[x+XO][y+YO][z+ZO] == "DESTROY") then
					local VecOut = vector.new(x+XO+Pos.x,y+YO,z+ZO+Pos.z)
					VecOut = VecOut:round()
					table.insert(RetTab,VecOut)
					Chunk[x+XO][y+YO][z+ZO] = "Assigned"
				end
				end end
			end
		end
	end
	file = fs.open("temp","w") file.write(textutils.serialise(RetTab)) file.close()
	return RetTab
end

function ChunkUpdate(x,y,z,Var)
	if not Var then
		Var = "minecraft:air"
	end
	Chunk[x][y][z] = Var
end

--end Chunk
--execution

GPSFreq = textutils.unserialise(FindOrEnterVar("GPSFreq.txt","GPS frequency 0-65535"))
QuarryFreq = textutils.unserialise(FindOrEnterVar("QuarryFreq.txt","Local quarry frequency 0-65535"))

Modem = peripheral.find("modem")
if not Modem then
	printError("No modem found")
	return false
end

UpdatePos()

Modem.open(QuarryFreq)
if not Modem.isOpen(QuarryFreq) then
	return nil,"Cound not open quarry freq"
end

local Data = {["op"] = "SignIn", ["d"] = -1, ["Dest"] = -1, ["SID"] = MYID}
Modem.transmit(QuarryFreq,QuarryFreq,textutils.serialise(Data))

while true do
	local _,side,sender,reply,msg,distance = os.pullEvent()
	if (_ == "modem_message") then
		local Tab = textutils.unserialise(msg)
		if Tab.Dest == ID then
			DirectMSG(Tab)
		elseif Tab.Dest == -1 then
			PublicMSG(Tab)
		end
	end
end

