--Intro

-- make sure to run Init(Modem,GPSFreq)

--Intro
--Declariations

os.loadAPI("GPSAPI.lua")

local Modem,GPSFreq
local Pos,Dir

local DoActions,VecIsZero,VecEqual,Update,Clamp,ClampDir
local TryMove,DirMove,MoveWithFNC,CopyTable,MoveFnc

--Declariations
--Refrences

-- Dir
-- -x = 1,West
-- -z = 2,North
-- +x = 3,East
-- +z = 4,South
-- +y = 5
-- -y = 6

DirRef = {
	[1] = "-x",[2] = "-z",[3] = "+x",[4] = "+z",
	["-x"] = 1,["-z"] = 2,["+x"] = 3,["+z"] = 4,
	
	[5] = "+y",[6] = "-y",
	["+y"] = 5,["-y"] = 6,
}

DirVector = {
	[1] = vector.new(-1,0,0),
	[2] = vector.new(0,0,-1),
	[3] = vector.new(1,0,0),
	[4] = vector.new(0,0,1),
	[5] = vector.new(0,1,0),
	[6] = vector.new(0,-1,0),
}

--Refrences
--Init

function Init(Modem1,GPSFreq1)
	Modem = Modem1
	GPSFreq = GPSFreq1
	local file = fs.open("turtlePosition.txt","r")
	if not file then
		CheckDir()
		UpdateGPS()
	else
		local Tab = textutils.unserialise(file.readAll())
		Dir = Tab.Dir
		Pos = Tab.Pos
		file.close()
	end
	Update()
end

--Init
--Position savers

function UpdateGPS()
	--Updates with gps
	Pos = GPSAPI.GetPos(Modem,GPSFreq,"Req")
	Pos = Pos:round()
	Update()
end

function Update()
	--Updates the turtlePosition File
	local Tab = {}
	Tab.Pos = Pos
	Tab.Dir = Dir
	file = fs.open("turtlePosition.txt","w")
	file.write(textutils.serialise(Tab))
	file.close()
end

--Position savers
--Checks

function CheckFuel(Needed)
	--Checks fuel level 1 fuel per block
	--If needed is nil it will default to 1
	if not Needed then
		Needed = 1
	end
	
	return turtle.getFuelLevel() >= Needed
end

--Checks
--Movement functions

function DirMove(MoveDir)--local
	--Updates positon bases on dir given
	Pos = Pos + DirVector[MoveDir]
	Update()
end

function MoveFnc(Call,RealDir)--local
	if not CheckFuel() then
		return false,"Fuel"
	end
	if not Call() then
		return false,"Cant"
	end
	
	if not RealDir then
		DirMove(Dir)
	else
		DirMove(RealDir)
	end
	return true
end

function Forward()
	return table.unpack({MoveFnc(turtle.forward)})
end

function Back()
	return table.unpack({MoveFnc(turtle.back,ClampDir(Dir+2))})
end

function Up()
	return table.unpack({MoveFnc(turtle.up,5)})
end

function Down()
	return table.unpack({MoveFnc(turtle.down,6)})
end

function Right()
	if not turtle.turnRight() then
		return false,"Cant"
	end
	return ChangeDir(1)
end

function Left()
	if not turtle.turnLeft() then
		return false,"Cant"
	end
	return ChangeDir(-1)
end

--Movement functions
--Direction functions

-- Dir
-- -x = 1,West
-- -z = 2,North
-- +x = 3,East
-- +z = 4,South
-- +y = 5
-- -y = 6

