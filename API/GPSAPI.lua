local MYID = os.getComputerID()

local function trilaterate(A, B, C) -- from CC tweaked
    local a2b = B.vPosition - A.vPosition
    local a2c = C.vPosition - A.vPosition

    if math.abs(a2b:normalize():dot(a2c:normalize())) > 0.999 then
        return nil
    end

    local d = a2b:length()
    local ex = a2b:normalize( )
    local i = ex:dot(a2c)
    local ey = (a2c - ex * i):normalize()
    local j = ey:dot(a2c)
    local ez = ex:cross(ey)

    local r1 = A.nDistance
    local r2 = B.nDistance
    local r3 = C.nDistance
	
    local x = (r1 * r1 - r2 * r2 + d * d) / (2 * d)
    local y = (r1 * r1 - r3 * r3 - x * x + (x - i) * (x - i) + j * j) / (2 * j)
	
    local result = A.vPosition + ex * x + ey * y
	
    local zSquared = r1 * r1 - x * x - y * y
    if zSquared > 0 then
        local z = math.sqrt(zSquared)
        local result1 = result + ez * z
        local result2 = result - ez * z
		
        local rounded1, rounded2 = result1:round(0.01), result2:round(0.01)
        if rounded1.x ~= rounded2.x or rounded1.y ~= rounded2.y or rounded1.z ~= rounded2.z then
            return rounded1, rounded2
        else
            return rounded1
        end
    end
    return result:round(0.01)
end

function Clamp(x,min1,max1)
	return ((x-min1)%(max1-min1+1))+min1
end

function GetPos(Modem,GPSFreq)
	local Data = {["op"] = "location_ping", ["d"] = MYID, ["Dest"] = -1, ["SID"] = MYID}
	Modem.transmit(GPSFreq,GPSFreq,textutils.serialise(Data))
	local Msgs = {}
	local Loop = true
	local MyTimer = os.startTimer(3)
	Modem.open(GPSFreq)
	if not Modem.isOpen(GPSFreq) then
		return nil,"Cound not open gps freq"
	end
	while (#Msgs < 4) and Loop do
		local _,side,sender,reply,msg,distance = os.pullEvent()
		if (_ == "modem_message") then
			local Tab = textutils.unserialise(msg)
			if (type(Tab) == "table") then 
				if Tab.Dest == MYID then
					if (Tab.op == "GPS CheckBack") then
						local PosR = Tab.d
						local Out = {}
						Out.vPosition = vector.new(PosR.x,PosR.y,PosR.z)
						Out.nDistance = distance
						Msgs[#Msgs+1] = Out
					end
				end
			end
		elseif (side == MyTimer) then
			return nil,"No gps response"
		end
	end
	
	Modem.close(GPSFreq)
	
	local TabPos = {}
	local PosCommon = {["Value"]=-1}
	for i=1,4 do
		local Pos1 = trilaterate(Msgs[Clamp(i,1,4)],Msgs[Clamp(i+1,1,4)],Msgs[Clamp(i+2,1,4)])
		local Index = tostring(TabPos.x)..","..tostring(TabPos.y)..","..tostring(TabPos.z)
		local Value = 0
		if not TabPos[Index] then
			TabPos[Index]=Pos1
			PosCommon[Index]=1
		else
			PosCommon[Index] = PosCommon[Index]+1
		end
		if (Value>PosCommon.Value) then
			PosCommon.Value = Value
			PosCommon.I = Index
		end
	end
	return TabPos[PosCommon.I]
end
