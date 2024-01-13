SWEP.PrintName = "Flashbang"
SWEP.Author = "Wamblez"
SWEP.Instructions = "Left click to shoot a flashbang"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.ViewModel = "models/weapons/v_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.Primary.Automatic = false
SWEP.Primary.ClipSize = 1  -- Set the magazine size
SWEP.Primary.DefaultClip = 1  -- Set the default ammo
SWEP.Primary.Ammo = "flashbang_ammo"  -- Set the ammo type

if CLIENT then
	language.Add("flashbang_ammo", "Flashbang Ammo")
end

-- Function to handle SWEP usage
function SWEP:PrimaryAttack()
    if self:CanPrimaryAttack() then
        self:TakePrimaryAmmo(1)  -- Consume one round of ammo
        if SERVER then
            local ply = self:GetOwner()
            local flashbang = ents.Create("npc_grenade_frag")  -- Create a grenade entity
            flashbang:SetPos(ply:GetShootPos() + ply:GetAimVector() * 20)  -- Set the initial position
            flashbang:SetAngles(ply:EyeAngles())  -- Set the initial angles
            flashbang:Spawn()  -- Spawn the grenade

            local phys = flashbang:GetPhysicsObject()
            if IsValid(phys) then
                phys:SetVelocity(ply:GetAimVector() * 1000)  -- Set the velocity
            end

            timer.Simple(2, function()
                if IsValid(flashbang) then
                    local explosion = ents.Create("env_explosion")  -- Create an explosion entity
                    explosion:SetPos(flashbang:GetPos())  -- Set the explosion position
                    explosion:SetOwner(ply)  -- Set the explosion owner
                    explosion:Spawn()  -- Spawn the explosion
                    explosion:SetKeyValue("iMagnitude", "250")  -- Set the explosion magnitude
                    explosion:Fire("Explode", 0, 0)  -- Trigger the explosion

                    local entities = ents.FindInSphere(flashbang:GetPos(), 500)  -- Find entities within a 5-meter radius
                    for _, ent in pairs(entities) do
                        if ent:IsPlayer() then
                            local distance = flashbang:GetPos():Distance(ent:GetPos())  -- Calculate the distance
                            local duration = 6 - (distance / 100)  -- Calculate the dynamic duration
                            ent:ScreenFade(SCREENFADE.OUT, Color(255, 255, 255, 255), duration, duration)  -- Apply the screen fade
                        end
                    end

                    flashbang:Remove()  -- Remove the flashbang entity
                end
            end)
        end
    end
end

-- Function to handle reloading
function SWEP:Reload()
    if self:GetOwner():GetAmmoCount(self.Primary.Ammo) > 0 and self:Clip1() < self.Primary.ClipSize then
        self:DefaultReload(ACT_VM_RELOAD)
    end
end