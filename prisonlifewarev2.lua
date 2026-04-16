-- ╔══════════════════════════════════════════════════╗
--   PrisonLifeWare v3  |  loXxiyt
--   Full Serotonin Integration
-- ╚══════════════════════════════════════════════════╝

local VERSION = "v3"

-- ── Tab / Container references ─────────────────────
local T  = "PLWare"
local CE = "ESP"
local CT = "TPS"
local CG = "GUARD"
local CI = "INMATE"
local CX = "SERO"
local CM = "MISC"

-- ── Serotonin internal references ──────────────────
local S_EX   = "Exploits"
local S_MAIN = "Main"
local S_MISC = "Misc"
local S_AB   = "Aimbot"
local S_VIS  = "Visuals"

-- ══════════════════════════════════════════════════
--  UI LAYOUT
-- ══════════════════════════════════════════════════

ui.newTab(T, "PrisonLifeWare")
ui.NewContainer(T, CE, "Item ESP",       { autosize = true, next = true })
ui.NewContainer(T, CT, "Teleports",      { autosize = true, next = true })
ui.NewContainer(T, CG, "Guard",          { autosize = true, next = true })
ui.NewContainer(T, CI, "Inmate",         { autosize = true, next = true })
ui.NewContainer(T, CX, "Sero Exploits",  { autosize = true, next = true })
ui.NewContainer(T, CM, "Misc",           { autosize = true })

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
--  SEROTONIN HELPERS
-- ══════════════════════════════════════════════════

local function sget(tab, cont, name)
    local ok, v = pcall(function() return ui.getValue(tab, cont, name) end)
    return ok and v or nil
end

local function sset(tab, cont, name, val)
    pcall(function() ui.setValue(tab, cont, name, val) end)
end

-- Aimbot control
local prev_smoothing = 75
local function aimbot_on(player_name)
    prev_smoothing = sget(S_AB, S_AB, "Smoothing") or 75
    game.PlayerWhitelist(player_name)
    sset(S_AB, S_AB, "Smoothing",  0)
    sset(S_AB, S_AB, "Silent Aim", true)
    sset(S_AB, S_AB, "Enabled",    true)
end

local function aimbot_off(player_name)
    game.PlayerWhitelist(player_name)
    sset(S_AB, S_AB, "Enabled",    false)
    sset(S_AB, S_AB, "Silent Aim", false)
    sset(S_AB, S_AB, "Smoothing",  prev_smoothing)
end

-- Orbit control
local function orbit_on(player_name)
    game.PlayerWhitelist(player_name)
    sset(S_EX, S_MAIN, "Orbit Target", true)
end

local function orbit_off(player_name)
    game.PlayerWhitelist(player_name)
    sset(S_EX, S_MAIN, "Orbit Target", false)
end

-- ══════════════════════════════════════════════════
--  CORE HELPERS
-- ══════════════════════════════════════════════════

local function now()   return utility.GetTickCount() end
local function glp()   return game.LocalPlayer       end

local function char()
    local p = glp(); if not p then return nil end
    local ok, r = pcall(function() return game.Workspace:FindFirstChild(p.Name) end)
    return ok and r or nil
end

local function hrp()
    local c = char(); if not c then return nil end
    local ok, r = pcall(function() return c:FindFirstChild("HumanoidRootPart") end)
    return ok and r or nil
end

local function wait_ms(ms)
    local s = now(); while now() - s < ms do end
end

local function tp(x, y, z)
    local h = hrp(); if not h then return end
    local v = Vector3.new(x, y, z)
    h.Position = v; wait_ms(35)
    h.Position = v; wait_ms(35)
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
    local t = c:FindFirstChildOfClass("Tool"); if not t then return false end
    local n = string.lower(t.Name)
    return n == "handcuffs" or n == "menottes"
end

local function is_crim(p)
    return p.Team and string.find(string.lower(p.Team), "criminal") ~= nil
end

