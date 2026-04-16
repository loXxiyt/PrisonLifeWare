-- ╔══════════════════════════════════════════════════╗
--   PrisonLifeWare v3  |  loXxiyt
-- ╚══════════════════════════════════════════════════╝

local VERSION = "v3"

local T  = "PLWare"
local CE = "ESP"
local CT = "TPS"
local CG = "GUARD"
local CI = "INMATE"
local CM = "MISC"

-- ══════════════════════════════════════════════════
--  UI
-- ══════════════════════════════════════════════════

ui.newTab(T, "PrisonLifeWare")
ui.NewContainer(T, CE, "Item ESP",  { autosize = true, next = true })
ui.NewContainer(T, CT, "Teleports", { autosize = true, next = true })
ui.NewContainer(T, CG, "Guard",     { autosize = true, next = true })
ui.NewContainer(T, CI, "Inmate",    { autosize = true, next = true })
ui.NewContainer(T, CM, "Misc",      { autosize = true })

-- ══════════════════════════════════════════════════
--  SCHEDULER
-- ══════════════════════════════════════════════════

local sched = { tasks = {}, ivs = {} }

function sched.after(ms, fn)
    table.insert(sched.tasks, { t = utility.GetTickCount() + ms, fn = fn })
end
function sched.every(ms, fn)
    table.insert(sched.ivs, { d = ms, last = utility.GetTickCount(), fn = fn })
end
function sched.tick()
    local now = utility.GetTickCount()
    for i = #sched.tasks, 1, -1 do
        local t = sched.tasks[i]
        if now >= t.t then t.fn(); table.remove(sched.tasks, i) end
    end
    for _, iv in ipairs(sched.ivs) do
        if now - iv.last >= iv.d then iv.last = now; iv.fn() end
    end
end

-- ══════════════════════════════════════════════════
--  CORE HELPERS
-- ══════════════════════════════════════════════════

local function now() return utility.GetTickCount() end

-- Use entity.GetLocalPlayer() — confirmed working in all tests
local function glp() return entity.GetLocalPlayer() end

local function char()
    local p = glp(); if not p then return nil end
    local ok, r = pcall(function()
        return game.Workspace:FindFirstChild(p.Name)
    end)
    return ok and r or nil
end

local function hrp()
    local c = char(); if not c then return nil end
    local ok, r = pcall(function()
        return c:FindFirstChild("HumanoidRootPart")
    end)
    return ok and r or nil
end

local function wait_ms(ms)
    local s = now()
    while now() - s < ms do end
end

-- Reliable 3-shot teleport
local function tp(x, y, z)
    local h = hrp(); if not h then return end
    local v = Vector3.new(x, y, z)
    h.Position = v; wait_ms(40)
    h.Position = v; wait_ms(40)
    h.Position = v
end

local function part_of(obj)
    return obj:FindFirstChild("Handle")
        or obj:FindFirstChild("Mesh")
        or obj:FindFirstChildOfClass("MeshPart")
        or obj:FindFirstChildOfClass("Part")
end

local function cuffs()
    local c = char(); if not c then return false end
    local t = c:FindFirstChildOfClass("Tool")
    if not t then return false end
    local n = string.lower(t.Name)
    return n == "handcuffs" or n == "menottes"
end

local function is_crim(p)
    return p.Team and string.find(string.lower(p.Team), "criminal") ~= nil
end

local WEAPONS = {
    ["AK-47"]=true,    ["Remington 870"]=true, ["Taser"]=true,
    ["M9"]=true,       ["FAL"]=true,           ["M700"]=true,
    ["MP5"]=true,      ["M4A1"]=true,          ["Revolver"]=true,
    ["C4 Explosive"]=true, ["Crude Knife"]=true,
    ["Hammer"]=true,   ["EBR"]=true,
}

local function armed_inmate(p)
    local c = game.Workspace:FindFirstChild(p.Name)
    if not c then return false end
    local t = c:FindFirstChildOfClass("Tool")
    return t and WEAPONS[t.Name] == true
end

local function valid_target(p)
    return p.IsAlive and (is_crim(p) or armed_inmate(p))
end

