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

function scheduler.after(delay_ms, cb)
    table.insert(scheduler.tasks, { time = utility.GetTickCount() + delay_ms, cb = cb })
end

function scheduler.every(delay_ms, cb)
    table.insert(scheduler.intervals, { delay = delay_ms, last_run = utility.GetTickCount(), cb = cb })
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

local function aim_and_click(player)
    local bp = player:GetBonePosition("HumanoidRootPart")
           or player:GetBonePosition("Torso")
           or player.Position
    local sx, sy, vis = utility.WorldToScreen(bp)
    if vis then
        game.SilentAim(sx, sy)
        mouse.Click("leftmouse")
        return true
    end
    return false
end

-- Check if a player is still a valid arrest target
-- Returns false if they became an inmate (got arrested)
local function is_valid_target(player)
    if not player.IsAlive then return false end
    -- Still a criminal = valid
    if is_criminal(player) then return true end
    -- Inmate with weapon = valid
    if inmate_has_weapon(player) then return true end
    -- Otherwise they became a regular inmate = skip
    return false
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
                        table.insert(cached_cards, {pos=pos, dist=dist, name=obj.Name, obj=obj})
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
        hrp.Position = Vector3.new(dest.X, dest.Y, dest.Z)
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
        hrp.Position = Vector3.new(saved_x, saved_y, saved_z)
    end
end

ui.NewButton(TAB_MAIN, C_TP, "Save Position", function()
    save_pos()
    if saved_x then
        print(string.format("[PLWare] Saved: %.1f %.1f %.1f", saved_x, saved_y, saved_z))
    end
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
    for _, p in ipairs(steps) do hrp.Position = p; wait_ms(220) end
    print("[PLWare] Jiggle done! Returning in 1s...")
    wait_ms(1000)
    local h2 = get_hrp()
    if h2 and saved_x then h2.Position = Vector3.new(saved_x, saved_y, saved_z) end
end)

ui.NewButton(TAB_MAIN, C_TP, "Return to Saved", function()
    if saved_x then tp_saved(); print("[PLWare] Returned.")
    else print("[PLWare] No saved position.") end
end)

