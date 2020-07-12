
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )

-- A chance of 100 makes the item 100 times more likely than with a chance of 1

local random_loot = {
	{ uuid = obj_plantables_carrot, 				chance = 25,	quantity = 1 },
	{ uuid = obj_plantables_redbeet, 				chance = 35,	quantity = 1 },
	{ uuid = obj_plantables_tomato, 				chance = 25,	quantity = 1 },
	{ uuid = obj_plantables_banana, 				chance = 25,	quantity = 1 },
	{ uuid = obj_plantables_blueberry, 				chance = 25,	quantity = 1 },
	{ uuid = obj_plantables_orange, 				chance = 20,	quantity = 1 },
	{ uuid = obj_plantables_potato, 				chance = 50,	quantity = randomStackAmountAvg10 },

	{ uuid = obj_consumable_sunshake, 				chance = 3 },

	{ uuid = obj_consumable_gas,					chance = 30,	quantity = randomStackAmountAvg10 },
	{ uuid = obj_consumable_battery,				chance = 15,	quantity = randomStackAmountAvg3 },
	{ uuid = obj_consumable_chemical,				chance = 25,	quantity = randomStackAmount5 },
	{ uuid = obj_consumable_fertilizer,				chance = 15,	quantity = randomStackAmount5 },
	{ uuid = obj_consumable_component,				chance = 35,	quantity = randomStackAmountAvg3 },
	{ uuid = obj_consumable_inkammo,				chance = 25,	quantity = randomStackAmountAvg10 },
	{ uuid = obj_consumable_glowstick,				chance = 8,		quantity = randomStackAmountAvg3 },
	{ uuid = obj_consumable_soilbag,				chance = 25,	quantity = randomStackAmountAvg3 },
	{ uuid = obj_consumable_glue,                   chance = 25, 	quantity = randomStackAmount5 },

	{ uuid = obj_resource_circuitboard,				chance = 15,	quantity = randomStackAmountAvg2},

	{ uuid = obj_seed_carrot,						chance = 5,		quantity = randomStackAmountAvg3 },
	{ uuid = obj_seed_redbeet,						chance = 5,		quantity = randomStackAmountAvg3 },
	{ uuid = obj_seed_tomato,						chance = 5,		quantity = randomStackAmountAvg3 },
	{ uuid = obj_seed_potato,						chance = 5,		quantity = randomStackAmountAvg3 },

	{ uuid = blk_glass,								chance = 5,		quantity = randomStackAmount20 },
	{ uuid = jnt_bearing, 							chance = 5,		quantity = randomStackAmountAvg2 },
	{ uuid = blk_carpet,							chance = 10,	quantity = randomStackAmountAvg10 },

}

