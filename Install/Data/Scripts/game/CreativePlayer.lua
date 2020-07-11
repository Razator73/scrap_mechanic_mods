
CreativePlayer = class( nil )
CreativePlayer.IsOpen = false
function CreativePlayer.server_onCreate( self )
	self.sv = {}
	self:sv_init()
end

function CreativePlayer.server_onRefresh( self )
	self:sv_init()
end

function CreativePlayer.sv_init( self ) end

function CreativePlayer.server_onDestroy( self ) end

function CreativePlayer.client_onCreate( self )
	self.cl = {}
	self:cl_init()
	self.cl.hud = sm.gui.createSurvivalHudGui()
	self.cl.hud:open()
end

function CreativePlayer.client_onRefresh( self )
	self:cl_init()
end
function ToggleToggle( param, player )
	if sm.localPlayer.getPlayer():getName() == player then
		CreativePlayer.IsOpen = param
	end
end
function CreativePlayer.cl_init(self) end

function CreativePlayer.client_onUpdate( self, dt ) 
			--TGOS edited this function a lot
			if self.cl.hud == nil then
				self.cl.hud = sm.gui.createSurvivalHudGui()
				self.cl.hud:open()
			end
			local character = sm.localPlayer.getPlayer():getCharacter()
			if CreativePlayer.IsOpen then
				self.cl.hud:setImage("COMPASS_BG", "$SURVIVAL_DATA/Scripts/WayPoints/camera-hud0.png")
			else
				self.cl.hud:setImage("COMPASS_BG", "")
			end
			self.cl.hud:setSliderData( "Health", 1, 1 )
			self.cl.hud:setSliderData( "Food", 1, 1 )
			self.cl.hud:setSliderData( "Water", 1, 1 )
			self.cl.hud:setSliderData( "Breath", 1, 1 )
			self.cl.hud:setText( 'Time', "GPS" )
			local radarDataT = ''
			local compassT = 'N                 NE                 E                 SE                 S                 SW                 W                 NW                 '
			local chPos = character.worldPosition
			local direction = character.direction
			local yaw = math.atan2( direction.y, direction.x )
			local hComp = chPos
			local aim = 0
			if hComp:length() > 1 then
				local fDir = sm.vec3.new(direction.x, direction.y, 0)
				local fhC = sm.vec3.new(hComp.x, hComp.y, 0)
				aim = math.acos(fDir:normalize():dot(fhC:normalize()))
				local crs = fDir:normalize():cross(fhC:normalize())
				if crs.z < 0 then aim = -aim end
			end
			local newCompT = ''
			self.cl.hud:setText( 'COMPASS_compcent', '[      ]')
			local angDeg = math.deg(yaw)
			local angCorr = -90
			local fitAng = #compassT/2 + (#compassT * (angDeg+angCorr)/360)
			for i=0,#compassT do
				local charI = math.floor(math.fmod(i-fitAng,#compassT))
				newCompT = newCompT .. compassT:sub(charI,charI)
			end
			self.cl.hud:setText( 'COMPASS_comp', newCompT )
			local posT = ''
			posT = math.floor(chPos.x)..','..math.floor(chPos.y)
			self.cl.hud:setText( 'COMPASS_pos', posT )

			local cellT = ''
			cellT = math.floor(chPos.x / 64)..','..math.floor(chPos.y  / 64)
			self.cl.hud:setText( 'COMPASS_cell', cellT )
		--TGO edited to here
end

function CreativePlayer.client_onInteract( self, character, state ) end

function CreativePlayer.server_onFixedUpdate( self, dt ) end

function CreativePlayer.server_onProjectile( self, hitPos, hitTime, hitVelocity, projectileName, attacker, damage ) end

function CreativePlayer.server_onMelee( self, hitPos, attacker, damage, power ) end

function CreativePlayer.server_onExplosion( self, center, destructionLevel ) end

function CreativePlayer.server_onCollision( self, other, collisionPosition, selfPointVelocity, otherPointVelocity, collisionNormal  ) end

function CreativePlayer.sv_e_staminaSpend( self, stamina ) end

function CreativePlayer.sv_e_receiveDamage( self, damageData ) end

function CreativePlayer.sv_e_respawn( self ) end

function CreativePlayer.sv_e_debug( self, params ) end

function CreativePlayer.sv_e_eat( self, edibleParams ) end

function CreativePlayer.sv_e_feed( self, params ) end

function CreativePlayer.sv_e_setRefiningState( self, params ) end

function CreativePlayer.sv_e_onLoot( self, params ) end

function CreativePlayer.sv_e_onStayPesticide( self ) end

function CreativePlayer.sv_e_onEnterFire( self ) end

function CreativePlayer.sv_e_onStayFire( self ) end

function CreativePlayer.sv_e_onEnterChemical( self ) end

function CreativePlayer.sv_e_onStayChemical( self ) end

function CreativePlayer.sv_e_startLocalCutscene( self, cutsceneInfoName ) end

function CreativePlayer.client_onCancel( self ) end

function CreativePlayer.client_onReload( self ) end

function CreativePlayer.server_onShapeRemoved( self, removedShapes ) end

function GetGameMode( self )return true end