local function has_cuffs_on(p)
    local c = game.Workspace:FindFirstChild(p.Name)
    if not c then return false end
    local t = c:FindFirstChildOfClass("Tool")
    if not t then return false end
    local n = string.lower(t.Name)
    return n == "handcuffs" or n == "menottes"
end

-- Aim at player using Serotonin SilentAim and left click
local function click_on(p)
    local bp = p:GetBonePosition("HumanoidRootPart")
            or p:GetBonePosition("Torso")
            or p.Position
    local sx, sy, vis = utility.WorldToScreen(bp)
    if not vis then return false end
    game.SilentAim(sx, sy)
    mouse.Click("leftmouse")
    return true
end

-- ══════════════════════════════════════════════════
--  ITEM ESP
-- ══════════════════════════════════════════════════

ui.NewCheckbox(T, CE, "Key Card ESP")
ui.NewCheckbox(T, CE, "Weapon ESP")
ui.NewColorpicker(T, CE, "Card Color",   { r=0,   g=220, b=255, a=255 }, true)
ui.NewColorpicker(T, CE, "Weapon Color", { r=255, g=140, b=0,   a=255 }, true)
ui.newSliderInt(T, CE, "ESP Range", 50, 2000, 800)

local CARDS = { ["Key card"]=true, ["Key Card"]=true }
local GUNS  = {
    ["AK-47"]=true,    ["Remington 870"]=true, ["Taser"]=true,
    ["M9"]=true,       ["FAL"]=true,           ["M700"]=true,
    ["MP5"]=true,      ["M4A1"]=true,          ["Revolver"]=true,
    ["C4 Explosive"]=true, ["Riot Shield"]=true,
    ["Crude Knife"]=true,  ["Hammer"]=true,    ["EBR"]=true,
}

local esp_cards = {}
local esp_guns  = {}

local function refresh_esp()
    esp_cards = {}
    esp_guns  = {}
    local c_on = ui.getValue(T, CE, "Key Card ESP")
    local g_on = ui.getValue(T, CE, "Weapon ESP")
    if not c_on and not g_on then return end
    local max_d = ui.getValue(T, CE, "ESP Range")
    local cam   = game.CameraPosition
    local ok, ch = pcall(function() return game.Workspace:GetChildren() end)
    if not ok then return end
    for _, obj in pairs(ch) do
        if obj.ClassName == "Model" or obj.ClassName == "Tool" then
            local p = part_of(obj)
            if p then
                local pos  = p.Position
                local dist = cam and (cam - pos).Magnitude or 0
                if dist <= max_d then
                    if c_on and CARDS[obj.Name] then
                        table.insert(esp_cards, { pos=pos, dist=dist })
                    elseif g_on and GUNS[obj.Name] then
                        table.insert(esp_guns, { pos=pos, dist=dist, name=obj.Name })
                    end
                end
            end
        end
    end
end

local function draw_esp()
    local c_on = ui.getValue(T, CE, "Key Card ESP")
    local g_on = ui.getValue(T, CE, "Weapon ESP")
    if not c_on and not g_on then return end
    local cc  = ui.getValue(T, CE, "Card Color")
    local gc  = ui.getValue(T, CE, "Weapon Color")
    local cc3 = Color3.fromRGB(cc.r, cc.g, cc.b)
    local gc3 = Color3.fromRGB(gc.r, gc.g, gc.b)

    local function render(e, label, col)
        local sx, sy, vis = utility.WorldToScreen(e.pos)
        if not vis then return end
        -- Corner-tick box (no filled bg = cleaner)
        local hw, k = 14, 5
        draw.Line(sx-hw, sy-hw, sx-hw+k, sy-hw,   col, 2)
        draw.Line(sx-hw, sy-hw, sx-hw,   sy-hw+k, col, 2)
        draw.Line(sx+hw, sy-hw, sx+hw-k, sy-hw,   col, 2)
        draw.Line(sx+hw, sy-hw, sx+hw,   sy-hw+k, col, 2)
        draw.Line(sx-hw, sy+hw, sx-hw+k, sy+hw,   col, 2)
        draw.Line(sx-hw, sy+hw, sx-hw,   sy+hw-k, col, 2)
        draw.Line(sx+hw, sy+hw, sx+hw-k, sy+hw,   col, 2)
        draw.Line(sx+hw, sy+hw, sx+hw,   sy+hw-k, col, 2)
        -- Label above box
        local tw, th = draw.GetTextSize(label, "Tahoma")
        draw.TextOutlined(label, sx-(tw/2), sy-hw-th-2, col, "Tahoma")
        -- Distance below box
        local ds = string.format("%.0fm", e.dist)
        local dw, _ = draw.GetTextSize(ds, "Tahoma")
        draw.TextOutlined(ds, sx-(dw/2), sy+hw+2, Color3.fromRGB(160,160,160), "Tahoma")
    end

    if c_on then for _, e in pairs(esp_cards) do render(e, "CARD",  cc3) end end
    if g_on then for _, e in pairs(esp_guns)  do render(e, e.name, gc3) end end