local random_epicloot = {
	{ uuid = obj_plantables_carrot, 				chance = 20,	quantity = randomStackAmountAvg2 },
	{ uuid = obj_plantables_redbeet, 				chance = 20,	quantity = randomStackAmountAvg2 },
	{ uuid = obj_plantables_tomato, 				chance = 20,	quantity = randomStackAmountAvg2 },
	{ uuid = obj_plantables_banana, 				chance = 20,	quantity = randomStackAmountAvg2 },
	{ uuid = obj_plantables_blueberry, 				chance = 20,	quantity = randomStackAmountAvg2 },
	{ uuid = obj_plantables_orange, 				chance = 20,	quantity = randomStackAmountAvg2 },
	{ uuid = obj_plantables_potato, 				chance = 30,	quantity = randomStackAmountAvg10 },

	{ uuid = obj_consumable_sunshake, 				chance = 25 },
	{ uuid = obj_consumable_longsandwich, 			chance = 30 },

	{ uuid = obj_consumable_gas,					chance = 30,	quantity = randomStackAmountAvg5 },
	{ uuid = obj_consumable_battery,				chance = 25,	quantity = randomStackAmount5 },
	{ uuid = obj_consumable_water,					chance = 10,	quantity = randomStackAmount10 },
	{ uuid = obj_consumable_chemical,				chance = 20,	quantity = randomStackAmount10 },
	{ uuid = obj_consumable_component,				chance = 70,	quantity = 1 },
	
	{ uuid = obj_resource_circuitboard,				chance = 50, 	quantity = randomStackAmountAvg3 },

	{ uuid = obj_seed_banana,						chance = 15,	quantity = randomStackAmountAvg2 },
	{ uuid = obj_seed_orange,						chance = 15,	quantity = randomStackAmountAvg2 },
	{ uuid = obj_seed_blueberry,					chance = 15,	quantity = randomStackAmountAvg2 },

	{ uuid = jnt_bearing, 							chance = 10,	quantity = 1 },
	
	{ uuid = obj_interactive_driverseat_01,			chance = 1,		quantity = 1 },
	{ uuid = obj_interactive_seat_01,				chance = 1,		quantity = 1 },
	{ uuid = obj_interactive_driversaddle_01,		chance = 1,		quantity = 1 },
	{ uuid = obj_interactive_saddle_01,				chance = 1,		quantity = 1 },
	{ uuid = obj_interactive_switch,				chance = 1,		quantity = 1 },
	{ uuid = obj_interactive_radio,					chance = 1,		quantity = 1 },
	{ uuid = obj_interactive_horn,					chance = 1,		quantity = 1 },
	{ uuid = obj_interactive_gasengine_01, 			chance = 1,		quantity = 1 },
	{ uuid = obj_interactive_electricengine_01, 	chance = 1,		quantity = 1 },
	{ uuid = obj_interactive_controller_01, 		chance = 1,		quantity = 1 },
}

local random_warehouseloot = {
	{ uuid = obj_plantables_carrot, 				chance = 5,		quantity = randomStackAmountAvg3 },
	{ uuid = obj_plantables_redbeet, 				chance = 5,		quantity = randomStackAmountAvg3 },
	{ uuid = obj_plantables_tomato, 				chance = 5,		quantity = randomStackAmountAvg3 },
	{ uuid = obj_plantables_banana, 				chance = 5,		quantity = randomStackAmountAvg3 },
	{ uuid = obj_plantables_blueberry, 				chance = 5,		quantity = randomStackAmountAvg3 },
	{ uuid = obj_plantables_orange, 				chance = 5,		quantity = randomStackAmountAvg3 },
	{ uuid = obj_plantables_pineapple, 				chance = 5,		quantity = randomStackAmountAvg3 },
	{ uuid = obj_plantables_broccoli, 				chance = 5,		quantity = randomStackAmountAvg3 },
	{ uuid = obj_consumable_sunshake, 				chance = 15 },
	{ uuid = obj_plantables_potato, 				chance = 20,	quantity = randomStackAmountAvg10 },
	{ uuid = obj_resource_circuitboard,				chance = 50 },
	{ uuid = obj_consumable_gas,					chance = 70,	quantity = randomStackAmountAvg5 },
	{ uuid = obj_consumable_battery,				chance = 40,	quantity = randomStackAmountAvg5 },
	{ uuid = obj_consumable_fertilizer,				chance = 25,	quantity = randomStackAmountAvg10 },
	{ uuid = obj_consumable_soilbag,				chance = 40,	quantity = randomStackAmountAvg3 },
	{ uuid = obj_consumable_component,				chance = 70,	quantity = 3 },
}

