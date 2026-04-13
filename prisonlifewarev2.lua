-- ============================================
--  PrisonLifeWare v2
--  github.com/loXxiyt/PrisonLifeWare
-- ============================================

local TAB_MAIN = "PLWare"
local C_ESP    = "ItemESP"
local C_TP     = "Teleports"
local C_GUARD  = "Guard"
local C_INMATE = "Inmate"
local C_MISC   = "Misc"

ui.newTab(TAB_MAIN, "PrisonLifeWare")
ui.NewContainer(TAB_MAIN, C_ESP,    "Item ESP",  { autosize = true, next = true })
ui.NewContainer(TAB_MAIN, C_TP,     "Teleports", { autosize = true, next = true })
ui.NewContainer(TAB_MAIN, C_GUARD,  "Guard",     { autosize = true, next = true })
ui.NewContainer(TAB_MAIN, C_INMATE, "Inmate",    { autosize = true, next = true })
ui.NewContainer(TAB_MAIN, C_MISC,   "Misc",      { autosize = true })

-- ============================================
--  SCHEDULER
-- ============================================

local scheduler = { tasks = {}, intervals = {} }

function scheduler.after(ms, cb)
    table.insert(scheduler.tasks, { time = utility.GetTickCount() + ms, cb = cb })
end

function scheduler.every(ms, cb)
    table.insert(scheduler.intervals, { delay = ms, last_run = utility.GetTickCount(), cb = cb })
end

function scheduler.run()
    local now = utility.GetTickCount()
    for i = #scheduler.tasks, 1, -1 do
        local t = scheduler.tasks[i]
        if now >= t.time then t.cb(); table.remove(scheduler.tasks, i) end
    end
    for _, iv in ipairs(scheduler.intervals) do
        if now - iv.last_run >= iv.delay then iv.last_run = now; iv.cb() end
    end
end

-- ============================================
--  HELPERS
-- ============================================

local function get_local_player()
    return entity.GetLocalPlayer()
end

local function get_char()
    local lp = get_local_player()
    if not lp then return nil end
    local ok, r = pcall(function() return game.Workspace:FindFirstChild(lp.Name) end)
    return ok and r or nil
end

local function get_hrp()
    local char = get_char()
    if not char then return nil end
    local ok, r = pcall(function() return char:FindFirstChild("HumanoidRootPart") end)
    return ok and r or nil
end

local function wait_ms(ms)
    local s = utility.GetTickCount()
    while utility.GetTickCount() - s < ms do end
end

local function get_part(obj)
    return obj:FindFirstChild("Handle")
        or obj:FindFirstChild("Mesh")
        or obj:FindFirstChildOfClass("MeshPart")
        or obj:FindFirstChildOfClass("Part")
end

local function has_handcuffs()
    local char = get_char()
    if not char then return false end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return false end
    local n = string.lower(tool.Name)
    return n == "handcuffs" or n == "menottes"
end

local function is_criminal(player)
    local t = player.Team
    return t and string.find(string.lower(t), "criminal") ~= nil
end

local WEAPON_NAMES = {
    ["AK-47"]=true,["Remington 870"]=true,["Taser"]=true,
    ["M9"]=true,["FAL"]=true,["M700"]=true,["MP5"]=true,
    ["M4A1"]=true,["Revolver"]=true,["C4 Explosive"]=true,
    ["Crude Knife"]=true,["Hammer"]=true,["EBR"]=true,
}

local function inmate_has_weapon(player)
    local char = game.Workspace:FindFirstChild(player.Name)
    if not char then return false end
    local tool = char:FindFirstChildOfClass("Tool")
    return tool and WEAPON_NAMES[tool.Name] == true
end

local function aim_at_player(player)
    local bp = player:GetBonePosition("HumanoidRootPart")
           or player:GetBonePosition("Torso")
           or player.Position
    local sx, sy, vis = utility.WorldToScreen(bp)
    if vis then game.SilentAim(sx, sy); return sx, sy, true end
    return 0, 0, false
end

local function aim_and_click(player)
    local sx, sy, vis = aim_at_player(player)
    if vis then mouse.Click("leftmouse"); return true end
    return false
end

local function is_valid_target(player)
    if not player.IsAlive then return false end
    return is_criminal(player) or inmate_has_weapon(player)
end

-- ============================================
--  ITEM ESP
-- ============================================

