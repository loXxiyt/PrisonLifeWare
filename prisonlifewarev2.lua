-- ╔══════════════════════════════════════════╗
--   PrisonLifeWare v2.5  |  loXxiyt
--   github.com/loXxiyt/PrisonLifeWare
-- ╚══════════════════════════════════════════╝

local PLW_VERSION = "v2.5"

local T  = "PLWare"
local CE = "ESP"
local CT = "TPS"
local CG = "GUARD"
local CI = "INMATE"
local CM = "MISC"

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
--  HELPERS
-- ══════════════════════════════════════════════

local function lp()  return entity.GetLocalPlayer() end
local function now() return utility.GetTickCount()  end

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

local function aim(p)
    local bp = p:GetBonePosition("HumanoidRootPart")
            or p:GetBonePosition("Torso")
            or p.Position
    local sx, sy, vis = utility.WorldToScreen(bp)
    if vis then game.SilentAim(sx, sy) end
    return sx, sy, vis
end

local function click(p)
    local _, _, vis = aim(p)
    if vis then mouse.Click("leftmouse"); return true end
    return false
end

-- Check if a player has handcuffs (actual arrest threat)
local function has_cuffs(p)
    local c = game.Workspace:FindFirstChild(p.Name); if not c then return false end
    local t = c:FindFirstChildOfClass("Tool"); if not t then return false end
    local n = string.lower(t.Name)
    return n == "handcuffs" or n == "menottes"
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
    local cc  = ui.getValue(T, CE, "Card Color")
    local gc  = ui.getValue(T, CE, "Weapon Color")
    local cc3 = Color3.fromRGB(cc.r, cc.g, cc.b)
    local gc3 = Color3.fromRGB(gc.r, gc.g, gc.b)
    local function render(e, label, col)
        local sx, sy, vis = utility.WorldToScreen(e.pos)
        if not vis then return end
        local hw = 14
        draw.Rect(sx-hw, sy-hw, hw*2, hw*2, col, 1.0)
        local k = 4
        draw.Line(sx-hw,   sy-hw,   sx-hw+k, sy-hw,   col, 2)
        draw.Line(sx-hw,   sy-hw,   sx-hw,   sy-hw+k, col, 2)
        draw.Line(sx+hw,   sy-hw,   sx+hw-k, sy-hw,   col, 2)
        draw.Line(sx+hw,   sy-hw,   sx+hw,   sy-hw+k, col, 2)
        draw.Line(sx-hw,   sy+hw,   sx-hw+k, sy+hw,   col, 2)
        draw.Line(sx-hw,   sy+hw,   sx-hw,   sy+hw-k, col, 2)
        draw.Line(sx+hw,   sy+hw,   sx+hw-k, sy+hw,   col, 2)
        draw.Line(sx+hw,   sy+hw,   sx+hw,   sy+hw-k, col, 2)
        local tw, th = draw.GetTextSize(label, "ConsolasBold")
        draw.TextOutlined(label, sx-(tw/2), sy-hw-th-3, col, "ConsolasBold")
        local ds = string.format("%.0fm", e.dist)
        local dw, _ = draw.GetTextSize(ds, "ConsolasBold")
        draw.TextOutlined(ds, sx-(dw/2), sy+hw+3, Color3.fromRGB(160,160,160), "ConsolasBold")
    end
    if c_on then for _, e in pairs(esp_cards) do render(e, "CARD",   cc3) end end
    if g_on then for _, e in pairs(esp_guns)  do render(e, e.name,  gc3) end end
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
local ESC_LOCS  = {
    ["Criminal Base"] = {-974.4, 108.3, 2057.2},
    ["Outside Gate"]  = {491.4,  95.5,  2052.5},
}
local ESC_NAMES = {"Criminal Base","Outside Gate"}