local random_loot_startarea = {
	{ uuid = obj_scrap_smallwheel,					chance = 10 },
	{ uuid = obj_consumable_gas,					chance = 25,	quantity = randomStackAmountAvg5 },
	{ uuid = obj_consumable_chemical,				chance = 15,	quantity = randomStackAmount3 },
	{ uuid = obj_consumable_soilbag,				chance = 25,	quantity = 1 },
	{ uuid = obj_plantables_carrot,					chance = 25,	quantity = 1 },
	{ uuid = obj_plantables_redbeet,				chance = 25,	quantity = 1 },
	{ uuid = obj_plantables_tomato,					chance = 25,	quantity = 1 },
	{ uuid = obj_seed_carrot,						chance = 20,	quantity = randomStackAmountAvg2 },
	{ uuid = obj_seed_redbeet,						chance = 20,	quantity = randomStackAmountAvg2 },
	{ uuid = obj_seed_tomato,						chance = 20,	quantity = randomStackAmountAvg2 },
	{ uuid = jnt_bearing,							chance = 10 },
}

-- Loot crates
local loot_crate_epic = {
	slots = function() return randomStackAmount( 2, 3, 5 ) end, --3
	selectTwo = {
		{ uuid = obj_outfitpackage_common, 			chance = 30 },
		{ uuid = obj_outfitpackage_rare, 			chance = 20 },
		{ uuid = obj_outfitpackage_epic, 			chance = 5 },

		{ uuid = obj_consumable_pizzaburger,		chance = 10,	quantity = randomStackAmountAvg2 },
		{ uuid = obj_consumable_component, 			chance = 20,	quantity = randomStackAmountAvg5 },

		{ uuid = jnt_suspensionoffroad_02, 			chance = 15 },
		{ uuid = jnt_suspensionsport_02, 			chance = 15 },
		{ uuid = jnt_interactive_piston_01, 		chance = 15 },
		{ uuid = obj_interactive_logicgate, 		chance = 8 },
		{ uuid = obj_interactive_timer, 			chance = 8 },
		{ uuid = obj_interactive_gasengine_02, 		chance = 5 },
		{ uuid = obj_interactive_electricengine_02, chance = 5 },
		{ uuid = obj_interactive_controller_02, 	chance = 5 },
		{ uuid = obj_powertools_drill,				chance = 1 },
		{ uuid = obj_powertools_sawblade,			chance = 1 },
	},
	randomLoot = random_epicloot
}

local loot_crate_epic_warehouse = {
	slots = function() return 3 end,
	selectOne = {
		{ uuid = jnt_suspensionoffroad_04, 			chance = 3 },
		{ uuid = jnt_suspensionsport_04, 			chance = 3 },
		{ uuid = jnt_interactive_piston_04, 		chance = 3 },
		{ uuid = obj_interactive_gasengine_04, 		chance = 3 },
		{ uuid = obj_interactive_electricengine_04, chance = 3 },
		{ uuid = obj_interactive_controller_04, 	chance = 3 },
		{ uuid = obj_interactive_driverseat_04, 	chance = 3 },
		{ uuid = obj_interactive_seat_04, 			chance = 3 },
		{ uuid = obj_interactive_driversaddle_04, 	chance = 3 },
		{ uuid = obj_interactive_saddle_04, 		chance = 3 },
		{ uuid = obj_interactive_thruster_03,		chance = 1 },
	},
	randomLoot = random_warehouseloot
}

local loot_crate_standard = {
	slots = function() return randomStackAmount( 1.5, 2, 3 ) end,
	selectOne = {
		{ uuid = obj_outfitpackage_common, 			chance = 3 },

		{ uuid = obj_consumable_component,			chance = 35 },
		{ uuid = nil,								chance = 53 }, -- No loot from selectOne
	},
	randomLoot = random_loot
}

local loot_crate_startarea = {
	slots = function() return randomStackAmount( 1, 2, 3 ) end,
	selectOne = {
		{ uuid = obj_consumable_sunshake,			chance = 1 },
		{ uuid = obj_consumable_component,			chance = 1 },
		{ uuid = obj_resource_circuitboard,			chance = 1 },
		{ uuid = nil,								chance = 2 }, -- No loot from selectOne
	},
	randomLoot = random_loot_startarea
}