local WEAPONS = {
    ["AK-47"]=true, ["Remington 870"]=true, ["Taser"]=true,
    ["M9"]=true,    ["FAL"]=true,           ["M700"]=true,
    ["MP5"]=true,   ["M4A1"]=true,          ["Revolver"]=true,
    ["C4 Explosive"]=true, ["Crude Knife"]=true,
    ["Hammer"]=true, ["EBR"]=true,
}

local function armed_inmate(p)
    local c = game.Workspace:FindFirstChild(p.Name); if not c then return false end
    local t = c:FindFirstChildOfClass("Tool")
    return t and WEAPONS[t.Name] == true
end

local function valid_target(p)
    return p.IsAlive and (is_crim(p) or armed_inmate(p))
end

local function has_cuffs_equipped(p)
    local c = game.Workspace:FindFirstChild(p.Name); if not c then return false end
    local t = c:FindFirstChildOfClass("Tool"); if not t then return false end
    local n = string.lower(t.Name)
    return n == "handcuffs" or n == "menottes"
end

local function click_target(p)
    local bp = p:GetBonePosition("HumanoidRootPart")
            or p:GetBonePosition("Torso")
            or p.Position
    local sx, sy, vis = utility.WorldToScreen(bp)
    if vis then
        game.SilentAim(sx, sy)
        mouse.Click("leftmouse")
        return true
    end
    return false
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
    ["AK-47"]=true, ["Remington 870"]=true, ["Taser"]=true,
    ["M9"]=true,    ["FAL"]=true,           ["M700"]=true,
    ["MP5"]=true,   ["M4A1"]=true,          ["Revolver"]=true,
    ["C4 Explosive"]=true, ["Riot Shield"]=true,
    ["Crude Knife"]=true,  ["Hammer"]=true, ["EBR"]=true,
}

local esp_cards = {}
local esp_guns  = {}

local function refresh_esp()
    esp_cards = {}
    esp_guns  = {}
    local c_on = ui.getValue(T, CE, "Key Card ESP")
    local g_on = ui.getValue(T, CE, "Weapon ESP")
    if not c_on and not g_on then return end
    local max_d   = ui.getValue(T, CE, "ESP Range")
    local cam     = game.CameraPosition
    local ok, ch  = pcall(function() return game.Workspace:GetChildren() end)
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
        local hw = 14
        -- Corner-tick box
        local k = 5
        draw.Line(sx-hw, sy-hw, sx-hw+k, sy-hw,   col, 2)
        draw.Line(sx-hw, sy-hw, sx-hw,   sy-hw+k, col, 2)
        draw.Line(sx+hw, sy-hw, sx+hw-k, sy-hw,   col, 2)
        draw.Line(sx+hw, sy-hw, sx+hw,   sy-hw+k, col, 2)
        draw.Line(sx-hw, sy+hw, sx-hw+k, sy+hw,   col, 2)
        draw.Line(sx-hw, sy+hw, sx-hw,   sy+hw-k, col, 2)
        draw.Line(sx+hw, sy+hw, sx+hw-k, sy+hw,   col, 2)
        draw.Line(sx+hw, sy+hw, sx+hw,   sy+hw-k, col, 2)
        -- Label + distance
        local tw, th = draw.GetTextSize(label, "ConsolasBold")
        draw.TextOutlined(label, sx-(tw/2), sy-hw-th-2, col, "ConsolasBold")
        local ds = string.format("%.0fm", e.dist)
        local dw, _ = draw.GetTextSize(ds, "ConsolasBold")
        draw.TextOutlined(ds, sx-(dw/2), sy+hw+2, Color3.fromRGB(150,150,150), "ConsolasBold")
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
    local name = LOC_NAMES[idx + 1]; if not name then return end
    local d    = LOCS[name];         if not d    then return end
    tp(d[1], d[2], d[3])
    print("[PLWare] → " .. name)
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
        print(string.format("[PLWare] Saved (%.0f, %.0f, %.0f)", sv.x, sv.y, sv.z))
    end
