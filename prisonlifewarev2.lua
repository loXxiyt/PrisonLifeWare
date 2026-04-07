--!nocheck
--!nolint

_P = {
    genDate = "2026-04-07T15:00:00.000000000+00:00",
    cfg = "PrisonLifeSpecific",
    vers = "2.6",
}

local events = {}
local config = {}

-- Simple Event System
function events.Add(name, func)
    if not events[name] then events[name] = {} end
    table.insert(events[name], func)
end

function events.ClearAll()
    events = {}
end

-- Simple Config
function config.GetValue(key)
    return _G.PrisonConfig and _G.PrisonConfig[key] or false
end

-- Environment
local env = {
    cached_guns = {},
    cached_doors = {},
    local_position = Vector3.new(0,0,0)
}

-- Core Caching
events.Add("onUpdate", function()
    local lp = entity.get_local_player()
    if lp and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        env.local_position = lp.Character.HumanoidRootPart.Position
    end
end)

events.Add("onSlowUpdate", function()
    local ws = game:GetService("Workspace")
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
    env.cached_guns = guns

    local doors = {}
    for _, obj in pairs(ws:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("door") or obj.Name:lower():find("gate") or obj.Name:lower():find("fence")) then
            table.insert(doors, obj)
        end
    end
    env.cached_doors = doors
end)

-- Auto Grab Guns
events.Add("onUpdate", function()
    if not config.GetValue("Auto Grab Guns") then return end
    if tick() % 2 > 1.5 then return end  -- simple cooldown

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
events.Add("onUpdate", function()
    if not config.GetValue("Remove Doors") then return end
    for _, door in pairs(env.cached_doors) do
        if door and door:IsA("BasePart") then
            door.CanCollide = false
            door.Transparency = 0.7
        end
    end
end)

-- Player ESP
events.Add("onPaint", function()
    if not config.GetValue("Visuals Enabled") or not config.GetValue("Player ESP") then return end
    for _, plr in ipairs(game.Players:GetPlayers()) do
        if plr ~= game.Players.LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local pos = plr.Character.HumanoidRootPart.Position
            local screen, onScreen = utility.world_to_screen(pos)
            if onScreen then
                local dist = (env.local_position - pos).Magnitude
                local color = plr.Team and plr.Team.Color or Color3.new(1,1,1)
                draw.text_outlined(plr.Name .. " ["..math.floor(dist).."m]", screen - Vector2.new(0,20), color, "ConsolasBold", 1)
            end
        end
    end
end)

-- Gun ESP
events.Add("onPaint", function()
    if not config.GetValue("Visuals Enabled") or not config.GetValue("Gun ESP") then return end
    for _, gun in pairs(env.cached_guns) do
        local screen, onScreen = utility.world_to_screen(gun.position)
        if onScreen then
            local dist = (env.local_position - gun.position).Magnitude
            draw.text_outlined(gun.name .. " ["..math.floor(dist).."m]", screen, Color3.fromRGB(0,255,100), "ConsolasBold", 1)
        end
    end
end)

-- Register the cheat events
cheat.Register("onUpdate", function(...) 
    for _, f in pairs(events.onUpdate or {}) do pcall(f, ...) end 
end)

cheat.Register("onPaint", function(...) 
    for _, f in pairs(events.onPaint or {}) do pcall(f, ...) end 
end)

cheat.Register("onSlowUpdate", function(...) 
    for _, f in pairs(events.onSlowUpdate or {}) do pcall(f, ...) end 
end)

print("✅ PrisonLifeWare Simple v2.6 loaded! Use your external menu to toggle the options.")
