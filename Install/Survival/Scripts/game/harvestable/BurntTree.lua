dofile "$SURVIVAL_DATA/Scripts/game/survival_loot.lua"

BurntTree = class()
local TrunkHealth = 100
local TrunkHits = 4
local DamagerPerHit = math.ceil( TrunkHealth / TrunkHits )

function BurntTree.server_onCreate( self )
	self.sv = {}
	self.sv.health = TrunkHealth
end

function BurntTree.server_onProjectile( self, hitPos, hitTime, hitVelocity, projectileName, attacker, damage )
	self:sv_onHit( DamagerPerHit )
end

function BurntTree.server_onMelee( self, hitPos, attacker, damage )
	self:sv_onHit( DamagerPerHit )
end

function BurntTree.server_onExplosion( self, center, destructionLevel )
	self:sv_onHit( TrunkHealth )
end

function BurntTree.server_onCollision( self, other, collisionPosition, selfPointVelocity, otherPointVelocity, collisionNormal )
	local impactVelocity = ( selfPointVelocity - otherPointVelocity ):length()
	if impactVelocity > 5.0 then
		if type( other ) == "Shape" then
			local damage = math.min( 2.5, impactVelocity)
			self:sv_onHit( damage )
		end
	end
end

function BurntTree.sv_onHit( self, damage )
	self.sv.health = self.sv.health - damage
	if self.sv.health <= 0 then
		if not self.sv.destroyed and sm.exists( self.harvestable ) then
			if self.data.destroyEffect then

				sm.effect.playEffect( self.data.destroyEffect, self.harvestable.worldPosition, nil, self.harvestable.worldRotation )
				sm.effect.playEffect( "Harvestable - Burnttree", self.harvestable.worldPosition )
			end

			local lootList = {}
			local slots = math.random( 4, 6 )
			for i = 1, slots do
				lootList[i] = { uuid = obj_resource_ember, quantity = 1 }
			end
			SpawnLoot( self.harvestable, lootList )

			self.harvestable:destroy()
			self.sv.destroyed = true
		end
	end
end