--Intro

--Supports numbers, table, recursive tables, bools, and strings

--Do be warned this is very hard to read in text as
--it stores tables by refrence and everything else by text

--The configuraton section below is how you setup the encoding it cannot be configured outside the api as of now
--TableFormating is how a table is converted into string
--Formats are how varible types are seperated they are added to the being and end of a decleration
--StringEncodes swap certain "words" into other when saving strings

--Useable functions
--IsValidFile(FileLocation) will tell you if a file is valid and is run on the file related functions
--serialise(Data) serialises data does not work with functions however functions can be turned into strings
--unserialise(Stri) reverse the above effect
--serialiseFile(Location,Data,Force),unserialiseFile(Location) same as above Force means overrideing any file there

--Intro
--Configuration
local TableFormating = {
	["tableStart"] = "{",		--normaly "{"
	["tableEnd"] = "}",			--normaly "}"
	["tableIndex"] = "[",		--normaly "["
	["tableIndexEnd"] = "]",	--normaly "]"
	["equal"] = "=",			--normaly "="
	--Used to refrence the table for latter recall
	["tableID"] = "|",			--normaly not present default is "|"
	["tableIDEnd"] = "|",		--normaly not present default is "|"
}

local Formats = {
	-- used for detecting
	["string"] = '"',			--normaly '"'
	["number"] = "n",
	["boolean"] = "b",
	["endfile"] = "E",
	["table"] = TableFormating["tableStart"],
} 

local StringEncodes = {--Strings are messy so this converts it so it wont be detected
	['"'] = "/'", -- i would highly reccomend puting the string format in here
	["\n"] = "*/n", -- i would also reccomend keeping this
}

local TableDefiner,ReadManager,TypeManager,LineHandler,TableHandler,TableContstuctor
local ReturnEnd,StringHandler,NumberHandler,BoolHandler,EndFile,ReadCharter

local PackFile,TypeComp,tableDefiningComp,tableComp,stringComp,numberComp,boolComp
local GetID

local CopyTable,AlwaysRet,AlwaysRet1

local TableRefHolder = {} --Used to hold table refrences in the event of recursive
local IDTab = {} --Used to cut down table id lengths
local GivenIDs = 0

--Configuration DO NOT EDIT BEYOND HERE
--Defining

local UnserFNC = {}
local SerFNC = {}
local MaxWalkBack = -1
local MinWalkBack = 300

local IDStri = "-10K-'s FileSystem"

function IsValidFile(Location)
	local File = fs.open(Location,"r")
	if not(File) then
		File.close()
		return nil,"Nofile"
	elseif not(File.readLine()==IDStri) then
		File.close()
		return nil,"NotCorrectFormat"
	end
	File.close()
	return true
end

--Defining
--unserialise

function unserialise(Stri)
	--Turns a string back into data
	TableRefHolder = {}
	
	local Tab = {}
	Tab.Stri = Stri
	Tab.At = 0
	
	local Res,Err = pcall(TableDefiner,Tab)
	if not Res then
		return nil,Err
	end
	
	local Res,Data = pcall(LineHandler,Tab)
	if not Res then
		return nil,Data
	end
	
	TableRefHolder = {}
	return Data
end

function unserialiseFile(Location)
	--unpacks a file
	--reads the file and returns the data
	local Ret,Err = IsValidFile(Location)
	if not(Ret) then
		return nil,Err
	end
	File = fs.open(Location,"r")
	File.readLine()
	local Stri = File.readAll()
	File.close()
	return table.unpack({unserialise(Stri)})
end

function ReadCharter(File)
	--Reads a string line by line
	File.At = File.At+1
	return File.Stri:sub(File.At,File.At)
end

function TableDefiner(File)
	--Calls table contstructor on all table definings at the begining
	local Defining = true
	while Defining do
		local EchoBack = {[Formats["endfile"]] = EndFile,[TableFormating["tableStart"]] = TableContstuctor}
		local Ret = ReadManager(EchoBack,File)
		if (type(Ret)=="function") then
			if (Ret == EndFile) then
				Defining = false
			end
		end
	end
end