ui.NewCheckbox(TAB_MAIN, C_ESP, "Card ESP")
ui.NewCheckbox(TAB_MAIN, C_ESP, "Gun ESP")
ui.NewColorpicker(TAB_MAIN, C_ESP, "Card Color", {r=0,   g=255, b=255, a=255}, true)
ui.NewColorpicker(TAB_MAIN, C_ESP, "Gun Color",  {r=255, g=150, b=0,   a=255}, true)
ui.newSliderInt(TAB_MAIN, C_ESP, "Max Distance", 50, 2000, 1000)

local CARD_NAMES = {["Key card"]=true, ["Key Card"]=true}
local GUN_NAMES  = {
    ["AK-47"]=true,["Remington 870"]=true,["Taser"]=true,
    ["M9"]=true,["FAL"]=true,["M700"]=true,["MP5"]=true,
    ["M4A1"]=true,["Revolver"]=true,["C4 Explosive"]=true,
    ["Riot Shield"]=true,["Crude Knife"]=true,["Hammer"]=true,["EBR"]=true,
}

local cached_cards = {}
local cached_guns  = {}

local function cache_items()
    cached_cards = {}
    cached_guns  = {}
    local card_on  = ui.getValue(TAB_MAIN, C_ESP, "Card ESP")
    local gun_on   = ui.getValue(TAB_MAIN, C_ESP, "Gun ESP")
    if not card_on and not gun_on then return end
    local max_dist = ui.getValue(TAB_MAIN, C_ESP, "Max Distance")
    local cam_pos  = game.CameraPosition
    local ok, ch   = pcall(function() return game.Workspace:GetChildren() end)
    if not ok then return end
    for _, obj in pairs(ch) do
        if obj.ClassName == "Model" or obj.ClassName == "Tool" then
            local part = get_part(obj)
            if part then
                local pos  = part.Position
                local dist = cam_pos and (cam_pos - pos).Magnitude or 0
                if dist <= max_dist then
                    if card_on and CARD_NAMES[obj.Name] then
                        table.insert(cached_cards, {pos=pos, dist=dist, name=obj.Name})
                    elseif gun_on and GUN_NAMES[obj.Name] then
                        table.insert(cached_guns, {pos=pos, dist=dist, name=obj.Name})
                    end
                end
            end
        end
    end
end

local function draw_cached_esp()
    local card_on = ui.getValue(TAB_MAIN, C_ESP, "Card ESP")
    local gun_on  = ui.getValue(TAB_MAIN, C_ESP, "Gun ESP")
    if not card_on and not gun_on then return end
    local cc  = ui.getValue(TAB_MAIN, C_ESP, "Card Color")
    local gc  = ui.getValue(TAB_MAIN, C_ESP, "Gun Color")
    local cc3 = Color3.fromRGB(cc.r, cc.g, cc.b)
    local gc3 = Color3.fromRGB(gc.r, gc.g, gc.b)
    local function de(e, lbl, col)
        local sx, sy, ok = utility.WorldToScreen(e.pos)
        if not ok then return end
        draw.Rect(sx-15, sy-15, 30, 30, col, 1.5)
        local tw, th = draw.GetTextSize(lbl)
        draw.TextOutlined(lbl, sx-(tw/2), sy-20-th, col)
        local dt = string.format("%.0fm", e.dist)
        local dw, _ = draw.GetTextSize(dt)
        draw.TextOutlined(dt, sx-(dw/2), sy+18, Color3.fromRGB(200,200,200))
    end
    if card_on then for _, e in pairs(cached_cards) do de(e, "KEY CARD", cc3) end end
    if gun_on  then for _, e in pairs(cached_guns)  do de(e, e.name,    gc3) end end
end

-- ============================================
--  TELEPORTS
-- ============================================

local loc_names = {
    "Armory","Criminal Base","Prison Yard",
    "Cells","Cafeteria","Outside Gate",
}
local LOCS = {
    ["Armory"]        = Vector3.new(816.5,  100.7, 2227.9),
    ["Criminal Base"] = Vector3.new(-974.4, 108.3, 2057.2),
    ["Prison Yard"]   = Vector3.new(807.9,  98.0,  2484.0),
    ["Cells"]         = Vector3.new(918.8,  100.0, 2484.5),
    ["Cafeteria"]     = Vector3.new(919.1,  100.0, 2227.9),
    ["Outside Gate"]  = Vector3.new(491.4,  95.5,  2052.5),
}
local esc_locs  = {
    ["Criminal Base"] = Vector3.new(-974.4, 108.3, 2057.2),
    ["Outside Gate"]  = Vector3.new(491.4,  95.5,  2052.5),
}
local esc_names = {"Criminal Base","Outside Gate"}

