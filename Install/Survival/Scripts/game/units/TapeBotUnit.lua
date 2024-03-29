dofile "$SURVIVAL_DATA/Scripts/game/units/unit_util.lua"
dofile "$SURVIVAL_DATA/Scripts/game/util/Ticker.lua"
dofile "$SURVIVAL_DATA/Scripts/game/util/Timer.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua"
dofile "$SURVIVAL_DATA/Scripts/game/units/states/PathingState.lua"
dofile "$SURVIVAL_DATA/Scripts/util.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_constants.lua"

TapebotUnit = class( nil )

local AllyRange = 20.0
local SuppressionFireTickTime = 4 * 40
local RandomRaidFireTickIntervalMin = 0 * 40
local RandomRaidFireTickIntervalMax = 2 * 40

function TapebotUnit.server_onCreate( self )
	
	self.target = nil
	self.previousTarget = nil
	self.lastTargetPosition = nil
	self.ambushPosition = nil
	
	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = {}
	end
	if self.saved.stats == nil then
		self.saved.stats = { hp = 10, maxhp = 10 }
	end

	if self.params then
		if self.params.tetherPoint then
			self.homePosition = self.params.tetherPoint + sm.vec3.new( 0, 0, self.unit.character:getHeight() * 0.5 )
			if self.params.ambush == true then
				self.ambushPosition = self.params.tetherPoint + sm.vec3.new( 0, 0, self.unit.character:getHeight() * 0.5 )
			end
			if self.params.raider == true then
				self.saved.raidPosition = self.params.tetherPoint + sm.vec3.new( 0, 0, self.unit.character:getHeight() * 0.5 )
			end
		end
		if self.params.raider then
			self.saved.raider = true
		end
		if self.params.groupId then
			g_unitManager:sv_addUnitToGroup( self.unit, self.params.groupId )
			self.saved.groupId = self.params.groupId
		end
		if self.params.isPatrolling ~= nil then
			self.saved.patrolling = self.params.isPatrolling
		end
		if self.params.temporary then
			self.saved.temporary = self.params.temporary
			self.saved.deathTickTimestamp = sm.game.getCurrentTick() + getTicksUntilDayCycleFraction( DAYCYCLE_DAWN )
		end
		if self.params.deathTick then
			self.saved.deathTickTimestamp = self.params.deathTick
		end
	end
	if self.saved.patrolling == nil then
		self.saved.patrolling = true
	end
	if not self.homePosition then
		self.homePosition = self.unit.character.worldPosition
	end
	
	self.storage:save( self.saved )
	
	if self.data then
		self.explosiveProjectile = self.data.explosiveProjectile
	end
	self.projectileBreachLevel = self.explosiveProjectile and 7 or 4

	self.unit.eyeHeight = self.unit.character:getHeight() * 0.75
	self.unit.visionFrustum = {
		{ 16.0, math.rad( 80.0 ), math.rad( 50.0 ) },
		{ 26.0, math.rad( 40.0 ), math.rad( 35.0 ) },
		{ 40.0, math.rad( 20.0 ), math.rad( 20.0 ) }
	}
	self.unit:setWhiskerData( 4, math.rad( 70.0 ), 1.0, 4.75 )
	self.noiseScale = 1.0
	self.impactCooldownTicks = 0
	self.specialHitsToDie = 2
	
	self.isInCombat = false
	self.combatTimer = Timer()
	self.combatTimer:start( 40 * 12 )
	
	-- Idle	
	self.idleState = self.unit:createState( "idle" )
	self.idleState.debugName = "idleState"
	
	-- Roam
	self.roamStartTimeMin = 40 * 4 -- 4 seconds
	self.roamStartTimeMax = 40 * 8 -- 8 seconds
	self.roamTimer = Timer()
	self.roamTimer:start( math.random( self.roamStartTimeMin, self.roamStartTimeMax ) )
	self.roamState = PathingState()
	self.roamState:sv_onCreate( self.unit )
	self.roamState:sv_setMovementType( "walk" )
	self.roamState:sv_setTolerance( 1.5 )
	self.roamState.debugName = "roam"
	
	--LookPositioning
	self.positioning = self.unit:createState( "positioning" )
	self.positioning.tolerance = 0.5
	self.positioning.debugName = "positioning"
	
	-- Pathing
	self.pathingState = PathingState()
	self.pathingState:sv_onCreate( self.unit )
	self.pathingState:sv_setMovementType( "sprint" )
	
	-- RangedAttack
	self.rangedAttack = self.unit:createState( "rangedAttack" )
	self.rangedAttack.spreadAngle = 3.0
	if self.explosiveProjectile then
		self.rangedAttack.projectile = "explosivetape"
		self.rangedAttack.cooldown = 3.0
		self.rangedAttack.aimTime = 0.25
	else
		self.rangedAttack.projectile = "tape"
		self.rangedAttack.cooldown = 0.95
		self.rangedAttack.aimTime = 0.1
	end
	self.rangedAttack.event = "shoot"
	self.rangedAttack.damage = 45
	self.rangedAttack.fakeOffset = sm.vec3.new( 0.5, 0.5, -0.25 )
	self.rangedAttack.velocity = 40
	
	self.attackRange = 40.0
	self.fireLaneWidth = 0.3
	self.predictedVelocity = sm.vec3.new( 0, 0, 0 )
	self.canShoot = false
	
	self.suppressionFireTimer = Timer()
	self.suppressionFireTimer:start( SuppressionFireTickTime )
	self.suppressionFireTimer.count = SuppressionFireTickTime

	self.randomRaidFireTimer = Timer()
	self.randomRaidFireTimer:start( math.random( RandomRaidFireTickIntervalMin, RandomRaidFireTickIntervalMax ) )

	-- Flee
	self.dayFlee = self.unit:createState( "flee" )
	self.dayFlee.movementAngleThreshold = math.rad( 180 )
	self.dayFlee.maxFleeTime = 0.0
	self.dayFlee.maxDeviation = 45 * math.pi / 180
	self.dayFlee.debugName = "dayFlee"

	-- Tumble
	initTumble( self )
	
	-- Crushing
	initCrushing( self, DEFAULT_CRUSH_TICK_TIME )
	
	self.currentState = self.idleState
	self.currentState:start()
	
	print( "-- TapebotUnit created --" )