end

-- ══════════════════════════════════════════════════
--  TELEPORTS
-- ══════════════════════════════════════════════════

local LOC_NAMES = {
    "Armory", "Criminal Base", "Prison Yard",
    "Cells",  "Cafeteria",     "Outside Gate",
}
local LOCS = {
    ["Armory"]        = { 816.5,  100.7, 2227.9 },
    ["Criminal Base"] = { -974.4, 108.3, 2057.2 },
    ["Prison Yard"]   = { 807.9,  98.0,  2484.0 },
    ["Cells"]         = { 918.8,  100.0, 2484.5 },
    ["Cafeteria"]     = { 919.1,  100.0, 2227.9 },
    ["Outside Gate"]  = { 491.4,  95.5,  2052.5 },
}
local ESC_LOCS  = {
    ["Criminal Base"] = { -974.4, 108.3, 2057.2 },
    ["Outside Gate"]  = { 491.4,  95.5,  2052.5 },
}
local ESC_NAMES = { "Criminal Base", "Outside Gate" }

ui.NewDropdown(T, CT, "Location", LOC_NAMES, 1)

ui.NewButton(T, CT, "Teleport", function()
    local idx  = ui.getValue(T, CT, "Location")
    local name = LOC_NAMES[idx + 1]
    if not name then return end
    local d = LOCS[name]
    if d then tp(d[1], d[2], d[3]); print("[PLWare] → " .. name) end
end)

local sv = { x=nil, y=nil, z=nil }

local function save_pos()
    local h = hrp()
    if h then sv.x, sv.y, sv.z = h.Position.X, h.Position.Y, h.Position.Z end
end
local function ret_pos()
    if sv.x then tp(sv.x, sv.y, sv.z) end
end

ui.NewButton(T, CT, "Save Position", function()
    save_pos()
    if sv.x then
        print(string.format("[PLWare] Saved %.0f %.0f %.0f", sv.x, sv.y, sv.z))
    end
end)

ui.NewButton(T, CT, "Grab Gun", function()
    local h = hrp(); if not h then return end
    save_pos()
    local Y, Z = 100.7, 2227.9
    for _, px in ipairs({ 817.0, 820.3, 813.8, 820.3, 819.0 }) do
        h.Position = Vector3.new(px, Y, Z); wait_ms(180)
        h.Position = Vector3.new(px, Y, Z); wait_ms(100)
    end
    wait_ms(800); ret_pos()
    print("[PLWare] Gun grab done")
end)

ui.NewButton(T, CT, "Return", function()
    if sv.x then ret_pos(); print("[PLWare] Returned")
    else print("[PLWare] No saved position") end
end)

ui.NewButton(T, CT, "Grab Key Card", function()
    local h = hrp(); if not h then return end
    if #esp_cards == 0 then
        print("[PLWare] Enable Key Card ESP first"); return
    end
    local best, bd = nil, math.huge
    for _, c in ipairs(esp_cards) do
        local d = (c.pos - h.Position).Magnitude
        if d < bd then bd = d; best = c end
    end
    if not best then return end
    save_pos()
    for i = 1, 3 do
        h.Position = Vector3.new(best.pos.X, best.pos.Y + 1, best.pos.Z)
        wait_ms(70)
    end
    local sx, sy, vis = utility.WorldToScreen(best.pos)
    if vis then
        for i = 1, 10 do
            game.SilentAim(sx, sy)
            mouse.Click("leftmouse")
            wait_ms(75)
        end
    end
    print(string.format("[PLWare] Card grabbed (%.0fm)", bd))
    wait_ms(250); ret_pos()
end)

