--!nocheck
--!nolint

_P = {
    genDate = "2026-04-07T13:00:00.000000000+00:00",
    cfg = "PrisonLifeSpecific",
    vers = "2.3",
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
    -- Event System
    function a.a()
        local handlers = { onPaint = {}, onUpdate = {}, onSlowUpdate = {}, shutdown = {} }
        local self = {}

        function self.Add(name, func)
            if not handlers[name] then return nil end
            table.insert(handlers[name], func)
            return #handlers[name]
        end

        function self.ClearAll()
            for k in pairs(handlers) do handlers[k] = {} end
        end

        function self:Initialise()
            for name in pairs(handlers) do
                cheat.Register(name, function(...)
                    for _, f in pairs(handlers[name]) do pcall(f, ...) end
                end)
            end
        end
        return self
    end

    function a.b() -- Registry
        local store = {}
        local self = {}
        self.__index = self
        function self:Register(name, tbl)
            tbl = tbl or {}
            store[name] = tbl
            return tbl
        end
        function self:Get(name) return store[name] end
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
            local_position = Vector3.new(),
            colour_cache = reg:Register("colour_cache", {}),
        }
    end

    -- Environment + Caching
    function a.e()
        local ws = game:GetService("Workspace")
        local events = a.load("a")
        local env = a.load("d")

        events.Add("onUpdate", function()
            local lp = entity.get_local_player()
            if lp and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                env.local_character = lp.Character
                env.local_position = lp.Character.HumanoidRootPart.Position
            end
        end)

        events.Add("onSlowUpdate", function()
            -- Guns from giver
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

            -- Doors, Gates, Fences
            local doors = {}
            for _, obj in pairs(ws:GetDescendants()) do
                if obj:IsA("BasePart") and (obj.Name:lower():find("door") or obj.Name:lower():find("gate") or obj.Name:lower():find("fence")) then
                    table.insert(doors, obj)
                end
            end
            env.cached_doors = doors
        end)
    end

    -- Auto Grab Guns (Prison Life specific)
    function a.autograb()
        local cfg = a.load("c")
        local events = a.load("a")
        local last = 0
        events.Add("onUpdate", function()
            if not cfg.GetValue("Auto Grab Guns") then return end
            if tick() - last < 1.5 then return end

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

    -- Remove Doors / Gates / Fences
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

    -- Player ESP
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
                        draw.text_outlined(plr.Name .. " [" .. math.floor(dist) .. "m]", screen - Vector2.new(0, 20), color, "ConsolasBold", 1)
                    end
                end
            end
        end)
    end

    -- Gun ESP
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
                    draw.text_outlined(gun.name .. " [" .. math.floor(dist) .. "m]", screen, Color3.fromRGB(0, 255, 100), "ConsolasBold", 1)
                end
            end
        end)
    end

    -- Full UI Builder (fixed & working style from your original DiddyWare)
    function a.u()
        local events = a.load("a")
        local cfg = a.load("c")
        local ui = {}

        local element = {}
        element.__index = element
        function element:Get() return cfg.GetValue(self.Name) end
        function element:Set(v)
            ui.setValue(self.TabRef, self.ContainerRef, self.Name, v)
            cfg.SetValue(self.Name, v)
        end
        function element:Visible(v)
            ui.setVisibility(self.TabRef, self.ContainerRef, self.Name, v)
        end

        local container = {}
        container.__index = container
        function container:Checkbox(name, default)
            ui.newCheckbox(self.TabRef, self.Ref, name, default or false)
            local el = setmetatable({TabRef = self.TabRef, ContainerRef = self.Ref, Name = name}, element)
            cfg.SetValue(name, default or false)
            return el
        end
        function container:SliderInt(name, min, max, default)
            ui.newSliderInt(self.TabRef, self.Ref, name, min, max, default)
            local el = setmetatable({TabRef = self.TabRef, ContainerRef = self.Ref, Name = name}, element)
            cfg.SetValue(name, default)
            return el
        end

        function ui.NewTab(tabName, displayName)
            ui.newTab(tabName, displayName)
            return setmetatable({TabRef = tabName, Ref = "Main"}, container)
        end

        function ui:Initialise()
            events.Add("onUpdate", function() end) -- placeholder for polling if needed
        end
        return ui
    end

    -- Tabs
    function a.features()
        local ui = a.load("u")
        local function init(tab)
            local f = tab:Container("Features", "Features", {autosize = true})
            f:Checkbox("Auto Grab Guns", true)
            f:Checkbox("Remove Doors", false)
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

    function a.y()
        local ui = a.load("u")
        local function init()
            local tab = ui.NewTab("PrisonLifeWare", "PrisonLifeWare")
            a.features().Initialise(tab)
            a.visuals().Initialise(tab)
        end
        return {Initialise = init}
    end
end

-- Main
local events = a.load("a")

local function main()
    a.load("e")()
    a.autograb()
    a.removedoors()
    a.playeresp()
    a.gunesp()
    a.load("y"):Initialise()

    events.Add("shutdown", function()
        events.ClearAll()
    end)

    print("✅ PrisonLifeWare v2.3 (Specific Features) loaded!")
end

main()