ui.NewDropdown(TAB_MAIN, C_TP, "Location", loc_names, 1)

ui.NewButton(TAB_MAIN, C_TP, "Teleport", function()
    local hrp = get_hrp()
    if not hrp then return end
    local idx  = ui.getValue(TAB_MAIN, C_TP, "Location")
    local name = loc_names[idx + 1]
    if not name then return end
    local dest = LOCS[name]
    if dest then
        for i = 1, 3 do hrp.Position = Vector3.new(dest.X, dest.Y, dest.Z); wait_ms(50) end
        print("[PLWare] Teleported to " .. name)
    end
end)

local saved_x, saved_y, saved_z = nil, nil, nil

local function save_pos()
    local hrp = get_hrp()
    if hrp then
        saved_x = hrp.Position.X
        saved_y = hrp.Position.Y
        saved_z = hrp.Position.Z
    end
end

local function tp_saved()
    local hrp = get_hrp()
    if hrp and saved_x then
        for i = 1, 3 do hrp.Position = Vector3.new(saved_x, saved_y, saved_z); wait_ms(50) end
    end
end

ui.NewButton(TAB_MAIN, C_TP, "Save Position", function()
    save_pos()
    if saved_x then print(string.format("[PLWare] Saved: %.1f %.1f %.1f", saved_x, saved_y, saved_z)) end
end)

ui.NewButton(TAB_MAIN, C_TP, "Grab Gun (TP + Jiggle)", function()
    local hrp = get_hrp()
    if not hrp then return end
    save_pos()
    local Y, Z = 100.7, 2227.9
    local steps = {
        Vector3.new(817.0,Y,Z), Vector3.new(820.3,Y,Z),
        Vector3.new(813.8,Y,Z), Vector3.new(820.3,Y,Z),
        Vector3.new(819.0,Y,Z),
    }
    for _, p in ipairs(steps) do
        for i = 1, 2 do hrp.Position = p; wait_ms(110) end
    end
    print("[PLWare] Jiggle done! Returning in 1s...")
    wait_ms(1000)
    local h2 = get_hrp()
    if h2 and saved_x then
        for i = 1, 3 do h2.Position = Vector3.new(saved_x, saved_y, saved_z); wait_ms(50) end
    end
end)

ui.NewButton(TAB_MAIN, C_TP, "Return to Saved", function()
    if saved_x then tp_saved(); print("[PLWare] Returned.")
    else print("[PLWare] No saved position.") end
end)

ui.NewButton(TAB_MAIN, C_TP, "TP + Grab Key Card", function()
    local hrp = get_hrp()
    if not hrp then return end
    if #cached_cards == 0 then print("[PLWare] Enable Card ESP first."); return end
    local best, bd = nil, math.huge
    for _, c in ipairs(cached_cards) do
        local d = (c.pos - hrp.Position).Magnitude
        if d < bd then bd = d; best = c end
    end
    if not best then return end
    save_pos()
    for i = 1, 3 do
        hrp.Position = Vector3.new(best.pos.X, best.pos.Y + 1, best.pos.Z)
        wait_ms(80)
    end
    local sx, sy, on_screen = utility.WorldToScreen(best.pos)
    if on_screen then
        for i = 1, 8 do
            game.SilentAim(sx, sy)
            mouse.Click("leftmouse")
            wait_ms(100)
        end
    end
    print(string.format("[PLWare] Grabbed Key Card (%.0fm)", bd))
    wait_ms(400)
    local h2 = get_hrp()
    if h2 and saved_x then
        for i = 1, 3 do h2.Position = Vector3.new(saved_x, saved_y, saved_z); wait_ms(50) end
        print("[PLWare] Returned!")
    end
end)

-- ============================================
--  GUARD FEATURES UI
-- ============================================

ui.NewCheckbox(TAB_MAIN, C_GUARD, "Auto Arrest")
ui.newSliderFloat(TAB_MAIN, C_GUARD, "Arrest Range", 5.0, 30.0, 12.0)
ui.NewCheckbox(TAB_MAIN, C_GUARD, "TP Arrest")
ui.newSliderFloat(TAB_MAIN, C_GUARD, "TP Arrest Range", 50.0, 500.0, 150.0)
ui.NewCheckbox(TAB_MAIN, C_GUARD, "Auto Reload")