-- ══════════════════════════════════════════════════
--  GUARD UI
-- ══════════════════════════════════════════════════

ui.NewCheckbox(T, CG, "Auto Arrest")
ui.newSliderFloat(T, CG, "Arrest Range",  5.0,   30.0,   12.0)
ui.NewCheckbox(T, CG, "TP Arrest")
ui.newSliderFloat(T, CG, "TP Range",      50.0,  5000.0, 300.0)
ui.NewCheckbox(T, CG, "Threat Tracker")
ui.NewCheckbox(T, CG, "Proximity Alert")
ui.newSliderFloat(T, CG, "Alert Range",   5.0,   50.0,   15.0)

-- ══════════════════════════════════════════════════
--  INMATE UI
-- ══════════════════════════════════════════════════

ui.NewCheckbox(T, CI, "Escape on Low HP")
ui.newSliderInt(T, CI,  "HP %",           5,     50,     25)
ui.NewDropdown(T, CI,   "Escape To",      ESC_NAMES, 1)
ui.NewCheckbox(T, CI, "Guard Detector")
ui.newSliderFloat(T, CI, "Detect Range",  5.0,   25.0,   10.0)
ui.NewCheckbox(T, CI, "Ghost Jitter")
ui.NewCheckbox(T, CI, "Auto Sprint")

-- ══════════════════════════════════════════════════
--  MISC UI
-- ══════════════════════════════════════════════════

ui.NewButton(T, CM, "Panic TP", function()
    tp(816.5, 100.7, 2227.9)
    print("[PLWare] PANIC → Armory")
end)

-- ══════════════════════════════════════════════════
--  GUARD STATE
-- ══════════════════════════════════════════════════

local CLICK_CD = 250    -- ms between arrest clicks
local TP_CYCLE = 3000   -- ms before TP arrest force-resets lock

local last_click = 0
local arr_active = false
local arr_status = "READY"
local last_alert = 0

-- TP Arrest uses Serotonin Orbit + Aimbot
-- We whitelist target → enable orbit (Sero circles them)
-- → aimbot locks on → we click to arrest
local tp_name   = nil
local tp_locked = false
local tp_start  = 0

local function tp_cleanup()
    if tp_name then
        -- Toggle whitelist off (call twice = remove)
        pcall(function()
            game.PlayerWhitelist(tp_name)
        end)
        -- Disable orbit and aimbot
        pcall(function()
            ui.setValue("Exploits", "Main", "Orbit Target", false)
        end)
        pcall(function()
            ui.setValue("Aimbot", "Aimbot", "Enabled",    false)
            ui.setValue("Aimbot", "Aimbot", "Silent Aim", false)
        end)
    end
    tp_name   = nil
    tp_locked = false
    tp_start  = 0
end

local function find_target(range)
    local h = hrp(); if not h then return nil end
    local mp = h.Position
    local best, bd = nil, range
    for _, p in ipairs(entity.GetPlayers(true)) do
        if valid_target(p) then
            local d = (p.Position - mp).Magnitude
            if d < bd then bd = d; best = p end
        end
    end
    return best
end

local function get_player_by_name(name)
    for _, p in ipairs(entity.GetPlayers(false)) do
        if p.Name == name then return p end
    end
    return nil
end

-- ── Auto Arrest ──────────────────────────────────
local function run_auto_arrest()
    if not ui.getValue(T, CG, "Auto Arrest") then
        arr_active = false; arr_status = "OFF"; return
    end
    if not cuffs() then
        arr_active = false; arr_status = "NO CUFFS"; return
    end
    local t = find_target(ui.getValue(T, CG, "Arrest Range"))
    if not t then
        arr_active = false; arr_status = "SCANNING"; return
    end
    arr_active = true
    arr_status = t.Name
    local n = now()
    if n - last_click >= CLICK_CD then
        last_click = n
        local h = hrp()
        if h then
            -- TP right beside target
            h.Position = Vector3.new(
                t.Position.X,
                t.Position.Y,
                t.Position.Z + 2.5
            )
        end
        click_on(t)
    end
end

