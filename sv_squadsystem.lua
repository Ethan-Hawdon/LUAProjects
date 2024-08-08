--Initialization 
local squadRoles = { "leader", "medic", "engineer", "tank", "assault", "scout", "raider", "soldier" }
local squads = {}
local maxSquads = 4
local maxSquadSize = 8
local buffRadius = 1000
local pingDuration = 10
local armourRegenTimers = {}
local healthregenTimers = {}
local ammoRegenTimers = {}
local originalhealth = {}
local playerBuffs = {}

--Creating the squads
for i = 1, maxSquads do
    squads[i] = { members = {}, roles = {nil, nil, nil, nil, nil, nil, nil, nil}, hasleader = false }
end

-- Count the members, since leavesquad can leave nil entries.
local function count(members)
    local count = 0
    for _, v in pairs(members) do
        if v ~= nil then
            count = count + 1
        end
    end
    return count
end 

--Looks for a nil on the table and puts the SteamID there, if none is found just inserts normally.
local function insert_member(members, value)
    for i = 1, #members do
        if members[i] == nil then
            members[i] = value
            return true
        end
    end
    table.insert(members, value)
    return false
end



--Iterates through every squad's members, returns true if the Player's SteamID is found. 
function in_squad(ply, squads)
    local steamid = ply:SteamID()
    for _, squad in ipairs(squads) do
        if table.HasValue(squad.members, steamid) then return true end 
    end 
    return false
end

--Return's the player's squad number. 
function squad_number(ply, squads)
    local steamid = ply:SteamID()
    for k,squad in ipairs(squads) do 
        if table.HasValue(squad.members, steamid) then return k end 
    end 
    return nil
end 

--Returns the position (key) of the player in the "members" Table, letting us see what the role of the player is.
function squad_position(ply, squad) 
    local steamid = ply:SteamID()
    for k,v in ipairs(squad.members) do 
        if v == steamid then return k end 
    end 
    return nil
end 

-- A check for if the player already has a role in the squad.
function player_hasrole(ply,squad,number)
    if squad.roles[number] then return true 
    else  return false end 
end 

-- Returns the leader's SteamID
function squad_leader(squad)
    if not(squad.hasleader) then return nil end  

    for k,role in ipairs(squad.roles) do 
        if role == "leader" then 
            return squad.members[k] -- Determine the position in the roles table (since we set the same position for the member and their role in the 2 tables)
        end  
    end 

end 

function leaderBuff(player)
    player:SetNWBool("LeaderBuff", true)    
end 

function medicBuff(player) 
    if IsValid(player) then
        local SID = player:SteamID()

        if healthregenTimers[SID] and IsValid(healthregenTimers[SID]) then
            healthregenTimers[SID]:Remove()
        end
    
        healthregenTimers[SID] = timer.Create("HealthRegenTimer_" .. SID, 1, 0, function() 
            if IsValid(player) then
                local health = player:Health() 
                local maxHealth = player:GetMaxHealth()

                if health < maxHealth then
                    player:SetHealth(math.min(health + 2, maxHealth)) --Makes sure if the player is at 99 hp for example, it won't regen to 101.
                end
            else
                -- Deletes once the player isn't valid, empties it.
                timer.Remove("HealTimer_" .. SID)
                healTimers[SID] = nil
            end
        end)
    else return end
end 

function engineerBuff(player) 
    if IsValid(player) then
        local SID = player:SteamID()

        if armourRegenTimers[SID] and IsValid(armourRegenTimers[SID]) then 
            armourRegenTimers[SID]:Remove()
        end
    
        armourRegenTimers[SID] = timer.Create("ArmourRegenTimer_" .. SID, 1, 0, function() 
            if IsValid(player) then 
                local armour = player:Armor()
                local maxArmour = player:GetMaxArmor()

                if armour < maxArmour then
                    player:SetArmor(math.min(armour + 2, maxArmour)) --Makes sure if the player is at 99 armor for example, it won't regen to 101.
                end
            else
                -- Deletes once the player isn't valid, empties it.
                timer.Remove("ArmourRegenTimer_" .. SID)
                armourRegenTimers[SID] = nil
            end
        end)        
    else return end
end