local function CheckDirFail(Rep,Org,ResetMove)
	if (Rep<3) then
		turtle.turnLeft()
		ResetMove[#ResetMove+1] = turtle.right
		return table.unpack({CheckDir(Rep+1,Org,ResetMove)})
	else
		DoActions(ResetMove)
	end
end

function CheckDir(Rep,Org,ResetMove)--do not enter a value
	if not(Rep) then
		Rep = 0
		if not CheckFuel() then
			return false,"Fuel"
		end
		UpdateGPS()
		Org = Pos
		ResetMove = {}
	end
	
	local DirOffset = 0
	if not(turtle.forward()) then
		if not(turtle.back()) then
			return table.unpack({CheckDirFail(Rep,Org,ResetMove)})
		else
			ResetMove[#ResetMove+1] = turtle.forward
			DirOffset=2
		end
	else
		ResetMove[#ResetMove+1] = turtle.back
	end
	
	UpdateGPS()
	local Pos2 = Pos
	local Dif = Pos2 - Org
	
	Dir = (2+Dif.x)*math.abs(Dif.x)+(3+Dif.z)*math.abs(Dif.z)
	if ((Dir < 1) or (Dir > 4) or (math.floor(Dir)~=math.ceil(Dir))) then
		return table.unpack({CheckDirFail(Rep,Pos2,ResetMove)})
	end
	
	Dir = ClampDir(Dir+DirOffset)
	DoActions(ResetMove)
	sleep(0.6)--Hopefuly resets the distance error
	UpdateGPS()
	return true,Dir
end

function TurnTo(Val)
	if (type(Val)) == "string" then
		Val = DirRef[Val]
	end
	if (ClampDir(Dir+1)==Val) then
		Right()
	end
	while not (Dir == Val) do
		Left()
	end
end

function ChangeDir(c)
	Dir = ClampDir(Dir+c)
	Update()
	return true
end

--Direction functions
--Get value functions

function GetDir()
	return Dir
end

function GetPos()
	return Pos
end

--Get value functions
--Misc functions local

function VecEqual(A,B)
	return 0==(math.abs(A.x-B.x)+math.abs(A.y-B.y)+math.abs(A.z-B.z))
end

function VecIsZero(A)
	return 0==(math.abs(A.x)+math.abs(A.y)+math.abs(A.z))
end

function DoActions(Actions)
	for i=1,#Actions do
		Actions[i]()
	end
end

function Clamp(x,min1,max1)
	x = x-min1 max1 = max1-min1+1
	return (x-max1*math.floor(x/max1))+min1
end

function ClampDir(x)
	return Clamp(x,1,4)
end

--Misc functions local
--Movement handlers

function GoToRaw(x,y,z)
	--Goes to a x,y,z positon
	return GoTo(vector.new(x,y,z))
end

function GoToRelative(x,y,z)
	--Goes to a relative x,y,z positon
	return GoTo(vector.new(x,y,z)+Pos)
end

function GoTo(GoPos,FuelOveride)
	--Goes to a vector position
	--FuelOveride can be nill when true it will run the turtle dry
	GoPos = vector.new(GoPos.x,GoPos.y,GoPos.z)
	GoPos = GoPos:round()
	local Dif = GoPos-Pos
	if ((not FuelOveride) and (not(CheckFuel(Dif.x+Dif.y+Dif.z)))) then
		return false,"Fuel+"
	end
	
	local DirFailed = {}
	local Fails = 0
	while not(VecIsZero(Dif)) do
		Dif = GoPos-Pos
		Dif = Dif:round()
		
		local Ret,Tab
		Ret,DirFailed,Tab = TryMove(Dif,DirFailed)
		
		if Ret then
			local Stuck,Moved,Err = table.unpack(Tab)
			if Moved then
				if Moved>0 then
					DirFailed = {}
				end
			end
		else
			if (Tab == "Cant move") then
				break
			end
		end
	end
	
	Dif = GoPos-Pos
	Dif = Dif:round()
	return VecIsZero(Dif)
end

function TryMove(Dif,DirFailed)--Local
	--Sees if it can move and returns the results
	local MoveThing = {{},{Dif.x,"<",1,Forward},{Dif.z,"<",2,Forward},{Dif.x,">",3,Forward},{Dif.z,">",4,Forward},{Dif.y,">",5,Up},{Dif.y,"<",6,Down}}
	local Move
	local MoveCall
	MoveThing[1] = MoveThing[Dir+1]
	
	for k,v in pairs(MoveThing) do
		if not(DirFailed[v[3]]) and (load("return "..tostring(v[1])..v[2].."0")()) then
			Move = v[1] DirFailed[v[3]]=true MoveCall=v[4]
			if (MoveCall==Forward) then
				TurnTo(v[3])
			end
			return true,DirFailed,{MoveWithFNC(Move,MoveCall)}
		end
	end
	
	return false,DirFailed,"Cant move"
end

function MoveWithFNC(Move,MoveCall)--Local
	--Tries running a movecall
	--Returns results and how far it moved
	Move = math.abs(Move)
	local Moved = 0
	while Move>Moved do
		if not(MoveCall()) then
			Move = 0
			return false,Moved,"Hit"
		else
			Moved = Moved + 1
		end
	end
	return true,Moved
end

--Movement handlers