-- ============================================
--  INMATE FEATURES UI
-- ============================================

ui.NewCheckbox(TAB_MAIN, C_INMATE, "Low Health Escape")
ui.newSliderInt(TAB_MAIN, C_INMATE, "HP Threshold %", 5, 50, 25)
ui.NewDropdown(TAB_MAIN, C_INMATE, "Escape To", {"Criminal Base","Outside Gate"}, 1)
ui.NewCheckbox(TAB_MAIN, C_INMATE, "Anti Arrest TP")
ui.newSliderFloat(TAB_MAIN, C_INMATE, "Guard Detect Range", 5.0, 20.0, 8.0)

-- ============================================
--  MISC UI
-- ============================================

ui.NewCheckbox(TAB_MAIN, C_MISC, "Car Boost")
ui.newSliderInt(TAB_MAIN, C_MISC, "Boost Speed", 50, 500, 150)
ui.NewCheckbox(TAB_MAIN, C_MISC, "FPS Boost")

-- ============================================
--  GUARD STATE
-- ============================================

local CLICK_CD        = 250
local TP_LOCK_TIMEOUT = 8000
local last_click_ms   = 0
local arrest_active   = false
local arrest_status   = "READY"
local tp_target_name  = nil
local tp_locked       = false
local tp_lock_start   = 0

local function reset_tp()
    tp_target_name = nil
    tp_locked      = false
    tp_lock_start  = 0
end

local function find_target(range)
    local hrp = get_hrp()
    if not hrp then return nil end
    local my_pos  = hrp.Position
    local players = entity.GetPlayers(true)
    local best, bd = nil, range
    for _, p in ipairs(players) do
        if is_valid_target(p) then
            local d = (p.Position - my_pos).Magnitude
            if d < bd then bd = d; best = p end
        end
    end
    return best
end

local function get_player_by_name(name)
    local all = entity.GetPlayers(false)
    for _, p in ipairs(all) do
        if p.Name == name then return p end
    end
    return nil
end

-- Auto Arrest — only fires when handcuffs equipped
local function run_auto_arrest()
    if not ui.getValue(TAB_MAIN, C_GUARD, "Auto Arrest") then
        arrest_active = false
        arrest_status = "OFF"
        return
    end
    if not has_handcuffs() then
        arrest_active = false
        arrest_status = "EQUIP HANDCUFFS"
        return
    end
    local now   = utility.GetTickCount()
    local range = ui.getValue(TAB_MAIN, C_GUARD, "Arrest Range")
    local best  = find_target(range)
    if not best then
        arrest_active = false
        arrest_status = "NO TARGET"
        return
    end
    arrest_active = true
    arrest_status = "LOCKING: " .. best.Name
    if now - last_click_ms >= CLICK_CD then
        last_click_ms = now
        local hrp = get_hrp()
        if hrp then
            hrp.Position = Vector3.new(best.Position.X, best.Position.Y, best.Position.Z + 2.5)
        end
        aim_and_click(best)
    end
end

-- TP Arrest — locks target, keeps chasing until no longer valid
-- Auto resets after timeout to prevent freezing
local function run_tp_arrest()
    if not ui.getValue(TAB_MAIN, C_GUARD, "TP Arrest") then
        reset_tp(); return
    end
    -- CRITICAL: only run if handcuffs equipped
    if not has_handcuffs() then
        arrest_status = "EQUIP HANDCUFFS"
        return
    end

    local now   = utility.GetTickCount()
    local range = ui.getValue(TAB_MAIN, C_GUARD, "TP Arrest Range")
    local hrp   = get_hrp()
    if not hrp then return end

    -- Auto reset if stuck too long
    if tp_locked and now - tp_lock_start > TP_LOCK_TIMEOUT then
        print("[PLWare] TP Arrest timeout — resetting")
        reset_tp(); return
    end

    -- Validate or find target
    local target = nil
    if tp_locked and tp_target_name then
        local p = get_player_by_name(tp_target_name)
        if not p or not is_valid_target(p) then
            -- Target arrested or gone
            print("[PLWare] Target done: " .. (tp_target_name or "?"))
            reset_tp(); return
        end
        target = p
    else
        local best = find_target(range)
        if not best then reset_tp(); return end
        tp_target_name = best.Name
        tp_locked      = true
        tp_lock_start  = now
        save_pos()
        print("[PLWare] Locked: " .. best.Name)
        target = best
    end

    if not target then return end

    -- TP beside target
    local tp  = target.Position
    local dx  = tp.X - hrp.Position.X
    local dz  = tp.Z - hrp.Position.Z
    local mag = math.sqrt(dx*dx + dz*dz)
    if mag > 0.5 then
        hrp.Position = Vector3.new(tp.X-(dx/mag)*2, tp.Y, tp.Z-(dz/mag)*2)
    else
        hrp.Position = Vector3.new(tp.X+2, tp.Y, tp.Z)
    end
    -- Second TP for reliability
    wait_ms(20)
    hrp.Position = Vector3.new(tp.X-(dx/(mag+0.01))*2, tp.Y, tp.Z-(dz/(mag+0.01))*2)

    if now - last_click_ms >= CLICK_CD then
        last_click_ms = now
        aim_and_click(target)
    end
