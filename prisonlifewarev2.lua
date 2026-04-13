-- ╔══════════════════════════════════════════╗
--   PrisonLifeWare v2  |  loXxiyt
--   github.com/loXxiyt/PrisonLifeWare
-- ╚══════════════════════════════════════════╝

local PLW_VERSION = "v2.4"

-- ── Tab / Container refs ──────────────────────
local T  = "PLWare"
local CE = "ESP"
local CT = "TPS"
local CG = "GUARD"
local CI = "INMATE"
local CM = "MISC"

-- ── UI Layout ─────────────────────────────────
ui.newTab(T, "PrisonLifeWare")
ui.NewContainer(T, CE, "Item ESP",  { autosize = true, next = true })
ui.NewContainer(T, CT, "Teleports", { autosize = true, next = true })
ui.NewContainer(T, CG, "Guard",     { autosize = true, next = true })
ui.NewContainer(T, CI, "Inmate",    { autosize = true, next = true })
ui.NewContainer(T, CM, "Misc",      { autosize = true })

-- ══════════════════════════════════════════════
--  SCHEDULER
-- ══════════════════════════════════════════════

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

-- ══════════════════════════════════════════════
--  CORE HELPERS
-- ══════════════════════════════════════════════

local function lp()  return entity.GetLocalPlayer() end
local function now() return utility.GetTickCount()   end

local function char()
    local p = lp(); if not p then return nil end
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

-- Reliable multi-frame TP
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
    local t = c:FindFirstChildOfClass("Tool"); if not t then return false end
    local n = string.lower(t.Name)
    return n == "handcuffs" or n == "menottes"
end

local CRIMINALS = string.lower
local function is_crim(p)
    return p.Team and string.find(string.lower(p.Team), "criminal") ~= nil
end

local WEAPONS = {
    ["AK-47"]=true,["Remington 870"]=true,["Taser"]=true,
    ["M9"]=true,["FAL"]=true,["M700"]=true,["MP5"]=true,
    ["M4A1"]=true,["Revolver"]=true,["C4 Explosive"]=true,
    ["Crude Knife"]=true,["Hammer"]=true,["EBR"]=true,
}

local function armed_inmate(p)
    local c = game.Workspace:FindFirstChild(p.Name); if not c then return false end
    local t = c:FindFirstChildOfClass("Tool")
    return t and WEAPONS[t.Name] == true
end

local function valid_target(p)
    return p.IsAlive and (is_crim(p) or armed_inmate(p))
end

-- Aim silently at a player, return screen coords
local function aim(p)
    local bp = p:GetBonePosition("HumanoidRootPart")
            or p:GetBonePosition("Torso")
            or p.Position
    local sx, sy, vis = utility.WorldToScreen(bp)
    if vis then game.SilentAim(sx, sy) end
    return sx, sy, vis
end

local function click(p)
    local sx, sy, vis = aim(p)
    if vis then mouse.Click("leftmouse"); return true end
    return false
end

-- ══════════════════════════════════════════════
--  ITEM ESP
-- ══════════════════════════════════════════════

ui.NewCheckbox(T, CE, "Key Card ESP")
ui.NewCheckbox(T, CE, "Weapon ESP")
ui.NewColorpicker(T, CE, "Card Color",   {r=0,   g=220, b=255, a=255}, true)
ui.NewColorpicker(T, CE, "Weapon Color", {r=255, g=140, b=0,   a=255}, true)
ui.newSliderInt(T, CE, "ESP Range", 50, 2000, 800)

