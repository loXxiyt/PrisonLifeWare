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
ui.NewContainer(TAB_MAIN, C_ESP,    "Item ESP",   { autosize = true, next = true })
ui.NewContainer(TAB_MAIN, C_TP,     "Teleports",  { autosize = true, next = true })
ui.NewContainer(TAB_MAIN, C_GUARD,  "Guard",      { autosize = true, next = true })
ui.NewContainer(TAB_MAIN, C_INMATE, "Inmate",     { autosize = true, next = true })
ui.NewContainer(TAB_MAIN, C_MISC,   "Misc",       { autosize = true })

-- ============================================
--  HELPERS
-- ============================================

local function get_local_player()
    return entity.GetLocalPlayer()
end

local function get_char()
    local lp = get_local_player()
    if not lp then return nil end
    local ok, result = pcall(function()
        return game.Workspace:FindFirstChild(lp.Name)
    end)
    return ok and result or nil
end

local function get_hrp()
    local char = get_char()
    if not char then return nil end
    local ok, result = pcall(function()
        return char:FindFirstChild("HumanoidRootPart")
    end)
    return ok and result or nil
end

local function wait_ms(ms)
    local start = utility.GetTickCount()
    while utility.GetTickCount() - start < ms do end
end

local function get_part(obj)
    return obj:FindFirstChild("Handle")
        or obj:FindFirstChild("Mesh")
        or obj:FindFirstChildOfClass("MeshPart")
        or obj:FindFirstChildOfClass("Part")
end

local function has_tool(name_check)
    local char = get_char()
    if not char then return false end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return false end
    if name_check then
        return string.lower(tool.Name) == string.lower(name_check)
    end
    return true
end

local function has_handcuffs()
    return has_tool("handcuffs") or has_tool("menottes")
end

local function get_tool_name()
    local char = get_char()
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    return tool and tool.Name or nil
end

local function is_criminal(player)
    local team = player.Team
    if not team then return false end
    return string.find(string.lower(team), "criminal") ~= nil
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
    local bone_pos = player:GetBonePosition("HumanoidRootPart")
                  or player:GetBonePosition("Torso")
                  or player.Position
    local sx, sy, visible = utility.WorldToScreen(bone_pos)
    if visible then
        game.SilentAim(sx, sy)
        mouse.Click("leftmouse")
        return true
    end
    return false
end

-- ============================================
--  ITEM ESP
-- ============================================

ui.NewCheckbox(TAB_MAIN, C_ESP, "Card ESP")
ui.NewCheckbox(TAB_MAIN, C_ESP, "Gun ESP")
ui.NewColorpicker(TAB_MAIN, C_ESP, "Card Color", { r=0, g=255, b=255, a=255 }, true)
ui.NewColorpicker(TAB_MAIN, C_ESP, "Gun Color",  { r=255, g=150, b=0, a=255 }, true)
ui.newSliderInt(TAB_MAIN, C_ESP, "Max Distance", 50, 2000, 1000)

local CARD_NAMES = { ["Key card"]=true, ["Key Card"]=true }
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
    local card_on = ui.getValue(TAB_MAIN, C_ESP, "Card ESP")
    local gun_on  = ui.getValue(TAB_MAIN, C_ESP, "Gun ESP")
    if not card_on and not gun_on then return end

    local max_dist = ui.getValue(TAB_MAIN, C_ESP, "Max Distance")
    local cam_pos  = game.CameraPosition
    local ok, children = pcall(function() return game.Workspace:GetChildren() end)
    if not ok then return end

    for _, obj in pairs(children) do
        if obj.ClassName == "Model" or obj.ClassName == "Tool" then
            local part = get_part(obj)
            if part then
                local pos  = part.Position
                local dist = cam_pos and (cam_pos - pos).Magnitude or 0
                if dist <= max_dist then
                    if card_on and CARD_NAMES[obj.Name] then
                        table.insert(cached_cards, { pos=pos, dist=dist, name=obj.Name, obj=obj })
                    elseif gun_on and GUN_NAMES[obj.Name] then
                        table.insert(cached_guns, { pos=pos, dist=dist, name=obj.Name })
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

    local cc = ui.getValue(TAB_MAIN, C_ESP, "Card Color")
    local gc = ui.getValue(TAB_MAIN, C_ESP, "Gun Color")
    local card_col = Color3.fromRGB(cc.r, cc.g, cc.b)
    local gun_col  = Color3.fromRGB(gc.r, gc.g, gc.b)

    local function draw_entry(entry, label, color)
        local sx, sy, on_screen = utility.WorldToScreen(entry.pos)
        if not on_screen then return end
        draw.Rect(sx-15, sy-15, 30, 30, color, 1.5)
        local tw, th = draw.GetTextSize(label)
        draw.TextOutlined(label, sx-(tw/2), sy-20-th, color)
        local dt = string.format("%.0fm", entry.dist)
        local dw, _ = draw.GetTextSize(dt)
        draw.TextOutlined(dt, sx-(dw/2), sy+18, Color3.fromRGB(200,200,200))
    end

    if card_on then for _, e in pairs(cached_cards) do draw_entry(e, "KEY CARD", card_col) end end
    if gun_on  then for _, e in pairs(cached_guns)  do draw_entry(e, e.name, gun_col)      end end