end

-- Auto Reload
local last_reload_ms = 0
local function run_auto_reload()
    if not ui.getValue(TAB_MAIN, C_GUARD, "Auto Reload") then return end
    local now = utility.GetTickCount()
    if now - last_reload_ms < 1000 then return end
    local char = get_char()
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    local gs = tool:FindFirstChild("GunStates")
    if not gs then return end
    local ok, attr = pcall(function() return gs:GetAttribute("Ammo") end)
    if ok and attr and attr.Value == 0 then
        last_reload_ms = now
        keyboard.Click("r", 30)
        print("[PLWare] Auto reload!")
    end
end

-- ============================================
--  INMATE LOGIC
-- ============================================

local last_escape_ms  = 0
local last_anti_ms    = 0
local escape_just_tp  = false
local escape_tp_time  = 0

local function run_low_health_escape()
    if not ui.getValue(TAB_MAIN, C_INMATE, "Low Health Escape") then return end
    local now = utility.GetTickCount()
    if now - last_escape_ms < 3000 then return end
    local lp = get_local_player()
    if not lp or lp.MaxHealth <= 0 then return end
    local thresh = ui.getValue(TAB_MAIN, C_INMATE, "HP Threshold %")
    if (lp.Health / lp.MaxHealth * 100) <= thresh then
        last_escape_ms = now
        escape_just_tp = true
        escape_tp_time = now
        local hrp = get_hrp()
        if hrp then
            local idx  = ui.getValue(TAB_MAIN, C_INMATE, "Escape To")
            local name = esc_names[idx + 1] or "Criminal Base"
            local dest = esc_locs[name]
            if dest then
                for i = 1, 3 do hrp.Position = Vector3.new(dest.X, dest.Y, dest.Z); wait_ms(50) end
                print("[PLWare] LOW HEALTH! Escaped to " .. name)
            end
        end
    end
end

local function run_anti_arrest()
    if not ui.getValue(TAB_MAIN, C_INMATE, "Anti Arrest TP") then return end
    local now = utility.GetTickCount()
    if escape_just_tp and now - escape_tp_time < 4000 then return end
    escape_just_tp = false
    if now - last_anti_ms < 2000 then return end
    local hrp = get_hrp()
    if not hrp then return end
    local range   = ui.getValue(TAB_MAIN, C_INMATE, "Guard Detect Range")
    local my_pos  = hrp.Position
    local lp      = get_local_player()
    for _, p in ipairs(entity.GetPlayers()) do
        if p.IsAlive and not is_criminal(p) and lp and p.Name ~= lp.Name then
            if (p.Position - my_pos).Magnitude <= range then
                last_anti_ms = now
                for i = 1, 3 do
                    hrp.Position = Vector3.new(-974.4, 108.3, 2057.2)
                    wait_ms(50)
                end
                print("[PLWare] Guard nearby! Anti-arrest TP!")
                return
            end
        end
    end
end

-- ============================================
--  CAR BOOST
--  Sets Velocity on the car's Main/Body part
--  in the direction it's facing using LookVector
-- ============================================