-- TP to card + press E to pick it up
ui.NewButton(TAB_MAIN, C_TP, "TP + Grab Key Card", function()
    local hrp = get_hrp()
    if not hrp then return end
    if #cached_cards == 0 then
        print("[PLWare] Enable Card ESP first.")
        return
    end

    -- Find closest card
    local best, bd = nil, math.huge
    for _, c in ipairs(cached_cards) do
        local d = (c.pos - hrp.Position).Magnitude
        if d < bd then bd = d; best = c end
    end
    if not best then return end

    save_pos()

    -- TP directly onto the card
    hrp.Position = Vector3.new(best.pos.X, best.pos.Y + 1, best.pos.Z)
    wait_ms(200)

    -- Press E multiple times to interact/pick up
    for i = 1, 5 do
        keyboard.Click("e", 30)
        wait_ms(100)
    end

    print(string.format("[PLWare] Attempted card pickup (%.0fm)", bd))

    -- Wait a moment then return
    wait_ms(400)
    local h2 = get_hrp()
    if h2 and saved_x then
        h2.Position = Vector3.new(saved_x, saved_y, saved_z)
        print("[PLWare] Returned after card grab!")
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

ui.NewCheckbox(TAB_MAIN, C_MISC, "FPS Boost")

-- ============================================
--  GUARD STATE
-- ============================================

local CLICK_CD      = 250   -- ms between arrest clicks
local last_click_ms = 0
local arrest_active = false
local arrest_status = "READY"

-- TP Arrest target tracking
-- We lock onto one target and keep going until they're
-- no longer a valid target (arrested = became inmate, dead, etc)
local tp_target_name    = nil
local tp_target_locked  = false  -- true when we've committed to a target

local function find_target(range)
    local hrp = get_hrp()
    if not hrp then return nil end
    local my_pos  = hrp.Position
    local players = entity.GetPlayers(true)
    local best, best_dist = nil, range
    for _, p in ipairs(players) do
        if is_valid_target(p) then
            local d = (p.Position - my_pos).Magnitude
            if d < best_dist then best_dist = d; best = p end
        end
    end
    return best
end

-- Get a specific player from entity list by name
local function get_player_by_name(name)
    local players = entity.GetPlayers(true)
    for _, p in ipairs(players) do
        if p.Name == name then return p end
    end
    -- Also check all players in case team changed
    local all = entity.GetPlayers(false)
    for _, p in ipairs(all) do
        if p.Name == name then return p end
    end
    return nil
end

-- Auto Arrest
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
            hrp.Position = Vector3.new(
                best.Position.X,
                best.Position.Y,
                best.Position.Z + 2.5
            )
        end
        aim_and_click(best)
    end
end

-- TP Arrest — locks onto target and keeps going
-- Stops ONLY when target is no longer a valid criminal/armed inmate
local function run_tp_arrest()
    if not ui.getValue(TAB_MAIN, C_GUARD, "TP Arrest") then
        tp_target_name   = nil
        tp_target_locked = false
        return
    end
    if not has_handcuffs() then return end

    local hrp = get_hrp()
    if not hrp then return end

    local now   = utility.GetTickCount()
    local range = ui.getValue(TAB_MAIN, C_GUARD, "TP Arrest Range")

    -- If we have a locked target, check if they're still valid
    if tp_target_locked and tp_target_name then
        local target = get_player_by_name(tp_target_name)

        -- Target gone or no longer valid (arrested = became inmate)
        if not target or not is_valid_target(target) then
            print("[PLWare] Target arrested or gone: " .. tp_target_name)
            tp_target_name   = nil
            tp_target_locked = false
            return
        end

        -- Still valid — keep chasing and arresting
        local tp  = target.Position
        local dx  = tp.X - hrp.Position.X
        local dz  = tp.Z - hrp.Position.Z
        local mag = math.sqrt(dx*dx + dz*dz)

        if mag > 0.5 then
            hrp.Position = Vector3.new(
                tp.X - (dx/mag)*2,
                tp.Y,
                tp.Z - (dz/mag)*2
            )
        else
            hrp.Position = Vector3.new(tp.X + 2, tp.Y, tp.Z)
        end

        if now - last_click_ms >= CLICK_CD then
            last_click_ms = now
            aim_and_click(target)
        end

    else
        -- No locked target — find the closest valid one
        local best = find_target(range)
        if not best then
            tp_target_name   = nil
            tp_target_locked = false
            return
        end
        -- Lock onto this target
        tp_target_name   = best.Name
        tp_target_locked = true
        save_pos()
        print("[PLWare] TP Arrest locked onto: " .. best.Name)
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

local last_escape_ms = 0
local last_anti_ms   = 0

local function run_low_health_escape()
    if not ui.getValue(TAB_MAIN, C_INMATE, "Low Health Escape") then return end
    local now = utility.GetTickCount()
    if now - last_escape_ms < 3000 then return end
    local lp = get_local_player()
    if not lp or lp.MaxHealth <= 0 then return end
    local thresh = ui.getValue(TAB_MAIN, C_INMATE, "HP Threshold %")
    local hp_pct = (lp.Health / lp.MaxHealth) * 100
    if hp_pct <= thresh then
        last_escape_ms = now
        local hrp = get_hrp()
        if hrp then
            local idx  = ui.getValue(TAB_MAIN, C_INMATE, "Escape To")
            local name = esc_names[idx + 1] or "Criminal Base"
            local dest = esc_locs[name]
            if dest then
                hrp.Position = Vector3.new(dest.X, dest.Y, dest.Z)
                print("[PLWare] LOW HEALTH! Escaped to " .. name)
            end
        end
    end
end

local function run_anti_arrest()
    if not ui.getValue(TAB_MAIN, C_INMATE, "Anti Arrest TP") then return end
    local now = utility.GetTickCount()
    if now - last_anti_ms < 2000 then return end
    local hrp = get_hrp()
    if not hrp then return end
    local range   = ui.getValue(TAB_MAIN, C_INMATE, "Guard Detect Range")
    local my_pos  = hrp.Position
    local lp      = get_local_player()
    local players = entity.GetPlayers()
    for _, p in ipairs(players) do
        if p.IsAlive and not is_criminal(p) and lp and p.Name ~= lp.Name then
            if (p.Position - my_pos).Magnitude <= range then
                last_anti_ms = now
                hrp.Position = Vector3.new(-974.4, 108.3, 2057.2)
                print("[PLWare] Guard nearby! Anti-arrest TP!")
                return
            end
        end
    end
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
        pcall(function() lighting.GlobalShadows  = false end)
        pcall(function() lighting.FogEnd         = 100000 end)
        pcall(function() lighting.FogStart       = 99999  end)
        pcall(function() lighting.ShadowSoftness = 0      end)
        print("[PLWare] FPS Boost ON")
    else
        pcall(function() lighting.GlobalShadows  = true  end)
        pcall(function() lighting.FogEnd         = 1000  end)
        pcall(function() lighting.FogStart       = 0     end)
        pcall(function() lighting.ShadowSoftness = 0.2   end)
        print("[PLWare] FPS Boost OFF")
    end
end

-- ============================================
--  DRAW INDICATORS
-- ============================================

local function draw_indicators()
    local sw, sh = cheat.getWindowSize()
    local x = 10
    local y = sh - 220

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
        if tp_target_name then
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

    if fps_on then
        line("FPS BOOST: ON", Color3.fromRGB(0,200,255))
    end
end

-- ============================================
--  CALLBACKS
-- ============================================

scheduler.every(1000, cache_items)

cheat.register("onPaint", function()
    draw_cached_esp()
    draw_indicators()
    local want = ui.getValue(TAB_MAIN, C_MISC, "FPS Boost")
    if want ~= fps_on then toggle_fps_boost(want) end
end)

cheat.register("onUpdate", function()
    scheduler.run()
    run_auto_arrest()
    run_tp_arrest()
    run_auto_reload()
    run_low_health_escape()
    run_anti_arrest()
end)

-- ============================================
print("[PrisonLifeWare] v2 loaded!")