end)

ui.NewButton(T, CT, "Grab Gun", function()
    local h = hrp(); if not h then return end
    save_pos()
    local Y, Z = 100.7, 2227.9
    for _, px in ipairs({ 817.0, 820.3, 813.8, 820.3, 819.0 }) do
        h.Position = Vector3.new(px, Y, Z); wait_ms(180)
        h.Position = Vector3.new(px, Y, Z); wait_ms(120)
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
    if #esp_cards == 0 then print("[PLWare] Enable Key Card ESP first"); return end
    -- Find closest card
    local best, bd = nil, math.huge
    for _, c in ipairs(esp_cards) do
        local d = (c.pos - h.Position).Magnitude
        if d < bd then bd = d; best = c end
    end
    if not best then return end
    save_pos()
    -- TP onto card
    for i = 1, 3 do
        h.Position = Vector3.new(best.pos.X, best.pos.Y + 1, best.pos.Z)
        wait_ms(70)
    end
    -- Click directly on card screen position
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
ui.newSliderFloat(T, CG, "Arrest Range",    5.0, 30.0,   12.0)
ui.NewCheckbox(T, CG, "TP Arrest")
ui.newSliderFloat(T, CG, "TP Range",       50.0, 5000.0, 300.0)
ui.NewCheckbox(T, CG, "Threat Tracker")
ui.NewCheckbox(T, CG, "Proximity Alert")
ui.newSliderFloat(T, CG, "Alert Range",     5.0, 50.0,   15.0)

-- ══════════════════════════════════════════════════
--  INMATE UI
-- ══════════════════════════════════════════════════

ui.NewCheckbox(T, CI, "Escape on Low HP")
ui.newSliderInt(T, CI,  "HP %",             5,   50,     25)
ui.NewDropdown(T, CI,   "Escape To", ESC_NAMES,  1)
ui.NewCheckbox(T, CI, "Guard Detector")
ui.newSliderFloat(T, CI, "Detect Range",    5.0, 25.0,   10.0)
ui.NewCheckbox(T, CI, "Ghost Jitter")
ui.NewCheckbox(T, CI, "Auto Sprint")

-- ══════════════════════════════════════════════════
--  SEROTONIN EXPLOITS UI
-- ══════════════════════════════════════════════════

ui.NewCheckbox(T, CX, "Speed Hack")
ui.newSliderInt(T, CX,  "Walk Speed",      16, 500, 60)
ui.NewCheckbox(T, CX, "Fly")
ui.NewCheckbox(T, CX, "Noclip")
ui.NewCheckbox(T, CX, "Infinite Jump")
ui.NewCheckbox(T, CX, "Bunnyhop")
ui.NewCheckbox(T, CX, "Jetpack")
ui.newSliderFloat(T, CX, "Jetpack Force",   1.0, 100.0, 10.0)
ui.NewCheckbox(T, CX, "Anti-Aim")
ui.NewCheckbox(T, CX, "No Jump Cooldown")
ui.NewCheckbox(T, CX, "Underground")
ui.NewCheckbox(T, CX, "Slow Fall")
ui.NewCheckbox(T, CX, "Anti AFK")
ui.NewButton(T, CX, "Reset All", function()
    local resets = {
        { S_EX, S_MAIN, "Speed",             false },
        { S_EX, S_MAIN, "Walkspeed",         false },
        { S_EX, S_MAIN, "Fly",               false },
        { S_EX, S_MAIN, "Infinite Jump",     false },
        { S_EX, S_MAIN, "Bunnyhop",          false },
        { S_EX, S_MAIN, "Anti Afk",          false },
        { S_EX, S_MISC, "Noclip",            false },
        { S_EX, S_MISC, "Jetpack",           false },
        { S_EX, S_MISC, "Enable Anti-Aim",   false },
        { S_EX, S_MISC, "No Jump Cooldown",  false },
        { S_EX, S_MISC, "Underground",       false },
        { S_EX, S_MISC, "Slow Fall",         false },
    }
    for _, r in ipairs(resets) do sset(r[1], r[2], r[3], r[4]) end
    -- Also reset our checkboxes
    local our = {
        "Speed Hack","Fly","Noclip","Infinite Jump",
        "Bunnyhop","Jetpack","Anti-Aim","No Jump Cooldown",
        "Underground","Slow Fall","Anti AFK"
    }
    for _, name in ipairs(our) do
        pcall(function() ui.setValue(T, CX, name, false) end)
    end
    print("[PLWare] All exploits reset")
end)

-- ══════════════════════════════════════════════════
--  MISC UI
-- ══════════════════════════════════════════════════

ui.NewButton(T, CM, "Panic TP", function()
    tp(816.5, 100.7, 2227.9)
    print("[PLWare] PANIC → Armory")
end)

-- ══════════════════════════════════════════════════
--  SEROTONIN EXPLOIT SYNC
--  Only writes on change — no spam
-- ══════════════════════════════════════════════════

local ex_prev = {}

local function sync_exploits()
    -- Speed Hack
    local sp_on  = ui.getValue(T, CX, "Speed Hack")
    local sp_val = ui.getValue(T, CX, "Walk Speed")
    if sp_on ~= ex_prev.sp_on or sp_val ~= ex_prev.sp_val then
        ex_prev.sp_on  = sp_on
        ex_prev.sp_val = sp_val
        sset(S_EX, S_MAIN, "Speed",     sp_on)
        sset(S_EX, S_MAIN, "Walkspeed", sp_on and sp_val or false)
    end

    -- Jetpack (with force value)
    local jp_on  = ui.getValue(T, CX, "Jetpack")
    local jp_val = ui.getValue(T, CX, "Jetpack Force")
    if jp_on ~= ex_prev.jp_on or jp_val ~= ex_prev.jp_val then
        ex_prev.jp_on  = jp_on
        ex_prev.jp_val = jp_val
        sset(S_EX, S_MISC, "Jetpack",       jp_on)
        sset(S_EX, S_MISC, "Jetpack Force", jp_val)
    end

    -- Simple bool toggles
    local toggles = {
        { "Fly",              S_EX, S_MAIN, "Fly"              },
        { "Noclip",           S_EX, S_MISC, "Noclip"           },
        { "Infinite Jump",    S_EX, S_MAIN, "Infinite Jump"    },
        { "Bunnyhop",         S_EX, S_MAIN, "Bunnyhop"         },
        { "Anti-Aim",         S_EX, S_MISC, "Enable Anti-Aim"  },
        { "No Jump Cooldown", S_EX, S_MISC, "No Jump Cooldown" },
        { "Underground",      S_EX, S_MISC, "Underground"      },
        { "Slow Fall",        S_EX, S_MISC, "Slow Fall"        },
        { "Anti AFK",         S_EX, S_MAIN, "Anti Afk"         },
    }
    for _, tg in ipairs(toggles) do
        local want = ui.getValue(T, CX, tg[1])
        if want ~= ex_prev[tg[1]] then
            ex_prev[tg[1]] = want
            sset(tg[2], tg[3], tg[4], want)
        end
    end
end

-- ══════════════════════════════════════════════════
--  GUARD STATE
-- ══════════════════════════════════════════════════

local CLICK_CD  = 250   -- ms between arrest clicks
local TP_CYCLE  = 3000  -- ms before TP arrest resets lock (prevents freeze)
local last_click = 0
local arr_active = false
local arr_status = "READY"

-- TP Arrest state
local tp_name      = nil   -- current target name
local tp_locked    = false
local tp_start     = 0
local last_alert   = 0

local function reset_tp_state()
    if tp_name then
        -- Clean up Serotonin state for previous target
        pcall(function() orbit_off(tp_name)  end)
        pcall(function() aimbot_off(tp_name) end)
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

local function get_by_name(name)
    for _, p in ipairs(entity.GetPlayers(false)) do
        if p.Name == name then return p end
    end
    return nil
end

-- ── Auto Arrest ────────────────────────────────────
local function run_auto_arrest()
    if not ui.getValue(T, CG, "Auto Arrest") then
        arr_active = false; arr_status = "OFF"; return
    end
    if not cuffs() then
        arr_active = false; arr_status = "NO HANDCUFFS"; return
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
            h.Position = Vector3.new(t.Position.X, t.Position.Y, t.Position.Z + 2.5)
        end
        click_target(t)
    end
end

-- ── TP Arrest (Orbit + Aimbot) ─────────────────────
-- Uses Serotonin's built-in Orbit to circle target
-- and Aimbot/SilentAim to lock on for arrest clicks
-- Resets every TP_CYCLE ms to prevent freeze
local function run_tp_arrest()
    if not ui.getValue(T, CG, "TP Arrest") then
        reset_tp_state(); return
    end
    if not cuffs() then return end

    local n = now()
    local h = hrp(); if not h then return end

    -- Forced cycle reset — prevents the frozen arrest state
    if tp_locked and n - tp_start >= TP_CYCLE then
        reset_tp_state(); return
    end

    local target = nil

    if tp_locked and tp_name then
        local p = get_by_name(tp_name)
        -- Target arrested = no longer valid
        if not p or not valid_target(p) then
            print("[PLWare] Arrested: " .. tp_name)
            reset_tp_state(); return
        end
        target = p
    else
        -- Acquire new target
        local best = find_target(ui.getValue(T, CG, "TP Range"))
        if not best then reset_tp_state(); return end
        tp_name   = best.Name
        tp_locked = true
        tp_start  = n
        save_pos()
        -- Engage Serotonin systems on target
        orbit_on(tp_name)
        aimbot_on(tp_name)
        print("[PLWare] Locked: " .. tp_name)
        target = best
    end

    if not target then return end

    -- TP beside target
    local pos = target.Position
    local dx  = pos.X - h.Position.X
    local dz  = pos.Z - h.Position.Z
    local mag = math.sqrt(dx*dx + dz*dz)
    if mag > 0.1 then
        h.Position = Vector3.new(pos.X-(dx/mag)*2, pos.Y, pos.Z-(dz/mag)*2)
        wait_ms(20)
        h.Position = Vector3.new(pos.X-(dx/mag)*2, pos.Y, pos.Z-(dz/mag)*2)
    else
        h.Position = Vector3.new(pos.X+2, pos.Y, pos.Z)
    end

    -- Arrest click
    if n - last_click >= CLICK_CD then
        last_click = n
        click_target(target)
    end
end

-- ── Proximity Alert ────────────────────────────────
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

local function run_escape()
    if not ui.getValue(T, CI, "Escape on Low HP") then return end
    local n = now(); if n - last_esc < 500 then return end
    last_esc = n
    local p = glp(); if not p or p.MaxHealth <= 0 then return end
    local thresh = ui.getValue(T, CI, "HP %")
    if (p.Health / p.MaxHealth * 100) <= thresh then
        last_esc = n + 3000
        just_esc = true; esc_time = n
        local idx  = ui.getValue(T, CI, "Escape To")
        local name = ESC_NAMES[idx + 1] or "Criminal Base"
        local d    = ESC_LOCS[name]
        if d then
            local h = hrp()
            if h then
                for i = 1, 5 do
                    h.Position = Vector3.new(d[1], d[2], d[3])
                    wait_ms(55)
                end
            end
            print("[PLWare] ESCAPE → " .. name)
        end
    end
end

local function run_guard_detector()
    if not ui.getValue(T, CI, "Guard Detector") then return end
    local n = now()
    if just_esc and n - esc_time < 5000 then return end
    just_esc = false
    if n - last_detect < 1500 then return end
    local h = hrp(); if not h then return end
    local range = ui.getValue(T, CI, "Detect Range")
    local mp    = h.Position
    local me    = glp()
    for _, p in ipairs(entity.GetPlayers()) do
        if p.IsAlive and me and p.Name ~= me.Name then
            if (p.Position - mp).Magnitude <= range and has_cuffs_equipped(p) then
                last_detect = n
                local idx  = ui.getValue(T, CI, "Escape To")
                local name = ESC_NAMES[idx + 1] or "Criminal Base"
                local d    = ESC_LOCS[name]
                if d then
                    local hh = hrp()
                    if hh then
                        for i = 1, 4 do
                            hh.Position = Vector3.new(d[1], d[2], d[3])
                            wait_ms(50)
                        end
                        print("[PLWare] Guard w/ cuffs! → " .. name)
                    end
                end
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
    ghost_timer = 0; ghost_dir = ghost_dir * -1
    local pos = h.Position
    h.Position = Vector3.new(pos.X + ghost_dir*0.4, pos.Y, pos.Z + ghost_dir*0.4)
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
    local n = now(); if n - threat_tick < 300 then return end
    threat_tick = n; threats = {}
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
        if vis then
            local pct = c.maxhp > 0 and (c.hp/c.maxhp) or 1
            local col = Color3.fromRGB(math.floor(255*(1-pct)), math.floor(255*pct), 30)
            -- Threat line from crosshair
            draw.Line(cx, cy, sx, sy, Color3.fromRGB(255, 80, 0), 1, 90)
            -- Ring
            draw.Circle(sx, sy, 10, col, 1.5, 16, 210)
            -- Velocity prediction arrow
            local spd = math.sqrt(c.vel.X^2 + c.vel.Z^2)
            if spd > 1 then
                local pred = Vector3.new(
                    c.pos.X + c.vel.X*1.5,
                    c.pos.Y + c.vel.Y*1.5,
                    c.pos.Z + c.vel.Z*1.5
                )
                local px, py, pvis = utility.WorldToScreen(pred)
                if pvis then
                    draw.Line(sx, sy, px, py, Color3.fromRGB(255,230,0), 1, 110)
                    local d = 5
                    draw.Line(px-d,py,   px,   py-d, Color3.fromRGB(255,230,0), 1, 190)
                    draw.Line(px,   py-d, px+d, py,   Color3.fromRGB(255,230,0), 1, 190)
                    draw.Line(px+d, py,   px,   py+d, Color3.fromRGB(255,230,0), 1, 190)
                    draw.Line(px,   py+d, px-d, py,   Color3.fromRGB(255,230,0), 1, 190)
                end
            end
            -- Info label
            local dist = h and (c.pos - h.Position).Magnitude or 0
            local info = string.format("%s  %.0fm  %d%%", c.name, dist, math.floor(pct*100))
            local tw, th = draw.GetTextSize(info, "ConsolasBold")
            draw.TextOutlined(info, sx-(tw/2), sy-14-th, col, "ConsolasBold")
        end
    end
end

-- ══════════════════════════════════════════════════
--  HUD  —  bottom-left, draws upward, ConsolasBold
-- ══════════════════════════════════════════════════

local H_FONT = "ConsolasBold"
local H_OK   = Color3.fromRGB(80,  255, 120)   -- active / good
local H_WARN = Color3.fromRGB(255, 200, 0  )   -- warning
local H_ERR  = Color3.fromRGB(255, 60,  60 )   -- danger / locking
local H_INFO = Color3.fromRGB(140, 190, 255)   -- info
local H_DIM  = Color3.fromRGB(90,  90,  90 )   -- dim / watermark
local H_PRP  = Color3.fromRGB(180, 80,  255)   -- purple
local H_CYN  = Color3.fromRGB(0,   220, 255)   -- cyan / exploit

local function hud()
    local sw, sh = cheat.getWindowSize()
    local x  = 12
    local y  = sh - 18
    local lh = 16

    local function ln(text, col)
        draw.TextOutlined(text, x, y, col, H_FONT)
        y = y - lh
    end

    -- Watermark
    ln("PLWare " .. VERSION, H_DIM)
    y = y - 4

    -- ── Exploits active ──────────────────────────
    if ui.getValue(T, CX, "Speed Hack") then
        ln(string.format("[ SPEED %d ]", ui.getValue(T, CX, "Walk Speed")), H_CYN)
    end
    if ui.getValue(T, CX, "Fly")             then ln("[ FLY ]",         H_CYN) end
    if ui.getValue(T, CX, "Noclip")          then ln("[ NOCLIP ]",      H_CYN) end
    if ui.getValue(T, CX, "Infinite Jump")   then ln("[ INF JUMP ]",    H_CYN) end
    if ui.getValue(T, CX, "Jetpack")         then ln("[ JETPACK ]",     H_CYN) end
    if ui.getValue(T, CX, "Anti-Aim")        then ln("[ ANTI-AIM ]",    H_CYN) end
    if ui.getValue(T, CX, "Underground")     then ln("[ UNDERGROUND ]", H_CYN) end
    if ui.getValue(T, CX, "Bunnyhop")        then ln("[ BHOP ]",        H_CYN) end

    -- ── Inmate ───────────────────────────────────
    if sprinting                             then ln("[ SPRINT ]",       H_OK)  end
    if ui.getValue(T, CI, "Ghost Jitter")    then ln("[ GHOST ]",        H_PRP) end
    if ui.getValue(T, CI, "Guard Detector")  then ln("[ GUARD DETECT ]", H_PRP) end

    if ui.getValue(T, CI, "Escape on Low HP") then
        local p = glp()
        if p and p.MaxHealth > 0 then
            local hp  = math.floor(p.Health / p.MaxHealth * 100)
            local thr = ui.getValue(T, CI, "HP %")
            ln(string.format("[ HP %d%% / ESC %d%% ]", hp, thr),
               hp <= thr and H_ERR or H_OK)
        end
    end

    -- ── Guard ────────────────────────────────────
    if ui.getValue(T, CG, "Proximity Alert") then ln("[ ALERT ]",       H_WARN) end

    if ui.getValue(T, CG, "Threat Tracker") then
        local cnt = #threats
        ln(string.format("[ THREATS: %d ]", cnt), cnt > 0 and H_ERR or H_OK)
    end

    if ui.getValue(T, CG, "TP Arrest") then
        if not cuffs() then
            ln("[ TP ARREST: CUFFS ]", H_WARN)
        elseif tp_name then
            ln("[ ORBIT: " .. tp_name .. " ]", H_ERR)
        else
            ln("[ TP ARREST: SCAN ]", H_INFO)
        end
    end

    if ui.getValue(T, CG, "Auto Arrest") then
        if not cuffs() then
            ln("[ AUTO ARR: CUFFS ]", H_WARN)
        elseif arr_active then
            ln("[ ARREST: " .. arr_status .. " ]", H_ERR)
        else
            ln("[ AUTO ARR: READY ]", H_OK)
        end
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
    sync_exploits()
    run_auto_arrest()
    run_tp_arrest()
    run_proximity_alert()
    run_escape()
    run_guard_detector()
    run_ghost_jitter(dt)
    run_auto_sprint()
end)

cheat.register("shutdown", function()
    -- Clean up all Serotonin state on unload
    if tp_name then
        pcall(function() orbit_off(tp_name)  end)
        pcall(function() aimbot_off(tp_name) end)
    end
    if sprinting then keyboard.Release("lshift") end
    print("[PLWare] Unloaded cleanly")
end)

-- ══════════════════════════════════════════════════
print("[PrisonLifeWare " .. VERSION .. "] Loaded")
