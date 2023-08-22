local SWEP = {Primary = {}, Secondary = {}} -- I don't know what this does

SWEP.PrintName = "Speedster Hands"
SWEP.DrawCrosshair = true
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
	self.MaxSpd = 2000
	self.MinSpd = 400 -- 400 is default sprint speed even though wiki says 600

	self:SetNWInt("CurSpd",self.MinSpd)

    if(self.SetHoldType) then
		self:SetHoldType("normal")
	else
		self:SetWeaponHoldType("normal") -- This makes your arms go to your sides
	end

	self:DrawShadow(false)

	self.NextUse = CurTime()

	/*
	timer.Create("SpeedsterHealthRegen" .. self.Owner:EntIndex(), 2, 0, function()
        if (not IsValid(self)) then return end
        self.Owner:SetHealth(math.Clamp(self.Owner:Health() + 5, 1, self.MaxHealth))
    end)
	*/
end

function SWEP:Deploy()
	hook.Add("ShouldCollide","TFPhaseHook",function(ent1,ent2)
		if(self.Phase == true) then
			if(ent1 == self:GetOwner() or ent2 == self:GetOwner()) then
				return false
			end
		end
	end)
end

if SERVER then
	function SWEP:PrimaryAttack()
		local ply = self:GetOwner()
		self.CurSpd = ply:GetRunSpeed()

		self:SetNWInt("CurSpd",self.CurSpd)		

		if(ply:KeyDown(IN_USE)) then
			ply:SetRunSpeed(math.Clamp(self.CurSpd + 50, self.MinSpd, self.MaxSpd))
		else
			ply:SetRunSpeed(math.Clamp(self.CurSpd + 20, self.MinSpd, self.MaxSpd))
		end
	end

	function SWEP:SecondaryAttack()
		local ply = self:GetOwner()
		self.CurSpd = ply:GetRunSpeed()

		self:SetNWInt("CurSpd",self.CurSpd)

		if(ply:KeyDown(IN_USE)) then
			ply:SetRunSpeed(math.Clamp(self.CurSpd - 50, self.MinSpd, self.MaxSpd))
		else
			ply:SetRunSpeed(math.Clamp(self.CurSpd - 20, self.MinSpd, self.MaxSpd))
		end
	end

	function SWEP:Reload() -- Phasing
		ply = self:GetOwner()

		if (not IsValid(ply)) then return end

		if self.NextUse < CurTime() then
			if not self.Phase then
				self.Phase = true

				Phase(ply,true,true)
			else
				self.Phase = false

				Phase(ply,false,true)
			end

			self.NextUse = CurTime() + 1
		end
	end

	function Phase(ply,on,playsound)
		local color = ply:GetColor()
		local rendMode = ply:GetRenderMode()
	
		if(on == true) then
			if(playsound == true) then
				ply:EmitSound("phase_start.wav",100,100)
			end

			ply:SetCustomCollisionCheck(true)
			ply:CollisionRulesChanged()

			color.a = 240
			ply:SetColor(color)
			ply:SetRenderMode(RENDERMODE_TRANSCOLOR)
		else
			if(playsound == true) then
				ply:EmitSound("phase_stop.wav",100,100)
			end

			ply:SetCustomCollisionCheck(true)
			ply:CollisionRulesChanged()

			ply:StopSound("phase_start.wav")

			color.a = 255
			ply:SetColor(color)
			ply:SetRenderMode(rendMode)
		end
	end

	function SWEP:Think() 
		--local ply = self:GetOwner()

		--I dont know how to do trails yet
		--util.SpriteTrail(ply,0,Color(255,95,215),false,5,1,5,1/(5+1)*0.5,"trails/plasma")
	end

	function SWEP:OnRemove() -- When the player dies
		Phase(self:GetOwner(),false,false)
		self:GetOwner():SetRunSpeed(400)
		self:SetNWInt("CurSpd",self.MinSpd)

		self:GetOwner():SetCustomCollisionCheck(false)
		self:GetOwner():CollisionRulesChanged()
		hook.Remove("ShouldCollide","PhaseHook")
	end
end

if CLIENT then
	function SWEP:Initialize()
        self.NextUse = CurTime()
		CurSpdDisp = 600
    end

	function SWEP:DrawHUD() --for displaying speed
		draw.WordBox(10, ScrW() - 200, ScrH() - 140, "Speed: " .. self:GetNWInt("CurSpd"), "Default", Color(0, 0, 0, 80), Color(255, 220, 0, 220))
	end

	
end

timer.Simple(0.1, function() weapons.Register(SWEP,"speedster_hands", true) end) --Putting this in a timer stops bugs from happening if the weapon is given while the game is paused