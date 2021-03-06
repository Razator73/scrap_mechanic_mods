
Data = class( nil )
WayPointPositions = {}
WayPointColor = {}
MapLevel = 0
save = false
Data.DataLoaded = false
Data.HasBeenRun = false
HasBeenCreated = false

function Data.client_onCreate( self )
	print("DATA BLOCK GENERATED")
	Data.DataLoaded = false
	save = false
	HasBeenCreated = true
	self.network:sendToServer("GetSavedDataAndStuff")
end

function Data.GetSavedDataAndStuff( self )
	local tmpData = self.storage:load()
	print("Getting Data...")
	if tmpData ~= nil then
		if (tmpData["TableA"] ~= {} and tmpData["TableB"] ~= {}) or tmpData["TableC"] ~= nil then
			WayPointPositions = tmpData["TableA"]
			WayPointColor = tmpData["TableB"]
			MapLevel = tmpData["TableC"]
		end
	end
	print(MapLevel)
	print(WayPointColor)
	print(WayPointPositions)
end

function GetBlockExsistance( self )
	return true
end

function Data.client_onUpdate( self, dt )
	if Data.DataLoaded == true then
		DataBlockLoaded()
		Data.DataLoaded = false
		Data.HasBeenRun = true
		print("Data Loaded!")
	elseif Data.HasBeenRun ~= true then
		self.network:sendToServer("GetSavedDataAndStuff")
		Data.DataLoaded = true
		Data.HasBeenRun = true
		print("Getting Data...")
	end
	if save then
		print("Saving Data...")
		save = false
		self.network:sendToServer( "SaveData", { TableA = WayPointPositions, TableB = WayPointColor, TableC = MapLevel } )
	end
end

function Data.SaveData( self, params )
	self.storage:save(params)
end


function SetPositions( params )
	WayPointPositions = params
	save = true
end

function GetPositions( self )
	return WayPointPositions
end

function SetColors( params )
	WayPointColor = params
	save = true
end

function GetColors( self )
	return WayPointColor
end

function SetMapLevel( params )
	MapLevel = params.level
	save = true
end

function GetSavedMapLevel( self )
	return MapLevel
end