if CLIENT then 
net.Receive("SendPingEntity", function()
    local ply = net.ReadEntity()
    local ent = net.ReadEntity()
    local duration = net.ReadInt(32) 

    if not IsValid(ply) or not IsValid(ent) then return end
    ply:SetNWBool("DrawHalo", true)
    ply:SetNWEntity("PingedEntity", ent)

    timer.Create( "PingHalo" .. ply:SteamID(), duration, 1, function()
        ply:SetNWBool("DrawHalo", false)
    end)

end)

hook.Add("PreDrawHalos", "EntityHaloHook", function()
    local ply = LocalPlayer()
    if ply:GetNWBool("DrawHalo", false) then
        local ent = ply:GetNWEntity("PingedEntity")
        if IsValid(ent) then
            halo.Add({ent}, Color(255, 0, 0), 1, 1, 1, true, true)
        end
    end
end)


net.Receive("SendPingMarker", function()
    local member = net.ReadEntity()
    local pos = net.ReadVector()
    local duration = net.ReadInt(32)
    
    
    local startTime = CurTime()
    
    local function DrawMarker()
        local elapsedTime = CurTime() - startTime
        
        if elapsedTime >= duration then
            hook.Remove("HUDPaint", "DrawPingMarker") 
            print("Marker display finished") 
            return
        end
        local screenPos = pos:ToScreen()
        surface.SetDrawColor(255, 0, 0, 150)
        local radius = 10
        local segments = 32
        local circle = {}
        
        for i = 1, segments do
            local angle = math.rad((i / segments) * -360)
            local x = screenPos.x + math.cos(angle) * radius
            local y = screenPos.y + math.sin(angle) * radius
            table.insert(circle, {x = x, y = y})
        end
        
        surface.DrawPoly(circle)
        


        hook.Add("HUDPaint", "DrawPingMarker", DrawMarker)
    end
    
    -- Start drawing the marker
    hook.Add("HUDPaint", "DrawPingMarker", DrawMarker)
end)

end     
