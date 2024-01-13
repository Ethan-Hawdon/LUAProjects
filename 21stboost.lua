-- Create a new SWEP
SWEP.PrintName = "21st Stim"
SWEP.Author = "Wamblez"
SWEP.Instructions = "Left click to activate the stim."
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.ViewModel = "models/weapons/v_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.Primary.Automatic = false

-- Define the damage and speed multipliers
local damageMultiplier = 0.1
local speedMultiplier = 1.5
local duration = 30
local cooldown = 30
local canUse = true

-- Function to apply the multipliers
local function ApplyMultipliers(ply)
    ply:SetWalkSpeed(ply:GetWalkSpeed() * speedMultiplier)
    ply:SetRunSpeed(ply:GetRunSpeed() * speedMultiplier)
    hook.Add("EntityTakeDamage", "DamageMultiplier", function(target, dmginfo)
        local damage = dmginfo:GetDamage()
        dmginfo:SetDamage(damage * damageMultiplier)
    end)
end

-- Function to remove the multipliers
local function RemoveMultipliers(ply)
    ply:SetWalkSpeed(ply:GetWalkSpeed() / speedMultiplier)
    ply:SetRunSpeed(ply:GetRunSpeed() / speedMultiplier)
    hook.Remove("EntityTakeDamage", "DamageMultiplier")
end

-- Function to handle SWEP usage
function SWEP:PrimaryAttack()
    if canUse then
        canUse = false
        local ply = self:GetOwner()
        ApplyMultipliers(ply)
        timer.Simple(duration, function()
            RemoveMultipliers(ply)
            timer.Simple(cooldown, function()
                canUse = true
            end)
        end)
    end
end