local function run_car_boost()
    if not ui.getValue(TAB_MAIN, C_MISC, "Car Boost") then return end
    if not keyboard.IsPressed("w") then return end

    local lp = get_local_player()
    if not lp then return end

    -- Find the VehicleSeat the player is sitting in
    -- by checking nearby car models for a VehicleSeat close to player pos
    local hrp = get_hrp()
    if not hrp then return end

    local my_pos = hrp.Position
    local speed  = ui.getValue(TAB_MAIN, C_MISC, "Boost Speed")

    -- Find closest car
    local best_seat = nil
    local best_dist = 10  -- must be within 10 studs

    for _, obj in ipairs(game.Workspace:GetDescendants()) do
        if obj.ClassName == "VehicleSeat" then
            local ok, pos = pcall(function() return obj.Position end)
            if ok and pos then
                local d = (pos - my_pos).Magnitude
                if d < best_dist then
                    best_dist = d
                    best_seat = obj
                end
            end
        end
    end

    if not best_seat then return end

    -- Get the car body (Main part or primary part)
    local car = best_seat.Parent
    if not car then return end

    -- Find the main structural part to apply velocity to
    local main_part = car:FindFirstChild("Main")
                   or car:FindFirstChild("Body")
                   or car:FindFirstChildOfClass("Part")

    if not main_part then return end

    -- Apply velocity in the direction the car is facing
    local look = main_part.LookVector
    if not look then return end

    main_part.Velocity = Vector3.new(
        look.X * speed,
        main_part.Velocity.Y,  -- preserve vertical velocity
        look.Z * speed
    )
end

-- ============================================
--  FPS BOOST
-- ============================================

local fps_on = false

local function toggle_fps_boost(enable)
    if enable == fps_on then return end
    fps_on = enable
    local lighting = game.GetService("Lighting")
    if not lighting then return end
    if enable then
        pcall(function() lighting.GlobalShadows  = false  end)
        pcall(function() lighting.FogEnd         = 100000 end)
        pcall(function() lighting.FogStart       = 99999  end)
        pcall(function() lighting.ShadowSoftness = 0      end)
        print("[PLWare] FPS Boost ON")
    else
        pcall(function() lighting.GlobalShadows  = true   end)
        pcall(function() lighting.FogEnd         = 1000   end)
        pcall(function() lighting.FogStart       = 0      end)
        pcall(function() lighting.ShadowSoftness = 0.2    end)
        print("[PLWare] FPS Boost OFF")
    end
end

-- ============================================
--  CRAZY FEATURE: CRIMINAL PREDICTION LINES
--  Draws a line from screen center to each criminal
--  with a PREDICTED future position based on velocity
--  Shows where they'll be in 1-2 seconds
--  Unique — no Prison Life script has this
-- ============================================

local cached_criminals    = {}
local last_criminal_cache = 0

local function cache_criminals()
    local now = utility.GetTickCount()
    if now - last_criminal_cache < 500 then return end
    last_criminal_cache = now
    cached_criminals = {}
    local players = entity.GetPlayers(true)
    for _, p in ipairs(players) do
        if p.IsAlive and is_valid_target(p) then
            table.insert(cached_criminals, {
                name     = p.Name,
                pos      = p.Position,
                vel      = p.Velocity,
                health   = p.Health,
                maxhp    = p.MaxHealth,
                team     = p.Team or "?",
            })
        end
    end
end

local function draw_criminal_prediction()
    if not ui.getValue(TAB_MAIN, C_GUARD, "Auto Arrest") and
       not ui.getValue(TAB_MAIN, C_GUARD, "TP Arrest") then
        return
    end
    if #cached_criminals == 0 then return end

    local sw, sh = cheat.getWindowSize()
    local cx, cy = sw / 2, sh / 2

    for _, c in ipairs(cached_criminals) do
        -- Current screen position
        local sx, sy, vis = utility.WorldToScreen(c.pos)
        if vis then
            -- Predicted position 1.5s in future based on velocity
            local pred_pos = Vector3.new(
                c.pos.X + c.vel.X * 1.5,
                c.pos.Y + c.vel.Y * 1.5,
                c.pos.Z + c.vel.Z * 1.5
            )
            local px, py, pvis = utility.WorldToScreen(pred_pos)

            -- Color based on health
            local hp_pct = c.maxhp > 0 and (c.health / c.maxhp) or 1
            local r = math.floor(255 * (1 - hp_pct))
            local g = math.floor(255 * hp_pct)
            local target_col = Color3.fromRGB(r, g, 0)

            -- Line from screen center to target
            draw.Line(cx, cy, sx, sy, Color3.fromRGB(255, 100, 0), 1, 120)

            -- Circle at current position
            draw.Circle(sx, sy, 8, target_col, 1.5, 12, 200)

            -- Predicted position marker (dotted look with small circle)
            if pvis then
                -- Line from current to predicted
                draw.Line(sx, sy, px, py, Color3.fromRGB(255, 255, 0), 1, 100)
                -- Diamond shape at predicted pos
                draw.Line(px-6, py,   px,   py-6, Color3.fromRGB(255,255,0), 1, 180)
                draw.Line(px,   py-6, px+6, py,   Color3.fromRGB(255,255,0), 1, 180)
                draw.Line(px+6, py,   px,   py+6, Color3.fromRGB(255,255,0), 1, 180)
                draw.Line(px,   py+6, px-6, py,   Color3.fromRGB(255,255,0), 1, 180)
            end

            -- Name + distance + HP above target
            local dist = 0
            local hrp  = get_hrp()
            if hrp then dist = (c.pos - hrp.Position).Magnitude end
            local info = string.format("%s | %.0fm | %d%%", c.name, dist, math.floor(hp_pct*100))
            local tw, th = draw.GetTextSize(info, "Verdana")
            draw.TextOutlined(info, sx-(tw/2), sy-22, target_col, "Verdana")
        end
    end
