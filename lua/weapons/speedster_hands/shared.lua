local SWEP = {Primary = {}, Secondary = {}} -- I don't know what this does

SWEP.PrintName      = "Speedster Hands"
SWEP.DrawCrosshair	= true
SWEP.SlotPos = 1
SWEP.Slot = 1
SWEP.Spawnable = true
SWEP.Weight = 1
SWEP.HoldType = "normal"
SWEP.Primary.Ammo = "none" --This stops it from giving pistol ammo when you get the hands
SWEP.Primary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Automatic = true

function SWEP:DrawWorldModel() end
function SWEP:DrawWorldModelTranslucent() end
function SWEP:CanPrimaryAttack() return false end
function SWEP:CanSecondaryAttack() return false end
function SWEP:Holster() return true end
function SWEP:ShouldDropOnDie() return false end
function SWEP:PreDrawViewModel() return true end -- This stops it from displaying as a pistol in your hands

function SWEP:Initialize()
	self.MaxSpd = 5000
	self.MinSpd = 600 --600 default sprint speed
	net.SetNWInt("CurSpd",self.MinSpd)

    if(self.SetHoldType) then
		self:SetHoldType("normal")
	else
		self:SetWeaponHoldType("normal") -- This makes your arms go to your sides
	end

	self:DrawShadow(false)

	self.NextUse = CurTime()
end

/*
hook.Add("ShouldCollide", "PhaseHook", function(ent1,ent2)
	return false
end)
*/

if SERVER then
	function SWEP:PrimaryAttack()
		local ply = self.Owner
		self.CurSpd = ply:GetRunSpeed()

		net.SetNWInt("CurSpd",self.CurSpd)		

		if(ply:KeyDown(IN_USE)) then
			ply:SetRunSpeed(math.Clamp(self.CurSpd + 50, self.MinSpd, self.MaxSpd))
		else
			ply:SetRunSpeed(math.Clamp(self.CurSpd + 20, self.MinSpd, self.MaxSpd))
		end
	end


	function SWEP:SecondaryAttack()
		local ply = self.Owner
		self.CurSpd = ply:GetRunSpeed()

		net.SetNWInt("CurSpd",self.CurSpd)

		if(ply:KeyDown(IN_USE)) then
			ply:SetRunSpeed(math.Clamp(self.CurSpd - 50, self.MinSpd, self.MaxSpd))
		else
			ply:SetRunSpeed(math.Clamp(self.CurSpd - 20, self.MinSpd, self.MaxSpd))
		end
	end

	function SWEP:Reload() -- Phasing
		local ply = self.Owner

		if (not IsValid(ply)) then return end

		if self.NextUse < CurTime() then
			if not self.Phase then
				self.Phase = true
				ply:EmitSound("buttons/button16.wav", 100, 120)
				self:SetNWInt("PhaseActive", 1)
				PlyCollision(ply,true)
			else
				self.Phase = false
				ply:EmitSound("buttons/button16.wav", 100, 100)
				self:SetNWInt("PhaseActive", 0)
				PlyCollision(ply,false)
			end

			self.NextUse = CurTime() + 1
		end
	end

	function PlyCollision(ply,on)
		local color = ply:GetColor()
		local rendMode = ply:GetRenderMode()

		--print(ply:GetCollisionGroup().." main")
	
		if(on == true) then
			color.a = 240
			ply:SetCollisionGroup(COLLISION_GROUP_WORLD)
			ply:SetColor(color)
			ply:SetRenderMode(RENDERMODE_TRANSCOLOR)

			--net.Start("speedsterphase")
			--net.WriteEntity(ply)
            --net.WriteBit(true)
            --net.Send(ply)
			--print(ply:GetCollisionGroup().." on")
		else
			color.a = 255
			ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
			ply:SetRenderMode(rendMode)

			--net.Start("speedsterphase")
			--net.WriteEntity(ply)
            --net.WriteBit(false)
            --net.Send(ply)
			--print(ply:GetCollisionGroup().." off")
		end
	end

	function SWEP:Think() 
		local ply = self.Owner
		
		--if ply:GetRunSpeed() > self.MinSpeed and ply:KeyDown(IN_RUN) then
			--util.SpriteTrail(ply,0,Color(255,95,215),false,5,1,5,1/(5+1)*0.5,"trails/plasma")
		--2end
	end
end

if CLIENT then
	function SWEP:Initialize()
        self.NextUse = CurTime()
		CurSpdDisp = 600
    end

	net.Receive("speedsterphase",function(len,ply)
		local pl = net.ReadEntity()
		if(IsValid(pl) and pl:IsPlayer()) then
			--pl:ChatPrint("receive")
			if(net.ReadBit() == 1) then
				pl:SetCollisionGroup(COLLISION_GROUP_WORLD)
				--pl:ChatPrint(pl:GetCollisionGroup().." on")
			else
				pl:SetCollisionGroup(COLLISION_GROUP_PLAYER)
				--pl:ChatPrint(pl:GetCollisionGroup().." off")
			end
		end
	end)

	function SWEP:DrawHUD() --for displaying speed
		draw.WordBox(10, ScrW() - 200, ScrH() - 140, "Speed: " .. net.getNWInt("CurSpd"), "Default", Color(0, 0, 0, 80), Color(255, 220, 0, 220))

	end

	
end

timer.Simple(0.1, function() weapons.Register(SWEP,"speedster_hands", true) end) --Putting this in a timer stops bugs from happening if the weapon is given while the game is paused