end

-- ============================================
--  TELEPORTS
-- ============================================

local location_names = {
    "Armory","Criminal Base","Prison Yard",
    "Cells","Cafeteria","Outside Gate",
}
local LOCATIONS = {
    ["Armory"]        = Vector3.new(816.5,  100.7, 2227.9),
    ["Criminal Base"] = Vector3.new(-974.4, 108.3, 2057.2),
    ["Prison Yard"]   = Vector3.new(807.9,  98.0,  2484.0),
    ["Cells"]         = Vector3.new(918.8,  100.0, 2484.5),
    ["Cafeteria"]     = Vector3.new(919.1,  100.0, 2227.9),
    ["Outside Gate"]  = Vector3.new(491.4,  95.5,  2052.5),
}
local escape_locations = {
    ["Criminal Base"] = Vector3.new(-974.4, 108.3, 2057.2),
    ["Outside Gate"]  = Vector3.new(491.4,  95.5,  2052.5),
}

ui.NewDropdown(TAB_MAIN, C_TP, "Location", location_names, 1)
ui.NewButton(TAB_MAIN, C_TP, "Teleport", function()
    local hrp  = get_hrp()
    if not hrp then return end
    local idx  = ui.getValue(TAB_MAIN, C_TP, "Location")
    local name = location_names[idx + 1]
    if not name then return end
    local dest = LOCATIONS[name]
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

local function return_to_saved()
    local hrp = get_hrp()
    if hrp and saved_x then
        hrp.Position = Vector3.new(saved_x, saved_y, saved_z)
    end
end

ui.NewButton(TAB_MAIN, C_TP, "Save Position", function()
    save_pos()
    if saved_x then
        print(string.format("[PLWare] Saved: %.1f, %.1f, %.1f", saved_x, saved_y, saved_z))
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
    for _, pos in ipairs(steps) do
        hrp.Position = pos
        wait_ms(220)
    end

    print("[PLWare] Jiggle done! Returning in 1s...")
    wait_ms(1000)
    local hrp2 = get_hrp()
    if hrp2 and saved_x then
        hrp2.Position = Vector3.new(saved_x, saved_y, saved_z)
        print("[PLWare] Returned!")
    end
end)

ui.NewButton(TAB_MAIN, C_TP, "Return to Saved", function()
    if saved_x then return_to_saved() print("[PLWare] Returned.")
    else print("[PLWare] No saved position.") end
end)

-- TP to nearest card with auto grab
ui.NewButton(TAB_MAIN, C_TP, "TP + Grab Key Card", function()
    local hrp = get_hrp()
    if not hrp then return end
    if #cached_cards == 0 then
        print("[PLWare] No cards cached. Enable Card ESP first.")
        return
    end

    -- Find closest card
    local best, best_dist = nil, math.huge
    local my_pos = hrp.Position
    for _, card in ipairs(cached_cards) do
        local d = (card.pos - my_pos).Magnitude
        if d < best_dist then best_dist = d; best = card end
    end

    if not best then return end
    save_pos()

    -- TP directly onto card
    hrp.Position = Vector3.new(best.pos.X, best.pos.Y + 1, best.pos.Z)
    wait_ms(150)

    -- Walk over it by jiggling slightly
    hrp.Position = Vector3.new(best.pos.X + 1, best.pos.Y + 1, best.pos.Z)
    wait_ms(150)
    hrp.Position = Vector3.new(best.pos.X - 1, best.pos.Y + 1, best.pos.Z)
    wait_ms(150)
    hrp.Position = Vector3.new(best.pos.X,     best.pos.Y + 1, best.pos.Z)
    wait_ms(200)

    print(string.format("[PLWare] Grabbed Key Card (was %.0fm away)", best_dist))
    -- Return to saved
    wait_ms(500)
    local hrp2 = get_hrp()
    if hrp2 and saved_x then
        hrp2.Position = Vector3.new(saved_x, saved_y, saved_z)
        print("[PLWare] Returned after card grab!")
    end
end)

-- ============================================
--  GUARD FEATURES
-- ============================================

ui.NewCheckbox(TAB_MAIN, C_GUARD, "Auto Arrest")
ui.newSliderFloat(TAB_MAIN, C_GUARD, "Arrest Range", 5.0, 30.0, 12.0)
ui.NewCheckbox(TAB_MAIN, C_GUARD, "TP Arrest")
ui.newSliderFloat(TAB_MAIN, C_GUARD, "TP Arrest Range", 50.0, 500.0, 150.0)
ui.NewCheckbox(TAB_MAIN, C_GUARD, "Fast Reload")
ui.NewCheckbox(TAB_MAIN, C_GUARD, "Safety TP After Arrest")

-- ============================================
--  INMATE FEATURES
-- ============================================

ui.NewCheckbox(TAB_MAIN, C_INMATE, "Low Health Escape")
ui.newSliderInt(TAB_MAIN, C_INMATE, "HP Threshold %", 5, 50, 25)
ui.NewDropdown(TAB_MAIN, C_INMATE, "Escape To", {"Criminal Base", "Outside Gate"}, 1)
ui.NewCheckbox(TAB_MAIN, C_INMATE, "Anti Arrest TP")
ui.newSliderFloat(TAB_MAIN, C_INMATE, "Guard Detect Range", 5.0, 20.0, 8.0)

-- ============================================
--  MISC FEATURES
-- ============================================

ui.NewCheckbox(TAB_MAIN, C_MISC, "FPS Boost")

-- ============================================
--  GUARD STATE
-- ============================================

local ARREST_CD         = 300
local last_arrest_ms    = 0
local last_safety_tp    = 0
local last_reload_ms    = 0
local tp_arrest_target  = nil
local arrest_active     = false
local arrest_status     = "READY"
local did_arrest        = false
local did_arrest_time   = 0

local function find_arrest_target(range)
    local hrp = get_hrp()
    if not hrp then return nil end
    local my_pos  = hrp.Position
    local players = entity.GetPlayers(true)
    local best, best_dist = nil, range

    for _, p in ipairs(players) do
        if p.IsAlive then
            local valid = is_criminal(p) or inmate_has_weapon(p)
            if valid then
                local dist = (p.Position - my_pos).Magnitude
                if dist < best_dist then
                    best_dist = dist
                    best = p
                end
            end
        end
    end
    return best
end

-- Auto Arrest with aura-style rapid clicking
local function run_auto_arrest(dt)
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
    local best  = find_arrest_target(range)

    if not best then
        arrest_active = false
        arrest_status = "NO TARGET"
        return
    end

    arrest_active = true
    arrest_status = "LOCKING: " .. best.Name

    -- Rapid arrest clicks like a kill aura
    if now - last_arrest_ms >= ARREST_CD then
        last_arrest_ms = now
        -- TP right next to target for reliable arrest
        local hrp = get_hrp()
        if hrp then
            local tp = best.Position
            hrp.Position = Vector3.new(tp.X, tp.Y, tp.Z + 2)
        end
        if aim_and_click(best) then
            did_arrest      = true
            did_arrest_time = now
        end
    end
end

-- Safety TP after arrest
local function run_safety_tp()
    if not ui.getValue(TAB_MAIN, C_GUARD, "Safety TP After Arrest") then return end
    if not did_arrest then return end

    local now = utility.GetTickCount()
    if now - did_arrest_time >= 1500 then
        did_arrest = false
        local hrp = get_hrp()
        if hrp then
            hrp.Position = Vector3.new(816.5, 100.7, 2227.9)
            print("[PLWare] Safety TP to Armory!")
        end
    end
end

-- TP Arrest with aura
local function run_tp_arrest()
    if not ui.getValue(TAB_MAIN, C_GUARD, "TP Arrest") then
        tp_arrest_target = nil
        return
    end
    if not has_handcuffs() then return end

    local hrp = get_hrp()
    if not hrp then return end

    local now   = utility.GetTickCount()
    local range = ui.getValue(TAB_MAIN, C_GUARD, "TP Arrest Range")
    local best  = find_arrest_target(range)

    if not best then
        tp_arrest_target = nil
        return
    end

    if tp_arrest_target ~= best.Name then
        tp_arrest_target = best.Name
        save_pos()
    end

    -- TP directly beside target
    local tp = best.Position
    local dir_x = tp.X - hrp.Position.X
    local dir_z = tp.Z - hrp.Position.Z
    local mag   = math.sqrt(dir_x*dir_x + dir_z*dir_z)
    if mag > 0 then
        hrp.Position = Vector3.new(
            tp.X - (dir_x/mag)*2,
            tp.Y,
            tp.Z - (dir_z/mag)*2
        )
    else
        hrp.Position = Vector3.new(tp.X, tp.Y, tp.Z + 2)
    end

    if now - last_arrest_ms >= ARREST_CD then
        last_arrest_ms  = now
        if aim_and_click(best) then
            did_arrest      = true
            did_arrest_time = now
        end
    end
end

-- Fast Reload: press R, immediately crouch, uncrouch after delay
-- This cancels the reload animation server-side
local reload_state   = "idle"  -- idle / crouching
local reload_timer   = 0

local function run_fast_reload(dt)
    if not ui.getValue(TAB_MAIN, C_GUARD, "Fast Reload") then
        reload_state = "idle"
        return
    end

    reload_timer = reload_timer + dt

    if reload_state == "idle" then
        -- Detect R key press
        if keyboard.IsPressed("r") then
            local now = utility.GetTickCount()
            if now - last_reload_ms >= 600 then
                last_reload_ms = now
                reload_state   = "crouching"
                reload_timer   = 0
                -- Tap R to start reload
                keyboard.Click("r", 20)
                -- Immediately crouch
                keyboard.Press("c")
            end
        end
    elseif reload_state == "crouching" then
        -- Hold crouch for 350ms then release — cancels animation
        if reload_timer >= 0.35 then
            keyboard.Release("c")
            reload_state = "idle"
            reload_timer = 0
            -- Switch to slot 1 to re-equip weapon instantly
            wait_ms(30)
            keyboard.Click("1", 15)
        end
    end
end

-- ============================================
--  INMATE LOGIC
-- ============================================

local last_escape_ms     = 0
local last_anti_ms       = 0
local escape_name_list   = {"Criminal Base", "Outside Gate"}

local function run_low_health_escape()
    if not ui.getValue(TAB_MAIN, C_INMATE, "Low Health Escape") then return end

    local now = utility.GetTickCount()
    if now - last_escape_ms < 3000 then return end

    local lp = get_local_player()
    if not lp or lp.MaxHealth <= 0 then return end

    local threshold = ui.getValue(TAB_MAIN, C_INMATE, "HP Threshold %")
    local hp_pct    = (lp.Health / lp.MaxHealth) * 100

    if hp_pct <= threshold then
        last_escape_ms = now
        local hrp = get_hrp()
        if hrp then
            local idx  = ui.getValue(TAB_MAIN, C_INMATE, "Escape To")
            local name = escape_name_list[idx + 1] or "Criminal Base"
            local dest = escape_locations[name]
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
    local players = entity.GetPlayers()

    for _, p in ipairs(players) do
        -- Detect guards (not criminals, not self)
        if p.IsAlive and not is_criminal(p) then
            local lp = get_local_player()
            if lp and p.Name ~= lp.Name then
                local dist = (p.Position - my_pos).Magnitude
                if dist <= range then
                    last_anti_ms = now
                    hrp.Position = Vector3.new(-974.4, 108.3, 2057.2)
                    print("[PLWare] Guard nearby! Anti-arrest TP!")
                    return
                end
            end
        end
    end
end

-- ============================================
--  FPS BOOST
-- ============================================

local fps_boost_active = false

local function toggle_fps_boost(enabled)
    if enabled == fps_boost_active then return end
    fps_boost_active = enabled

    local ok, _ = pcall(function()
        for _, obj in ipairs(game.Workspace:GetDescendants()) do
            if obj.ClassName == "Part" or obj.ClassName == "UnionOperation" then
                if enabled then
                    obj.Material = "SmoothPlastic"
                    obj.Reflectance = 0
                end
            end
            if obj.ClassName == "Decal" or obj.ClassName == "Texture" or obj.ClassName == "SpecialMesh" then
                obj.Transparency = enabled and 1 or 0
            end
        end
    end)

    print("[PLWare] FPS Boost: " .. (enabled and "ON" or "OFF"))
end

-- ============================================
--  DRAW INDICATORS
-- ============================================

local function draw_indicators()
    local sw, sh = cheat.getWindowSize()
    -- Position in bottom-left to avoid overlapping game UI
    local x_base = 10
    local y_base = sh - 200
    local y = y_base

    local function draw_line(label, color)
        draw.TextOutlined(label, x_base, y, color, "Verdana")
        y = y + 18
    end

    -- Guard
    if ui.getValue(TAB_MAIN, C_GUARD, "Auto Arrest") then
        if arrest_status == "EQUIP HANDCUFFS" then
            draw_line("AUTO ARREST: EQUIP HANDCUFFS", Color3.fromRGB(255,200,0))
        elseif arrest_status == "NO TARGET" then
            draw_line("AUTO ARREST: NO TARGET", Color3.fromRGB(100,255,100))
        elseif arrest_active then
            draw_line("AUTO ARREST: " .. arrest_status, Color3.fromRGB(255,50,50))
        end
    end

    if ui.getValue(TAB_MAIN, C_GUARD, "TP Arrest") then
        if tp_arrest_target then
            draw_line("TP ARREST: " .. tp_arrest_target, Color3.fromRGB(255,120,0))
        else
            draw_line("TP ARREST: SEARCHING", Color3.fromRGB(100,200,255))
        end
    end

    if ui.getValue(TAB_MAIN, C_GUARD, "Fast Reload") then
        local col = reload_state == "crouching"
            and Color3.fromRGB(255,80,80)
            or  Color3.fromRGB(255,220,50)
        draw_line("FAST RELOAD: " .. (reload_state == "crouching" and "CANCELLING" or "READY"), col)
    end

    if ui.getValue(TAB_MAIN, C_GUARD, "Safety TP After Arrest") then
        draw_line("SAFETY TP: ON", Color3.fromRGB(150,255,150))
    end

    -- Inmate
    if ui.getValue(TAB_MAIN, C_INMATE, "Low Health Escape") then
        local lp = get_local_player()
        if lp and lp.MaxHealth > 0 then
            local hp = math.floor((lp.Health / lp.MaxHealth) * 100)
            local thresh = ui.getValue(TAB_MAIN, C_INMATE, "HP Threshold %")
            local col = hp <= thresh
                and Color3.fromRGB(255,50,50)
                or  Color3.fromRGB(100,255,100)
            draw_line(string.format("HP: %d%% | ESCAPE AT: %d%%", hp, thresh), col)
        end
    end

    if ui.getValue(TAB_MAIN, C_INMATE, "Anti Arrest TP") then
        draw_line("ANTI ARREST: ACTIVE", Color3.fromRGB(200,100,255))
    end

    -- Misc
    if fps_boost_active then
        draw_line("FPS BOOST: ON", Color3.fromRGB(0,200,255))
    end
end

-- ============================================
--  CALLBACKS
-- ============================================

cheat.register("onSlowUpdate", cache_items)

cheat.register("onPaint", function()
    draw_cached_esp()
    draw_indicators()

    -- FPS Boost toggle check (on paint so it updates live)
    local fps_on = ui.getValue(TAB_MAIN, C_MISC, "FPS Boost")
    if fps_on ~= fps_boost_active then
        toggle_fps_boost(fps_on)
    end
end)

cheat.register("onUpdate", function()
    local dt = utility.GetDeltaTime()

    -- Guard
    run_auto_arrest(dt)
    run_tp_arrest()
    run_safety_tp()
    run_fast_reload(dt)

    -- Inmate
    run_low_health_escape()
    run_anti_arrest()
end)

-- ============================================
print("[PrisonLifeWare] v2 loaded!")