end

function TapebotUnit.server_onRefresh( self )
	print( "-- TapebotUnit refreshed --" )
end

function TapebotUnit.server_onDestroy( self )
	print( "-- TapebotUnit terminated --" )
end

function TapebotUnit.server_onFixedUpdate( self, dt )
	
	if sm.exists( self.unit ) and not self.destroyed then
		if self.saved.deathTickTimestamp and sm.game.getCurrentTick() >= self.saved.deathTickTimestamp then
			self.unit:destroy()
			self.destroyed = true
			return
		end
	end

	if not sm.exists( self.unit ) then
		return
	end
	
	if updateCrushing( self ) then
		print("'TapebotUnit' was crushed!")
		self:sv_onDeath( sm.vec3.new( 0, 0, 0 ) )
	end
	
	updateTumble( self )
	updateAirTumble( self, self.idleState )
	
	if self.currentState then
		self.canShootTarget = self:updateAim( dt )
		self.currentState:onFixedUpdate( dt )
	
		local raidWalk = self.saved.raider and self.target == nil and self.currentState == self.pathingState
		self.unit:setMovementDirection( self.currentState:getMovementDirection() )
		self.unit:setMovementType( raidWalk and "walk" or self.currentState:getMovementType() )
		self.unit:setFacingDirection( self.currentState:getFacingDirection() )
		
		if self.currentState == self.idleState then
			self.roamTimer:tick()
		end
		
		if self.isInCombat then
			self.combatTimer:tick()
		end

		if not self.suppressionFireTimer:done() then
			self.suppressionFireTimer:tick()
		end

		if self.saved.raider and self.currentState ~= self.rangedAttack and self.target == nil and self.suppressionFireTimer:done() then
			self.randomRaidFireTimer:tick()
			if self.randomRaidFireTimer:done() then
				local contacts = sm.physics.getSphereContacts( self.unit.character.worldPosition, self.attackRange )
				if #contacts.bodies > 0 then
					local validShapes = {}
					for _, body in ipairs( contacts.bodies ) do
						if body.destructable then
							for _, shape in ipairs( body:getShapes() ) do
								local shapeQualityLevel = sm.item.getQualityLevel( shape.shapeUuid )
								if shape.destructable and self.projectileBreachLevel >= shapeQualityLevel and shapeQualityLevel > 0 then
									validShapes[#validShapes+1] = shape
								end
							end
						end
					end

					if #validShapes > 0 then
						local targetShape = validShapes[math.random( 1, #validShapes )]
						local targetPosition = targetShape.worldPosition
						if sm.item.isBlock( targetShape.shapeUuid ) then
							local targetLocalPosition = targetShape:getClosestBlockLocalPosition( self.unit.character.worldPosition )
							targetPosition = targetShape.body:transformPoint( ( targetLocalPosition + sm.vec3.new( 0.5, 0.5, 0.5 ) ) * 0.25 )
						end
						self.rangedAttack.aimPoint = targetPosition
						self.suppressionFireTimer:reset()
					end
				end
				self.randomRaidFireTimer:start( math.random( RandomRaidFireTickIntervalMin, RandomRaidFireTickIntervalMax ) )
			end
		end
		
		self.impactCooldownTicks = math.max( self.impactCooldownTicks - 1, 0 )
	end
	
	-- Update target for character
	if self.target ~= self.previousTarget then
		self:sv_updateCharacterTarget()
		self.previousTarget = self.target
	end
end

function TapebotUnit.updateAim( self, dt )
	if self.target and sm.exists( self.target ) and type( self.target ) == "Character" and not self.target:isDowned() then
		local success, aimPoint = sm.ai.getAimPosition( self.unit.character, self.target, self.attackRange, self.fireLaneWidth )
		if success then
			-- Predict target movement from its velocity
			if self.predictedVelocity:length() > 0 and self.target:getVelocity():length() > self.predictedVelocity:length() then
				self.predictedVelocity = magicPositionInterpolation( self.predictedVelocity, self.target:getVelocity(), dt, 1.0 / 10.0 )
			else
				self.predictedVelocity = self.target:getVelocity()
			end
			local distanceToTarget = ( aimPoint - self.unit.character.worldPosition ):length()
			local predictionScale = distanceToTarget / math.max( self.rangedAttack.velocity, 1.0 )
			self.rangedAttack.aimPoint = aimPoint + self.predictedVelocity * predictionScale
			return true
		end
	elseif self.target and sm.exists( self.target ) and type( self.target ) == "Harvestable" then
		local success, aimPoint = sm.ai.getAimPosition( self.unit.character, self.target, self.attackRange, self.fireLaneWidth )
		if success then
			self.rangedAttack.aimPoint = aimPoint
			return true
		end
	end
	return false
end

function TapebotUnit.server_onUnitUpdate( self, dt )
	
	if not sm.exists( self.unit ) then
		return
	end
	
	if self.unit.character:isTumbling() then
		return
	end
	
	if self.currentState then
		self.currentState:onUnitUpdate( dt )
	end

	-- Temporary units are routed by the daylight
	if self.saved.temporary then
		if self.currentState ~= self.dayFlee and sm.game.getCurrentTick() >= self.saved.deathTickTimestamp - DaysInTicks( 1 / 24 ) then
			local prevState = self.currentState
			prevState:stop()
			self.currentState = self.dayFlee
			self.currentState:start()
		end
		if self.currentState == self.dayFlee then
			return
		end
	end
	local targetCharacter
	local closestVisiblePlayerCharacter
	local closestHeardPlayerCharacter
	local closestVisibleWocCharacter
	local closestVisibleWormCharacter
	local closestVisibleCrop
	closestVisiblePlayerCharacter = sm.ai.getClosestVisiblePlayerCharacter( self.unit )
	if not closestVisiblePlayerCharacter then
		closestHeardPlayerCharacter = listenForCharacterNoise( self.unit.character, self.noiseScale )
	end
	if not closestVisiblePlayerCharacter and not closestHeardPlayerCharacter then
		closestVisibleWocCharacter = sm.ai.getClosestVisibleCharacterType( self.unit, unit_woc )
	end
	if not closestVisibleWocCharacter and not closestVisiblePlayerCharacter and not closestHeardPlayerCharacter then
		closestVisibleWormCharacter = sm.ai.getClosestVisibleCharacterType( self.unit, unit_worm )
	end
	if self.saved.raider then
		closestVisibleCrop = sm.ai.getClosestVisibleCrop( self.unit )
	end

	-- Find target
	if closestVisiblePlayerCharacter then
		targetCharacter = closestVisiblePlayerCharacter
	elseif closestHeardPlayerCharacter then
		targetCharacter = closestHeardPlayerCharacter
	elseif closestVisibleWocCharacter then
		targetCharacter = closestVisibleWocCharacter
	elseif closestVisibleWormCharacter then
		targetCharacter = closestVisibleWormCharacter
	end
	
	-- Share found target
	local foundTarget = false
	if targetCharacter and self.target == nil then
		if self.saved.groupId then
			for _, allyUnit in ipairs( g_unitManager:sv_getUnitGroup( self.saved.groupId ) ) do
				if sm.exists( allyUnit ) and self.unit ~= allyUnit then
					if ( allyUnit.character.worldPosition - self.unit.character.worldPosition ):length() <= AllyRange then
						sm.event.sendToUnit( allyUnit, "sv_e_receiveTarget", { targetCharacter = targetCharacter, sendingUnit = self.unit } )
					end
				end
			end
		end
		foundTarget = true
	end
	
	-- Check for targets acquired from callbacks
	if self.eventTarget and targetCharacter == nil then
		targetCharacter = self.eventTarget
	end
	self.eventTarget = nil

	if self.saved.raider then
		selectRaidTarget( self, targetCharacter, closestVisibleCrop )
	else
		if targetCharacter then
			self.target = targetCharacter
		else
			self.target = closestVisibleCrop
		end
	end

	if self.target then
		self.lastTargetPosition = self.target.worldPosition
	end

	-- Raiders will continue attacking an ambush position
	if self.saved.raidPosition then
		local flatFromToRaid = sm.vec3.new( self.saved.raidPosition.x,  self.saved.raidPosition.y, self.unit.character.worldPosition.z ) - self.unit.character.worldPosition
		if flatFromToRaid:length() >= RAIDER_AMBUSH_RADIUS then
			self.ambushPosition = self.saved.raidPosition
		end
	end

	-- Ambushers will always have somewhere they want to go
	if self.ambushPosition then
		if not self.lastTargetPosition and not self.target then
			self.lastTargetPosition = self.ambushPosition
		end
		local flatFromToAmbush = sm.vec3.new(  self.ambushPosition.x,  self.ambushPosition.y, self.unit.character.worldPosition.z ) - self.unit.character.worldPosition
		if flatFromToAmbush:length() <= 2.0 then
			-- Finished ambush
			self.ambushPosition = nil
		end
	end
	
	local prevState = self.currentState
	local prevInCombat = self.isInCombat
	if closestVisiblePlayerCharacter or closestHeardPlayerCharacter or self.lastTargetPosition or not self.suppressionFireTimer:done() then
		self.isInCombat = true
		self.combatTimer:reset()
	end
	if self.combatTimer:done() then
		self.isInCombat = false
	end
	
	-- Update pathingState destination and condition
	local pathingConditions = { { variable = sm.pathfinder.conditionProperty.target, value = ( self.lastTargetPosition and 1 or 0 ) } }
	self.pathingState:sv_setConditions( pathingConditions )
	if self.currentState == self.pathingState then
		if self.target then
			local currentTargetPosition = self.target.worldPosition
			if type( self.target ) == "Harvestable" then
				currentTargetPosition = self.target.worldPosition + sm.vec3.new( 0, 0, self.unit.character:getHeight() * 0.5 )
			end
			self.pathingState:sv_setDestination( currentTargetPosition )
		elseif self.lastTargetPosition then
			self.pathingState:sv_setDestination( self.lastTargetPosition )
		end
	end
	
	local done, result = self.currentState:isDone()
	local abortState = 	( ( self.currentState == self.pathingState or self.currentState == self.roamState ) and self.canShootTarget and self.isInCombat ) or 
						( prevInCombat and self.combatTimer:done() ) or
						( not self.suppressionFireTimer:done() )
	if done or abortState then
		
		if self.isInCombat then
			-- Select combat state
			if not self.suppressionFireTimer:done() then
				self.currentState = self.rangedAttack
			elseif self.target then
				if self.canShootTarget then
					-- Attack towards target character
					self.currentState = self.rangedAttack
					if type( self.target ) == "Character" and self.target:isPlayer() then
						self.suppressionFireTimer:reset()
					end
				else
					-- Pathing towards target character
					if self.currentState ~= self.pathingState then
						self.pathingState:sv_setDestination( self.target.worldPosition )
					end
					self.currentState = self.pathingState
				end
			elseif self.lastTargetPosition then
				if self.currentState ~= self.pathingState then
					self.pathingState:sv_setDestination( self.lastTargetPosition )
				end
				self.currentState = self.pathingState
				self.lastTargetPosition = nil
			end
		else
			-- Select non-combat state
			if self.roamTimer:done() and not ( self.currentState == self.idleState and result == "started" ) then
				self.roamTimer:start( math.random( self.roamStartTimeMin, self.roamStartTimeMax ) )
				if self.saved.patrolling then
					local validPositions = {}
					if self.currentState ~= self.roamState and self.currentState ~= self.positioningState then
						-- Look for roam position near home
						local nodes = sm.pathfinder.getSortedNodes( self.homePosition, 2, 16 )
						if nodes and #nodes > 0 then
							for _, node in ipairs( nodes ) do
								local path = sm.pathfinder.getPath( self.unit.character, node:getPosition() )
								if #path > 0 then
									validPositions[#validPositions+1] = node:getPosition()
								end
							end
						end

						if #validPositions == 0 then
							-- Look for roam position near self
							local nodes = sm.pathfinder.getSortedNodes( self.unit.character.worldPosition, 2, 16 )
							if nodes and #nodes > 0 then
								for _, node in ipairs( nodes ) do
									local path = sm.pathfinder.getPath( self.unit.character, node:getPosition() )
									if #path > 0 then
										validPositions[#validPositions+1] = node:getPosition()
									end
								end
							end
						end
					end
					if #validPositions > 0 then
						self.roamState:sv_setDestination( validPositions[math.random(1, #validPositions)] )
						self.currentState = self.roamState
					elseif self.currentState ~= self.roamState and self.currentState ~= self.positioningState then
						self.positioning.desiredPosition = self.unit.character.worldPosition
						self.positioning.desiredDirection = self.unit.character.direction:rotateZ( math.random() * 2 * math.pi )
						self.currentState = self.positioning
					end
				else
					self.positioning.desiredPosition = self.unit.character.worldPosition
					self.positioning.desiredDirection = self.unit.character.direction:rotateZ( math.random() * 2 * math.pi )
					self.currentState = self.positioning
				end
			elseif not ( self.currentState == self.roamState and result == "roaming" ) then
				self.currentState = self.idleState
			end
		end
		
	end
	
	if prevState ~= self.currentState then
		
		if ( prevState == self.roamState and self.currentState ~= self.idleState ) or ( prevState == self.idleState and self.currentState ~= self.roamState ) then
			self.unit:sendCharacterEvent( "alerted" )
		elseif ( self.currentState == self.idleState and prevState ~= self.roamState ) or ( self.currentState == self.roamState and prevState ~= self.idleState) then
			self.unit:sendCharacterEvent( "roaming" )
		end
		
		prevState:stop()
		self.currentState:start()
	end
	
end

function TapebotUnit.sv_e_worldEvent( self, params )
	if sm.exists( self.unit ) and self.isInCombat == false then
		if params.eventName == "projectileHit" then
			if self.unit.character then
				local distanceToProjectile = ( self.unit.character.worldPosition - params.hitPos ):length()
				if distanceToProjectile <= 4.0 then
					if self.eventTarget == nil and params.attacker and params.attacker.character then
						self.eventTarget = params.attacker.character
					end
				end
			end
		elseif params.eventName == "projectileFire" then
			if self.unit.character then
				local distanceToShooter = ( self.unit.character.worldPosition - params.firePos ):length()
				if distanceToShooter <= 10.0 then
					if self.eventTarget == nil and params.attacker and params.attacker.character then
						self.eventTarget = params.attacker.character
					end
				end
			end
		end
	end
end

function TapebotUnit.server_onProjectile( self, hitPos, hitTime, hitVelocity, projectileName, attacker, damage )
	if type( attacker ) == "Player" or ( type( attacker ) == "Shape" and not isTrapProjectile( projectileName ) ) then
		if damage > 0 then
			if self.eventTarget == nil then
				if type( attacker ) == "Player" then
					self.eventTarget = attacker:getCharacter()
				elseif type( attacker ) == "Shape" then
					self.eventTarget = attacker
				end
			end
		
			local ZAxis = sm.vec3.new( 0.0, 0.0, 1.0 )
			local impact = hitVelocity:normalize() * 6
			
			if self:nearHead( hitPos ) then
				sm.effect.playEffect( "TapeBot - HeadShot", hitPos, sm.vec3.zero(), sm.vec3.getRotation( ZAxis, hitVelocity:normalize() ) )
				self:sv_takeDamage( damage, impact, true )
			else
				sm.effect.playEffect( "TapeBot - Hit", hitPos, sm.vec3.zero(), sm.vec3.getRotation( ZAxis, hitVelocity:normalize() ) )
				self:sv_takeDamage( damage, impact, false )
			end
		end
	end
end

function TapebotUnit.server_onMelee( self, hitPos, attacker, damage, power )
	if type( attacker ) == "Player" then
		local attackingCharacter = attacker:getCharacter()
		local ZAxis = sm.vec3.new( 0.0, 0.0, 1.0 )
		local attackDirection = ( self.unit.character.worldPosition - attackingCharacter.worldPosition ):normalize()
		local impact = attackDirection * 6

		if self.currentState == self.staggeredEventState then
			ApplyKnockback( self.unit.character, attackDirection, power )
		end
		
		if self.eventTarget == nil then
			self.eventTarget = attackingCharacter
		end

		sm.effect.playEffect( "TapeBot - Hit", hitPos, sm.vec3.zero(), sm.vec3.getRotation( ZAxis, attackDirection ) )
		self:sv_takeDamage( damage, impact, false )
	end
end

function TapebotUnit.server_onExplosion( self, center, destructionLevel )
	local impact = ( self.unit:getCharacter().worldPosition - center ):normalize()
	self:sv_takeDamage( self.saved.stats.maxhp, impact, false )
end

function TapebotUnit.server_onCollision( self, other, collisionPosition, selfPointVelocity, otherPointVelocity, collisionNormal )
	
	if type( other ) == "Character" then
		if not sm.exists( other ) then
			return
		end
		if other:isPlayer() then
			if self.eventTarget == nil then
				self.eventTarget = other
			end
		end
	elseif type( other ) == "Shape" then
		if not sm.exists( other ) then
			return
		end
		if self.target == nil and self.eventTarget == nil then
			local creationBodies = other.body:getCreationBodies()
			for _, body in ipairs( creationBodies ) do
				local seatedCharacters = body:getAllSeatedCharacter()
				if #seatedCharacters > 0 then
					self.eventTarget = seatedCharacters[1]
					break
				end
			end
		end
	end
	
	if self.impactCooldownTicks > 0 then
		return
	end
		
	local damageFraction, tumbleTicks = CharacterCollision( self, other, collisionPosition, selfPointVelocity, otherPointVelocity, collisionNormal )
	local damage = damageFraction * self.saved.stats.maxhp
	if damage > 0 or tumbleTicks > 0 then
		self.impactCooldownTicks = 0.25 * 40
	end
	if damage > 0 then
		print("'TapebotUnit' took collision damage")
		self:sv_takeDamage( damage, collisionNormal, false )
	end
	if tumbleTicks > 0 then
		startTumble( self, tumbleTicks, self.idleState )
	end
	
end

function TapebotUnit.server_onCollisionCrush( self )
	if not sm.exists( self.unit ) then
		return
	end
	onCrush( self )
end

function TapebotUnit.sv_updateCharacterTarget( self )
	if self.unit.character then
		sm.event.sendToCharacter( self.unit.character, "sv_n_updateTarget", { target = self.target } )
	end
end

function TapebotUnit.sv_takeDamage( self, damage, impact, headHit )
	if self.saved.stats.hp > 0 then
		self.saved.stats.hp = self.saved.stats.hp - damage
		self.saved.stats.hp = math.max( self.saved.stats.hp, 0 )
		print( "'TapebotUnit' received:", damage, "damage.", self.saved.stats.hp, "/", self.saved.stats.maxhp, "HP" )
		if self.saved.stats.hp <= 0 or headHit then
			self:sv_onDeath( impact, headHit )
		else
			self.storage:save( self.saved )
		end
	end
end

function TapebotUnit.sv_onDeath( self, impact, headDestroyed )
	local character = self.unit:getCharacter()
	if not self.destroyed then
		self.saved.stats.hp = 0
		self.unit:destroy()
		print("'TapebotUnit' killed!")
		sm.effect.playEffect( "TapeBot - Destroyed", character.worldPosition )
		self:sv_spawnParts( impact, headDestroyed )
		local loot = SelectLoot( "loot_tapebot" )
		SpawnLoot( self.unit, loot )
		self.destroyed = true
	end
end

function TapebotUnit.sv_spawnParts( self, impact, headDestroyed )
	local character = self.unit:getCharacter()

	local lookDirection = character:getDirection()
	local bodyPos = character.worldPosition
	local bodyRot = sm.quat.identity()
	lookDirection = sm.vec3.new( lookDirection.x, lookDirection.y, 0 )
	if lookDirection:length() >= FLT_EPSILON then
		lookDirection = lookDirection:normalize()
		bodyRot = sm.vec3.getRotation( sm.vec3.new( 0, 1, 0 ), lookDirection  ) --Turn tapebot parts sideways
	end
	local bodyOffset = bodyRot * sm.vec3.new( -0.25, 0.25, 0.375 )
	bodyPos = bodyPos - bodyOffset

	local headBody = sm.body.createBody( bodyPos, bodyRot, true )
	local headShape = headBody:createPart( obj_robotparts_tapebothead01, sm.vec3.new( 0, 1, 2 ), sm.vec3.new( 0, 1, 0 ), sm.vec3.new( -1, 0, 0 ), true )
	sm.physics.applyImpulse( headShape, impact * headShape.mass, true )
	if headDestroyed == true then
		print("'TapebotUnit' head destroyed!")
		sm.physics.applyImpulse( headShape, sm.vec3.new( 0, 0, 6 ) * headShape.mass, true )
	end

	local middleBody = sm.body.createBody( bodyPos, bodyRot, true )
	local middleShape= middleBody:createPart( obj_robotparts_tapebottorso01, sm.vec3.new( 0, 0, 0 ), sm.vec3.new( 0, 1, 0 ), sm.vec3.new( -1, 0, 0 ), true )
	sm.physics.applyImpulse( middleShape, impact * middleShape.mass, true )

	local leftArmBody = sm.body.createBody( bodyPos, bodyRot, true )
	local leftArmShape = leftArmBody:createPart( obj_robotparts_tapebotleftarm01, sm.vec3.new( -5, 5, 3 ), sm.vec3.new( 0, 0, -1 ), sm.vec3.new( 1, 0, 0 ), true )
	sm.physics.applyImpulse( leftArmShape, impact * leftArmShape.mass, true )

	local rightArmBody = sm.body.createBody( bodyPos, bodyRot, true )
	local rightArmShape = rightArmBody:createPart( obj_robotparts_tapebotshooter, sm.vec3.new( 1, 2, 0 ), sm.vec3.new( 0, 1, 0 ), sm.vec3.new( -1, 0, 0 ), true )
	sm.physics.applyImpulse( rightArmShape, impact * rightArmShape.mass, true )
	if self.explosiveProjectile then
		rightArmShape.interactable:setParams( { projectileName = "explosivetape", projectileDamage = 20 } )
	else
		rightArmShape.interactable:setParams( { projectileName = "tape", projectileDamage = 20 } )
	end

	local tiltAxis = sm.vec3.new( 0, 1, 0 ):rotateZ( math.rad( math.random( 0, 359 ) ) )
	local tiltRotation = sm.quat.angleAxis( math.rad( math.random( 18, 22 ) ), tiltAxis )

	if self.explosiveProjectile then
		local redTapebotColor = sm.color.new( "8f2525ff" )
		headShape:setColor( redTapebotColor )
		middleShape:setColor( redTapebotColor )
		leftArmShape:setColor( redTapebotColor )
		rightArmShape:setColor( redTapebotColor )
	end
end

function TapebotUnit.nearHead( self, hitPos )
	return hitPos.z > self.unit:getCharacter().worldPosition.z + 0.25
end

function TapebotUnit.sv_e_receiveTarget( self, params )
	if self.unit ~= params.unit then
		if self.eventTarget == nil then
			self.eventTarget = params.targetCharacter
		end
	end
end

function TapebotUnit.sv_e_onEnterWater( self ) end

function TapebotUnit.sv_e_onStayWater( self ) end
