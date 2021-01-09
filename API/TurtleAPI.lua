os.loadAPI("GPSAPI.lua")

local Modem,GPSFreq
local Pos,Dir

local DoActions,VecIsZero,VecEqual,Update,Clamp,ClampDir

-- make sure to run Init(Modem,GPSFreq)

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

function UpdateGPS()
	local Tab = {}
	Pos = GPSAPI.GetPos(Modem,GPSFreq,"Req")
	Pos = Pos:round()
	Tab.Pos = Pos
	Tab.Dir = Dir
	file = fs.open("turtlePosition.txt","w")
	file.write(textutils.serialise(Tab))
	file.close()
end

function Update()
	local Tab = {}
	Tab.Pos = Pos
	Tab.Dir = Dir
	file = fs.open("turtlePosition.txt","w")
	file.write(textutils.serialise(Tab))
	file.close()
end

function CheckFuel(Needed)
	local fuel = turtle.getFuelLevel()
	if not Needed then
		return fuel > 0
	else
		return fuel >= Needed
	end
end

function DirMove(MoveDir)
	Pos = Pos + DirVector[MoveDir]
	Update()
end

function DirMoveBack(MoveDir)
	DirMove(Clamp(MoveDir+2,1,4))
end

function Forward()
	if not CheckFuel() then
		return false,"Fuel"
	end
	
	if not turtle.forward() then
		return false,"Cant"
	end
	
	DirMove(Dir)
	return true
end

function Back()
	if not CheckFuel() then
		return false,"Fuel"
	end
	if not turtle.back() then
		return false,"Cant"
	end
	
	DirMoveBack(Dir)
	return true
end

function Up()
	if not CheckFuel() then
		return false,"Fuel"
	end
	if not turtle.up() then
		return false,"Cant"
	end
	Pos.y = Pos.y + 1
	Update()
	return true
end

function Down()
	if not CheckFuel() then
		return false,"Fuel"
	end
	if not turtle.down() then
		return false,"Cant"
	end
	Pos.y = Pos.y - 1
	Update()
	return true
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

function ChangeDir(c)
	Dir = ClampDir(Dir+c)
	Update()
	return true
end

function GetPos()
	return Pos
end

-- movement functions
-- direction functions

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

function GetDir()
	return Dir
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

-- direction functions
-- Misc functions local

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

-- Misc functions local
-- Executable functions

function Init(Modem1,GPSFreq1)
	Modem = Modem1
	GPSFreq = GPSFreq1
	local file = fs.open("turtlePosition.txt","r")
	if not file then
		CheckDir()
		UpdateGPS()
		local Tab = {}
		Tab.Dir = Dir
		Tab.Pos = Pos
		local file = fs.open("turtlePosition.txt","w")
		file.write(textutils.serialise(Tab))
		file.close()
	else
		local Tab = textutils.unserialise(file.readAll())
		Dir = Tab.Dir
		Pos = Tab.Pos
		file.close()
	end
	Update()
end

function GoToRaw(x,y,z)
	return GoTo(vector.new(x,y,z))
end

function GoToRelative(x,y,z)
	return GoTo(vector.new(x,y,z)+Pos)
end

function GoTo(GoPos,FuelOveride)--FuelOveride can be nill when true it will run the turtle dry
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
		Ret,DirFailed,Tab = TryForMove(Dif,DirFailed)
		
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

function TryForMove(Dif,DirFailed)
	local Move = 0
	local MoveCall = Forward
	if ((Dif.x>0) and not(DirFailed[3])) then
		TurnTo(3) DirFailed[3] = true
		Move = Dif.x
	elseif ((Dif.x<0) and not(DirFailed[1])) then
		TurnTo(1) DirFailed[1] = true
		Move = Dif.x
	elseif ((Dif.z>0) and not(DirFailed[4])) then
		TurnTo(4) DirFailed[4] = true
		Move = Dif.z
	elseif ((Dif.z<0) and not(DirFailed[2])) then
		TurnTo(2) DirFailed[2] = true
		Move = Dif.z
	elseif ((Dif.y<0) and not(DirFailed[6])) then
		DirFailed[6] = true MoveCall = Down
		Move = Dif.z
	elseif ((Dif.y>0) and not(DirFailed[5])) then
		DirFailed[5] = true MoveCall = Up
		Move = Dif.y
	else
		return false,DirFailed,"Cant move"
	end
	return true,DirFailed,{MoveWithFNC(Move,MoveCall)}
end

function MoveWithFNC(Move,MoveCall)
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