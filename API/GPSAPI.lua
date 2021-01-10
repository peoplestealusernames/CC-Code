--Intro

--A custom gps api GetPos(Modem,GPSFreq,Raw)
--Diffrence between this and default is this supports custom freq
--Position is calculated from the computer or turtle not modem

--PARAMETERS
--Modem is a modem perpherial
--GPSFreq is the number for your gps port or frequecy
--Mode has to values "Raw" or "Req"
--	Req means it will never time out and keep requesting until it gets a response
--		This mode however has a long time before it will send reponses to save performance
--		This performance saver only kicks in after the max repeat have gone through
--	Raw means it will return whatever it gets
--		This means it bypasses the round function that normally fixxes the issue below
--Rep is how many times it has already run keep it nil or zero

-- The distance return of the MSG recived event is a bit finichy with movement
-- I dont know what causes it or how to fix it but at times it could cause this function to return null
-- If it is set to required mode it wont however it may take on avg ~.4 seconds to correct itself

--Intro
--Code

local MYID = os.getComputerID()

local function VecEqual(A,B)
	return 0==(math.abs(A.x-B.x)+math.abs(A.y-B.y)+math.abs(A.z-B.z))
end

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

local function narrow( p1, p2, fix ) -- from CC tweaked
    local dist1 = math.abs( (p1 - fix.vPosition):length() - fix.nDistance)
    local dist2 = math.abs( (p2 - fix.vPosition):length() - fix.nDistance)
   
    if math.abs(dist1 - dist2) < 0.01 then
        return p1, p2
    elseif dist1 < dist2 then
        return p1:round( 0.01 )
    else
        return p2:round( 0.01 )
    end
end

local function Clamp(x,min1,max1)
	return ((x-min1)%(max1-min1+1))+min1
end

local function ReadMSG(Tab)
	if type(Tab) == "table" then
		if(Tab.op) then
			if(Tab.op == "GPS CheckBack") then
				return vector.new(Tab.d.x,Tab.d.y,Tab.d.z)
			end
		end
	end
	return nil
end

local Send = {["op"] = "location_ping", ["d"] = MYID, ["Dest"] = -1, ["SID"] = MYID}
local Send = textutils.serialise(Send)

function GetPos(Modem,GPSFreq,Mode,Rep)
	--Gets position
	if not Mode then
		Mode = ""
	end
	if not Rep then
		Rep = 0
	end
	Rep = Rep+1
	
	local MyTimer
	if (Rep<5) then
		MyTimer = os.startTimer(0.1)--CC has zero latency so this is ok
	else
		MyTimer = os.startTimer(5)
	end
	local Msgs = {}
	local Recived = {}
	
	--Gets ready for msges
	Modem.open(GPSFreq)
	Modem.transmit(GPSFreq,GPSFreq,Send)
	--Gets msgs from GPS system
	while (#Msgs<4) do
		local _,side,sender,reply,msg,distance = os.pullEvent()
		if (_ == "modem_message") then
			local Tab = textutils.unserialise(msg)
			local Pos = ReadMSG(Tab)
			if Pos then
				local k = tostring(Pos.x)..","..tostring(Pos.y)..","..tostring(Pos.z)
				if (not Recived[k]) then
					Recived[k] = true
					local Tab = {}
					Tab.vPosition = Pos
					Tab.nDistance = distance
					table.insert(Msgs,Tab)
				end
			end
		elseif (side == MyTimer) then
			if (Rep<5) then
				return table.unpack({GetPos(Modem,GPSFreq,Mode,Rep)})
			else
				if Mode == "Req" then
					os.sleep(5)
					return table.unpack({GetPos(Modem,GPSFreq,Mode,Rep)})
				end
				return nil,"No gps response"
			end
		end
	end
	Modem.close(GPSFreq)
	
	--trilaterate position from messages
	local Results = {}
	for i=1,4 do
		local Tabs = {}
		for k,v in pairs(Msgs) do
			table.insert(Tabs,Msgs[Clamp(k+i,1,4)])
		end
		local Pos,Pos1 = trilaterate(Tabs[1],Tabs[2],Tabs[3])
		if Pos1 then
			Pos  = narrow(Pos,Pos1,Tabs[4])
		end
		local k = textutils.serialise(Pos)
		if (Results[k]) then
			Results[k]=Results[k]+1
		else
			Results[k]=1
		end
	end
	
	--Takes result that was returned the most
	local Biggest = -1
	local Ret
	for k,v in pairs(Results) do
		if (v>Biggest) then
			Ret = textutils.unserialise(k)
			Biggest = v
		end
	end
	
	--Make sure the response is valid and if it is return it
	local Ret = vector.new(Ret.x,Ret.y,Ret.z)
	if (Biggest==1) or not(VecEqual(Ret,Ret:round())) and not(Mode=="Raw") then
		if (Rep<10) then
			sleep(0.2)
			return table.unpack({GetPos(Modem,GPSFreq,Mode,Rep)})
		else
			if Mode == "Req" then
				os.sleep(1)
				return table.unpack({GetPos(Modem,GPSFreq,Mode,Rep)})
			end
			return nil,"Return pos invalid"
		end
	end
	return Ret
end