-- ── TP Arrest ────────────────────────────────────
-- Locks onto target, uses Serotonin Orbit + Aimbot,
-- force-resets every TP_CYCLE ms to prevent freeze
local function run_tp_arrest()
    if not ui.getValue(T, CG, "TP Arrest") then
        tp_cleanup(); return
    end
    if not cuffs() then return end

    local n = now()
    local h = hrp(); if not h then return end

    -- Force cycle reset every 3s — fixes frozen arrest
    if tp_locked and n - tp_start >= TP_CYCLE then
        tp_cleanup(); return
    end

    local target = nil
    if tp_locked and tp_name then
        local p = get_player_by_name(tp_name)
        if not p or not valid_target(p) then
            -- Arrested or left
            print("[PLWare] Done: " .. tp_name)
            tp_cleanup(); return
        end
        target = p
    else
        -- Find new target
        local best = find_target(ui.getValue(T, CG, "TP Range"))
        if not best then tp_cleanup(); return end

        tp_name   = best.Name
        tp_locked = true
        tp_start  = n
        save_pos()

        -- Engage Serotonin on target
        pcall(function()
            game.PlayerWhitelist(tp_name)
            ui.setValue("Exploits", "Main", "Orbit Target", true)
            ui.setValue("Aimbot", "Aimbot", "Smoothing",  0)
            ui.setValue("Aimbot", "Aimbot", "Silent Aim", true)
            ui.setValue("Aimbot", "Aimbot", "Enabled",    true)
        end)

        print("[PLWare] Orbit: " .. tp_name)
        target = best
    end

    if not target then return end

    -- TP beside target using direction offset
    local pos = target.Position
    local dx  = pos.X - h.Position.X
    local dz  = pos.Z - h.Position.Z
    local mag = math.sqrt(dx*dx + dz*dz)
    if mag > 0.1 then
        local nx = pos.X - (dx/mag)*2
        local nz = pos.Z - (dz/mag)*2
        h.Position = Vector3.new(nx, pos.Y, nz)
        wait_ms(20)
        h.Position = Vector3.new(nx, pos.Y, nz)
    else
        h.Position = Vector3.new(pos.X + 2, pos.Y, pos.Z)
    end

    if n - last_click >= CLICK_CD then
        last_click = n
        click_on(target)
    end
end

-- ── Proximity Alert ──────────────────────────────
local function run_proximity_alert()
    if not ui.getValue(T, CG, "Proximity Alert") then return end
    local n = now(); if n - last_alert < 2500 then return end
    local h = hrp(); if not h then return end
    local range = ui.getValue(T, CG, "Alert Range")
    for _, p in ipairs(entity.GetPlayers(true)) do
        if valid_target(p) and (p.Position - h.Position).Magnitude <= range then
            last_alert = n
            audio.beep(880, 120); wait_ms(60); audio.beep(1200, 80)
            return
        end
    end
end

-- ══════════════════════════════════════════════════
--  INMATE STATE
-- ══════════════════════════════════════════════════

local last_esc    = 0
local last_detect = 0
local just_esc    = false
local esc_time    = 0
local ghost_timer = 0
local ghost_dir   = 1
local sprinting   = false

local function do_escape(label)
    local idx  = ui.getValue(T, CI, "Escape To")
    local name = ESC_NAMES[idx + 1] or "Criminal Base"
    local d    = ESC_LOCS[name]
    if not d then return end
    local h = hrp()
    if h then
        for i = 1, 5 do
            h.Position = Vector3.new(d[1], d[2], d[3])
            wait_ms(55)
        end
        print("[PLWare] " .. label .. " → " .. name)
    end
end

local function run_escape()
    if not ui.getValue(T, CI, "Escape on Low HP") then return end
    local n = now()
    if n - last_esc < 500 then return end
    last_esc = n
    local p = glp()
    if not p or p.MaxHealth <= 0 then return end
    local thresh = ui.getValue(T, CI, "HP %")
    if (p.Health / p.MaxHealth * 100) <= thresh then
        last_esc = n + 3000
        just_esc = true; esc_time = n
        do_escape("LOW HP ESCAPE")
    end
end