local loot_crate_standard_warehouse = {
	slots = function() return randomStackAmount( 1, 2, 3 ) end,
	selectOne = {
		{ uuid = obj_plantables_broccoli, 			chance = 1,		quantity = 1 },
		{ uuid = obj_plantables_pineapple, 			chance = 1,		quantity = 1 },
		{ uuid = nil,								chance = 5 }, -- No loot from selectOne
	},	
	randomLoot = random_warehouseloot
}

local loot_ruinchest = {
	slots = function() return randomStackAmount( 1, 3, 6 ) end,
	selectOne = nil,
	randomLoot = random_loot
}

local loot_ruinchest_startarea = {
	slots = function() return randomStackAmount( 1, 1.5, 4 ) end,
	selectOne = nil,
	randomLoot = random_loot_startarea
}

local loot_woc = {
	slots = function() return 1 end,
	selectOne = {
	{ uuid = obj_resource_steak,				chance = 2, 	quantity = 1 },
	{ uuid = obj_resource_steak,				chance = 4, 	quantity = 2 },
	{ uuid = obj_resource_steak,				chance = 3, 	quantity = 3 },
	{ uuid = obj_resource_steak,				chance = 1, 	quantity = 4 },
	}
}

local loot_woc_milk = {
	slots = function() return 1 end,
	selectOne = {
	{ uuid = obj_consumable_milk,				chance = 1, 	quantity = 1 },
	{ uuid = obj_consumable_milk,				chance = 3, 	quantity = 2 },
	{ uuid = obj_consumable_milk,				chance = 2, 	quantity = 3 },
	}
}

local loot_glow_goop = {
	slots = function() return 1 end,
	selectOne = {
	{ uuid = obj_resource_glowpoop,				chance = 1, 	quantity = 1 },
	{ uuid = obj_resource_glowpoop,				chance = 3, 	quantity = 2 },
	{ uuid = obj_resource_glowpoop,				chance = 2, 	quantity = 3 },
	}
}

local loot_totebot_green = {
	slots = function() return randomStackAmount ( 0.5, 1, 2 ) end,
	randomLoot = {
		{ uuid = obj_resource_circuitboard,		chance = 40 },
		{ uuid = obj_consumable_fertilizer,		chance = 10, 	quantity = randomStackAmountAvg5 },
		{ uuid = obj_consumable_component,		chance = 10 },
		{ uuid = obj_consumable_component,		chance = 5, 	quantity = 2 },
	}
}

local loot_haybot = {
	slots = function() return randomStackAmount( 1, 1, 1.5 ) end,
	randomLoot = {
		{ uuid = obj_consumable_component,		chance = 15 },
		{ uuid = obj_consumable_component,		chance = 7, 	quantity = 2 },
		{ uuid = obj_resource_circuitboard,		chance = 20, 	quantity = randomStackAmountAvg2 },
		{ uuid = obj_consumable_battery,		chance = 8 },
		{ uuid = nil,							chance = 5 },
	}
}

local loot_tapebot = {
	slots = function() return randomStackAmount( 1, 1.5, 2 ) end,
	randomLoot = {
		{ uuid = obj_consumable_glue,			chance = 18, 	quantity = randomStackAmountAvg2 },
		{ uuid = obj_resource_circuitboard,		chance = 12, 	quantity = randomStackAmountAvg2 },
		{ uuid = obj_consumable_component,		chance = 30, 	quantity = randomStackAmountAvg3 },
		{ uuid = obj_plantables_potato,			chance = 24, 	quantity = randomStackAmount10 },
		{ uuid = obj_consumable_battery,		chance = 8, 	quantity = randomStackAmountAvg2 },
		{ uuid = obj_outfitpackage_common,		chance = 6 },
		{ uuid = blk_metal1,					chance = 21, 	quantity = 25 },
	}
}

