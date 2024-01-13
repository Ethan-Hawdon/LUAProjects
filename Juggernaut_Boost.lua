SWEP.PrintName = "Juggernaut Vial"
SWEP.Author = "Wamblez"
SWEP.Instructions = "Left click to activate juggernaut boost"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.ViewModel = "models/weapons/v_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.Primary.Automatic = false

-- Define the multipliers and duration
local damageMultiplier = 2
local damageReduction = 0.25
local speedReduction = 0.5
local duration = 30  -- Duration in seconds
local cooldown = 30  -- Cooldown in seconds
local canUse = true

-- Function to apply the adrenaline boost
local function ApplyAdrenalineBoost(ply)
    ply:SetWalkSpeed(ply:GetWalkSpeed() * speedReduction)
    ply:SetRunSpeed(ply:GetRunSpeed() * speedReduction)
    hook.Add("EntityTakeDamage", "AdrenalineDamageReduction", function(target, dmginfo)
        local damage = dmginfo:GetDamage()
        dmginfo:SetDamage(damage * damageReduction)
    end)
    ply.AdrenalineDamageMultiplier = damageMultiplier
end

-- Function to remove the adrenaline boost
local function RemoveAdrenalineBoost(ply)
    ply:SetWalkSpeed(ply:GetWalkSpeed() / speedReduction)
    ply:SetRunSpeed(ply:GetRunSpeed() / speedReduction)
    hook.Remove("EntityTakeDamage", "AdrenalineDamageReduction")
    ply.AdrenalineDamageMultiplier = nil
end

-- Function to handle SWEP usage
function SWEP:PrimaryAttack()
    if canUse then
        canUse = false
        local ply = self:GetOwner()
        ApplyAdrenalineBoost(ply)  -- Apply the adrenaline boost
        timer.Simple(duration, function()
            RemoveAdrenalineBoost(ply)  -- Remove the adrenaline boost after the duration
            timer.Simple(cooldown, function()
                canUse = true  -- Set canUse to true after the cooldown
            end)
        end)
    end
end