local function run_guard_detector()
    if not ui.getValue(T, CI, "Guard Detector") then return end
    local n = now()
    -- Don't fire right after a low HP escape
    if just_esc and n - esc_time < 5000 then return end
    just_esc = false
    if n - last_detect < 1500 then return end
    local h = hrp(); if not h then return end
    local range = ui.getValue(T, CI, "Detect Range")
    local mp    = h.Position
    local me    = glp()
    for _, p in ipairs(entity.GetPlayers()) do
        if p.IsAlive and me and p.Name ~= me.Name then
            if (p.Position - mp).Magnitude <= range and has_cuffs_on(p) then
                last_detect = n
                do_escape("GUARD DETECTED")
                return
            end
        end
    end
end

local function run_ghost_jitter(dt)
    if not ui.getValue(T, CI, "Ghost Jitter") then return end
    local h = hrp(); if not h then return end
    ghost_timer = ghost_timer + dt
    if ghost_timer < 0.08 then return end
    ghost_timer = 0
    ghost_dir   = ghost_dir * -1
    local pos   = h.Position
    h.Position  = Vector3.new(pos.X + ghost_dir*0.4, pos.Y, pos.Z + ghost_dir*0.4)
end

local function run_auto_sprint()
    local on = ui.getValue(T, CI, "Auto Sprint")
    if on and not sprinting then
        keyboard.Press("lshift"); sprinting = true
    elseif not on and sprinting then
        keyboard.Release("lshift"); sprinting = false
    end
end

-- ══════════════════════════════════════════════════
--  THREAT TRACKER
-- ══════════════════════════════════════════════════

local threats     = {}
local threat_tick = 0

local function update_threats()
    local n = now()
    if n - threat_tick < 300 then return end
    threat_tick = n
    threats = {}
    for _, p in ipairs(entity.GetPlayers(true)) do
        if valid_target(p) then
            table.insert(threats, {
                name  = p.Name,
                pos   = p.Position,
                vel   = p.Velocity,
                hp    = p.Health,
                maxhp = p.MaxHealth,
            })
        end
    end
end

local function draw_threat_tracker()
    if not ui.getValue(T, CG, "Threat Tracker") then return end
    if #threats == 0 then return end
    local sw, sh = cheat.getWindowSize()
    local cx, cy = sw/2, sh/2
    local h      = hrp()
    for _, c in ipairs(threats) do
        local sx, sy, vis = utility.WorldToScreen(c.pos)
        if not vis then goto continue end
        local pct = c.maxhp > 0 and (c.hp/c.maxhp) or 1
        local col = Color3.fromRGB(
            math.floor(255*(1-pct)),
            math.floor(255*pct),
            30
        )
        -- Orange line from crosshair to target
        draw.Line(cx, cy, sx, sy, Color3.fromRGB(255,80,0), 1, 85)
        -- Health-colored ring at target
        draw.Circle(sx, sy, 10, col, 1.5, 16, 210)
        -- Velocity prediction arrow
        local spd = math.sqrt(c.vel.X^2 + c.vel.Z^2)
        if spd > 1 then
            local pred = Vector3.new(
                c.pos.X + c.vel.X*1.5,
                c.pos.Y + c.vel.Y*1.5,
                c.pos.Z + c.vel.Z*1.5
            )
            local px, py, pv = utility.WorldToScreen(pred)
            if pv then
                draw.Line(sx, sy, px, py, Color3.fromRGB(255,220,0), 1, 100)
                local d = 5
                draw.Line(px-d, py,   px,   py-d, Color3.fromRGB(255,220,0), 1, 180)
                draw.Line(px,   py-d, px+d, py,   Color3.fromRGB(255,220,0), 1, 180)
                draw.Line(px+d, py,   px,   py+d, Color3.fromRGB(255,220,0), 1, 180)
                draw.Line(px,   py+d, px-d, py,   Color3.fromRGB(255,220,0), 1, 180)
            end
        end
        -- Name + dist + HP label
        local dist = h and (c.pos - h.Position).Magnitude or 0
        local info = string.format("%s  %.0fm  %d%%", c.name, dist, math.floor(pct*100))
        local tw, th = draw.GetTextSize(info, "Tahoma")
        draw.TextOutlined(info, sx-(tw/2), sy-14-th, col, "Tahoma")
        ::continue::
    end
end

-- ══════════════════════════════════════════════════
--  HUD — bottom-left panel, Tahoma font
--  Semi-transparent dark background for readability
-- ══════════════════════════════════════════════════