function raiderBuff(player) 
    local steamID = player:SteamID()
    if IsValid(player) then
        if ammoRegenTimers[steamID] and timer.Exists("AmmoRegenTimer_" .. steamID) then 
            timer.Remove("AmmoRegenTimer_" .. steamID)
        end
        ammoRegenTimers[steamID] = timer.Create("AmmoRegenTimer_" .. steamID, 1, 0, function() 
            if IsValid(player) then
                local wep = player:GetActiveWeapon()
                if IsValid(wep) then 
                    local ammoType = wep:GetPrimaryAmmoType()
                    local currentAmmo = player:GetAmmoCount(ammoType)
                    player:SetAmmo(currentAmmo + 3, ammoType)  -- Add 3 ammo to the reserves every second
                end
            else
                timer.Remove("AmmoRegenTimer_" .. steamID)
            end
        end)
    end
end

function tankBuff(player) 
    if not player:GetNWBool("HasOriginalMaxHealth", false) then
        player:SetNWFloat("OriginalMaxHealth", player:GetMaxHealth())
        player:SetNWBool("HasOriginalMaxHealth", true)
    end

    player:SetMaxHealth(player:GetMaxHealth() * 1.1)
end



function assaultBuff(player) 
    player:SetNWBool("AssaultBuff", true)
end 


function scoutBuff(player) 
    player:SetWalkSpeed(180)
end


-- Applies buff, inserts the buff given into the playerBuffs table specific to the player. This ensures that the player can recieve additional buffs without having to go out of range.
function ApplyBuff(player, buff)
    if not playerBuffs[player:SteamID()] then
        playerBuffs[player:SteamID()] = {}
    end
    _G[buff](player)
    table.insert(playerBuffs[player:SteamID()], buff)
end

--Remove all buffs, doesn't matter if they weren't put on the player
function removeBuff(member)
    if not playerBuffs[member] then return end

    for i, activeBuff in ipairs(playerBuffs[member]) do
        if activeBuff == buff then
            table.remove(playerBuffs[member], i)
            break
        end
    end
    
    local SID = member:SteamID()
    
    if armourRegenTimers[SID] and IsValid(armourRegenTimers[SID]) then 
        armourRegenTimers[SID]:Remove()
    end

    if healthRegenTimers[SID] and IsValid(healthRegenTimers[SID]) then 
        healthRegenTimers[SID]:Remove()
    end

    if ammoRegenTimers[SID] and IsValid(ammoRegenTimers[SID]) then 
        ammoRegenTimers[SID]:Remove()
    end

    member:SetNWBool("Buffed", false)
    member:SetWalkSpeed(160)
    
    if member:GetNWBool("HasOriginalMaxHealth", false) then
        local originalMaxHealth = member:GetNWFloat("OriginalMaxHealth")
        member:SetMaxHealth(originalMaxHealth)
        member:SetNWBool("HasOriginalMaxHealth", false)
    end
end

if SERVER then -- Has to be strictly in the server or the util.AddNetworkMessage won't work

-- Joining squad / Defining role. When joining a squad, stores the Player's SteamID in the "members" Table. When selecting a role, adds it to the "roles" Table.
-- Also added a leavesquad command.
hook.Add("PlayerSay", "ChooseSquadRole", function(ply, text, team)
    if string.sub(text, 1, 10) == "!joinsquad" then
        local chosenSquad = tonumber(string.sub(text, 12, 12)) -- 12th position would be the number.
        if chosenSquad and chosenSquad > 0 and chosenSquad <= maxSquads then
            if count(squads[chosenSquad].members) < maxSquadSize and not(in_squad(ply, squads)) then -- Makes sure the player isn't in a squad.
                insert_member(squads[chosenSquad].members, ply:SteamID())
                ply:ChatPrint("You joined squad " .. chosenSquad)
            elseif in_squad(ply, squads) then 
                ply:ChatPrint("You are already in a squad!")
            else 
                ply:ChatPrint("This squad is full!")
            end
        else
            ply:ChatPrint("Invalid Command. Please ensure you used the right format and squad number!")
        end
    end 

    if string.sub(text, 1, 10) == "!squadrole" then
        if in_squad(ply,squads) then
            local chosenRole = string.lower( string.sub(text, 12, string.len(text)) )
            local squad = squads[squad_number(ply, squads)]
            local pos = squad_position(ply,squad) -- Positiong in the members table.
            if table.HasValue(squadRoles, chosenRole) then
                if not table.HasValue(squad.roles, chosenRole) or not(squad) then
                    if squad.roles[pos] != chosenRole then 
                        squad.roles[pos] = chosenRole
                        ply:ChatPrint("Your role has successfully been set to " .. chosenRole .. "!")
                        if chosenRole == "leader" then 
                            squad.hasleader = true 
                        end 
                    else 
                        ply:ChatPrint("You already have that role or it is taken!")
                    end 
                end 
            else
                ply:ChatPrint("Invalid role. Available roles: " .. table.concat(squadRoles, ", "))
            end
        else
            ply:ChatPrint("You need to join a squad before choosing a role.")
        end
    end


    if string.sub(text, 1, 11) == "!leavesquad" then
        local sid = ply:SteamID() 
        if in_squad(ply, squads) then 
            ply:ChatPrint("You've left squad ".. squad_number(ply, squads))
            local squad = squads[squad_number(ply, squads)]
            local position = squad_position(ply, squad)
    
            squad.members[position] = nil
        else 
            ply:ChatPrint("You're not in a squad!")
        end 
    end

end)


