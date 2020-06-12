dofile "overworld/generate_cells.lua"
dofile "$GAME_DATA/Scripts/game/terrain/cell_rotation_utility.lua"
dofile "random_generation.lua"

local SCALE_HACK = false
local SCALE = 8
local ADD_LOD = 1
local DEBUG_COLORS = false

----------------------------------------------------------------------------------------------------
-- Initialization
----------------------------------------------------------------------------------------------------

function init()
	initRoadAndCliffTiles()
	initMeadowTiles()
	initForestTiles()
	initFieldTiles()
	initBurntForestTiles()
	initAutumnForestTiles()
	initLakeTiles()
	initMountainTiles()
	initDesertTiles()
	initPoiTiles()
end

function create( xMin, xMax, yMin, yMax, seed, data, padding )
	--seed = 1337 --HACK: Constant seed for testing
	--math.randomseed( os.time() )
	--seed = math.random( 1073741823 )
	--seed = 852772513
	
	print( "Creating overworld terrain" )
	print( "Bounds X: ["..xMin..", "..xMax.."], Y: ["..yMin..", "..yMax.."]" )
	print( "Seed: "..seed )

	print( "Total cells: " .. ( xMax - xMin + 1 ) * ( yMax - yMin + 1 ) )

	generateOverworldCelldata( xMin, xMax, yMin, yMax, seed, data, padding )
	
	sm.terrainData.save( g_cellData )
	
	createControlPoints()
end

----------------------------------------------------------------------------------------------------

function load()
	print( "Loading overworld terrain" )
	if sm.terrainData.exists() then
		g_cellData = sm.terrainData.load()
		--print( "Bounds X: [" .. g_cellData.bounds.xMin .. ", " .. g_cellData.bounds.xMax .. "], Y: [" .. g_cellData.bounds.yMin .. ", " .. g_cellData.bounds.yMax .. "]" )
		--print( "Seed: "..g_cellData.seed )
		
		createControlPoints()
		return true
	end
	print( "No terrain data found" )
	return false
end

function createControlPoints()
	g_cpWestEdge = {}
	g_cpSouthEdge = {}
	g_cpMid = {}
	for y = g_cellData.bounds.yMin, g_cellData.bounds.yMax do
		g_cpWestEdge[y] = {}
		g_cpSouthEdge[y] = {}
		g_cpMid[y] = {}
		for x = g_cellData.bounds.xMin, g_cellData.bounds.xMax do
			g_cpWestEdge[y][x] = ( getCornerElevationLevel( x, y ) + getCornerElevationLevel( x, y + 1 ) ) / 2
			g_cpSouthEdge[y][x] = ( getCornerElevationLevel( x, y ) + getCornerElevationLevel( x + 1, y ) ) / 2
			local cpEastEdge = ( getCornerElevationLevel( x + 1, y ) + getCornerElevationLevel( x + 1, y + 1 ) ) / 2
			g_cpMid[y][x] = ( g_cpWestEdge[y][x] + cpEastEdge ) / 2
		end
	end
end

----------------------------------------------------------------------------------------------------
-- Utility
----------------------------------------------------------------------------------------------------

function getMidElevation( cellX, cellY )
	if insideCellBounds( cellX, cellY ) then
		return g_cpMid[cellY][cellX]
	end
	return 0
end

function getWestElevation( cellX, cellY )
	if insideCellBounds( cellX, cellY ) then
		return g_cpWestEdge[cellY][cellX]
	end
	return 0
end

function getEastElevation( cellX, cellY )
	return getWestElevation( cellX + 1, cellY )
end

function getSouthElevation( cellX, cellY )
	if insideCellBounds( cellX, cellY ) then
		return g_cpSouthEdge[cellY][cellX]
	end
	return 0
end

function getSouthWestElevation( cellX, cellY )
	if insideCellBounds( cellX, cellY ) then
		return g_cellData.elevation[cellY][cellX]
	end
	return 0
end

function getSouthEastElevation( cellX, cellY )
	return getSouthWestElevation( cellX + 1, cellY )
end


function getNorthElevation( cellX, cellY )
	return getSouthElevation( cellX, cellY + 1 )
end

----------------------------------------------------------------------------------------------------

function flatTowardsWest( cellX, cellY )
	local flags = getRoadCliffFlags( cellX, cellY )
	if bit.band( MASK_ROADS_SN, flags ) == 0 then return 0 end
	if bit.band( MASK_ROADS, flags ) ~= 0 then return 1 end
	return 0
end

function flatTowardsEast( cellX, cellY )
	local flags = getRoadCliffFlags( cellX, cellY )
	if bit.band( MASK_ROADS_SN, flags ) == 0 then return 0 end
	if bit.band( MASK_ROADS, flags ) ~= 0 then return 1 end
	return 0
end

function flatTowardsSouth( cellX, cellY )
	local flags = getRoadCliffFlags( cellX, cellY )
	if bit.band( MASK_ROADS_WE, flags ) == 0 then return 0 end
	if bit.band( MASK_ROADS, flags ) ~= 0 then return 1 end
	return 0
end

function flatTowardsNorth( cellX, cellY )
	local flags = getRoadCliffFlags( cellX, cellY )
	if bit.band( MASK_ROADS_WE, flags ) == 0 then return 0 end
	if bit.band( MASK_ROADS, flags ) ~= 0 then return 1 end
	return 0