function ReadManager(FNCArr,File)
	--Reads until TypeManager gives a return
	local Stri = ""
	local TF,Out
	while not TF do
		Stri = Stri..ReadCharter(File)
		if (#Stri<=MaxWalkBack) then
			TF,Out = TypeManager(FNCArr,File,Stri)
		elseif (#Stri>MaxWalkBack) then
			TF,Out = TypeManager(FNCArr,File,string.sub(Stri,-MaxWalkBack))
		end
	end
	return Out
end

function TypeManager(FNCArr,File,Stri)
	--Iterates through a string to find if one of FNCArr indexes is found as a string
	for i=1,#Stri-MinWalkBack+1 do
		local FNC = FNCArr[string.sub(Stri,i)]
		if (FNC) then
			return true,FNC(File)
		end
	end
	
	return false
end

function LineHandler(File)
	--The only version of ReadManager just calls it with proper formating now
	return table.unpack({ReadManager(SerFNC,File)})
end

function TableContstuctor(File)
	--Called from TableDefiner FNCArr
	--Creates tables from their refrences at the being of the string
	local CallBack = {[TableFormating["tableID"]] = AlwaysRet}
	ReadManager(CallBack,File)
	local ID = ReturnEnd(File,TableFormating["tableIDEnd"])
	local Tab = TableRefHolder[ID]
	if not(Tab) then
		Tab = {}
		TableRefHolder[ID] = Tab
	end
	
	while true do
		local EchoBack = {[TableFormating["tableEnd"]] = AlwaysRet1,[TableFormating["tableIndex"]] = AlwaysRet}
		local MSG = ReadManager(EchoBack,File)
		if (MSG == AlwaysRet1) then
			break
		end
		local Index = LineHandler(File)
		
		local EchoBack = {[TableFormating["equal"]] = AlwaysRet}
		ReadManager(EchoBack,File)
		
		Tab[Index] = LineHandler(File)
	end
	
	return Tab
end

function ReturnEnd(File,EndStri)
	--Runs until it finds EndStri then return everything -EndStri
	local Stri = ""
	while true do
		Stri = Stri..ReadCharter(File)
		local Check = string.sub(Stri,#Stri-#EndStri+1)
		if (Check == EndStri) then
			return string.reverse(string.sub(string.reverse(Stri),#EndStri+1))
		end
	end
end

--The handlers get called when their type is found
--The way types are detected are from the SerFNC array defined at the bottem
--This array pulls from the Formats and adds functions to them

function TableHandler(File)
	--Starts after a the table index is found
	local CallBack = {[TableFormating["tableID"]] = AlwaysRet}
	ReadManager(CallBack,File)
	local ID = ReturnEnd(File,TableFormating["tableIDEnd"])
	local Table = TableRefHolder[ID]
	if not(Table) then
		Table = {}
		TableRefHolder[ID] = Table
	end
	
	ReturnEnd(File,TableFormating["tableEnd"])
	return Table
end

function StringHandler(File)
	--Starts after a the string index is found
	local Stri = ReturnEnd(File,Formats["string"])
	for v,k in pairs(StringEncodes) do
		Stri = string.gsub(Stri,k,v)
	end
	return Stri
end

function NumberHandler(File)
	--Starts after a the number index is found
	return tonumber(ReturnEnd(File,Formats["number"]))
end

function BoolHandler(File)
	--Starts after a the bool index is found
	return "T"==(ReturnEnd(File,Formats["boolean"]))
end

function EndFile()
	--Use to serve a function now is just a refrence call
	return EndFile
end

--unserialise
--serialise

function serialise(Data)
	--reads data and gives string
	TableRefHolder = {}
	GivenIDs = 0 IDTab = {}
	local Res,Stri = pcall(TypeComp,Data)
	if not Res then
		return nil,Stri
	end
	local Res,TableData = pcall(tableDefiningComp)
	if not Res then
		return nil,TableData
	end
	TableRefHolder = {}
	GivenIDs = 0 IDTab = {}
	return TableData..Formats["endfile"].."\n"..Stri..Formats["endfile"]
end

function serialiseFile(Location,Data,Force)
	--reads data and puts it to file
	if not Force then
		local Ret,Err = IsValidFile(Location)
		if not Ret then
			if not(Err == "Nofile") then
				return Ret,Err
			end
		end
	end
	local Ret,Err = serialise(Data)
	if not Ret then
		return nil,Err
	end
	
	local File = fs.open(Location,"w")
	File.write(IDStri.."\n")
	File.write(Ret)
	File.close()
	return true
end

function tableDefiningComp()
	--Runs when a table type is found
	local Stri = ""
	
	local Loop = true
	while (Loop) do -- As i was using the ID as a index i cant you #table so this is the best i got
		Loop = false
		local OldTableRefHolder = CopyTable(TableRefHolder)
		TableRefHolder={}
		for ID,Data in pairs(OldTableRefHolder) do
			Loop = true
			local Ret = TableFormating["tableStart"]..TableFormating["tableID"]..ID..TableFormating["tableIDEnd"]
			for k,v in pairs(Data) do
				local TypeVar = type(k)
				k=TypeComp(k)
				Ret=Ret..TableFormating["tableIndex"]..k..TableFormating["tableIndexEnd"]..TableFormating["equal"]..TypeComp(v)
			end
			Stri = Stri .. Ret..TableFormating["tableEnd"]
		end
	end
	return Stri
end

function TypeComp(Data)
	--Runs a function based on it type
	local TypeVar = type(Data)
	local Stri = Formats[TypeVar]
	local FNC = UnserFNC[TypeVar] --Defined at the bottem uses Formats table
	return FNC(Data,Stri)
end

function GetID(Data)
	--Turns a table into its respective indexed table id
	local ID1 = tostring(Data)
	local ID
	if (IDTab[ID1]) then
		return IDTab[ID1],true
	else
		GivenIDs=GivenIDs+1
		IDTab[ID1] = GivenIDs
		return GivenIDs,false
	end
end

--The Comp functions are the same as handlers but for writing data
--The functions get called when their type is found

function tableComp(Data,Stri)
	--Runs when a table type is found
	local ID,FoundID = GetID(Data)
	
	if not(FoundID) then
		TableRefHolder[ID] = Data
	end
	return TableFormating["tableStart"]..TableFormating["tableID"]..ID..TableFormating["tableIDEnd"]..TableFormating["tableEnd"]
end

function stringComp(Data,Stri)
	--Runs when a string is found
	for k,v in pairs(StringEncodes) do
		Data = string.gsub(Data,k,v)
	end
	return Stri..Data..Stri
end

function numberComp(Data,Stri)
	--Runs when a number is found
	return Stri..tostring(Data)..Stri 
end

function boolComp(Data,Stri)
	--Runs when a bool is found
	if Data then
		return Stri.."T"..Stri
	else
		return Stri.."F"..Stri
	end
end

--serialise
--extra functions

function CopyTable(A)
	local B = {}
	for k,v in pairs(A) do
		B[k] = v
	end
	return B
end

--AlwaysRet are the same as EndFile

function AlwaysRet()
	return AlwaysRet
end

function AlwaysRet1()
	return AlwaysRet1
end

--extra functions
--some code run

--MinWalkBack and MaxWalkBack are the min is the shortest string and the MaxWalkBack is the longest
--This determines what the TypeManager iterates through

for k,v in pairs(TableFormating) do
	if (#v>MaxWalkBack) then
		MaxWalkBack = #v
	end
	if (#v<MinWalkBack) then
		MinWalkBack = #v
	end
end

for k,v in pairs(Formats) do
	if (#v>MaxWalkBack) then
		MaxWalkBack = #v
	end
	if (#v<MinWalkBack) then
		MinWalkBack = #v
	end
end

--Defining the function tables

UnserFNC["string"] = stringComp
UnserFNC["table"] = tableComp
UnserFNC["number"] = numberComp
UnserFNC["boolean"] = boolComp

SerFNC[Formats["string"]] = StringHandler
SerFNC[Formats["table"]] = TableHandler
SerFNC[Formats["number"]] = NumberHandler
SerFNC[Formats["endfile"]] = EndFile
SerFNC[Formats["boolean"]] = BoolHandler