local loot_farmbot = {
	slots = function() return randomStackAmount( 3, 4 ) end,
	selectOne = {
		{ uuid = obj_survivalobject_keycard,	chance = 20 },
	},
	randomLoot = {
		{ uuid = blk_metal2,					chance = 24,	quantity = 50 },
		{ uuid = obj_consumable_component,		chance = 44,	quantity = randomStackAmountAvg5 },
		{ uuid = obj_resource_circuitboard,		chance = 44,	quantity = randomStackAmountAvg5 },
		{ uuid = obj_consumable_fertilizer,		chance = 8,		quantity = randomStackAmountAvg10 },
		{ uuid = obj_outfitpackage_rare,		chance = 8 },
		{ uuid = obj_outfitpackage_epic,		chance = 1 },
		{ uuid = obj_powertools_drill,			chance = 1 },
	}
}

local lootTables = {
	["loot_crate_startarea"] = loot_crate_startarea,
	["loot_ruinchest_startarea"] = loot_ruinchest_startarea,
	["loot_crate_epic"] = loot_crate_epic,
	["loot_crate_epic_warehouse"] = loot_crate_epic_warehouse,
	["loot_crate_standard"] = loot_crate_standard,
	["loot_crate_standard_warehouse"] = loot_crate_standard_warehouse,
	["loot_ruinchest"] = loot_ruinchest,
	["loot_woc"] = loot_woc,
	["loot_woc_milk"] = loot_woc_milk,
	["loot_glow_goop"] = loot_glow_goop,
	["loot_totebot_green"] = loot_totebot_green,
	["loot_haybot"] = loot_haybot,
	["loot_tapebot"] = loot_tapebot,
	["loot_farmbot"] = loot_farmbot,
}

function SelectOne( list )
	local sum = 0
	for _,v in ipairs( list ) do
		sum = sum + v.chance --NOTE: Could precalculate sum
	end

	local rand = math.random() * sum

	sum = 0
	for _,v in ipairs( list ) do
		sum = sum + v.chance

		if rand <= sum then
			local quantity = 1
			if v.quantity then
				if type( v.quantity ) == "function" then
					quantity = v.quantity()
				else
					quantity = v.quantity
				end
			end
			return {
				uuid = v.uuid,
				quantity = quantity
			}
		end
	end
	return nil
end

function SelectTwo( list )
	local sum = 0
	for _,v in ipairs( list ) do
		sum = sum + v.chance --NOTE: Could precalculate sum
	end

	local rand = math.random() * sum

	sum = 0
	for _,v in ipairs( list ) do
		sum = sum + v.chance

		if rand <= sum then
			local quantity = 1
			if v.quantity then
				if type( v.quantity ) == "function" then
					quantity = v.quantity()
				else
					quantity = v.quantity
				end
			end
			return {
				uuid = v.uuid,
				quantity = quantity
			}
		end
	end
	return nil
	
end

function SelectThree( list )
	local sum = 0
	for _,v in ipairs( list ) do
		sum = sum + v.chance --NOTE: Could precalculate sum
	end

	local rand = math.random() * sum

	sum = 0
	for _,v in ipairs( list ) do
		sum = sum + v.chance

		if rand <= sum then
			local quantity = 1
			if v.quantity then
				if type( v.quantity ) == "function" then
					quantity = v.quantity()
				else
					quantity = v.quantity
				end
			end
			return {
				uuid = v.uuid,
				quantity = quantity
			}
		end
	end
	return nil
	
end

