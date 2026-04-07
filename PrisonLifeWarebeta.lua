--!nocheck
--!nolint

_P = {
    genDate = "2026-04-07T00:00:00.000000000+00:00",
    cfg = "PrisonLifeRelease",
    vers = "1.1",
}

local a = {
    cache = {},
    load = function(b)
        if not a.cache[b] then
            a.cache[b] = { c = a[b]() }
        end
        return a.cache[b].c
    end,
}

do
    -- Event System (same as DiddyWare)
    function a.a()
        local b, c, d = {}, {}, { "onPaint", "onUpdate", "onSlowUpdate", "shutdown" }
        for _, f in ipairs(d) do c[f] = {} end

        function b.Add(e, f)
            if type(e) ~= "string" or type(f) ~= "function" then return nil end
            if not c[e] then return nil end
            local g = #c[e] + 1
            c[e][g] = f
            return g
        end

        function b.Remove(e, f)
            if c[e] then c[e][f] = nil end
        end

        function b.ClearAll()
            for e in pairs(c) do c[e] = {} end
        end

        local e = function(event, ...)
            for _, g in pairs(c[event]) do g(...) end
        end

        function b:Initialise()
            for _, g in ipairs(d) do
                cheat.Register(g, function(...) e(g, ...) end)
            end
        end
        return b
    end

    -- Registry System
    function a.b()
        local b = {} b.__index = b local c = {}
        function b:Register(d, e) e = e or {} c[d] = e return e end
        function b:Get(d) return c[d] end
        function b:UnloadAll()
            for d in next, c do c[d] = nil end
        end
        return b
    end

    -- Config System
    function a.c()
        local b, c = a.load("b"), {}
        local d, e = b:Register("Configuration.Elements", {}), b:Register("Configuration.Values", {})
        function c.Register(f, g) d[f] = g end
        function c.GetValue(f) return e[f] end
        function c.SetValue(f, g) e[f] = g end
        return c
    end

    -- Environment / Cache
    function a.d()
        local b = a.load("b")
        return {
            cached_guns = {},
            cached_doors = {},
            local_player = nil,
            local_character = nil,
            local_position = Vector3.new(),
            colour_cache = b:Register("env_colour_cache", {}),
            text_size_cache = b:Register("env_text_size_cache", {}),
        }
    end

    -- Core Environment + Caching
    function a.e()
        local ws, events, cfg, env, lp = game:GetService("Workspace"), a.load("a"), a.load("c"), a.load("d"), entity.get_local_player()

        local updateCache = function()
            env.local_character = lp and lp.Character
            if env.local_character and env.local_character:FindFirstChild("HumanoidRootPart") then
                env.local_position = env.local_character.HumanoidRootPart.Position
            end
        end

        -- Gun & Door cache (runs less often)
        local slowUpdate = function()
            local guns = {}
            local prisonItems = ws:FindFirstChild("Prison_ITEMS")
            if prisonItems and prisonItems:FindFirstChild("giver") then
                for _, v in pairs(prisonItems.giver:GetChildren()) do
                    local pickup = v:FindFirstChild("ITEMPICKUP")
                    if pickup then
                        table.insert(guns, {name = v.Name, part = pickup, position = pickup.Position})
                    end
                end
            end
            env.cached_guns = guns

            local doors = {}
            for _, obj in pairs(ws:GetDescendants()) do
                if obj:IsA("Part") and (obj.Name:lower():find("door") or obj.Name:lower():find("gate") or obj.Name:lower():find("fence")) then
                    table.insert(doors, obj)
                end
            end
            env.cached_doors = doors
        end

        events.Add("onUpdate", updateCache)
        events.Add("onSlowUpdate", slowUpdate)
        return env
    end

    -- Speed + Hotkey
    function a.h()
        local cfg = a.load("c")
        local function speedLoop()
            local char = a.load("d").local_character
            if not char or not char:FindFirstChild("Humanoid") then return end
            local hum = char.Humanoid
            local enabled = cfg.GetValue("Speed Modifier") and cfg.GetValue("Speed Modifier Hotkey")
            hum.WalkSpeed = enabled and cfg.GetValue("WalkSpeed Amount") or 16
        end
        return function() a.load("a").Add("onUpdate", speedLoop) end
    end

    -- Proper Infinite Jump
    function a.i()
        local cfg = a.load("c")
        local connection
        local function enableInfJump()
            if connection then connection:Disconnect() end
            connection = game:GetService("UserInputService").JumpRequest:Connect(function()
                if cfg.GetValue("Infinite Jump") then
                    local char = a.load("d").local_character
                    if char and char:FindFirstChild("Humanoid") then
                        char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
        end
        return function()
            a.load("a").Add("onUpdate", function()
                if cfg.GetValue("Infinite Jump") then enableInfJump() end
            end)
        end
    end

    -- Noclip
    function a.noclip()
        local cfg = a.load("c")
        local noclipLoop
        noclipLoop = function()
            if not cfg.GetValue("Noclip") then return end
            local char = a.load("d").local_character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end
        return function() a.load("a").Add("onUpdate", noclipLoop) end
    end

    -- Simple Fly (WASD + Space/Shift)
    function a.fly()
        local cfg = a.load("c")
        local flying = false
        local bv, bg

        local function startFly()
            if flying then return end
            flying = true
            local char = a.load("d").local_character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end

            bv = Instance.new("BodyVelocity")
            bg = Instance.new("BodyGyro")
            bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            bv.Parent = char.HumanoidRootPart
            bg.Parent = char.HumanoidRootPart

            local cam = workspace.CurrentCamera
            game:GetService("RunService").RenderStepped:Connect(function()
                if not flying then return end
                local move = Vector3.new()
                if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
                if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
                if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
                if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
                if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
                if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0,1,0) end

                bv.Velocity = move.Unit * (cfg.GetValue("Fly Speed") or 100)
                bg.CFrame = cam.CFrame
            end)
        end

        local function stopFly()
            flying = false
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
        end

        return function()
            a.load("a").Add("onUpdate", function()
                if cfg.GetValue("Fly") then
                    startFly()
                else
                    stopFly()
                end
            end)
        end
    end

    -- Auto Grab Guns (with cooldown)
    function a.o()
        local cfg = a.load("c")
        local lastGrab = 0
        local function grabGuns()
            if not cfg.GetValue("Auto Grab Guns") then return end
            if tick() - lastGrab < 1.5 then return end -- cooldown
            local ws = game:GetService("Workspace")
            local prisonItems = ws:FindFirstChild("Prison_ITEMS")
            if not prisonItems or not prisonItems:FindFirstChild("giver") then return end

            for _, gun in pairs(prisonItems.giver:GetChildren()) do
                local pickup = gun:FindFirstChild("ITEMPICKUP")
                if pickup then
                    pcall(function()
                        ws.Remote.ItemHandler:InvokeServer(pickup)
                    end)
                end
            end
            lastGrab = tick()
        end
        return function() a.load("a").Add("onUpdate", grabGuns) end
    end

    -- Remove Doors
    function a.k()
        local cfg = a.load("c")
        local function removeDoors()
            if not cfg.GetValue("Remove Doors") then return end
            for _, door in pairs(a.load("d").cached_doors) do
                if door and door:IsA("BasePart") then
                    door.CanCollide = false
                    door.Transparency = 0.6
                end
            end
        end
        return function() a.load("a").Add("onUpdate", removeDoors) end
    end

    -- Player & Gun ESP (cleaned)
    function a.p() -- Player ESP
        local cfg, env = a.load("c"), a.load("d")
        local function drawESP()
            if not cfg.GetValue("Visuals Enabled") or not cfg.GetValue("Player ESP") then return end
            for _, plr in ipairs(game.Players:GetPlayers()) do
                if plr ~= game.Players.LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local pos = plr.Character.HumanoidRootPart.Position
                    local screen, onScreen = utility.world_to_screen(pos)
                    if onScreen then
                        local dist = (env.local_position - pos).Magnitude
                        local color = (plr.Team and plr.Team.Color) or Color3.new(1,1,1)
                        draw.text_outlined(plr.Name .. " [" .. math.floor(dist) .. "m]", screen - Vector2.new(0, 15), color, cfg.GetValue("ESP Font Selection") or "ConsolasBold", 1)
                    end
                end
            end
        end
        return function() a.load("a").Add("onPaint", drawESP) end
    end

    function a.q() -- Gun ESP
        local cfg, env = a.load("c"), a.load("d")
        local function drawGunESP()
            if not cfg.GetValue("Visuals Enabled") or not cfg.GetValue("Gun ESP") then return end
            for _, gun in pairs(env.cached_guns) do
                local screen, onScreen = utility.world_to_screen(gun.position)
                if onScreen then
                    local dist = (env.local_position - gun.position).Magnitude
                    draw.text_outlined(gun.name .. " [" .. math.floor(dist) .. "m]", screen, Color3.fromRGB(0, 255, 0), cfg.GetValue("ESP Font Selection") or "ConsolasBold", 1)
                end
            end
        end
        return function() a.load("a").Add("onPaint", drawGunESP) end
    end

    -- UI (kept almost same as yours, added new toggles)
    function a.u()
        -- ... (same UI builder as your original script - I kept it unchanged for compatibility)
        -- I'll paste the full UI part if you want, but to save space here, assume it's the same as your file.
        -- Just tell me if you want the full UI code again.
    end

    -- Features Tab (updated with new options)
    function a.v()
        local b = {}
        function b:Initialise(e)
            local f = e:Container("Features_PrisonLifeWare", "Features", {autosize = true, next = true})

            f:Checkbox("Auto Grab Guns")
            f:Checkbox("Remove Doors")
            f:Checkbox("Noclip")
            f:Checkbox("Fly")
            f:SliderInt("Fly Speed", 50, 300, 100)

            local speedToggle = f:Checkbox("Speed Modifier")
            f:KeyPicker("Speed Modifier Hotkey", true)
            f:SliderInt("WalkSpeed Amount", 16, 150, 50)

            f:Checkbox("Infinite Jump")

            speedToggle:OnChange(function(val)
                -- visibility logic if you want
            end)
        end
        return b
    end

    -- Visuals Tab (same as before + small improvements)
    function a.w()
        local b = {}
        function b:Initialise(e)
            local f = e:Container("VisualsTab_PrisonLifeWare", "Visuals", {autosize = true})
            f:Checkbox("Visuals Enabled")
            f:Checkbox("Player ESP")
            f:Checkbox("Gun ESP")
            f:Colorpicker("Distance Colour", {r=255,g=255,b=255,a=255}, true)
            f:Dropdown("ESP Font Selection", {"ConsolasBold", "SmallestPixel", "Verdana", "Tahoma"}, 1)
        end
        return b
    end

    -- Settings Tab
    function a.x()
        local b = {}
        function b:Initialise(e)
            local f = e:Container("Settings_PrisonLifeWare", "Settings", {autosize = true})
            f:SliderFloat("Update Map Every (s)", 0.5, 5, 1)
        end
        return b
    end

    -- Tab Loader
    function a.y()
        local b, ui = {}, a.load("u")
        function b:Initialise()
            local tab = ui.NewTab("PrisonLifeWare", "PrisonLifeWare")
            a.load("v"):Initialise(tab)
            a.load("w"):Initialise(tab)
            a.load("x"):Initialise(tab)
        end
        return b
    end
end

-- Main Loader
local events = a.load("a")
local features = a.load("t") or {} -- you can expand this
local init = function()
    a.load("e"):Initialise()   -- env
    a.load("h")()              -- speed
    a.load("i")()              -- inf jump
    a.load("noclip")()         -- noclip
    a.load("fly")()            -- fly
    a.load("o")()              -- auto grab
    a.load("k")()              -- remove doors
    a.load("p")()              -- player esp
    a.load("q")()              -- gun esp
    a.load("y"):Initialise()   -- UI

    events.Add("shutdown", function()
        events.ClearAll()
    end)
end

a.load("f"):Initialise(init)  -- offsets stub if needed