local CARDS = {["Key card"]=true, ["Key Card"]=true}
local GUNS  = {
    ["AK-47"]=true,["Remington 870"]=true,["Taser"]=true,
    ["M9"]=true,["FAL"]=true,["M700"]=true,["MP5"]=true,
    ["M4A1"]=true,["Revolver"]=true,["C4 Explosive"]=true,
    ["Riot Shield"]=true,["Crude Knife"]=true,["Hammer"]=true,["EBR"]=true,
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
    local cam_pos = game.CameraPosition
    local ok, ch  = pcall(function() return game.Workspace:GetChildren() end)
    if not ok then return end
    for _, obj in pairs(ch) do
        if obj.ClassName == "Model" or obj.ClassName == "Tool" then
            local p = part_of(obj)
            if p then
                local pos  = p.Position
                local dist = cam_pos and (cam_pos - pos).Magnitude or 0
                if dist <= max_d then
                    if c_on and CARDS[obj.Name] then
                        table.insert(esp_cards, {pos=pos, dist=dist})
                    elseif g_on and GUNS[obj.Name] then
                        table.insert(esp_guns, {pos=pos, dist=dist, name=obj.Name})
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

    local cc = ui.getValue(T, CE, "Card Color")
    local gc = ui.getValue(T, CE, "Weapon Color")
    local cc3 = Color3.fromRGB(cc.r, cc.g, cc.b)
    local gc3 = Color3.fromRGB(gc.r, gc.g, gc.b)

    local function render(e, label, col)
        local sx, sy, vis = utility.WorldToScreen(e.pos)
        if not vis then return end
        -- Clean box with corner accents
        local hw, hh = 14, 14
        draw.Rect(sx-hw, sy-hh, hw*2, hh*2, col, 1.0)
        -- Corner ticks
        local t = 4
        draw.Line(sx-hw, sy-hh, sx-hw+t, sy-hh, col, 2)
        draw.Line(sx-hw, sy-hh, sx-hw, sy-hh+t, col, 2)
        draw.Line(sx+hw, sy-hh, sx+hw-t, sy-hh, col, 2)
        draw.Line(sx+hw, sy-hh, sx+hw, sy-hh+t, col, 2)
        draw.Line(sx-hw, sy+hh, sx-hw+t, sy+hh, col, 2)
        draw.Line(sx-hw, sy+hh, sx-hw, sy+hh-t, col, 2)
        draw.Line(sx+hw, sy+hh, sx+hw-t, sy+hh, col, 2)
        draw.Line(sx+hw, sy+hh, sx+hw, sy+hh-t, col, 2)
        -- Label
        local tw, th = draw.GetTextSize(label, "ConsolasBold")
        draw.TextOutlined(label, sx-(tw/2), sy-hh-th-3, col, "ConsolasBold")
        -- Distance
        local ds = string.format("%.0fm", e.dist)
        local dw, _ = draw.GetTextSize(ds, "ConsolasBold")
        draw.TextOutlined(ds, sx-(dw/2), sy+hh+3, Color3.fromRGB(180,180,180), "ConsolasBold")
    end

    if c_on then for _, e in pairs(esp_cards) do render(e, "CARD", cc3)      end end
    if g_on then for _, e in pairs(esp_guns)  do render(e, e.name, gc3)      end end
end

-- ══════════════════════════════════════════════
--  TELEPORTS
-- ══════════════════════════════════════════════

local LOC_NAMES = {
    "Armory","Criminal Base","Prison Yard",
    "Cells","Cafeteria","Outside Gate",
}
local LOCS = {
    ["Armory"]        = {816.5,  100.7, 2227.9},
    ["Criminal Base"] = {-974.4, 108.3, 2057.2},
    ["Prison Yard"]   = {807.9,  98.0,  2484.0},
    ["Cells"]         = {918.8,  100.0, 2484.5},
    ["Cafeteria"]     = {919.1,  100.0, 2227.9},
    ["Outside Gate"]  = {491.4,  95.5,  2052.5},
}
local ESC_LOCS = {
    ["Criminal Base"] = {-974.4, 108.3, 2057.2},
    ["Outside Gate"]  = {491.4,  95.5,  2052.5},
}
local ESC_NAMES = {"Criminal Base","Outside Gate"}

ui.NewDropdown(T, CT, "Location", LOC_NAMES, 1)

ui.NewButton(T, CT, "Teleport", function()
    local h = hrp(); if not h then return end
    local idx  = ui.getValue(T, CT, "Location")
    local name = LOC_NAMES[idx + 1]; if not name then return end
    local d    = LOCS[name]; if not d then return end
    tp(d[1], d[2], d[3])
    print("[PLWare] → " .. name)
end)

local sv_x, sv_y, sv_z = nil, nil, nil

local function save()
    local h = hrp()
    if h then sv_x,sv_y,sv_z = h.Position.X, h.Position.Y, h.Position.Z end
end

local function ret()
    if sv_x then tp(sv_x, sv_y, sv_z) end
end

ui.NewButton(T, CT, "Save Position", function()
    save()
    if sv_x then print(string.format("[PLWare] Saved (%.0f %.0f %.0f)", sv_x, sv_y, sv_z)) end
end)

ui.NewButton(T, CT, "Grab Gun", function()
    local h = hrp(); if not h then return end
    save()
    local Y, Z = 100.7, 2227.9
    -- Sweep confirmed pad positions
    for _, px in ipairs({817.0, 820.3, 813.8, 820.3, 819.0}) do
        h.Position = Vector3.new(px, Y, Z); wait_ms(200)
        h.Position = Vector3.new(px, Y, Z); wait_ms(120)
    end
    print("[PLWare] Grab done — returning in 1s...")
    wait_ms(1000)
    ret()
end)

ui.NewButton(T, CT, "Return", function()
    if sv_x then ret(); print("[PLWare] Returned.")
    else print("[PLWare] No saved position.") end
end)

ui.NewButton(T, CT, "Grab Key Card", function()
    local h = hrp(); if not h then return end
    if #esp_cards == 0 then print("[PLWare] Enable Key Card ESP first."); return end
    local best, bd = nil, math.huge
    for _, c in ipairs(esp_cards) do
        local d = (c.pos - h.Position).Magnitude
        if d < bd then bd = d; best = c end
    end
    if not best then return end
    save()
    -- TP onto card 3x for reliability
    for i = 1, 3 do
        h.Position = Vector3.new(best.pos.X, best.pos.Y+1, best.pos.Z)
        wait_ms(80)
    end
    -- Aim directly at card and click
    local sx, sy, vis = utility.WorldToScreen(best.pos)
    if vis then
        for i = 1, 10 do
            game.SilentAim(sx, sy)
            mouse.Click("leftmouse")
            wait_ms(80)
        end
    end
    print(string.format("[PLWare] Card grabbed (%.0fm)", bd))
    wait_ms(300)
    ret()
end)

-- ══════════════════════════════════════════════
--  GUARD UI
-- ══════════════════════════════════════════════

ui.NewCheckbox(T, CG, "Auto Arrest")
ui.newSliderFloat(T, CG, "Arrest Range", 5.0, 30.0, 12.0)
ui.NewCheckbox(T, CG, "TP Arrest")
ui.newSliderFloat(T, CG, "TP Range", 50.0, 500.0, 150.0)
ui.NewCheckbox(T, CG, "Threat Tracker")
ui.NewCheckbox(T, CG, "Proximity Alert")
ui.newSliderFloat(T, CG, "Alert Range", 5.0, 50.0, 15.0)

-- ══════════════════════════════════════════════
--  INMATE UI
-- ══════════════════════════════════════════════

ui.NewCheckbox(T, CI, "Escape on Low HP")
ui.newSliderInt(T, CI, "HP %", 5, 50, 25)
ui.NewDropdown(T, CI, "Escape To", {"Criminal Base","Outside Gate"}, 1)
ui.NewCheckbox(T, CI, "Anti Arrest")
ui.newSliderFloat(T, CI, "Guard Range", 5.0, 20.0, 8.0)

-- ══════════════════════════════════════════════
--  MISC UI
-- ══════════════════════════════════════════════

ui.NewCheckbox(T, CM, "FPS Boost")
ui.NewCheckbox(T, CM, "Panic Button")
ui.NewHotkey(T, CM)

-- ══════════════════════════════════════════════
--  GUARD STATE
-- ══════════════════════════════════════════════

local CLICK_CD    = 250
local TP_TIMEOUT  = 8000
local last_click  = 0
local arr_active  = false
local arr_status  = "READY"
local tp_name     = nil
local tp_locked   = false
local tp_start    = 0
local last_alert  = 0
local alert_beep  = false

local function reset_tp()
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

-- ── Auto Arrest ────────────────────────────────
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
        if h then h.Position = Vector3.new(t.Position.X, t.Position.Y, t.Position.Z+2.5) end
        click(t)
    end
end

-- ── TP Arrest ─────────────────────────────────
local function run_tp_arrest()
    if not ui.getValue(T, CG, "TP Arrest") then reset_tp(); return end
    if not cuffs() then arr_status = "NO HANDCUFFS"; return end

    local n = now()
    local h = hrp(); if not h then return end

    -- Auto-reset on timeout
    if tp_locked and n - tp_start > TP_TIMEOUT then
        print("[PLWare] Timeout — next target"); reset_tp(); return
    end

    local target = nil
    if tp_locked and tp_name then
        local p = get_by_name(tp_name)
        if not p or not valid_target(p) then
            print("[PLWare] Arrested: " .. (tp_name or "?")); reset_tp(); return
        end
        target = p
    else
        local best = find_target(ui.getValue(T, CG, "TP Range"))
        if not best then reset_tp(); return end
        tp_name   = best.Name
        tp_locked = true
        tp_start  = n
        save()
        print("[PLWare] Chasing: " .. best.Name)
        target = best
    end

    if not target then return end

    -- Smooth TP beside target using direction vector
    local tp_pos = target.Position
    local dx     = tp_pos.X - h.Position.X
    local dz     = tp_pos.Z - h.Position.Z
    local mag    = math.sqrt(dx*dx + dz*dz)
    local ox, oz = (mag > 0.1) and dx/mag*2 or 0, (mag > 0.1) and dz/mag*2 or 2
    h.Position   = Vector3.new(tp_pos.X-ox, tp_pos.Y, tp_pos.Z-oz)
    wait_ms(25)
    h.Position   = Vector3.new(tp_pos.X-ox, tp_pos.Y, tp_pos.Z-oz)

    if n - last_click >= CLICK_CD then
        last_click = n; click(target)
    end
end

-- ── Proximity Alert ────────────────────────────
local function run_proximity_alert()
    if not ui.getValue(T, CG, "Proximity Alert") then return end
    local n = now()
    if n - last_alert < 2000 then return end
    local h = hrp(); if not h then return end
    local range = ui.getValue(T, CG, "Alert Range")
    for _, p in ipairs(entity.GetPlayers(true)) do
        if valid_target(p) and (p.Position - h.Position).Magnitude <= range then
            last_alert = n
            audio.beep(880, 150)
            wait_ms(80)
            audio.beep(1100, 100)
            return
        end
    end
end

-- ══════════════════════════════════════════════
--  INMATE STATE
-- ══════════════════════════════════════════════

local last_esc    = 0
local last_anti   = 0
local just_esc    = false
local esc_time    = 0

local function run_escape()
    if not ui.getValue(T, CI, "Escape on Low HP") then return end
    local n = now(); if n - last_esc < 3000 then return end
    local p = lp(); if not p or p.MaxHealth <= 0 then return end
    local thresh = ui.getValue(T, CI, "HP %")
    if (p.Health / p.MaxHealth * 100) <= thresh then
        last_esc  = n
        just_esc  = true
        esc_time  = n
        local idx  = ui.getValue(T, CI, "Escape To")
        local name = ESC_NAMES[idx+1] or "Criminal Base"
        local d    = ESC_LOCS[name]
        if d then
            tp(d[1], d[2], d[3])
            print("[PLWare] ESCAPE → " .. name)
        end
    end
end

local function run_anti_arrest()
    if not ui.getValue(T, CI, "Anti Arrest") then return end
    local n = now()
    if just_esc and n - esc_time < 4000 then return end
    just_esc = false
    if n - last_anti < 2000 then return end
    local h = hrp(); if not h then return end
    local range = ui.getValue(T, CI, "Guard Range")
    local mp    = h.Position
    local me    = lp()
    for _, p in ipairs(entity.GetPlayers()) do
        if p.IsAlive and not is_crim(p) and me and p.Name ~= me.Name then
            if (p.Position - mp).Magnitude <= range then
                last_anti = n
                tp(-974.4, 108.3, 2057.2)
                print("[PLWare] Guard detected — anti-arrest TP!")
                return
            end
        end
    end
end

-- ══════════════════════════════════════════════
--  FPS BOOST
-- ══════════════════════════════════════════════

local fps_active = false

local function set_fps_boost(on)
    if on == fps_active then return end
    fps_active = on
    local lg = game.GetService("Lighting"); if not lg then return end
    pcall(function() lg.GlobalShadows  = not on   end)
    pcall(function() lg.FogEnd         = on and 100000 or 1000 end)
    pcall(function() lg.FogStart       = on and 99999  or 0    end)
    pcall(function() lg.ShadowSoftness = on and 0      or 0.2  end)
    print("[PLWare] FPS Boost: " .. (on and "ON" or "OFF"))
end

-- ══════════════════════════════════════════════
--  PANIC BUTTON
--  Instantly TPs to armory when hotkey pressed
-- ══════════════════════════════════════════════

local function run_panic()
    if not ui.getValue(T, CM, "Panic Button") then return end
    local hk = ui.GetHotkey(T, CM, "Panic Button")
    -- Panic: TP to armory instantly
    -- (hotkey handled via ui.GetHotkey — trigger manually via button too)
end

ui.NewButton(T, CM, "Panic TP Now", function()
    tp(816.5, 100.7, 2227.9)
    print("[PLWare] PANIC — Armory!")
end)

-- ══════════════════════════════════════════════
--  THREAT TRACKER
--  Criminal prediction lines + health + velocity
-- ══════════════════════════════════════════════

local threat_cache    = {}
local last_threat_upd = 0

local function update_threats()
    local n = now(); if n - last_threat_upd < 300 then return end
    last_threat_upd = n
    threat_cache = {}
    for _, p in ipairs(entity.GetPlayers(true)) do
        if valid_target(p) then
            table.insert(threat_cache, {
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
    if #threat_cache == 0 then return end

    local sw, sh   = cheat.getWindowSize()
    local cx, cy   = sw/2, sh/2
    local h        = hrp()

    for _, c in ipairs(threat_cache) do
        local sx, sy, vis = utility.WorldToScreen(c.pos)
        if vis then
            local hp_pct = c.maxhp > 0 and (c.hp / c.maxhp) or 1
            local r = math.floor(255*(1-hp_pct))
            local g = math.floor(255*hp_pct)
            local tc = Color3.fromRGB(r, g, 30)

            -- Line from crosshair to target
            draw.Line(cx, cy, sx, sy, Color3.fromRGB(255,80,0), 1, 100)

            -- Target circle
            draw.Circle(sx, sy, 10, tc, 1.5, 16, 220)

            -- Velocity prediction arrow (1.5s ahead)
            local spd = math.sqrt(c.vel.X^2 + c.vel.Z^2)
            if spd > 1 then
                local pred = Vector3.new(
                    c.pos.X + c.vel.X*1.5,
                    c.pos.Y + c.vel.Y*1.5,
                    c.pos.Z + c.vel.Z*1.5
                )
                local px, py, pvis = utility.WorldToScreen(pred)
                if pvis then
                    draw.Line(sx, sy, px, py, Color3.fromRGB(255,230,0), 1, 130)
                    -- Arrow head diamond
                    local d = 5
                    draw.Line(px-d,py, px,py-d, Color3.fromRGB(255,230,0), 1, 200)
                    draw.Line(px,py-d, px+d,py, Color3.fromRGB(255,230,0), 1, 200)
                    draw.Line(px+d,py, px,py+d, Color3.fromRGB(255,230,0), 1, 200)
                    draw.Line(px,py+d, px-d,py, Color3.fromRGB(255,230,0), 1, 200)
                end
            end

            -- Info label: name + dist + HP
            local dist = h and (c.pos - h.Position).Magnitude or 0
            local info = string.format("%s  %.0fm  %d%%", c.name, dist, math.floor(hp_pct*100))
            local tw, th = draw.GetTextSize(info, "ConsolasBold")
            draw.TextOutlined(info, sx-(tw/2), sy-14-th, tc, "ConsolasBold")
        end
    end
end

-- ══════════════════════════════════════════════
--  HUD — bottom-left status panel
--  Clean bracket style with ConsolasBold
-- ══════════════════════════════════════════════

local FONT   = "ConsolasBold"
local C_LIVE = Color3.fromRGB(80,  255, 120)  -- active / ok
local C_WARN = Color3.fromRGB(255, 200, 0  )  -- warning
local C_DEAD = Color3.fromRGB(255, 60,  60 )  -- danger / locking
local C_INFO = Color3.fromRGB(160, 200, 255)  -- info / searching
local C_DIM  = Color3.fromRGB(120, 120, 120)  -- dim

local function hud()
    local sw, sh = cheat.getWindowSize()
    local x  = 12
    local y  = sh - 18
    local lh = 17  -- line height, draw upwards

    local function ln(txt, col)
        draw.TextOutlined(txt, x, y, col, FONT)
        y = y - lh
    end

    -- Version watermark
    ln("PLWare " .. PLW_VERSION, C_DIM)
    y = y - 4  -- small gap after watermark

    -- ── Misc ────────────────────
    if fps_active       then ln("[ FPS BOOST ]", C_INFO) end
    if ui.getValue(T, CM, "Panic Button") then
        ln("[ PANIC READY ]", C_LIVE)
    end

    -- ── Inmate ──────────────────
    if ui.getValue(T, CI, "Anti Arrest") then
        ln("[ ANTI ARREST ]", Color3.fromRGB(180, 80, 255))
    end

    if ui.getValue(T, CI, "Escape on Low HP") then
        local p = lp()
        if p and p.MaxHealth > 0 then
            local hp  = math.floor(p.Health/p.MaxHealth*100)
            local thr = ui.getValue(T, CI, "HP %")
            local col = (hp <= thr) and C_DEAD or C_LIVE
            ln(string.format("[ HP %d%% | ESC %d%% ]", hp, thr), col)
        end
    end

    -- ── Guard ───────────────────
    if ui.getValue(T, CG, "Proximity Alert") then
        ln("[ ALERT ACTIVE ]", C_WARN)
    end

    if ui.getValue(T, CG, "Threat Tracker") then
        local cnt = #threat_cache
        local col = cnt > 0 and C_DEAD or C_LIVE
        ln(string.format("[ THREATS: %d ]", cnt), col)
    end

    if ui.getValue(T, CG, "TP Arrest") then
        if not cuffs() then
            ln("[ TP ARREST: CUFFS ]", C_WARN)
        elseif tp_name then
            ln("[ CHASING: " .. tp_name .. " ]", C_DEAD)
        else
            ln("[ TP ARREST: SCAN ]", C_INFO)
        end
    end

    if ui.getValue(T, CG, "Auto Arrest") then
        if not cuffs() then
            ln("[ AUTO ARR: CUFFS ]", C_WARN)
        elseif arr_active then
            ln("[ ARREST: " .. arr_status .. " ]", C_DEAD)
        else
            ln("[ AUTO ARR: READY ]", C_LIVE)
        end
    end
end

-- ══════════════════════════════════════════════
--  CALLBACKS
-- ══════════════════════════════════════════════

sched.every(800, refresh_esp)

cheat.register("onPaint", function()
    draw_esp()
    draw_threat_tracker()
    hud()
    local want = ui.getValue(T, CM, "FPS Boost")
    if want ~= fps_active then set_fps_boost(want) end
end)

cheat.register("onUpdate", function()
    sched.tick()
    update_threats()
    run_auto_arrest()
    run_tp_arrest()
    run_proximity_alert()
    run_escape()
    run_anti_arrest()
end)

-- ══════════════════════════════════════════════
print("[PrisonLifeWare " .. PLW_VERSION .. "] Loaded")
