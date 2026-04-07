--!nocheck
--!nolint

-- PrisonLifeWare - Specific Features
-- Auto Grab Guns + Remove Doors + Player ESP + Gun ESP

local data = {
    cached_guns = {},
    cached_doors = {},
    local_position = Vector3.new(0,0,0)
}

-- ==================== UI SETUP (same style as your other scripts) ====================
ui.newTab("PrisonLifeWare", "PrisonLifeWare")

ui.newContainer("PrisonLifeWare", "Features", "Features", {next = true})
ui.newCheckbox("PrisonLifeWare", "Features", "Auto Grab Guns", true)
ui.newCheckbox("PrisonLifeWare", "Features", "Remove Doors", false)

ui.newContainer("PrisonLifeWare", "Visuals", "Visuals", {next = true})
ui.newCheckbox("PrisonLifeWare", "Visuals", "Visuals Enabled", true)
ui.newCheckbox("PrisonLifeWare", "Visuals", "Player ESP", true)
ui.newCheckbox("PrisonLifeWare", "Visuals", "Gun ESP", true)

-- ==================== CACHING ====================
cheat.Register("onSlowUpdate", function()
    local ws = game:GetService("Workspace")

    -- Guns
    local guns = {}
    local giver = ws:FindFirstChild("Prison_ITEMS") and ws.Prison_ITEMS:FindFirstChild("giver")
    if giver then
        for _, v in pairs(giver:GetChildren()) do
            local pickup = v:FindFirstChild("ITEMPICKUP")
            if pickup then
                table.insert(guns, {name = v.Name, position = pickup.Position})
            end
        end
    end
    data.cached_guns = guns

    -- Doors / Gates / Fences
    local doors = {}
    for _, obj in pairs(ws:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("door") or obj.Name:lower():find("gate") or obj.Name:lower():find("fence")) then
            table.insert(doors, obj)
        end
    end
    data.cached_doors = doors
end)

-- Local Position
cheat.Register("onUpdate", function()
    local lp = entity.get_local_player()
    if lp and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        data.local_position = lp.Character.HumanoidRootPart.Position
    end
end)

-- Auto Grab Guns
cheat.Register("onUpdate", function()
    if not ui.getValue("PrisonLifeWare", "Features", "Auto Grab Guns") then return end

    local ws = game:GetService("Workspace")
    local giver = ws:FindFirstChild("Prison_ITEMS") and ws.Prison_ITEMS:FindFirstChild("giver")
    if not giver then return end

    for _, v in pairs(giver:GetChildren()) do
        local pickup = v:FindFirstChild("ITEMPICKUP")
        if pickup then
            pcall(function()
                ws.Remote.ItemHandler:InvokeServer(pickup)
            end)
        end
    end
end)

-- Remove Doors
cheat.Register("onUpdate", function()
    if not ui.getValue("PrisonLifeWare", "Features", "Remove Doors") then return end

    for _, door in pairs(data.cached_doors) do
        if door and door:IsA("BasePart") then
            door.CanCollide = false
            door.Transparency = 0.7
        end
    end
end)

-- Player ESP
cheat.Register("onPaint", function()
    if not ui.getValue("PrisonLifeWare", "Visuals", "Visuals Enabled") then return end
    if not ui.getValue("PrisonLifeWare", "Visuals", "Player ESP") then return end

    for _, plr in ipairs(game.Players:GetPlayers()) do
        if plr ~= game.Players.LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local pos = plr.Character.HumanoidRootPart.Position
            local screen, onScreen = utility.world_to_screen(pos)
            if onScreen then
                local dist = (data.local_position - pos).Magnitude
                local color = plr.Team and plr.Team.Color or Color3.new(1,1,1)
                draw.text_outlined(plr.Name .. " ["..math.floor(dist).."m]", screen - Vector2.new(0,20), color, "ConsolasBold", 1)
            end
        end
    end
end)

-- Gun ESP
cheat.Register("onPaint", function()
    if not ui.getValue("PrisonLifeWare", "Visuals", "Visuals Enabled") then return end
    if not ui.getValue("PrisonLifeWare", "Visuals", "Gun ESP") then return end

    for _, gun in pairs(data.cached_guns) do
        local screen, onScreen = utility.world_to_screen(gun.position)
        if onScreen then
            local dist = (data.local_position - gun.position).Magnitude
            draw.text_outlined(gun.name .. " ["..math.floor(dist).."m]", screen, Color3.fromRGB(0,255,100), "ConsolasBold", 1)
        end
    end
end)

print("✅ PrisonLifeWare loaded! Check the side menu for toggles.")