local F   = "Tahoma"
local COK  = Color3.fromRGB(80,  255, 120)
local CWRN = Color3.fromRGB(255, 200, 0  )
local CERR = Color3.fromRGB(255, 60,  60 )
local CNFO = Color3.fromRGB(140, 190, 255)
local CDIM = Color3.fromRGB(90,  90,  90 )
local CPRP = Color3.fromRGB(180, 80,  255)

local function hud()
    local sw, sh = cheat.getWindowSize()
    local x  = 10
    local lh = 15

    -- Collect lines first so we can draw background
    local lines = {}
    local function ln(text, col)
        table.insert(lines, { text=text, col=col })
    end

    -- Guard
    if ui.getValue(T, CG, "Auto Arrest") then
        if not cuffs() then
            ln("AUTO ARR  NO CUFFS", CWRN)
        elseif arr_active then
            ln("ARREST   " .. arr_status, CERR)
        else
            ln("AUTO ARR  READY", COK)
        end
    end

    if ui.getValue(T, CG, "TP Arrest") then
        if not cuffs() then
            ln("TP ARR   NO CUFFS", CWRN)
        elseif tp_name then
            ln("ORBIT    " .. tp_name, CERR)
        else
            ln("TP ARR   SCANNING", CNFO)
        end
    end

    if ui.getValue(T, CG, "Threat Tracker") then
        local cnt = #threats
        ln(string.format("THREATS  %d", cnt), cnt > 0 and CERR or COK)
    end

    if ui.getValue(T, CG, "Proximity Alert") then
        ln("ALERT    ON", CWRN)
    end

    -- Inmate
    if ui.getValue(T, CI, "Escape on Low HP") then
        local p = glp()
        if p and p.MaxHealth > 0 then
            local hp  = math.floor(p.Health / p.MaxHealth * 100)
            local thr = ui.getValue(T, CI, "HP %")
            ln(string.format("HP       %d%%  ESC %d%%", hp, thr),
               hp <= thr and CERR or COK)
        end
    end

    if ui.getValue(T, CI, "Guard Detector") then ln("DETECT   ON", CPRP) end
    if ui.getValue(T, CI, "Ghost Jitter")   then ln("GHOST    ON", CPRP) end
    if sprinting                            then ln("SPRINT   ON", COK)  end

    -- Watermark always last (bottom)
    ln("PLWare " .. VERSION, CDIM)

    if #lines == 0 then return end

    -- Measure panel width
    local max_w = 0
    for _, l in ipairs(lines) do
        local w, _ = draw.GetTextSize(l.text, F)
        if w > max_w then max_w = w end
    end

    local pad_x = 8
    local pad_y = 6
    local panel_w = max_w + pad_x*2
    local panel_h = #lines * lh + pad_y*2
    local panel_x = x - pad_x
    local panel_y = sh - 18 - (#lines - 1) * lh - pad_y

    -- Dark semi-transparent background
    draw.RectFilled(panel_x, panel_y, panel_w, panel_h,
                    Color3.fromRGB(10, 10, 10), 0, 160)

    -- Thin top accent line
    draw.Line(panel_x, panel_y, panel_x + panel_w, panel_y,
              Color3.fromRGB(0, 180, 255), 1, 180)

    -- Draw text bottom-up
    local y = sh - 18
    for i = #lines, 1, -1 do
        local l = lines[i]
        draw.TextOutlined(l.text, x, y, l.col, F)
        y = y - lh
    end
end

-- ══════════════════════════════════════════════════
--  CALLBACKS
-- ══════════════════════════════════════════════════

sched.every(800, refresh_esp)

cheat.register("onPaint", function()
    draw_esp()
    draw_threat_tracker()
    hud()
end)

cheat.register("onUpdate", function()
    local dt = utility.GetDeltaTime()
    sched.tick()
    update_threats()
    run_auto_arrest()
    run_tp_arrest()
    run_proximity_alert()
    run_escape()
    run_guard_detector()
    run_ghost_jitter(dt)
    run_auto_sprint()
end)

cheat.register("shutdown", function()
    tp_cleanup()
    if sprinting then keyboard.Release("lshift") end
    print("[PLWare] Unloaded")
end)

-- ══════════════════════════════════════════════════
print("[PrisonLifeWare " .. VERSION .. "] Loaded")