end

-- ============================================
--  DRAW INDICATORS
-- ============================================

local function draw_indicators()
    local sw, sh = cheat.getWindowSize()
    local x = 10
    local y = sh - 200

    local function line(lbl, col)
        draw.TextOutlined(lbl, x, y, col, "Verdana")
        y = y + 18
    end

    if ui.getValue(TAB_MAIN, C_GUARD, "Auto Arrest") then
        if arrest_status == "EQUIP HANDCUFFS" then
            line("AUTO ARREST: EQUIP HANDCUFFS", Color3.fromRGB(255,200,0))
        elseif arrest_status == "NO TARGET" then
            line("AUTO ARREST: SEARCHING", Color3.fromRGB(100,255,100))
        elseif arrest_active then
            line("AUTO ARREST: " .. arrest_status, Color3.fromRGB(255,50,50))
        end
    end

    if ui.getValue(TAB_MAIN, C_GUARD, "TP Arrest") then
        if not has_handcuffs() then
            line("TP ARREST: EQUIP HANDCUFFS", Color3.fromRGB(255,200,0))
        elseif tp_target_name then
            line("TP ARREST: " .. tp_target_name, Color3.fromRGB(255,120,0))
        else
            line("TP ARREST: SEARCHING", Color3.fromRGB(100,200,255))
        end
    end

    if ui.getValue(TAB_MAIN, C_GUARD, "Auto Reload") then
        line("AUTO RELOAD: ON", Color3.fromRGB(255,220,50))
    end

    if ui.getValue(TAB_MAIN, C_INMATE, "Low Health Escape") then
        local lp = get_local_player()
        if lp and lp.MaxHealth > 0 then
            local hp  = math.floor((lp.Health / lp.MaxHealth) * 100)
            local thr = ui.getValue(TAB_MAIN, C_INMATE, "HP Threshold %")
            line(
                string.format("HP: %d%% (escape at %d%%)", hp, thr),
                hp <= thr and Color3.fromRGB(255,50,50) or Color3.fromRGB(100,255,100)
            )
        end
    end

    if ui.getValue(TAB_MAIN, C_INMATE, "Anti Arrest TP") then
        line("ANTI ARREST: ACTIVE", Color3.fromRGB(200,100,255))
    end

    if ui.getValue(TAB_MAIN, C_MISC, "Car Boost") then
        local spd = ui.getValue(TAB_MAIN, C_MISC, "Boost Speed")
        line(string.format("CAR BOOST: %d (hold W)", spd), Color3.fromRGB(0,255,200))
    end

    if fps_on then line("FPS BOOST: ON", Color3.fromRGB(0,200,255)) end
end

-- ============================================
--  CALLBACKS
-- ============================================

scheduler.every(1000, cache_items)

cheat.register("onPaint", function()
    draw_cached_esp()
    draw_criminal_prediction()
    draw_indicators()
    local want = ui.getValue(TAB_MAIN, C_MISC, "FPS Boost")
    if want ~= fps_on then toggle_fps_boost(want) end
end)

cheat.register("onUpdate", function()
    scheduler.run()
    cache_criminals()
    run_auto_arrest()
    run_tp_arrest()
    run_auto_reload()
    run_low_health_escape()
    run_anti_arrest()
    run_car_boost()
end)

-- ============================================
print("[PrisonLifeWare] v2 loaded!")