function SelectLoot( lootTableName, slotLimit )
	local lootList = {}

	local lootTable = lootTables[lootTableName]

	local slots = lootTable.slots and lootTable.slots() or 1
	if slotLimit then
		slots = math.min( slots, slotLimit )
	end

	if slots > 0 and lootTable.selectOne then
		local loot = SelectOne( lootTable.selectOne )
		if loot and loot.uuid then
			lootList[#lootList + 1] = loot
		end
	end
	
	while #lootList < 2 and lootTable.selectTwo do
		local loot = SelectTwo( lootTable.selectTwo )
		assert( loot and loot.uuid )
			lootList[#lootList + 1] = loot
	end
	
	while #lootList < 3 and lootTable.selectThree do
		local loot = SelectThree( lootTable.selectThree )
		assert( loot and loot.uuid )
			lootList[#lootList + 1] = loot
	end
	
	while #lootList < slots and lootTable.randomLoot do
		local loot = SelectOne( lootTable.randomLoot )
		assert( loot and loot.uuid )
		lootList[#lootList + 1] = loot
	end

	return lootList
end

function SpawnLoot( origin, lootList, worldPosition )

	if worldPosition == nil then
		if type( origin ) == "Shape" then
			worldPosition = origin.worldPosition
		elseif type( origin ) == "Player" or type( origin ) == "Unit" then
			local character = origin:getCharacter()
			if character then
				worldPosition = character.worldPosition
			end
		elseif type( origin ) == "Harvestable" then
			worldPosition = origin.worldPosition
		end
	end

	if worldPosition then
		for i = 1, #lootList do
			local dir
			local up
			if type( origin ) == "Shape" then
				dir = sm.vec3.new( 1.0, 0.0, 0.0 )
				up = sm.vec3.new( 0, 1, 0 )
			else
				dir = sm.vec3.new( 0.0, 1.0, 0.0 )
				up = sm.vec3.new( 0, 0, 1 )
			end

			local firstCircle = 6
			local secondCircle = 13
			local thirdCircle = 26

			if i < 6 then
				local divisions = ( firstCircle - ( firstCircle - math.min( #lootList, firstCircle - 1 ) ) )
				dir = dir:rotate( i * 2 * math.pi / divisions, up )
				local right = dir:cross( up )
				dir = dir:rotate( math.pi / 2, right  )
				dir = dir:rotate( math.pi / 18, right  )
			elseif i < 13 then
				local divisions = ( secondCircle - ( secondCircle - math.min( #lootList - firstCircle + 1, secondCircle - firstCircle ) ) )
				dir = dir:rotate( i * 2 * math.pi / divisions, up )
				local right = dir:cross( up )
				dir = dir:rotate( math.pi / 2, right  )
				dir = dir:rotate( math.pi / 9, right  )
			elseif i < 26 then
				local dvisions = ( thirdCircle - ( thirdCircle - math.min( #lootList - secondCircle + 1, thirdCircle - secondCircle ) ) )
				dir = dir:rotate( i * 2 * math.pi / dvisions, up )
				local right = dir:cross( up )
				dir = dir:rotate( math.pi / 2, right  )
				dir = dir:rotate( 2 * math.pi / 9, right  )
			else
				-- Out of predetermined room, place randomly
				dir = dir:rotate( math.random() * 2 * math.pi, up )
				local right = dir:cross( up )
				dir = dir:rotate( math.pi / 2, right  )
				dir = dir:rotate( ( math.pi / 18 ) + math.random() * ( ( 2 * math.pi / 9 ) - ( math.pi / 18 ) ), right  )
			end

			local loot = lootList[i]
			local params = { lootUid = loot.uuid, lootQuantity = loot.quantity or 1 }
			local vel = dir * (4+math.random()*2)

			if type( origin ) == "Shape" then
				sm.projectile.shapeCustomProjectileAttack( params, "loot", 0, sm.vec3.new( 0, 0, 0 ), vel, origin, 0 )
			elseif type( origin ) == "Player" or type( origin ) == "Unit" then
				sm.projectile.customProjectileAttack( params, "loot", 0, worldPosition, vel, origin, worldPosition, worldPosition, 0 )
			elseif type( origin ) == "Harvestable" then
				sm.projectile.harvestableCustomProjectileAttack( params, "loot", 0, worldPosition, vel, origin, 0 )
			end
		end
	end
end
