os.loadAPI("NetworkAPI.lua")

local Modem = peripheral.find("modem")
NetworkAPI.Init(Modem,101)

while true do
	term.clear()
	term.setCursorPos(1,1)
	printError("enter OP")
	local Op = read()
	printError("enter payload")
	local Payload = read()
	printError("enter Dest")
	local Dest = tonumber(read())
	
	if not Dest then
		Dest = -1
	end
	
	local Ret,Err = NetworkAPI.Send(Op,Payload,Dest)
	if not Ret then
		print(Err)
		sleep(5)
	end
end