end

----------------------------------------------------------------------------------------------------

function getMidElevationX( x0, y0, xFract )
	local t = xFract
	local x1 = x0 + 1
	local c0, c1, c2, c3
	
	c0 = getMidElevation( x0, y0 )
	
	if flatTowardsEast( x0, y0 ) == 1 then
		c1 = getMidElevation( x0, y0 )
	else
		c1 = getEastElevation( x0, y0 )
	end
	
	if flatTowardsWest( x1, y0 ) == 1 then
		c2 = getMidElevation( x1, y0 )
	else
		c2 = getWestElevation( x1, y0 )
	end
	
	c3 = getMidElevation( x1, y0 )
	
	return sm.util.bezier3( c0, c1, c2, c3, t )
end

function getSouthElevationX( x0, y0, xFract )
	local t = xFract
	local x1 = x0 + 1
	
	local flatnessEast = flatTowardsEast( x0, y0 - 1 ) * 0.5 + flatTowardsEast( x0, y0 ) * 0.5
	local flatnessWest = flatTowardsWest( x1, y0 - 1 ) * 0.5 + flatTowardsWest( x1, y0 ) * 0.5
	
	local c0 = getSouthElevation( x0, y0 )
	local c1 = sm.util.lerp( getSouthEastElevation( x0, y0 ), getSouthElevation( x0, y0 ), flatnessEast )
	local c2 = sm.util.lerp( getSouthWestElevation( x1, y0 ), getSouthElevation( x1, y0 ), flatnessWest )
	local c3 = getSouthElevation( x1, y0 )
	
	return sm.util.bezier3( c0, c1, c2, c3, t )
end

function getNorthElevationX( x0, y0, xFract )
	return getSouthElevationX( x0, y0 + 1, xFract )
end

----------------------------------------------------------------------------------------------------

local function getElev( x, y )
	local cellX, cellY = getCell( x, y )
	local xFract, yFract = getFraction( x, y ) -- Fraction in cell [0,1)

	local x0, y0
	local xFract2, yFract2 --Mid to mid
	
	if xFract < 0.5 then
		x0 = cellX - 1
		xFract2 = xFract + 0.5
	else
		x0 = cellX
		xFract2 = xFract - 0.5
	end
	
	if yFract < 0.5 then
		y0 = cellY - 1
		yFract2 = yFract + 0.5
	else
		y0 = cellY
		yFract2 = yFract - 0.5
	end
	
	local flatnessNorth = sm.util.lerp( flatTowardsNorth( x0, y0 ), flatTowardsNorth( x0 + 1, y0 ), xFract2 )
	local flatnessSouth = sm.util.lerp( flatTowardsSouth( x0, y0 + 1 ), flatTowardsSouth( x0 + 1, y0 + 1 ), xFract2 )
	
	local c0 = getMidElevationX( x0, y0, xFract2 )
	local c1 = sm.util.lerp( getNorthElevationX( x0, y0, xFract2 ), getMidElevationX( x0, y0, xFract2 ), flatnessNorth )
	local c2 = sm.util.lerp( getSouthElevationX( x0, y0 + 1, xFract2 ), getMidElevationX( x0, y0 + 1, xFract2 ), flatnessSouth )
	local c3 = getMidElevationX( x0, y0 + 1, xFract2 )
	
	return sm.util.bezier3( c0, c1, c2, c3, yFract2 )
end

local FlattenCache = {}

