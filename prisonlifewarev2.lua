--!nocheck
--!nolint

_P = {
    genDate = "2026-04-07T12:00:00.000000000+00:00",
    cfg = "PrisonLifeRelease",
    vers = "1.2",
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
    -- ==================== CORE SYSTEMS (same style as DiddyWare) ====================
    function a.a() -- Event System
        local events = {}
        local handlers = { onPaint = {}, onUpdate = {}, onSlowUpdate = {}, shutdown = {} }

        function events.Add(name, func)
            if not handlers[name] then return nil end
            table.insert(handlers[name], func)
            return #handlers[name]
        end

        function events.Remove(name, id)
            if handlers[name] and handlers[name][id] then
                handlers[name][id] = nil
            end
        end

        function events.ClearAll()
            for k in pairs(handlers) do handlers[k] = {} end
        end

        function events:Initialise()
            for name in pairs(handlers) do
                cheat.Register(name, function(...)
                    for _, f in pairs(handlers[name]) do
                        pcall(f, ...)
                    end
                end)
            end
        end
        return events
    end

    function a.b() -- Registry
        local self = {} self.__index = self
        local store = {}
        function self:Register(name, tbl)
            tbl = tbl or {}
            store[name] = tbl
            return tbl
        end
        function self:Get(name) return store[name] end
        function self:UnloadAll() store = {} end
        return self
    end

    function a.c() -- Config
        local reg = a.load("b")
        local values = reg:Register("Config.Values", {})
        local self = {}
        function self.GetValue(k) return values[k] end
        function self.SetValue(k, v) values[k] = v end
        return self
    end

    function a.d() -- Environment
        local reg = a.load("b")
        return {
            cached_guns = {},
            cached_doors = {},
            local_character = nil,
            local_position = Vector3.new(0,0,0),
            colour_cache = reg:Register("colour_cache", {}),
            text_size_cache = reg:Register("text_size_cache", {}),
        }
    end

    -- ==================== ENVIRONMENT & CACHING ====================
    function a.e()
        local ws = game:GetService("Workspace")
        local events = a.load("a")
        local cfg = a.load("c")
        local env = a.load("d")

        events.Add("onUpdate", function()
            local lp = entity.get_local_player()
            if lp and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                env.local_character = lp.Character
                env.local_position = lp.Character.HumanoidRootPart.Position
            end
        end)

        events.Add("onSlowUpdate", function()
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
            env.cached_guns = guns

            -- Doors / Gates / Fences
            local doors = {}
            for _, obj in pairs(ws:GetDescendants()) do
                if obj:IsA("BasePart") and (obj.Name:lower():find("door") or obj.Name:lower():find("gate") or obj.Name:lower():find("fence")) then
                    table.insert(doors, obj)
                end
            end
            env.cached_doors = doors
        end)
    end

    -- ==================== FEATURES ====================
    function a.speed()
        local cfg = a.load("c")
        local events = a.load("a")
        local env = a.load("d")
        events.Add("onUpdate", function()
            if not cfg.GetValue("Speed Modifier") then return end
            local char = env.local_character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = cfg.GetValue("WalkSpeed Amount") or 50
            end
        end)
    end

    function a.infinitejump()
        local cfg = a.load("c")
        local uis = game:GetService("UserInputService")
        uis.JumpRequest:Connect(function()
            if cfg.GetValue("Infinite Jump") then
                local char = a.load("d").local_character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
    end

    function a.noclip()
        local cfg = a.load("c")
        local events = a.load("a")
        local env = a.load("d")
        events.Add("onUpdate", function()
            if not cfg.GetValue("Noclip") then return end
            local char = env.local_character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end

    function a.fly()
        local cfg = a.load("c")
        local events = a.load("a")
        local flying = false
        local bv, bg

        local function start()
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
                if not flying or not cfg.GetValue("Fly") then return end
                local move = Vector3.new()
                local uis = game:GetService("UserInputService")
                if uis:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
                if uis:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
                if uis:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
                if uis:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
                if uis:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
                if uis:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0,1,0) end

                if move.Magnitude > 0 then
                    bv.Velocity = move.Unit * (cfg.GetValue("Fly Speed") or 100)
                else
                    bv.Velocity = Vector3.new()
                end
                bg.CFrame = cam.CFrame
            end)
        end

        local function stop()
            flying = false
            if bv then bv:Destroy() bv = nil end
            if bg then bg:Destroy() bg = nil end
        end

        events.Add("onUpdate", function()
            if cfg.GetValue("Fly") then
                start()
            else
                stop()
            end
        end)
    end

    function a.autograb()
        local cfg = a.load("c")
        local last = 0
        local events = a.load("a")
        events.Add("onUpdate", function()
            if not cfg.GetValue("Auto Grab Guns") then return end
            if tick() - last < 1.2 then return end
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
            last = tick()
        end)
    end

    function a.removedoors()
        local cfg = a.load("c")
        local env = a.load("d")
        local events = a.load("a")
        events.Add("onUpdate", function()
            if not cfg.GetValue("Remove Doors") then return end
            for _, door in pairs(env.cached_doors) do
                if door and door:IsA("BasePart") then
                    door.CanCollide = false
                    door.Transparency = 0.7
                end
            end
        end)
    end

    -- ==================== ESP ====================
    function a.playeresp()
        local cfg = a.load("c")
        local env = a.load("d")
        local events = a.load("a")
        events.Add("onPaint", function()
            if not cfg.GetValue("Visuals Enabled") or not cfg.GetValue("Player ESP") then return end
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
    end

    function a.gunesp()
        local cfg = a.load("c")
        local env = a.load("d")
        local events = a.load("a")
        events.Add("onPaint", function()
            if not cfg.GetValue("Visuals Enabled") or not cfg.GetValue("Gun ESP") then return end
            for _, gun in pairs(env.cached_guns) do
                local screen, onScreen = utility.world_to_screen(gun.position)
                if onScreen then
                    local dist = (env.local_position - gun.position).Magnitude
                    draw.text_outlined(gun.name .. " ["..math.floor(dist).."m]", screen, Color3.fromRGB(0,255,100), "ConsolasBold", 1)
                end
            end
        end)
    end

    -- ==================== UI BUILDER (full version from your original style) ====================
    function a.u()
        local events = a.load("a")
        local cfg = a.load("c")
        local reg = a.load("b")
        local elements = {}
        local ui = {}

        local elementMeta = {}
        elementMeta.__index = elementMeta
        function elementMeta:Get() return cfg.GetValue(self.Name) end
        function elementMeta:Set(v)
            ui.setValue(self.Tab, self.Container, self.Name, v)
            cfg.SetValue(self.Name, v)
        end
        function elementMeta:Visible(v) ui.setVisibility(self.Tab, self.Container, self.Name, v) end

        local containerMeta = {}
        containerMeta.__index = containerMeta
        function containerMeta:Checkbox(name, default)
            ui.newCheckbox(self.Tab, self.Ref, name, default or false)
            local el = setmetatable({Tab = self.Tab, Container = self.Ref, Name = name}, elementMeta)
            cfg.SetValue(name, default or false)
            return el
        end
        function containerMeta:SliderInt(name, min, max, default)
            ui.newSliderInt(self.Tab, self.Ref, name, min, max, default)
            local el = setmetatable({Tab = self.Tab, Container = self.Ref, Name = name}, elementMeta)
            cfg.SetValue(name, default)
            return el
        end
        function containerMeta:KeyPicker(name, default)
            ui.newHotkey(self.Tab, self.Ref, name, default)
            return setmetatable({Tab = self.Tab, Container = self.Ref, Name = name}, elementMeta)
        end
        function containerMeta:Dropdown(name, options, default)
            ui.newDropdown(self.Tab, self.Ref, name, options, default)
            return setmetatable({Tab = self.Tab, Container = self.Ref, Name = name}, elementMeta)
        end

        function ui.NewTab(tabName, displayName)
            ui.newTab(tabName, displayName)
            return setmetatable({Tab = tabName, Ref = "Main"}, containerMeta)
        end

        function ui:Initialise()
            events.Add("onUpdate", function()
                -- poll values if needed (you can expand later)
            end)
        end
        return ui
    end

    -- ==================== TABS ====================
    function a.features()
        local ui = a.load("u")
        local function init(tab)
            local f = tab:Container("Features", "Features", {autosize = true})

            f:Checkbox("Auto Grab Guns", true)
            f:Checkbox("Remove Doors", false)
            f:Checkbox("Noclip", false)
            f:Checkbox("Fly", false)
            f:SliderInt("Fly Speed", 50, 300, 120)
            f:Checkbox("Speed Modifier", false)
            f:SliderInt("WalkSpeed Amount", 16, 120, 50)
            f:Checkbox("Infinite Jump", false)
        end
        return {Initialise = init}
    end

    function a.visuals()
        local ui = a.load("u")
        local function init(tab)
            local v = tab:Container("Visuals", "Visuals", {autosize = true})
            v:Checkbox("Visuals Enabled", true)
            v:Checkbox("Player ESP", true)
            v:Checkbox("Gun ESP", true)
        end
        return {Initialise = init}
    end

    function a.y() -- Tab Loader
        local ui = a.load("u")
        local function init()
            local mainTab = ui.NewTab("PrisonLifeWare", "PrisonLifeWare")
            a.features().Initialise(mainTab)
            a.visuals().Initialise(mainTab)
        end
        return {Initialise = init}
    end
end

-- ==================== MAIN INITIALIZATION ====================
local events = a.load("a")

local function main()
    a.load("e")()        -- environment
    a.speed()
    a.infinitejump()
    a.noclip()
    a.fly()
    a.autograb()
    a.removedoors()
    a.playeresp()
    a.gunesp()
    a.load("y"):Initialise()   -- UI

    events.Add("shutdown", function()
        events.ClearAll()
    end)

    print("✅ PrisonLifeWare v1.2 loaded successfully!")
end

-- Start
main()