ui.NewDropdown(T, CT, "Location", LOC_NAMES, 1)
ui.NewButton(T, CT, "Teleport", function()
    local idx  = ui.getValue(T, CT, "Location")
    local name = LOC_NAMES[idx+1]; if not name then return end
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
    for _, px in ipairs({817.0, 820.3, 813.8, 820.3, 819.0}) do
        h.Position = Vector3.new(px, Y, Z); wait_ms(200)
        h.Position = Vector3.new(px, Y, Z); wait_ms(100)
    end
    print("[PLWare] Done — returning...")
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
    for i = 1, 3 do
        h.Position = Vector3.new(best.pos.X, best.pos.Y+1, best.pos.Z)
        wait_ms(80)
    end
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
ui.newSliderFloat(T, CG, "TP Range", 50.0, 5000.0, 300.0)
ui.NewCheckbox(T, CG, "Threat Tracker")
ui.NewCheckbox(T, CG, "Proximity Alert")
ui.newSliderFloat(T, CG, "Alert Range", 5.0, 50.0, 15.0)

-- ══════════════════════════════════════════════
--  INMATE UI
-- ══════════════════════════════════════════════

ui.NewCheckbox(T, CI, "Escape on Low HP")
ui.newSliderInt(T, CI, "HP %", 5, 50, 25)
ui.NewDropdown(T, CI, "Escape To", {"Criminal Base","Outside Gate"}, 1)
ui.NewCheckbox(T, CI, "Guard Detector")
ui.newSliderFloat(T, CI, "Detect Range", 5.0, 25.0, 10.0)
ui.NewCheckbox(T, CI, "Ghost Jitter")
ui.NewCheckbox(T, CI, "Auto Sprint")

-- ══════════════════════════════════════════════
--  MISC UI
-- ══════════════════════════════════════════════

ui.NewCheckbox(T, CM, "Panic Button")
ui.NewButton(T, CM, "Panic TP Now", function()
    tp(816.5, 100.7, 2227.9)
    print("[PLWare] PANIC → Armory!")
end)

-- ══════════════════════════════════════════════
--  GUARD STATE
-- ══════════════════════════════════════════════

local CLICK_CD   = 250
-- TP Arrest cycle: active for 3s then resets itself
-- This prevents the "frozen" state where it stops working
local TP_CYCLE   = 3000   -- arrest for 3s then reset and re-lock
local last_click = 0
local arr_active = false
local arr_status = "READY"

-- TP Arrest state
local tp_name    = nil
local tp_locked  = false
local tp_start   = 0      -- when current lock started
local last_alert = 0

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

-- ── Auto Arrest ───────────────────────────────
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
            h.Position = Vector3.new(t.Position.X, t.Position.Y, t.Position.Z+2.5)
        end
        click(t)
    end
end

-- ── TP Arrest with forced cycle reset ─────────
-- Every TP_CYCLE ms it resets the lock completely
-- then immediately re-acquires — this forces a fresh
-- aim + position cycle which fixes the "frozen" state
local function run_tp_arrest()
    if not ui.getValue(T, CG, "TP Arrest") then
        reset_tp(); return
    end
    if not cuffs() then return end

    local n = now()
    local h = hrp(); if not h then return end

    -- FORCED CYCLE RESET every TP_CYCLE ms
    -- This is the fix for the frozen arrest issue
    if tp_locked and n - tp_start >= TP_CYCLE then
        reset_tp()  -- wipe state completely
        return       -- skip this frame, re-acquire next frame
    end

    -- Find or validate target
    local target = nil
    if tp_locked and tp_name then
        local p = get_by_name(tp_name)
        -- Target gone or no longer valid = arrested
        if not p or not valid_target(p) then
            print("[PLWare] Arrested: " .. (tp_name or "?"))
            reset_tp(); return
        end
        target = p
    else
        -- Acquire new target
        local best = find_target(ui.getValue(T, CG, "TP Range"))
        if not best then reset_tp(); return end
        tp_name   = best.Name
        tp_locked = true
        tp_start  = n
        save()
        print("[PLWare] Target: " .. best.Name)
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

    -- Click at arrest CD
    if n - last_click >= CLICK_CD then
        last_click = n
        click(target)
    end
end

-- ── Proximity Alert ───────────────────────────
local function run_proximity_alert()
    if not ui.getValue(T, CG, "Proximity Alert") then return end
    local n = now(); if n - last_alert < 2500 then return end
    local h = hrp(); if not h then return end
    local range = ui.getValue(T, CG, "Alert Range")
    for _, p in ipairs(entity.GetPlayers(true)) do
        if valid_target(p) and (p.Position - h.Position).Magnitude <= range then
            last_alert = n
            audio.beep(880, 120)
            wait_ms(70)
            audio.beep(1200, 80)
            return
        end
    end
end

-- ══════════════════════════════════════════════
--  INMATE FEATURES
-- ══════════════════════════════════════════════

local last_esc     = 0
local last_detect  = 0
local just_esc     = false
local esc_time     = 0
local ghost_timer  = 0
local ghost_dir    = 1

-- ── Escape on Low HP ─────────────────────────
-- Checks every 500ms, aggressive TP with 5 attempts
local function run_escape()
    if not ui.getValue(T, CI, "Escape on Low HP") then return end
    local n = now(); if n - last_esc < 500 then return end
    last_esc = n
    local p = lp(); if not p or p.MaxHealth <= 0 then return end
    local thresh = ui.getValue(T, CI, "HP %")
    local hp_pct = (p.Health / p.MaxHealth) * 100
    if hp_pct <= thresh then
        -- Set cooldown longer to avoid spam
        last_esc  = n + 3000
        just_esc  = true
        esc_time  = n
        local idx  = ui.getValue(T, CI, "Escape To")
        local name = ESC_NAMES[idx+1] or "Criminal Base"
        local d    = ESC_LOCS[name]
        if d then
            -- 5 aggressive TPs to make sure it lands
            local h = hrp()
            if h then
                for i = 1, 5 do
                    h.Position = Vector3.new(d[1], d[2], d[3])
                    wait_ms(60)
                end
            end
            print("[PLWare] ESCAPE → " .. name .. " (" .. math.floor(hp_pct) .. "%)")
        end
    end
end

-- ── Guard Detector ────────────────────────────
-- Detects guards with handcuffs specifically
-- Much more reliable than generic team check
local function run_guard_detector()
    if not ui.getValue(T, CI, "Guard Detector") then return end
    local n = now()
    -- Suppress for 5s after escape TP
    if just_esc and n - esc_time < 5000 then return end
    just_esc = false
    if n - last_detect < 1500 then return end
    local h = hrp(); if not h then return end
    local range = ui.getValue(T, CI, "Detect Range")
    local mp    = h.Position
    local me    = lp()
    for _, p in ipairs(entity.GetPlayers()) do
        if p.IsAlive and me and p.Name ~= me.Name then
            local dist = (p.Position - mp).Magnitude
            if dist <= range and has_cuffs(p) then
                -- Guard with cuffs nearby = real threat
                last_detect = n
                local idx  = ui.getValue(T, CI, "Escape To")
                local name = ESC_NAMES[idx+1] or "Criminal Base"
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

-- ── Ghost Jitter ─────────────────────────────
-- Rapidly microshifts your position making it
-- very hard for guards to get a clean arrest click
-- Subtle enough that it looks like network lag
local function run_ghost_jitter(dt)
    if not ui.getValue(T, CI, "Ghost Jitter") then return end
    local h = hrp(); if not h then return end
    ghost_timer = ghost_timer + dt
    if ghost_timer < 0.08 then return end  -- fires ~12x per second
    ghost_timer = 0
    ghost_dir   = ghost_dir * -1
    local pos   = h.Position
    local shift = ghost_dir * 0.4  -- tiny shift, barely visible
    h.Position  = Vector3.new(pos.X + shift, pos.Y, pos.Z + shift)
end

-- ── Auto Sprint ───────────────────────────────
-- Holds shift constantly so you always run
-- Releases on death to avoid getting stuck
local sprint_was_on = false
local function run_auto_sprint()
    local on = ui.getValue(T, CI, "Auto Sprint")
    if on then
        if not sprint_was_on then
            keyboard.Press("lshift")
            sprint_was_on = true
        end
    else
        if sprint_was_on then
            keyboard.Release("lshift")
            sprint_was_on = false
        end
    end
end

-- ══════════════════════════════════════════════
--  THREAT TRACKER
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
    local sw, sh = cheat.getWindowSize()
    local cx, cy = sw/2, sh/2
    local h      = hrp()
    for _, c in ipairs(threat_cache) do
        local sx, sy, vis = utility.WorldToScreen(c.pos)
        if vis then
            local hp_pct = c.maxhp > 0 and (c.hp/c.maxhp) or 1
            local r  = math.floor(255*(1-hp_pct))
            local g  = math.floor(255*hp_pct)
            local tc = Color3.fromRGB(r, g, 30)
            -- Line from center to target
            draw.Line(cx, cy, sx, sy, Color3.fromRGB(255,80,0), 1, 90)
            -- Target ring
            draw.Circle(sx, sy, 10, tc, 1.5, 16, 200)
            -- Velocity arrow
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
                    draw.Line(px-d,py,   px,   py-d, Color3.fromRGB(255,230,0), 1, 180)
                    draw.Line(px,   py-d, px+d, py,   Color3.fromRGB(255,230,0), 1, 180)
                    draw.Line(px+d, py,   px,   py+d, Color3.fromRGB(255,230,0), 1, 180)
                    draw.Line(px,   py+d, px-d, py,   Color3.fromRGB(255,230,0), 1, 180)
                end
            end
            -- Label
            local dist = h and (c.pos - h.Position).Magnitude or 0
            local info = string.format("%s  %.0fm  %d%%", c.name, dist, math.floor(hp_pct*100))
            local tw, th = draw.GetTextSize(info, "ConsolasBold")
            draw.TextOutlined(info, sx-(tw/2), sy-14-th, tc, "ConsolasBold")
        end
    end
end

-- ══════════════════════════════════════════════
--  HUD
-- ══════════════════════════════════════════════

local FONT  = "ConsolasBold"
local C_OK  = Color3.fromRGB(80,  255, 120)
local C_WRN = Color3.fromRGB(255, 200, 0  )
local C_ERR = Color3.fromRGB(255, 60,  60 )
local C_NFO = Color3.fromRGB(140, 190, 255)
local C_DIM = Color3.fromRGB(100, 100, 100)
local C_PRP = Color3.fromRGB(180, 80,  255)

local function hud()
    local sw, sh = cheat.getWindowSize()
    local x  = 12
    local y  = sh - 18
    local lh = 16

    local function ln(txt, col)
        draw.TextOutlined(txt, x, y, col, FONT)
        y = y - lh
    end

    -- Watermark
    ln("PLWare " .. PLW_VERSION, C_DIM)
    y = y - 3

    -- Misc
    if ui.getValue(T, CM, "Panic Button") then
        ln("[ PANIC READY ]", C_WRN)
    end

    -- Inmate
    if ui.getValue(T, CI, "Auto Sprint") then
        ln("[ SPRINT: ON ]", C_OK)
    end

    if ui.getValue(T, CI, "Ghost Jitter") then
        ln("[ GHOST JITTER ]", C_PRP)
    end

    if ui.getValue(T, CI, "Guard Detector") then
        ln("[ GUARD DETECT ]", C_PRP)
    end

    if ui.getValue(T, CI, "Escape on Low HP") then
        local p = lp()
        if p and p.MaxHealth > 0 then
            local hp  = math.floor(p.Health/p.MaxHealth*100)
            local thr = ui.getValue(T, CI, "HP %")
            local col = (hp <= thr) and C_ERR or C_OK
            ln(string.format("[ HP %d%% | ESC <%d%% ]", hp, thr), col)
        end
    end

    -- Guard
    if ui.getValue(T, CG, "Proximity Alert") then
        ln("[ ALERT ON ]", C_WRN)
    end

    if ui.getValue(T, CG, "Threat Tracker") then
        local cnt = #threat_cache
        ln(string.format("[ THREATS: %d ]", cnt), cnt > 0 and C_ERR or C_OK)
    end

    if ui.getValue(T, CG, "TP Arrest") then
        if not cuffs() then
            ln("[ TP: NEED CUFFS ]", C_WRN)
        elseif tp_name then
            ln("[ TP → " .. tp_name .. " ]", C_ERR)
        else
            ln("[ TP: SCAN ]", C_NFO)
        end
    end

    if ui.getValue(T, CG, "Auto Arrest") then
        if not cuffs() then
            ln("[ ARR: NEED CUFFS ]", C_WRN)
        elseif arr_active then
            ln("[ ARR: " .. arr_status .. " ]", C_ERR)
        else
            ln("[ ARR: READY ]", C_OK)
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
end)

cheat.register("onUpdate", function()
    local dt = utility.GetDeltaTime()
    sched.tick()
    update_threats()
    -- Guard
    run_auto_arrest()
    run_tp_arrest()
    run_proximity_alert()
    -- Inmate
    run_escape()
    run_guard_detector()
    run_ghost_jitter(dt)
    run_auto_sprint()
end)

-- ══════════════════════════════════════════════
print("[PrisonLifeWare " .. PLW_VERSION .. "] Loaded")