function getElevationHeightAt( x, y )
	local cellX, cellY = getCell( x, y )
	
	local blend
	local cacheKey = bit.bor( bit.lshift( cellY + 128, 8 ), cellX + 128 )
	local flattenList = FlattenCache[cacheKey]
	
	if flattenList == nil then
		flattenList = {}

		for i = -1, 1 do
			for j = -1, 1 do
				local id, tileCellOffsetX, tileCellOffsetY = getCellTileIdAndOffset( cellX + j, cellY + i )

				if id ~= 0 then
					local nodes = sm.terrainTile.getNodesForCell( id, tileCellOffsetX, tileCellOffsetY )
					for _, node in ipairs( nodes ) do
						if valueExists( node.tags, "FLATTEN" ) then
							local rx, ry = rotateLocal( cellX + j, cellY + i, round( node.pos.x ), round( node.pos.y ) )
							flattenList[#flattenList + 1] = {
								x = rx + ( cellX + j ) * CELL_SIZE,
								y = ry + ( cellY + i ) * CELL_SIZE,
								r = node.scale.x * 0.5
							}
						end
					end
				end
			end
		end

		-- Randomly flatten some cells for good building spot
		if insideCellBounds( cellX, cellY ) then
			if #flattenList == 0 and g_cellData.flags[cellY][cellX] == 0 and sm.noise.intNoise2d( cellX, cellY, g_cellData.seed + 358 ) % 7 == 0 then
				flattenList[#flattenList + 1] = {
					x = ( cellX + 0.5 ) * CELL_SIZE,
					y = ( cellY + 0.5 ) * CELL_SIZE,
					r = 16
				}
			end
		end

		-- if #flattenList > 0 then
		-- 	local rotationStep = getCellRotationStep( cellX, cellY )
		-- 	print( "#flat on "..cellX..","..cellY..":"..#flattenList, "rot:", rotationStep )
		-- end
		
		FlattenCache[cacheKey] = flattenList
	end

	for _,flat in ipairs( flattenList ) do
		local dx = x - flat.x
		local dy = y - flat.y
		local dst = math.sqrt( dx * dx + dy * dy ) / flat.r
		if dst < 2.0 then
			local p = sm.util.smoothstep( 2, 1, dst )
			if not blend or p > blend.p then
				blend = {
					x = flat.x,
					y = flat.y,
					p = p
				}
			end
		end
	end


	if blend then
		local a = getElev( x, y )
		local b = math.floor( getElev( blend.x, blend.y ) * 4 + 0.5 ) * 0.25
		return a + ( b - a ) * blend.p
		--return b
	end

	return getElev( x, y )
end

----------------------------------------------------------------------------------------------------

function getCliffHeightAt( x, y )
	local cellX, cellY = getCell( x, y )

	local cliffLevelSW = getCornerCliffLevel( cellX, cellY )
	local cliffLevelSE = getCornerCliffLevel( cellX + 1, cellY )
	local cliffLevelNW = getCornerCliffLevel( cellX, cellY + 1 )
	local cliffLevelNE = getCornerCliffLevel( cellX + 1, cellY + 1 )

	return math.min( math.min( cliffLevelSW, cliffLevelSE ), math.min( cliffLevelNW, cliffLevelNE ) ) * 8
end

----------------------------------------------------------------------------------------------------

function getDetailHeightAt( x, y, lod )
	local cellX, cellY = getCell( x, y )
	local id, tileCellOffsetX, tileCellOffsetY = getCellTileIdAndOffset( cellX, cellY )

	local rx, ry = inverseRotateLocal( cellX, cellY, x - cellX * CELL_SIZE, y - cellY * CELL_SIZE )

	return sm.terrainTile.getHeightAt( id, tileCellOffsetX, tileCellOffsetY, lod, rx, ry )
end

----------------------------------------------------------------------------------------------------

function getElevationNormalAt( x, y )
	local o = 2.0
	local dx = getElevationHeightAt( x + o, y ) - getElevationHeightAt( x - o, y )
	local dy = getElevationHeightAt( x, y + o ) - getElevationHeightAt( x, y - o )
	local xDir = sm.vec3.new( o * 2, 0, dx )
	local yDir = sm.vec3.new( 0, o * 2, dy )
	return sm.vec3.normalize( sm.vec3.cross( xDir, yDir ) )
end

----------------------------------------------------------------------------------------------------
-- Generator API Getters
----------------------------------------------------------------------------------------------------

function getHeightAt( x, y, lod )
	if SCALE_HACK == true then
		x = x * SCALE
		y = y * SCALE
		lod = lod + ADD_LOD
	end
	
	local height = -16
	local cellX, cellY = getCell( x, y )
	if insideCellBounds( cellX, cellY ) == true then
		height = getDetailHeightAt( x, y, lod )
		height = height + getElevationHeightAt( x, y )
		height = height + getCliffHeightAt( x, y )
	end
	if SCALE_HACK == true then
		return height / SCALE
	end
	return height
end

----------------------------------------------------------------------------------------------------

local function cornerDebugColor( cornerX, cornerY, color )
	local colors = {
		sm.color.new( "340042" ),
		sm.color.new( "342870" ),
		sm.color.new( "26547b" ),
		sm.color.new( "1f7f79" ),
		sm.color.new( "2fac66" ),
		sm.color.new( "7fd335" ),
		sm.color.new( "fce51e" )
	}
	local c

	local val = sm.util.clamp( g_cellData.cornerDebug[cornerY][cornerX], 0, 1 ) * 6

	local c0 = colors[math.floor( val ) + 1]
	local c1 = colors[math.ceil( val ) + 1]
	local p = val % 1
	c = { sm.util.lerp( c0.r, c1.r, p ), sm.util.lerp( c0.g, c1.g, p ), sm.util.lerp( c0.b, c1.b, p ) }

	if c then
		color[1] = c[1]
		color[2] = c[2]
		color[3] = c[3]
	end
end

local function cellDebugColor( cellX, cellY, color )
	local c
	if g_cellData.cellDebug[cellY][cellX] == DEBUG_R then
		c = { 1.0, 0.0, 0.0 }
	elseif g_cellData.cellDebug[cellY][cellX] == DEBUG_G then
		c = { 0.0, 1.0, 0.0 }
	elseif g_cellData.cellDebug[cellY][cellX] == DEBUG_B then
		c = { 0.0, 0.0, 1.0 }
	elseif g_cellData.cellDebug[cellY][cellX] == DEBUG_C then
		c = { 0.0, 1.0, 1.0 }
	elseif g_cellData.cellDebug[cellY][cellX] == DEBUG_M then
		c = { 1.0, 0.0, 1.0 }
	elseif g_cellData.cellDebug[cellY][cellX] == DEBUG_Y then
		c = { 1.0, 1.0, 0.0 }
	elseif g_cellData.cellDebug[cellY][cellX] == DEBUG_BLACK then
		c = { 0.1, 0.1, 0.1 }
	elseif g_cellData.cellDebug[cellY][cellX] == DEBUG_ORANGE then
		c = { 1.0, 0.5, 0.0 }
	elseif g_cellData.cellDebug[cellY][cellX] == DEBUG_PINK then
		c = { 1.0, 0.0, 0.5 }
	elseif g_cellData.cellDebug[cellY][cellX] == DEBUG_LIME then
		c = { 0.5, 1.0, 0.0 }
	elseif g_cellData.cellDebug[cellY][cellX] == DEBUG_SPING then
		c = { 0.0, 1.0, 0.5 }
	elseif g_cellData.cellDebug[cellY][cellX] == DEBUG_PURPLE then
		c = { 0.5, 0.0, 1.0 }
	elseif g_cellData.cellDebug[cellY][cellX] == DEBUG_LAKE then
		c = { 0.0, 0.5, 1.0 }
	end
	if c then
		color[1] = c[1]
		color[2] = c[2]
		color[3] = c[3]
	end
end

function getColorAt( x, y, lod )
	if SCALE_HACK == true then
		x = x * SCALE
		y = y * SCALE
		lod = lod + ADD_LOD
	end
	
	local noise = sm.noise.octaveNoise2d( x / 8, y / 8, 5, 45 )
	local brightness = noise * 0.25 + 0.75
	
	local cornerX, cornerY = getClosestCorner( x, y )
	local cellX, cellY = getCell( x, y )
	
	if insideCellBounds( cellX, cellY ) == true then
		local id, tileCellOffsetX, tileCellOffsetY = getCellTileIdAndOffset( cellX, cellY )
	
		local rx, ry = inverseRotateLocal( cellX, cellY, x - cellX * CELL_SIZE, y - cellY * CELL_SIZE )
	
		local r, g, b = sm.terrainTile.getColorAt( id, tileCellOffsetX, tileCellOffsetY, lod, rx, ry )
	
		local color = { r, g, b }

		if DEBUG_COLORS then
			--cornerDebugColor( cornerX, cornerY, color )
			cellDebugColor( cellX, cellY, color )
		end
		
		--brightness = 0.75 -- No noise

		--Checkerboard pattern
		--brightness = brightness * ( math.abs( cellX ) % 2 * 0.1 + 0.9 )
		--brightness = brightness * ( math.abs( cellY ) % 2 * 0.1 + 0.9 )

		if DEBUG_COLORS then
			--brightness = sm.util.clamp( g_cellData.cornerDebug[cornerY][cornerX], 0, 1 )
		end

		return color[1] * brightness, color[2] * brightness, color[3] * brightness

	elseif insideCornerBounds( cornerX, cornerY ) then

		local color = { 0.0, 0.5, 1.0 }
		if DEBUG_COLORS then
			--cornerDebugColor( cornerX, cornerY, color )
			--brightness = sm.util.clamp( g_cellData.cornerDebug[cornerY][cornerX], 0, 1 )
		end
		return color[1] * brightness, color[2] * brightness, color[3] * brightness

	else

		local color = { 0.0, 0.5, 1.0 }
		if DEBUG_COLORS then
			brightness = 0.8
		end
		return color[1] * brightness, color[2] * brightness, color[3] * brightness
	end
end

----------------------------------------------------------------------------------------------------

function getMaterialAt( x, y, lod )
	if SCALE_HACK == true then
		x = x * SCALE
		y = y * SCALE
		lod = lod + ADD_LOD
	end
	
	local cellX, cellY = getCell( x, y )
	if insideCellBounds( cellX, cellY ) == true then
	
--		if cellX == 0 then
--			return 1, 0, 0, 0, 0, 0, 0, 0
--		elseif cellX == 1 then
--			return 0, 1, 0, 0, 0, 0, 0, 0
--		elseif cellX == 2 then
--			return 0, 0, 1, 0, 0, 0, 0, 0
--		elseif cellX == 3 then
--			return 0, 0, 0, 1, 0, 0, 0, 0
--		elseif cellX == 4 then
--			return 0, 0, 0, 0, 1, 0, 0, 0
--		elseif cellX == 5 then
--			return 0, 0, 0, 0, 0, 1, 0, 0
--		elseif cellX == 6 then
--			return 0, 0, 0, 0, 0, 0, 1, 0
--		elseif cellX == 7 then
--			return 0, 0, 0, 0, 0, 0, 0, 1
--		end
		local id, tileCellOffsetX, tileCellOffsetY = getCellTileIdAndOffset( cellX, cellY )
		
		local rx, ry = inverseRotateLocal( cellX, cellY, x - cellX * CELL_SIZE, y - cellY * CELL_SIZE )
		
		return sm.terrainTile.getMaterialAt( id, tileCellOffsetX, tileCellOffsetY, lod, rx, ry )
	end
	return 1, 0, 0, 0, 0, 0, 0, 0
end

----------------------------------------------------------------------------------------------------

function getClutterIdxAt( x, y )
	if SCALE_HACK == true then
		x = x * SCALE
		y = y * SCALE
	end
	
	local cellX, cellY = getCell( x * 0.5, y * 0.5 )
	if insideCellBounds( cellX, cellY ) == true then
		local id, tileCellOffsetX, tileCellOffsetY = getCellTileIdAndOffset( cellX, cellY )
		
		local rx, ry = inverseRotateLocal( cellX, cellY, x - cellX * CELL_SIZE * 2, y - cellY * CELL_SIZE * 2, CELL_SIZE * 2 - 1 )

		return sm.terrainTile.getClutterIdxAt( id, tileCellOffsetX, tileCellOffsetY, rx, ry )
	else
		return -1
	end
end

----------------------------------------------------------------------------------------------------

function getEffectMaterialAt( x, y )
	if SCALE_HACK == true then
		return "Grass"
	end

	local mat0, mat1, mat2, mat3, mat4, mat5, mat6, mat7 = getMaterialAt(x, y, 0)
	
	local materialWeights = {}
	materialWeights["Grass"] = math.max(mat4, mat7)
	materialWeights["Rock"] = math.max(mat0, mat2, mat5)
	materialWeights["Dirt"] = math.max(mat3, mat6)
	materialWeights["Sand"] = math.max(mat1)
	local weightThreshold = 0.25
	local selectedKey = "Grass"
	
	for key, weight in pairs(materialWeights) do
		if weight > materialWeights[selectedKey] and weight > weightThreshold then
			selectedKey = key
		end
	end
	
	return selectedKey
end

----------------------------------------------------------------------------------------------------

-- Invalid asset hunt!
invalidAssets = {
}

local water_asset_uuid = sm.uuid.new( "990cce84-a683-4ea6-83cc-d0aee5e71e15" )

function getAssetsForCell( cellX, cellY, size )
	if SCALE_HACK == true then
		return {}
	end
	
	local id, tileCellOffsetX, tileCellOffsetY = getCellTileIdAndOffset( cellX, cellY )

	if id ~= 0 then
		local lake = isLake( cellX, cellY )

		local assets = sm.terrainTile.getAssetsForCell( id, tileCellOffsetX, tileCellOffsetY, size )
		for _,asset in ipairs( assets ) do
			-- Invalid asset hunt!
			if invalidAssets[tostring( asset.uuid )] then
				sm.log.error( "Invalid asset {"..tostring( asset.uuid ).."} in tile: '"..getTilePath( id ).."'" )
			end
			
			local rx, ry = rotateLocal( cellX, cellY, asset.pos.x, asset.pos.y )
	
			local x = cellX * CELL_SIZE + rx
			local y = cellY * CELL_SIZE + ry
	
			local height = asset.pos.z + getCliffHeightAt( x, y )

			-- Water rotation
			if lake and asset.uuid == water_asset_uuid then
				asset.rot = sm.quat.new( 0.7071067811865475, 0.0, 0.0, 0.7071067811865475 )
			else
				height = height + getElevationHeightAt( x, y )
				asset.rot = getRotationStepQuat( cellX, cellY ) * asset.rot
			end
			asset.pos = sm.vec3.new( rx, ry, height )


			local nor = getElevationNormalAt( x, y )
			if nor.z < 0.999848 then --Slope angle > 1 deg
				asset.slopeNormal = nor
			end
		end
	
		return assets
	end
	return {}
end

----------------------------------------------------------------------------------------------------

function getHarvestablesForCell( cellX, cellY, size )
	if SCALE_HACK == true then
		return {}
	end

	local id, tileCellOffsetX, tileCellOffsetY = getCellTileIdAndOffset( cellX, cellY )
	if id ~= 0 then
		-- Load harvestables from cell
		local harvestables = sm.terrainTile.getHarvestablesForCell( id, tileCellOffsetX, tileCellOffsetY, size )
		for _, harvestable in ipairs( harvestables ) do
			local rx, ry = rotateLocal( cellX, cellY, harvestable.pos.x, harvestable.pos.y )
	
			local x = cellX * CELL_SIZE + rx
			local y = cellY * CELL_SIZE + ry
	
			local height = harvestable.pos.z + getElevationHeightAt( x, y ) + getCliffHeightAt( x, y )
			harvestable.pos = sm.vec3.new( rx, ry, height )
			harvestable.rot = getRotationStepQuat( cellX, cellY ) * harvestable.rot

			local nor = getElevationNormalAt( x, y )
			if nor.z < 0.999848 then --Slope angle > 1 deg
				harvestable.slopeNormal = nor
			end
		end
		
		return harvestables
	end
	return {}
end

----------------------------------------------------------------------------------------------------
g_nodes = {}
g_nodeCount = 0
g_creations = {}

blueprintTable = {}

blueprintTable["Kit_RoadsideMarket_Antenna"] =						{	"$SURVIVAL_DATA/LocalBlueprints/Kit_RoadsideMarket_Antenna_01.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/Kit_RoadsideMarket_Antenna_02.blueprint" }

blueprintTable["Kit_RoadsideMarket_LightLantern"] =					{	"$SURVIVAL_DATA/LocalBlueprints/Kit_RoadsideMarket_LightLantern_01.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/Kit_RoadsideMarket_LightLantern_02.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/Kit_RoadsideMarket_LightLantern_03.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/Kit_RoadsideMarket_LightLantern_04.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/Kit_RoadsideMarket_LightLantern_05.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/Kit_RoadsideMarket_LightLantern_06.blueprint" }

blueprintTable["RoadsideMarket_Clutter_BoxWood"] =					{{	"$SURVIVAL_DATA/LocalBlueprints/RoadsideMarket_Clutter_BoxWood_01.blueprint", 10 },
																		"$SURVIVAL_DATA/LocalBlueprints/RoadsideMarket_Clutter_BoxWood_02.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/RoadsideMarket_Clutter_BoxWood_03.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/RoadsideMarket_Clutter_BoxWood_04.blueprint" }

blueprintTable["RoadsideMarket_Clutter_FruitCrateDisplay"] =		{	"$SURVIVAL_DATA/LocalBlueprints/RoadsideMarket_Clutter_FruitCrateDisplay_01.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/RoadsideMarket_Clutter_FruitCrateDisplay_02.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/RoadsideMarket_Clutter_FruitCrateDisplay_03.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/RoadsideMarket_Clutter_FruitCrateDisplay_04.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/RoadsideMarket_Clutter_FruitCrateDisplay_05.blueprint" }

blueprintTable["RoadsideMarket_Clutter_PottedPlant"] =				{	"$SURVIVAL_DATA/LocalBlueprints/RoadsideMarket_Clutter_PottedPlant_01.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/RoadsideMarket_Clutter_PottedPlant_02.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/RoadsideMarket_Clutter_PottedPlant_03.blueprint" }

blueprintTable["RoadsideMarket_Clutter_SeedBag"] =					{	"$SURVIVAL_DATA/LocalBlueprints/RoadsideMarket_Clutter_SeedBag_01.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/RoadsideMarket_Clutter_SeedBag_02.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/RoadsideMarket_Clutter_SeedBag_03.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/RoadsideMarket_Clutter_SeedBag_04.blueprint" }

blueprintTable["StartAreaFarm_SeedBag"] =							{	"$SURVIVAL_DATA/LocalBlueprints/StartAreaFarm_SeedBag_01.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/StartAreaFarm_SeedBag_02.blueprint" }

blueprintTable["WarehouseExterior_Barrack"] =						{	"$SURVIVAL_DATA/LocalBlueprints/WarehouseExterior_Barrack_01.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/WarehouseExterior_Barrack_02.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/WarehouseExterior_Barrack_03.blueprint" }

blueprintTable["WarehouseExterior_Clutter_JunkCrate"] =				{	"$SURVIVAL_DATA/LocalBlueprints/WarehouseExterior_Clutter_JunkCrate_01.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/WarehouseExterior_Clutter_JunkCrate_02.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/WarehouseExterior_Clutter_JunkCrate_03.blueprint" }

blueprintTable["WarehouseExterior_Clutter_JunkSpill"] =				{	"$SURVIVAL_DATA/LocalBlueprints/WarehouseExterior_Clutter_JunkSpill_01.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/WarehouseExterior_Clutter_JunkSpill_02.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/WarehouseExterior_Clutter_JunkSpill_03.blueprint" }

blueprintTable["WarehouseExterior_Clutter_Pallet_Junk"] =			{	"$SURVIVAL_DATA/LocalBlueprints/WarehouseExterior_Clutter_Pallet_Junk_01.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/WarehouseExterior_Clutter_Pallet_Junk_02.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/WarehouseExterior_Clutter_Pallet_Junk_03.blueprint" }

blueprintTable["WarehouseExterior_Roof_Tower_Water"] =				{	"$SURVIVAL_DATA/LocalBlueprints/WarehouseExterior_Roof_Tower_Water_01.blueprint",
																		"$SURVIVAL_DATA/LocalBlueprints/WarehouseExterior_Roof_Tower_Water_02.blueprint" }

----------------------------------------------------------------------------------------------------

prefabTable = {}

prefabTable["RoadsideMarket_ShackLarge"] =							{	"$SURVIVAL_DATA/LocalPrefabs/RoadsideMarket_ShackLarge_01.prefab",
																		"$SURVIVAL_DATA/LocalPrefabs/RoadsideMarket_ShackLarge_02.prefab",
																		"$SURVIVAL_DATA/LocalPrefabs/RoadsideMarket_ShackLarge_03.prefab",
																		"$SURVIVAL_DATA/LocalPrefabs/RoadsideMarket_ShackLarge_04.prefab" }

prefabTable["RoadsideMarket_ShackMedium"] =							{	"$SURVIVAL_DATA/LocalPrefabs/RoadsideMarket_ShackMedium_01.prefab",
																		"$SURVIVAL_DATA/LocalPrefabs/RoadsideMarket_ShackMedium_02.prefab",
																		"$SURVIVAL_DATA/LocalPrefabs/RoadsideMarket_ShackMedium_03.prefab",
																		"$SURVIVAL_DATA/LocalPrefabs/RoadsideMarket_ShackMedium_04.prefab" }

prefabTable["RoadsideMarket_ShackSmall"] =							{	"$SURVIVAL_DATA/LocalPrefabs/RoadsideMarket_ShackSmall_01.prefab",
																		"$SURVIVAL_DATA/LocalPrefabs/RoadsideMarket_ShackSmall_02.prefab",
																		"$SURVIVAL_DATA/LocalPrefabs/RoadsideMarket_ShackSmall_03.prefab",
																		"$SURVIVAL_DATA/LocalPrefabs/RoadsideMarket_ShackSmall_04.prefab" }

----------------------------------------------------------------------------------------------------

function loadPrefab( prefab, loadFlags, prefabIndex )

	print( "Loading prefab:", prefab.name, "tagged:", prefab.tag )
	local mergeCreations = bit.band( prefab.flags, MergeCreationFlag ) ~= 0
	randomizePrefab( prefab, prefabTable )
	local creations, prefabs, nodes =  sm.terrainTile.getContentFromPrefab( prefab.name, loadFlags )

	for _,creation in ipairs( creations ) do

		randomizeCreation( creation, blueprintTable )

		creation.rot = prefab.rot * creation.rot
		creation.pos = prefab.pos + (prefab.rot * creation.pos)
		creation.tags = prefab.tags
		creation.mergeCreation = mergeCreations

		g_creations[#g_creations + 1] = creation
	end

	for _,subPrefab in ipairs( prefabs ) do

		subPrefab.rot = prefab.rot * subPrefab.rot
		subPrefab.pos = prefab.pos + ( prefab.rot * ( subPrefab.pos * prefab.scale ) )
		subPrefab.scale = prefab.scale * subPrefab.scale
		
		for _,tag in ipairs(prefab.tags) do
			subPrefab.tags[#subPrefab.tags + 1] = tag
		end
		
		if mergeCreations then
			subPrefab.flags = bit.bor( subPrefab.flags, MergeCreationFlag )
		end

		loadPrefab( subPrefab, loadFlags, prefabIndex )
	end

	local nodeCount = g_nodeCount
	
	for _,node in ipairs( nodes ) do

		node.rot = prefab.rot * node.rot
		node.pos = prefab.pos + ( prefab.rot * ( node.pos * prefab.scale ) )
		node.scale = node.scale * prefab.scale

		if valueExists( node.tags, "CONNECTABLE" ) then
			node.params.connections.id = node.params.connections.id + g_nodeCount;

			for index, value in ipairs(node.params.connections.otherIds) do
				if (type(value) == "table") then
					value.id = value.id + g_nodeCount
				else
					node.params.connections.otherIds[index] = node.params.connections.otherIds[index] + g_nodeCount
				end
			end


			nodeCount = math.max( node.params.connections.id, nodeCount )
		end
		
		g_nodes[#g_nodes + 1] = node
	end

	g_nodeCount = nodeCount + 1
end

function prepareCell( cellX, cellY, loadFlags )

	g_nodes = {}
	-- This value needs to be larger then the number of connection nodes in the cell
	g_nodeCount = 65536
	g_creations = {}
	
	if SCALE_HACK == true then
		return {}
	end
	
	local id, tileCellOffsetX, tileCellOffsetY = getCellTileIdAndOffset( cellX, cellY )
	if id ~= 0 then
		local prefabs = sm.terrainTile.getPrefabsForCell( id, tileCellOffsetX, tileCellOffsetY )
		for prefabIndex, prefab in ipairs(prefabs) do
			loadPrefab( prefab, loadFlags, prefabIndex )
		end
	end

end

function getNodesForCell( cellX, cellY )
	if SCALE_HACK == true then
		return {}
	end

	local hasReflectionProbe = false

	local id, tileCellOffsetX, tileCellOffsetY = getCellTileIdAndOffset( cellX, cellY )
	if id ~= 0 then
		local nodes = sm.terrainTile.getNodesForCell( id, tileCellOffsetX, tileCellOffsetY )
		for _, node in ipairs(nodes) do
			g_nodes[#g_nodes + 1] = node
		end

		local lake = isLake( cellX, cellY )

		for _, node in ipairs( g_nodes ) do
			local rx, ry = rotateLocal( cellX, cellY, node.pos.x, node.pos.y )

			local x = cellX * CELL_SIZE + rx
			local y = cellY * CELL_SIZE + ry

			local height = node.pos.z + getCliffHeightAt( x, y )
			if not lake or not valueExists( node.tags, "WATER" ) then
				height = height + getElevationHeightAt( x, y )
			end
			node.pos = sm.vec3.new( rx, ry, height )
			node.rot = getRotationStepQuat( cellX, cellY ) * node.rot

			hasReflectionProbe = hasReflectionProbe or valueExists( node.tags, "REFLECTION" )
		end

		if not hasReflectionProbe then
			local x = ( cellX + 0.5 ) * CELL_SIZE
			local y = ( cellY + 0.5 ) * CELL_SIZE
			local node = {}
			node.pos = sm.vec3.new( 32, 32, getElevationHeightAt( x, y ) + getCliffHeightAt( x, y ) + 4 )
			node.rot = sm.quat.new( 0.707107, 0, 0, 0.707107 )
			node.scale = sm.vec3.new( 64, 64, 64 )
			node.tags = { "REFLECTION" }
			g_nodes[#g_nodes + 1] = node
		end

		return g_nodes
	end
	return {}
end

----------------------------------------------------------------------------------------------------

function getCreationsForCell( cellX, cellY )
	if SCALE_HACK == true then
		return {}
	end

	local id, tileCellOffsetX, tileCellOffsetY = getCellTileIdAndOffset( cellX, cellY )
	if id ~= 0 then
		local cellCreations = sm.terrainTile.getCreationsForCell( id, tileCellOffsetX, tileCellOffsetY )
		for _, cellCreation in ipairs(cellCreations) do

			randomizeCreation( cellCreation, blueprintTable )

			g_creations[#g_creations + 1] = cellCreation
		end

		for i,creation in ipairs(g_creations) do
			local rx, ry = rotateLocal( cellX, cellY, creation.pos.x, creation.pos.y )

			local x = cellX * CELL_SIZE + rx
			local y = cellY * CELL_SIZE + ry

			local height = creation.pos.z + getCliffHeightAt( x, y )
			if isFlat( cellX, cellY ) then
				-- Get elevation at center
				height = height + getElevationHeightAt( ( cellX + 0.5 ) * CELL_SIZE, ( cellY + 0.5 ) * CELL_SIZE )
			else
				height = height + getElevationHeightAt( x, y )
			end
			creation.pos = sm.vec3.new( rx, ry, height )
			creation.rot = getRotationStepQuat( cellX, cellY ) * creation.rot
		end

		return g_creations
	end

	return {}
end

----------------------------------------------------------------------------------------------------

function getDecalsForCell( cellX, cellY )
	if SCALE_HACK == true then
		return {}
	end

	local id, tileCellOffsetX, tileCellOffsetY = getCellTileIdAndOffset( cellX, cellY )
	if id ~= 0 then
		local cellDecals = sm.terrainTile.getDecalsForCell( id, tileCellOffsetX, tileCellOffsetY )
		for _, decal in ipairs(cellDecals) do
			local rx, ry = rotateLocal( cellX, cellY, decal.pos.x, decal.pos.y )

			local x = cellX * CELL_SIZE + rx
			local y = cellY * CELL_SIZE + ry

			local height = decal.pos.z + getElevationHeightAt( x, y ) + getCliffHeightAt( x, y )
			decal.pos = sm.vec3.new( rx, ry, height )
			decal.rot = getRotationStepQuat( cellX, cellY ) * decal.rot
		end

		return cellDecals
	end

	return {}
end

----------------------------------------------------------------------------------------------------

local TypeTags = { "MEADOW", "FOREST", "DESERT", "FIELD", "BURNTFOREST", "AUTUMNFOREST", "MOUNTAIN", "LAKE" }

local PoiTags = {
	[POI_MECHANICSTATION_MEDIUM] = "MECHANICSTATION",
	[POI_PACKINGSTATIONVEG_MEDIUM] = "PACKINGSTATION",
	[POI_PACKINGSTATIONFRUIT_MEDIUM] = "PACKINGSTATION",
	[POI_HIDEOUT_XL] = "HIDEOUT",

	[POI_WAREHOUSE2_LARGE] = "WAREHOUSE2",
	[POI_WAREHOUSE3_LARGE] = "WAREHOUSE3",
	[POI_WAREHOUSE4_LARGE] = "WAREHOUSE4",
	[POI_BURNTFOREST_FARMBOTSCRAPYARD_LARGE] = "SCRAPYARD",

	[POI_ROAD] = "ROAD",

	[POI_CAMP] = "CAMP",
	[POI_RUIN] = "RUIN",
	[POI_RANDOM] = "RANDOM",

	[POI_FOREST_CAMP] = "CAMP",
	[POI_FOREST_RUIN] = "RUIN",
	[POI_FOREST_RANDOM] = "RANDOM",

	[POI_DESERT_RANDOM] = "RANDOM",

	[POI_FARMINGPATCH] = "FARMINGPATCH",
	[POI_FIELD_RUIN] = "RUIN",
	[POI_FIELD_RANDOM] = "RANDOM",

	[POI_BURNTFOREST_CAMP] = "CAMP",
	[POI_BURNTFOREST_RUIN] = "RUIN",
	[POI_BURNTFOREST_RANDOM] = "RANDOM",

	[POI_AUTUMNFOREST_CAMP] = "CAMP",
	[POI_AUTUMNFOREST_RUIN] = "RUIN",
	[POI_AUTUMNFOREST_RANDOM] = "RANDOM",

	[POI_RUIN_MEDIUM] = "RUIN_MEDIUM",
	[POI_FOREST_RUIN_MEDIUM] = "RUIN_MEDIUM",

	[POI_CHEMLAKE_MEDIUM] = "CHEMLAKE",
	[POI_BUILDAREA_MEDIUM] = "BUILDAREA",

	[POI_LAKE_UNDERWATER_MEDIUM] = "UNDERWATER_MEDIUM",
}

function getTagsForCell( cellX, cellY )
	if SCALE_HACK == true then
		return {}
	end

	local tags = {}

	local type = getCellType( cellX, cellY )
	if type >= 1 and type <= 8 then
		tags[#tags + 1] = TypeTags[type]
	end

	local id = getCellTileIdAndOffset( cellX, cellY )
	if id ~= 0 then
		local poiType = getPoiType( id )
		if poiType then
			local tag = PoiTags[poiType]
			if tag then
				tags[#tags + 1] = tag
			end
			tags[#tags + 1] = "POI"
		end
	end

	if cellX >= -46 and cellX < -46 + 20 and cellY >= -46 and cellY < -46 + 16 then
		tags[#tags + 1] = "STARTAREA"
	end

	return tags
end

----------------------------------------------------------------------------------------------------
-- Tile Reader Path Getter
----------------------------------------------------------------------------------------------------

function getTilePath( id )

	local tilePath = getTile( id )
	if tilePath then
		return tilePath
	end

	-- Not found!
	return "../Survival/Terrain/Tiles/ERROR.TILE"
end
