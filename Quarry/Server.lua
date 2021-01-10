os.loadAPI("GPSAPI.lua")
os.loadAPI("NetworkAPI.lua")
os.loadAPI("NetworkLib.lua")
os.loadAPI("TurtleAPI.lua")

local QuarryArea = {["x"] = 7,["z"] = 7,["yTop"] = 69,["yBottem"] = 1}
QuarryArea.y = QuarryArea.yTop-QuarryArea.yBottem--Do not use except when proccessing data

local QuarryRelPos = vector.new(-math.floor(QuarryArea.x/2),QuarryArea.yBottem,-math.floor(QuarryArea.z/2))

--How large of a area the turtles get assigned
local MineArea = {x=3,y=3,z=3}

MineArea.xmax = MineArea.x-1
MineArea.ymax = MineArea.y-1
MineArea.zmax = MineArea.z-1

local MineAreas = {}
MineAreas.x=math.ceil(QuarryArea.x/MineArea.x)
MineAreas.y=math.ceil(QuarryArea.y/MineArea.y)
MineAreas.z=math.ceil(QuarryArea.z/MineArea.z)

MineAreas.xmax = MineAreas.x-1
MineAreas.ymax = MineAreas.y-1
MineAreas.zmax = MineAreas.z-1

local Worth = {DESTROY=3,Assigned=2,Clear=1}

local AssignedChunks = {}
local OnNet = {}
local Chunk = {}--Defined latter
local Modem, QuarryFreq, GPSFreq, Pos
local MYID = os.getComputerID()

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

function DirectMSG(Op,Payload,SID)
	if Op == "reply FNC" then
		
	elseif Op == "reply SignIn" then
		OnNet[Payload] = "Ready"
		AssignChunk(SID)
	elseif Op == "FinishedQuarry" then
		local Brick = AssignedChunks[SID]
		if Brick then
			SetMineAreaValue(Brick.x,Brick.y,Brick.z,"Clear")
		end
		for k,v in pairs(Payload) do
			v = GlobalToRel(v)
			if Chunk[XYZStri(v.x,v.y,v.z)] then
				Chunk[XYZStri(v.x,v.y,v.z)] = "DESTROY"
			end
		end
		AssignedChunks[SID] = nil
		AssignChunk(SID)
	end
end

function PublicMSG(Op,Payload,SID)
	if Op == "Ready" then
		OnNet[Payload] = "Ready"
		AssignChunk(SID)
	end
end

function AssignChunk(ID)
	local Blocks = MineAreaAssign(ID)
	for k,v in pairs(Blocks) do
		Blocks[k] = RelToGlobal(v)
	end
	NetworkAPI.Send("QuarryBlocks",Blocks,ID)
end

function MoveTo(ID,Vec)
	local Script = "TurtleAPI.GoTo("..textutils.serialise(Vec)..")"
	NetworkAPI.Send("RunFNC",Script,ID)
end

--End controller
--Cordinate handler

function RelToGlobal(Vec)
	Vec.x = Vec.x+Pos.x
	Vec.z = Vec.z+Pos.z
	return Vec+QuarryRelPos
end

function GlobalToRel(Vec)
	Vec.x = Vec.x-Pos.x
	Vec.z = Vec.z-Pos.z
	return Vec-QuarryRelPos
end

function XYZStri(x,y,z)
	return tostring(x)..","..tostring(y)..","..tostring(z)
end

for x=0,QuarryArea.x-1 do
	for y=QuarryArea.yBottem,QuarryArea.yTop do
		for z=0,QuarryArea.z-1 do
			Chunk[XYZStri(x,y,z)] = "DESTROY"
		end
	end
end

--Cordinate handler
--Chunk Handler

function GetMineAreaValue(XO,YO,ZO)
	XO=XO*MineArea.x
	YO=YO*MineArea.y
	ZO=ZO*MineArea.z
	local Ret = ""
	local CWorth = -1
	for y=0,MineArea.ymax do
		for z=0,MineArea.zmax do
			for x=0,MineArea.xmax do
				local Block = Chunk[XYZStri(x+XO,y+YO,z+ZO)]
				if (Block) then
					if (Worth[Block]>CWorth) then
						CWorth=Worth[Block]
						Ret = Block
					end
				end
			end
		end
	end
	return Ret
end

function SetMineAreaValue(XO,YO,ZO,Value)
	XO=XO*MineArea.x
	YO=YO*MineArea.y
	ZO=ZO*MineArea.z
	local Ret = {}
	for y1=0,MineArea.ymax do
		local y = (MineArea.ymax-y1)
		for z=0,MineArea.zmax do
			for x=0,MineArea.xmax do
				local Block = Chunk[XYZStri(x+XO,y+YO,z+ZO)]
				if (Block) then
					Chunk[XYZStri(x+XO,y+YO,z+ZO)]=Value
					table.insert(Ret,vector.new(x+XO,y+YO,z+ZO))
				end
			end
		end
	end
	return Ret
end

function MineAreaAssign(ID)
	local Ret,x,y,z = GetMineableChunk()
	if not Ret then
		return nil
	end
	AssignedChunks[ID] = {x=x,y=y,z=z}
	return SetMineAreaValue(x,y,z,"Assigned")
end

function GetMineableChunk()
	local CanGoDown = false
	for y1=0,MineAreas.ymax do
		local y = -(y1-MineAreas.ymax)
		CanGoDown = false
		for z=0,MineAreas.zmax do
			for x=0,MineAreas.xmax do
				local Ret = GetMineAreaValue(x,y,z)
				if (Ret=="DESTROY") then
					return true,x,y,z
				elseif (Ret=="Clear") then
					CanGoDown = true
				end
			end
		end
		
		if not CanGoDown then
			break
		end
	end
	return nil
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

NetworkAPI.Init(Modem,QuarryFreq)
TurtleAPI.Init(Modem,GPSFreq)

--NetworkAPI.Send(Op,Payload,Dest)
NetworkAPI.Send("SignIn",-1,-1)

while true do
	local _,side,sender,reply,msg,distance = os.pullEvent()
	if (_ == "modem_message") then
		local Op,Payload,Dest,SID,ToUs = NetworkAPI.Unpack(msg)
		if NetworkLib.CheckCall(Op,Payload,Dest) then
			
		elseif ToUs then
			DirectMSG(Op,Payload,SID)
		elseif Dest == -1 then
			PublicMSG(Op,Payload,SID)
		end
	end
end

