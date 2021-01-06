os.loadAPI("GPSAPI.lua")

local Modem,GPSFreq
local Pos,Dir

local DoActions,VecIsZero,VecEqual,Update,Clamp,ClampDir

-- make sure to run Init(Modem,GPSFreq)

DirRef = {
	[1] = "-x",[2] = "-z",[3] = "+x",[4] = "+z",
	["-x"] = 1,["-z"] = 2,["+x"] = 3,["+z"] = 4,
}

function UpdateGPS()
	local Tab = {}
	Pos = GPSAPI.GetPos(Modem,GPSFreq)
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

function Forward()
	if not CheckFuel() then
		return false,"Fuel"
	end
	
	if not turtle.forward() then
		return false,"Cant"
	end
	if(Dir == 1) then
		Pos.x = Pos.x - 1
	elseif(Dir == 2) then
		Pos.z = Pos.z - 1
	elseif(Dir == 3) then
		Pos.x = Pos.x + 1
	elseif(Dir == 4) then
		Pos.z = Pos.z + 1
	end
	Update()
	return true
end

function Back()
	if not CheckFuel() then
		return false,"Fuel"
	end
	if not turtle.back() then
		return false,"Cant"
	end
	if(Dir == 1) then
		Pos.x = Pos.x + 1
	elseif(Dir == 2) then
		Pos.z = Pos.z + 1
	elseif(Dir == 3) then
		Pos.x = Pos.x - 1
	elseif(Dir == 4) then
		Pos.z = Pos.z - 1
	end
	Update()
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
-- -x = 1
-- -z = 2
-- +x = 3
-- +z = 4

local function CheckDirFail(Rep,Org,ResetMove)
	if (Rep<3) then
		turtle.turnLeft()
		ResetMove[#ResetMove+1] = turtle.right
		return CheckDir(Rep+1,Org,ResetMove)
	else
		DoActions(ResetMove)
	end
end

function CheckDir(Rep,Org,ResetMove)--do not enter a value
	if not(Rep) then -- first run through
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
			return CheckDirFail(Rep,Org,ResetMove)
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
	Dir = (1+Dif.x)*math.abs(Dif.x)+(3+Dif.z)*math.abs(Dif.z)
	
	if ((Dir < 1) or (Dir > 4)) then
		return CheckDirFail(Rep,Org,ResetMove)
	end
	
	Dir = ClampDir(Dir+DirOffset)
	DoActions(ResetMove)
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
--TurtleAPI.GoToRelative(10,10,10)
function GoTo(GoPos,FuelOveride)--FuelOveride can be nill when true it will run the turtle dry
	GoPos = vector.new(GoPos.x,GoPos.y,GoPos.z)
	GoPos = GoPos:round()
	local Dif = GoPos-Pos
	if ((not FuelOveride) and (not(CheckFuel(Dif:length()*2)))) then
		return false,"Fuel+"
	end
	local VertFail = false
	local HortFail = false
	local DirFailed = {}
	local Fails = 0
	while not(VecIsZero(Dif)) do
		-- local FDist = Pos-GPSAPI.GetPos(Modem,GPSFreq)
		-- if not VecEqual(Pos,GPSAPI.GetPos(Modem,GPSFreq)) then
			-- printError("VECTORS NOT EQUAL ABORT ",FDist.x,FDist.y,FDist.z)
		-- end
		Dif = GoPos-Pos
		Dif = Dif:round()
		if ((not((Dif.x==0) and (Dif.z==0))) and (not HortFail)) then
			local Tab,Dir = TryForMove(Dif,DirFailed)
			local Res,ErrCode,Moved = unpack(Tab)
			print(Res,ErrCode,Moved )
			print(Dif)
			if not(Res) then
				if (ErrCode == "Hit") then
					DirFailed[Dir] = true
					Fails = Fails + 1
				elseif ("Cant move") then
					
				end
				
				if (Moved>0) then
					DirFailed = {}
					Fails = 0
					VertFail = false
					print("ResetV")
				else
					local FailsNeeded = 2
					if ((Dif.x==0) or (Dif.z==0)) then
						FailsNeeded = 1
					end
					if (Fails >= FailsNeeded) then
						HortFail = true
						print("FailH")
						DirFailed = {}
						Fails = 0
					end
				end
			else
				VertFail = false
			end
		else
			local Tab = TryVertMove(Dif,DirFailed)
			local Res,ErrCode,Moved = unpack(Tab)
			if not(Res) then
				if (ErrCode == "Hit") then
					VertFail = true
					print("FailV")
				end
				if (Moved>0) then
					HortFail = false
					print("ResetH")
				end
			else
				HortFail = false
			end
		end
		
		if (HortFail and VertFail) then
			print(VertFail,HortFail)
			Dif = vector.new(0,0,0)
			print("end")
			return false,"Fail#1"
		end
		--os.sleep(2)
	end
	return true
end

-- Dir
-- -x = 1
-- -z = 2
-- +x = 3
-- +z = 4

function TryForMove(Dif,DirFailed)
	local Move = 0
	local Extra = ""
	local MoveCall = Forward
	if ((Dif.x>0) and not(DirFailed[3])) then
		TurnTo(3) Extra = 3
		Move = math.abs(Dif.x)
	elseif ((Dif.x<0) and not(DirFailed[1])) then
		TurnTo(1) Extra = 1
		Move = math.abs(Dif.x)
	elseif ((Dif.z>0) and not(DirFailed[4])) then
		TurnTo(4) Extra = 4
		Move = math.abs(Dif.z)
	elseif ((Dif.z<0) and not(DirFailed[2])) then
		TurnTo(2) Extra = 2
		Move = math.abs(Dif.z)
	else
		return false,"Cant move"
	end
	return {MoveWithFNC(Move,MoveCall)},Extra
end

function TryVertMove(Dif)
	local Move = Dif.y
	local MoveCall
	if (Move>0) then
		MoveCall = Up
	elseif (Move<0) then
		MoveCall = Down
	else
		return true
	end
	return {MoveWithFNC(Move,MoveCall)}
end

function MoveWithFNC(Move,MoveCall)
	Move = math.abs(Move)
	local Moved = 0
	while Move>0 do
		if not(MoveCall()) then
			Move = 0
			return false,"Hit",Moved
		else
			Move = Move - 1
			Moved = Moved + 1
		end
	end
	return true
end