-- Checks every second for the distance etc, updates as needed.
timer.Create("SquadLeaderCheck", 1, 0, function()     
    local BuffRoles = {"leader", "medic", "engineer", "tank", "assault", "scout", "raider"}
    
    for _, squad in ipairs(squads) do 
        if squad_leader(squad) then 
            local leader = player.GetBySteamID(squad_leader(squad))
            
            local membersCopy = {}
            for _, memberSID in pairs(squad.members) do
                if memberSID then
                    table.insert(membersCopy, memberSID)
                end
            end
            local rolesCopy = {} -- In case the roles increase or decrease, this dynamically iterates over the table.
            for i = 1, #squad.roles do
                local role = squad.roles[i]
                if role then
                    table.insert(rolesCopy, role)
                end
            end
            for _, memberSID in pairs(membersCopy) do 
                if memberSID then 
                    local member = player.GetBySteamID(memberSID)
                    local distance = leader:GetPos():Distance(member:GetPos())
                    
                    if distance < buffRadius then 
                        for _, role in pairs(rolesCopy) do 
                            if table.HasValue(BuffRoles, role) then -- Apply buffs to the player if they are within range
                                if not playerBuffs[member:SteamID()] then 
                                    playerBuffs[member:SteamID()] = {} 
                                end 
                                if not table.HasValue(playerBuffs[member:SteamID()], role) then -- Check if the player already has the buff
                                    ApplyBuff(member, role.."Buff")
                                end
                            end 
                        end 
                    elseif distance > buffRadius then 
                        removeBuff(member)
                    end     
                end         
            end
        end 
    end 
end)

-- Damage modification, increasing/decreasing damage as needed.
hook.Add("EntityTakeDamage", "DamageBuffs", function(target, dmginfo)
    local damage = dmginfo:GetDamage()
    local attacker = dmginfo:GetAttacker()
    if IsValid(attacker) and attacker:IsPlayer() then 
        if attacker:GetNWBool("AssaultBuff", false) then 
            dmginfo:SetDamage(damage * 1.1)
        end 
    end 

    if target:IsPlayer() and IsValid(target) then
        if target:GetNWBool("LeaderBuff", false) then
            dmginfo:SetDamage(damage * 0.9)
        end 
    end 
end)

-- If the player leaves, remove them and their role if present.
hook.Add( "PlayerDisconnected", "Playerleave", function(ply)
    local sid = ply:SteamID() 
    if in_squad(ply, squads) then 
        local squad = squads[squad_number(ply, squads)]
        local position = squad_position(ply, squad)
    
        squad.members[position] = nil
    end 
end )


--Network strings
util.AddNetworkString("SendPingEntity")
util.AddNetworkString("SendPingMarker")

-- Pinging system
hook.Add("PlayerSay", "EntityPing", function(ply, text, team)
    if string.sub(text, 1, 5) == "/ping" then
        if in_squad(ply, squads) then
            local trace = ply:GetEyeTrace()
            local squad = squads[squad_number(ply, squads)]
            
            for k, steamID in pairs(squad.members) do
                if steamID then 
                    local member = player.GetBySteamID(steamID)
                    if IsValid(member) then 
                        if IsValid(trace.Entity) then
                            net.Start("SendPingEntity")
                            net.WriteEntity(member)
                            net.WriteEntity(trace.Entity)
                            net.WriteInt(pingDuration, 32)
                            net.Send(member)
                        else
                            net.Start("SendPingMarker")
                            net.WriteEntity(member)
                            net.WriteVector(trace.HitPos)
                            net.WriteInt(pingDuration, 32)
                            net.Send(member)
                        end
                    end
                end
            end
        else
            ply:ChatPrint("You can't ping while you're not in a squad!")
        end
    end
end)

end 
