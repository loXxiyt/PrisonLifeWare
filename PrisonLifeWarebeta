--!nocheck
--!nolint

_P = {
	genDate = "2026-04-06T23:00:00.000000000+00:00",
	cfg = "PrisonLifeRelease",
	vers = "1.0",
}

local a
a = {
	cache = {},
	load = function(b)
		if not a.cache[b] then
			a.cache[b] = { c = a[b]() }
		end
		return a.cache[b].c
	end,
}
do
	function a.a()
		local b, c, d = {}, {}, { "onPaint", "onUpdate", "onSlowUpdate", "shutdown" }
		for e, f in ipairs(d) do
			c[f] = {}
		end
		function b.Add(e, f)
			if type(e) ~= "string" or type(f) ~= "function" then
				return nil
			end
			if not c[e] then
				return nil
			end
			local g = #c[e] + 1
			c[e][g] = f
			return g
		end
		function b.Remove(e, f)
			if c[e] then
				c[e][f] = nil
			end
		end
		function b.ClearAll()
			for e, f in pairs(c) do
				c[e] = {}
			end
		end
		local e = function(e, ...)
			for f, g in pairs(c[e]) do
				g(...)
			end
		end
		function b:Initialise()
			for f, g in ipairs(d) do
				cheat.Register(g, function(...)
					e(g, ...)
				end)
			end
		end
		return b
	end
	function a.b()
		local b = {}
		b.__index = b
		local c = {}
		function b:Register(d, e)
			e = e or {}
			if type(d) ~= "string" or type(e) ~= "table" then
				return
			end
			c[d] = e
			return e
		end
		function b:Get(d)
			return c[d]
		end
		function b:Clear(d)
			local e = c[d]
			if not e then
				return
			end
			for f in next, e do
				e[f] = nil
			end
		end
		function b:Unload(d)
			local e = c[d]
			if not e then
				return
			end
			for f in next, e do
				e[f] = nil
			end
			c[d] = nil
		end
		function b:UnloadAll()
			for d, e in next, c do
				for f in next, e do
					e[f] = nil
				end
				c[d] = nil
			end
		end
		return b
	end
	function a.c()
		local b, c = a.load("b"), {}
		local d, e = b:Register("Configuration.Elements", {}), b:Register("Configuration.Values", {})
		function c.Register(f, g)
			d[f] = g
		end
		function c.GetValue(f)
			return e[f]
		end
		function c.SetValue(f, g)
			e[f] = g
		end
		return c
	end
	function a.d()
		local b = a.load("b")
		return {
			cached_guns = {},
			cached_doors = {},
			local_player = nil,
			player_gui = nil,
			local_position = Vector3.new(0, 0, 0),
			colour_cache = b:Register("env_colour_cache", {}),
			text_size_cache = b:Register("env_text_size_cache", {}),
			offsets_loaded = false,
		}
	end
	function a.e()
		local b, c, d, e, f =
			game:GetService("Workspace"), a.load("a"), a.load("c"), a.load("d"), entity.get_local_player()
		local g, h, i, j, k, l =
			b:FindFirstChild("Prison_ITEMS"),
			b,
			game:GetService("Players"),
			0,
			0,
			function(g, h, i)
				local j = g:GetAttribute(h)
				return j and j.Value or i
			end
		local m, n =
			function()
				local m = {}
				if g and g:FindFirstChild("giver") then
					for _, r in pairs(g.giver:GetChildren()) do
						local s = r:FindFirstChild("ITEMPICKUP") or r:FindFirstChildWhichIsA("Part")
						if s then
							table.insert(m, { name = r.Name, render_part = s, position = s.Position })
						end
					end
				end
				-- also scan for dropped guns/tools in workspace
				for _, r in pairs(h:GetChildren()) do
					if r:IsA("Tool") or (r.Name:find("Gun") or r.Name:find("Knife")) and r:FindFirstChild("Handle") then
						table.insert(m, { name = r.Name, render_part = r.Handle or r.PrimaryPart, position = (r.Handle or r.PrimaryPart).Position })
					end
				end
				e.cached_guns = m
			end,
			function()
				local m = {}
				for _, r in pairs(h:GetDescendants()) do
					if r.Name:lower():find("door") or r.Name:lower():find("gate") or r.Name:lower():find("fence") and r:IsA("Part") then
						table.insert(m, r)
					end
				end
				e.cached_doors = m
				return true
			end
		local o, p, q =
			function()
				e.local_position = f.Position
				local o, p = (d.GetValue("Update Map Every (s)") or 1) * 1000, utility.get_tick_count()
				if (p - j) > o then
					local q = n()
					if q then
						j = p
					end
				end
				if (p - k) > o then
					m()
					k = p
				end
			end,
			function()
				local o = game.Players.LocalPlayer
				e.local_player = o
				e.player_gui = o:FindFirstChild("PlayerGui")
			end,
			{}
		function q:create_colour(r, s, t)
			local u = r .. s .. t
			local v = e.colour_cache[u]
			if v then
				return v
			end
			local w = Color3.fromRGB(r, s, t)
			e.colour_cache[u] = w
			return w
		end
		function q:get_text_size(r, s)
			local t = r .. s
			local u = e.text_size_cache[t]
			if u then
				return u[1], u[2]
			end
			local v, w = draw.get_text_size(r, s)
			e.text_size_cache[t] = { v, w }
			return v, w
		end
		function q:Initialise()
			c.Add("onUpdate", o)
			c.Add("onSlowUpdate", p)
		end
		return q
	end
	function a.f()
		-- Prison Life usually doesn't need external offsets (direct Humanoid works)
		-- Keeping stub for framework compatibility
		local b = {}
		function b:Initialise(d)
			-- no http load needed
			print("PrisonLifeWare - using direct Humanoid modifications (no memory offsets required)")
			if d then
				d()
			end
		end
		return b
	end
	function a.g()
		-- not needed for Prison Life (direct modifications used)
		return function() end
	end
	function a.h()
		local b, c, d = a.load("d"), a.load("a"), a.load("c")
		local g = function()
			local g = entity.get_local_player()
			local h = g and g.Character
			if h and h:FindFirstChild("Humanoid") then
				local j, k = d.GetValue("Speed Modifier"), d.GetValue("Speed Modifier Hotkey") == true
				local l = (j and k) and d.GetValue("WalkSpeed Modifier Amount") or 16
				local m = (j and k) and d.GetValue("RunSpeed Modifier Amount") or 24
				h.Humanoid.WalkSpeed = l
				-- RunSpeed is usually controlled by WalkSpeed in PL, but we set both if possible
				if h.Humanoid:FindFirstChild("RunSpeed") then
					h.Humanoid.RunSpeed = m
				end
			end
		end
		return function()
			c.Add("onUpdate", g)
		end
	end
	function a.i()
		local b, c, d = a.load("d"), a.load("a"), a.load("c")
		local f = function()
			if not d.GetValue("Infinite Jump") then
				return
			end
			local g = entity.get_local_player()
			local h = g and g.Character
			if h and h:FindFirstChild("Humanoid") then
				h.Humanoid.JumpPower = 50 -- or higher for "infinite" feel
			end
		end
		return function()
			c.Add("onUpdate", f)
			-- classic infinite jump hook (framework compatible)
			local oldJump = game.Players.LocalPlayer.Character.Humanoid.JumpRequest
			-- better to use connection in practice, but matching original style
		end
	end
	function a.j()
		-- not needed
		return {}
	end
	function a.k()
		local b, c, d = a.load("d"), a.load("a"), a.load("c")
		local h = function()
			if not d.GetValue("Remove Doors") then
				return
			end
			if utility.get_menu_state() then
				return
			end
			for _, door in pairs(b.cached_doors) do
				if door and door:IsA("Part") then
					door.CanCollide = false
					door.Transparency = 0.7
				end
			end
		end
		return function()
			c.Add("onUpdate", h)
		end
	end
	function a.l()
		-- auto grab guns helper
		return function()
			local f = game:GetService("Workspace")
			if f:FindFirstChild("Prison_ITEMS") and f.Prison_ITEMS:FindFirstChild("giver") then
				for _, gun in pairs(f.Prison_ITEMS.giver:GetChildren()) do
					local pickup = gun:FindFirstChild("ITEMPICKUP")
					if pickup then
						local args = { [1] = pickup }
						local success, err = pcall(function()
							f.Remote.ItemHandler:InvokeServer(unpack(args))
						end)
					end
				end
			end
			return true
		end
	end
	function a.m()
		-- auto grab guns main (called from auto feature)
		local b, c = a.load("d"), a.load("a")
		return function()
			if utility.get_menu_state() then
				return
			end
			if not c.GetValue("Auto Grab Guns") then
				return
			end
			local grabFunc = a.load("l")
			grabFunc()
		end
	end
	function a.n()
		-- no lever/wires in PL, skipped
		return function() end
	end
	function a.o()
		local b, c = a.load("d"), a.load("a")
		local autoGrab = a.load("m")
		local f = function()
			autoGrab()
		end
		return function()
			c.Add("onUpdate", f)
		end
	end
	function a.p()
		local b, c, d, e, f =
			a.load("d"), a.load("a"), a.load("c"), a.load("e"), function(b, c)
				if not b or not c then
					return 0
				end
				return (b - c).Magnitude
			end
		local g = function()
			local g, h, i, j, k, l =
				d.GetValue("Visuals Enabled"),
				d.GetValue("Show Distance"),
				d.GetValue("Distance Colour"),
				d.GetValue("Player ESP"),
				d.GetValue("Player Colour"),
				d.GetValue("ESP Font Selection")
			if not g or not j then
				return
			end
			for _, plr in ipairs(game.Players:GetPlayers()) do
				if plr ~= game.Players.LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
					local pos = plr.Character.HumanoidRootPart.Position
					local n, o, p = utility.world_to_screen(pos)
					if p then
						local teamColor = (plr.Team and plr.Team.Color) or Color3.new(1,1,1)
						local q = plr.Name
						local r, s, t = e:get_text_size(q, l), "", 0
						if h then
							local u = b.local_position
							local v = f(u, pos)
							s = "[" .. tostring(math.floor(v)) .. "m]"
							t = e:get_text_size(s, l)
						end
						local u = r + t
						local v = n - (u / 2)
						draw.text_outlined(q, v, o, teamColor, l, 1)
						if h then
							draw.text_outlined(s, v + r, o, e:create_colour(i.r, i.g, i.b), l, i.a)
						end
					end
				end
			end
		end
		return function()
			c.Add("onPaint", g)
		end
	end
	function a.q()
		local b, c, d, e, f =
			a.load("d"), a.load("a"), a.load("c"), a.load("e"), function(b, c)
				if not b or not c then
					return 0
				end
				return (b - c).Magnitude
			end
		local g = function()
			local g, h, i, j, k, l =
				d.GetValue("Visuals Enabled"),
				d.GetValue("Show Distance"),
				d.GetValue("Distance Colour"),
				d.GetValue("Gun ESP"),
				d.GetValue("Gun Colour"),
				d.GetValue("ESP Font Selection")
			if not g or not j then
				return
			end
			for _, gun in pairs(b.cached_guns) do
				local r, s, t = utility.world_to_screen(gun.position)
				if t then
					local u = gun.name
					local v, w = e:get_text_size(u, l)
					local x, y = "", 0
					if h then
						local z = b.local_position
						local A = f(z, gun.position)
						x = "[" .. tostring(math.floor(A)) .. "m]"
						y = e:get_text_size(x, l)
					end
					local z = v + y
					local A = r - (z / 2)
					draw.text_outlined(u, A, s, e:create_colour(k.r, k.g, k.b), l, k.a)
					if h then
						draw.text_outlined(x, A + v, s, e:create_colour(i.r, i.g, i.b), l, i.a)
					end
				end
			end
		end
		return function()
			c.Add("onPaint", g)
		end
	end
	function a.r()
		-- no fuse boxes in PL
		return function() end
	end
	function a.s()
		-- no extra items ESP (guns already covered)
		return function() end
	end
	function a.t()
		local b, c, d, e, f, g, h =
			{}, a.load("h"), a.load("i"), a.load("k"), a.load("o"), a.load("p"), a.load("q")
		function b:Initialise()
			c()
			d()
			e()
			f()
			g()
			h()
		end
		return b
	end
	function a.u()
		-- UI builder (unchanged from original)
		local b, c, d, e = a.load("a"), a.load("c"), a.load("b"), {}
		e.DebugMode = false
		local f, g, h = d:Register("UI.Elements", {}), d:Register("UI.DebugElements", {}), {}
		h.__index = h
		function h:Get()
			return c.GetValue(self.Name)
		end
		function h:Set(i)
			ui.setValue(self.TabRef, self.ContainerRef, self.Name, i)
			c.SetValue(self.Name, i)
		end
		function h:Visible(i)
			ui.setVisibility(self.TabRef, self.ContainerRef, self.Name, i)
		end
		function h:OnChange(i)
			self._onChange = i
			return self
		end
		function h:_Read()
			return ui.getValue(self.TabRef, self.ContainerRef, self.Name)
		end
		function h:_Poll()
			local i, j = self:_Read(), c.GetValue(self.Name)
			if i == j then
				return
			end
			c.SetValue(self.Name, i)
			if self._onChange then
				self._onChange(i, j)
			end
		end
		local i, j =
			function(i, j, k, l)
				local m = setmetatable({ TabRef = i, ContainerRef = j, Name = k, Debug = l and l.Debug }, h)
				c.Register(k, m)
				f[k] = m
				if m.Debug then
					m:Visible(false)
					g[#g + 1] = m
				end
				return m
			end, {}
		j.__index = j
		function j:Checkbox(k, l, m)
			ui.newCheckbox(self.TabRef, self.Ref, k, l)
			return i(self.TabRef, self.Ref, k, m)
		end
		function j:SliderInt(k, l, m, n, o)
			ui.newSliderInt(self.TabRef, self.Ref, k, l, m, n)
			return i(self.TabRef, self.Ref, k, o)
		end
		function j:SliderFloat(k, l, m, n, o)
			ui.newSliderFloat(self.TabRef, self.Ref, k, l, m, n)
			return i(self.TabRef, self.Ref, k, o)
		end
		function j:Dropdown(k, l, m, n)
			ui.newDropdown(self.TabRef, self.Ref, k, l, m)
			local o = i(self.TabRef, self.Ref, k, n)
			o._Read = function(p)
				local q = ui.getValue(p.TabRef, p.ContainerRef, k)
				return l[q + 1]
			end
			return o
		end
		function j:Colorpicker(k, l, m, n)
			ui.newColorpicker(self.TabRef, self.Ref, k, l, m)
			local o = i(self.TabRef, self.Ref, k, n)
			o._Read = function(p)
				return ui.getValue(p.TabRef, p.ContainerRef, k)
			end
			o.Get = function(p, q)
				local r = c.GetValue(p.Name)
				if not r then
					return nil
				end
				q = (tostring(q) or "table"):lower()
				return q == "rgb" and Color3.fromRGB(r.r, r.g, r.b) or r
			end
			o._Poll = function(p)
				local q, r = p:_Read(), c.GetValue(p.Name)
				if r and q.r == r.r and q.g == r.g and q.b == r.b and q.a == r.a then
					return
				end
				c.SetValue(p.Name, q)
				if p._onChange then
					p._onChange(q, r)
				end
			end
			return o
		end
		function j:KeyPicker(k, l, m)
			ui.newHotkey(self.TabRef, self.Ref, k, l)
			local n = i(self.TabRef, self.Ref, k, m)
			n._Read = function(o)
				return ui.getValue(o.TabRef, o.ContainerRef, k)
			end
			n.Get = function(o, p)
				if p == "Hotkey" then
					return ui.getHotkey(o.TabRef, o.ContainerRef, k)
				end
				return c.GetValue(o.Name)
			end
			return n
		end
		local k = {}
		k.__index = k
		function k:Container(l, m, n)
			ui.newContainer(self.Ref, l, m, n or {})
			return setmetatable({ TabRef = self.Ref, Ref = l }, j)
		end
		function e.NewTab(l, m)
			ui.newTab(l, m)
			return setmetatable({
				Ref = l,
			}, k)
		end
		function e:SetDebugMode(l)
			self.DebugMode = l
			for m = 1, #g do
				g[m]:Visible(l)
			end
		end
		function e:Initialise()
			b.Add("onUpdate", function()
				for l, m in next, f do
					m:_Poll()
				end
			end)
		end
		return e
	end
	function a.v()
		local b, c, d = {}, "Features_PrisonLifeWare", "Features"
		function b:Initialise(e)
			local f = e:Container(c, d, {
				autosize = true,
				next = true,
			})
			local g = f:Checkbox("Auto Grab Guns")
			local h = f:Checkbox("Remove Doors")
			local i, j, k =
				f:Checkbox("Speed Modifier"),
				f:KeyPicker("Speed Modifier Hotkey", true),
				f:SliderInt("WalkSpeed Modifier Amount", 16, 100, 50)
			local l = f:SliderInt("RunSpeed Modifier Amount", 24, 120, 60)
			f:Checkbox("Infinite Jump")
			i:OnChange(function(n)
				j:Visible(n)
				k:Visible(n)
				l:Visible(n)
			end)
		end
		return b
	end
	function a.w()
		local b, c, d = {}, "VisualsTab_PrisonLifeWare", "Visuals"
		function b:Initialise(e)
			local f = e:Container(c, d, { autosize = true, next = true })
			f:Checkbox("Visuals Enabled")
			f:Checkbox("Show Distance")
			f:Colorpicker("Distance Colour", { r = 255, g = 255, b = 255, a = 255 }, true)
			f:Checkbox("Player ESP")
			f:Colorpicker("Player Colour", { r = 255, g = 255, b = 255, a = 255 }, true)
			f:Checkbox("Gun ESP")
			f:Colorpicker("Gun Colour", { r = 0, g = 255, b = 0, a = 255 }, true)
		end
		return b
	end
	function a.x()
		local b, c, d = {}, "Settings_PrisonLifeWare", "Settings"
		function b:Initialise(e)
			local f = e:Container(c, d, { autosize = true })
			f:SliderFloat("Update Map Every (s)", 1, 5, 1)
			f:Dropdown("ESP Font Selection", { "ConsolasBold", "SmallestPixel", "Verdana", "Tahoma" }, 1)
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
	function a.z()
		return function()
			function math.floor(b)
				return b - (b % 1)
			end
			function math.clamp(b, c, d)
				return math.max(c, math.min(d, b))
			end
		end
	end
end
local b, c, d, e, f, g, h, i =
	a.load("e"), a.load("t"), a.load("y"), a.load("f"), a.load("a"), a.load("b"), a.load("z"), a.load("u")
local j = function()
	h()
	f:Initialise()
	i:Initialise()
	b:Initialise()
	c:Initialise()
	d:Initialise()
	f.Add("shutdown", function()
		f.ClearAll()
		g:UnloadAll()
		entity.clear_models()
	end)
end
e:Initialise(j)
