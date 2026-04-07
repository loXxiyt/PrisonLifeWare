--!nocheck
--!nolint

_P = {
    genDate = "2026-04-07T14:45:00.000000000+00:00",
    cfg = "PrisonLifeSpecific",
    vers = "2.5",
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
    -- Event System (exact same as your first DiddyWare)
    function a.a()
        local b, c, d = {}, {}, { "onPaint", "onUpdate", "onSlowUpdate", "shutdown" }
        for e, f in ipairs(d) do c[f] = {} end

        function b.Add(e, f)
            if type(e) ~= "string" or type(f) ~= "function" then return nil end
            if not c[e] then return nil end
            local g = #c[e] + 1
            c[e][g] = f
            return g
        end

        function b.ClearAll()
            for e, f in pairs(c) do c[e] = {} end
        end

        local call = function(e, ...)
            for f, g in pairs(c[e]) do g(...) end
        end

        function b:Initialise()
            for f, g in ipairs(d) do
                cheat.Register(g, function(...) call(g, ...) end)
            end
        end
        return b
    end

    function a.b()
        local b = {} b.__index = b local c = {}
        function b:Register(d, e) e = e or {} c[d] = e return e end
        function b:Get(d) return c[d] end
        function b:UnloadAll() c = {} end
        return b
    end

    function a.c()
        local b, c = a.load("b"), {}
        local d, e = b:Register("Configuration.Elements", {}), b:Register("Configuration.Values", {})
        function c.Register(f, g) d[f] = g end
        function c.GetValue(f) return e[f] end
        function c.SetValue(f, g) e[f] = g end
        return c
    end

    function a.d()
        local b = a.load("b")
        return {
            cached_guns = {},
            cached_doors = {},
            local_position = Vector3.new(0,0,0),
            colour_cache = b:Register("env_colour_cache", {}),
            text_size_cache = b:Register("env_text_size_cache", {}),
        }
    end

    -- Environment + Caching
    function a.e()
        local ws, events, cfg, env = game:GetService("Workspace"), a.load("a"), a.load("c"), a.load("d")

        events.Add("onUpdate", function()
            local lp = entity.get_local_player()
            if lp and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                env.local_position = lp.Character.HumanoidRootPart.Position
            end
        end)

        events.Add("onSlowUpdate", function()
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
    end

    -- Auto Grab Guns (Prison Life specific)
    function a.o()
        local cfg = a.load("c")
        local last = 0
        local events = a.load("a")
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

    -- Remove Doors
    function a.k()
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
    function a.p()
        local cfg, env = a.load("c"), a.load("d")
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
                        draw.text_outlined(plr.Name .. " ["..math.floor(dist).."m]", screen - Vector2.new(0,20), color, cfg.GetValue("ESP Font Selection") or "ConsolasBold", 1)
                    end
                end
            end
        end)
    end

    -- Gun ESP
    function a.q()
        local cfg, env = a.load("c"), a.load("d")
        local events = a.load("a")
        events.Add("onPaint", function()
            if not cfg.GetValue("Visuals Enabled") or not cfg.GetValue("Gun ESP") then return end
            for _, gun in pairs(env.cached_guns) do
                local screen, onScreen = utility.world_to_screen(gun.position)
                if onScreen then
                    local dist = (env.local_position - gun.position).Magnitude
                    draw.text_outlined(gun.name .. " ["..math.floor(dist).."m]", screen, Color3.fromRGB(0,255,100), cfg.GetValue("ESP Font Selection") or "ConsolasBold", 1)
                end
            end
        end)
    end

    -- UI Builder (exact same as your original DiddyWare)
    function a.u()
        local b, c, d, e = a.load("a"), a.load("c"), a.load("b"), {}
        e.DebugMode = false
        local f, g, h = d:Register("UI.Elements", {}), d:Register("UI.DebugElements", {}), {}
        h.__index = h
        function h:Get() return c.GetValue(self.Name) end
        function h:Set(i)
            ui.setValue(self.TabRef, self.ContainerRef, self.Name, i)
            c.SetValue(self.Name, i)
        end
        function h:Visible(i) ui.setVisibility(self.TabRef, self.ContainerRef, self.Name, i) end

        local i, j = function(i, j, k, l)
            local m = setmetatable({ TabRef = i, ContainerRef = j, Name = k, Debug = l and l.Debug }, h)
            c.Register(k, m)
            f[k] = m
            if m.Debug then m:Visible(false) g[#g+1] = m end
            return m
        end, {}

        j.__index = j
        function j:Checkbox(k, l, m)
            ui.newCheckbox(self.TabRef, self.Ref, k, l)
            return i(self.TabRef, self.Ref, k, m)
        end
        function j:Dropdown(k, l, m, n)
            ui.newDropdown(self.TabRef, self.Ref, k, l, m)
            return i(self.TabRef, self.Ref, k, n)
        end

        local k = {} k.__index = k
        function k:Container(l, m, n)
            ui.newContainer(self.Ref, l, m, n or {})
            return setmetatable({ TabRef = self.Ref, Ref = l }, j)
        end

        function e.NewTab(l, m)
            ui.newTab(l, m)
            return setmetatable({ Ref = l }, k)
        end

        function e:Initialise()
            b.Add("onUpdate", function()
                for l, m in next, f do
                    if m._Poll then m:_Poll() end
                end
            end)
        end
        return e
    end

    -- Features Tab
    function a.v()
        local b = {}
        function b:Initialise(e)
            local f = e:Container("Features_PrisonLifeWare", "Features", {autosize = true, next = true})
            f:Checkbox("Auto Grab Guns", true)
            f:Checkbox("Remove Doors", false)
        end
        return b
    end

    -- Visuals Tab
    function a.w()
        local b = {}
        function b:Initialise(e)
            local f = e:Container("VisualsTab_PrisonLifeWare", "Visuals", {autosize = true, next = true})
            f:Checkbox("Visuals Enabled", true)
            f:Checkbox("Player ESP", true)
            f:Checkbox("Gun ESP", true)
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

    function a.y()
        local b, c, d, e, f = {}, a.load("u"), a.load("v"), a.load("w"), a.load("x")
        function b:Initialise()
            local g = c.NewTab("PrisonLifeWare", "PrisonLifeWare")
            d:Initialise(g)
            e:Initialise(g)
            f:Initialise(g)
        end
        return b
    end
end

-- Main
local events = a.load("a")

local function main()
    a.load("e")()
    a.o()  -- Auto Grab Guns
    a.k()  -- Remove Doors
    a.p()  -- Player ESP
    a.q()  -- Gun ESP
    a.load("y"):Initialise()

    events.Add("shutdown", function()
        events.ClearAll()
    end)

    print("✅ PrisonLifeWare Specific v2.5 loaded successfully!")
end

main()
