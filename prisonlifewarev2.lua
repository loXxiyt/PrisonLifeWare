-- ============================================
--  PrisonLifeWare v2
--  github.com/loXxiyt/PrisonLifeWare
-- ============================================

local TAB_MAIN = "PLWare"
local C_ESP    = "ItemESP"
local C_TP     = "Teleports"
local C_GUARD  = "Guard"
local C_INMATE = "Inmate"

ui.newTab(TAB_MAIN, "PrisonLifeWare")
ui.NewContainer(TAB_MAIN, C_ESP,   "Item ESP",   { autosize = true, next = true })
ui.NewContainer(TAB_MAIN, C_TP,    "Teleports",  { autosize = true, next = true })
ui.NewContainer(TAB_MAIN, C_GUARD, "Guard",      { autosize = true, next = true })
ui.NewContainer(TAB_MAIN, C_INMATE,"Inmate",     { autosize = true })

-- ============================================
--  HELPERS
-- ============================================

local function get_hrp()
    local lp = entity.GetLocalPlayer()
    if not lp then return nil end
    local char = game.LocalPlayer and game.LocalPlayer.Character
    -- Serotonin safe way to get HRP
    local ok, result = pcall(function()
        return game.Workspace:FindFirstChild(lp.Name)
            and game.Workspace:FindFirstChild(lp.Name):FindFirstChild("HumanoidRootPart")
    end)
    if ok and result then return result end
    return nil
end

local function get_local_char()
    local lp = entity.GetLocalPlayer()
    if not lp then return nil end
    local ok, result = pcall(function()
        return game.Workspace:FindFirstChild(lp.Name)
    end)
    if ok then return result end
    return nil
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

-- Check if local player has handcuffs equipped
local function has_handcuffs()
    local char = get_local_char()
    if not char then return false end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return false end
    local name = string.lower(tool.Name)
    return name == "handcuffs" or name == "menottes"
end

-- Check if local player has taser equipped
local function has_taser()
    local char = get_local_char()
    if not char then return false end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return false end
    return string.lower(tool.Name) == "taser"
end

-- Check if local player has a gun equipped
local function get_equipped_tool_name()
    local char = get_local_char()
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    return tool and tool.Name or nil
end

-- Check if player is criminal by team
local function is_criminal(player)
    local team = player.Team
    if not team then return false end
    return string.find(string.lower(team), "criminal") ~= nil
end

-- Check if inmate has a weapon (can be arrested)
local function inmate_has_weapon(player)
    local char = game.Workspace:FindFirstChild(player.Name)
    if not char then return false end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return false end
    local name = tool.Name
    -- Check against known weapon names
    local weapons = {
        ["AK-47"]=true, ["Remington 870"]=true, ["Taser"]=true,
        ["M9"]=true, ["FAL"]=true, ["M700"]=true, ["MP5"]=true,
        ["M4A1"]=true, ["Revolver"]=true, ["C4 Explosive"]=true,
        ["Crude Knife"]=true, ["Hammer"]=true, ["EBR"]=true,
    }
    return weapons[name] == true
end

-- Aim and click at a player
local function aim_and_click(player)
    local bone_pos = player:GetBonePosition("HumanoidRootPart")
                  or player:GetBonePosition("Torso")
                  or player.Position
    local sx, sy, on_screen = utility.WorldToScreen(bone_pos)
    if on_screen then
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
ui.NewColorpicker(TAB_MAIN, C_ESP, "Card Color", { r=0,   g=255, b=255, a=255 }, true)
ui.NewColorpicker(TAB_MAIN, C_ESP, "Gun Color",  { r=255, g=150, b=0,   a=255 }, true)
ui.newSliderInt(TAB_MAIN, C_ESP, "Max Distance", 50, 2000, 1000)

local CARD_NAMES = { ["Key card"]=true, ["Key Card"]=true }

local GUN_NAMES = {
    ["AK-47"]=true, ["Remington 870"]=true, ["Taser"]=true,
    ["M9"]=true, ["FAL"]=true, ["M700"]=true, ["MP5"]=true,
    ["M4A1"]=true, ["Revolver"]=true, ["C4 Explosive"]=true,
    ["Riot Shield"]=true, ["Crude Knife"]=true, ["Hammer"]=true, ["EBR"]=true,
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
    if not ok or not children then return end

    for _, obj in pairs(children) do
        local cn = obj.ClassName
        if cn == "Model" or cn == "Tool" then
            local part = get_part(obj)
            if part then
                local pos  = part.Position
                local dist = cam_pos and (cam_pos - pos).Magnitude or 0
                if dist <= max_dist then
                    if card_on and CARD_NAMES[obj.Name] then
                        table.insert(cached_cards, { pos=pos, dist=dist, name=obj.Name })
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

    local cc_raw = ui.getValue(TAB_MAIN, C_ESP, "Card Color")
    local gc_raw = ui.getValue(TAB_MAIN, C_ESP, "Gun Color")
    local card_col = Color3.fromRGB(cc_raw.r, cc_raw.g, cc_raw.b)
    local gun_col  = Color3.fromRGB(gc_raw.r, gc_raw.g, gc_raw.b)

    local function draw_entry(entry, label, color)
        local sx, sy, on_screen = utility.WorldToScreen(entry.pos)
        if not on_screen then return end
        draw.Rect(sx - 15, sy - 15, 30, 30, color, 1.5)
        local tw, th = draw.GetTextSize(label)
        draw.TextOutlined(label, sx - (tw/2), sy - 20 - th, color)
        local dt = string.format("%.0fm", entry.dist)
        local dw, _ = draw.GetTextSize(dt)
        draw.TextOutlined(dt, sx - (dw/2), sy + 18, Color3.fromRGB(200,200,200))
    end

    if card_on then
        for _, e in pairs(cached_cards) do draw_entry(e, "KEY CARD", card_col) end
    end
    if gun_on then
        for _, e in pairs(cached_guns) do draw_entry(e, e.name, gun_col) end
    end
end

-- ============================================
--  TELEPORTS
-- ============================================

local location_names = {
    "Armory", "Criminal Base", "Prison Yard",
    "Cells",  "Cafeteria",     "Outside Gate",
}

local LOCATIONS = {
    ["Armory"]        = Vector3.new(816.5,  100.7, 2227.9),
    ["Criminal Base"] = Vector3.new(-974.4, 108.3, 2057.2),
    ["Prison Yard"]   = Vector3.new(807.9,  98.0,  2484.0),
    ["Cells"]         = Vector3.new(918.8,  100.0, 2484.5),
    ["Cafeteria"]     = Vector3.new(919.1,  100.0, 2227.9),
    ["Outside Gate"]  = Vector3.new(491.4,  95.5,  2052.5),
}

ui.NewDropdown(TAB_MAIN, C_TP, "Location", location_names, 1)

ui.NewButton(TAB_MAIN, C_TP, "Teleport", function()
    local hrp = get_hrp()
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

ui.NewButton(TAB_MAIN, C_TP, "Save Position", function()
    local hrp = get_hrp()
    if hrp then
        saved_x = hrp.Position.X
        saved_y = hrp.Position.Y
        saved_z = hrp.Position.Z
        print(string.format("[PLWare] Saved: %.1f, %.1f, %.1f", saved_x, saved_y, saved_z))
    end
end)

ui.NewButton(TAB_MAIN, C_TP, "Grab Gun (TP + Jiggle)", function()
    local hrp = get_hrp()
    if not hrp then return end
    saved_x = hrp.Position.X
    saved_y = hrp.Position.Y
    saved_z = hrp.Position.Z

    local Y, Z = 100.7, 2227.9
    hrp.Position = Vector3.new(817.0, Y, Z)  wait_ms(200)
    hrp.Position = Vector3.new(820.3, Y, Z)  wait_ms(250)
    hrp.Position = Vector3.new(813.8, Y, Z)  wait_ms(200)
    hrp.Position = Vector3.new(820.3, Y, Z)  wait_ms(250)
    hrp.Position = Vector3.new(819.0, Y, Z)  wait_ms(150)

    print("[PLWare] Jiggle done! Returning in 1s...")
    wait_ms(1000)
    local hrp2 = get_hrp()
    if hrp2 and saved_x then
        hrp2.Position = Vector3.new(saved_x, saved_y, saved_z)
        print("[PLWare] Auto returned!")
    end
end)

ui.NewButton(TAB_MAIN, C_TP, "Return to Saved", function()
    local hrp = get_hrp()
    if hrp and saved_x then
        hrp.Position = Vector3.new(saved_x, saved_y, saved_z)
        print("[PLWare] Returned.")
    else
        print("[PLWare] No saved position.")
    end
end)

ui.NewButton(TAB_MAIN, C_TP, "TP to Key Card", function()
    local hrp = get_hrp()
    if not hrp then return end
    if #cached_cards == 0 then
        print("[PLWare] No cards found. Enable Card ESP first.")
        return
    end
    local best, best_dist = nil, math.huge
    local my_pos = hrp.Position
    for _, card in ipairs(cached_cards) do
        local d = (card.pos - my_pos).Magnitude
        if d < best_dist then best_dist = d; best = card end
    end
    if best then
        saved_x = hrp.Position.X
        saved_y = hrp.Position.Y
        saved_z = hrp.Position.Z
        hrp.Position = Vector3.new(best.pos.X, best.pos.Y + 3, best.pos.Z)
        print(string.format("[PLWare] TP'd to Key Card (%.0fm)", best_dist))
    end
end)

-- ============================================
--  GUARD FEATURES
-- ============================================

-- Auto Arrest (criminals + armed inmates)
ui.NewCheckbox(TAB_MAIN, C_GUARD, "Auto Arrest")
ui.newSliderFloat(TAB_MAIN, C_GUARD, "Arrest Range", 5.0, 30.0, 12.0)

-- TP Arrest
ui.NewCheckbox(TAB_MAIN, C_GUARD, "TP Arrest")
ui.newSliderFloat(TAB_MAIN, C_GUARD, "TP Arrest Range", 50.0, 500.0, 150.0)

-- Fast Reload (R + crouch cancel)
ui.NewCheckbox(TAB_MAIN, C_GUARD, "Fast Reload")

-- Safety TP after arrest
ui.NewCheckbox(TAB_MAIN, C_GUARD, "Safety TP After Arrest")

-- ============================================
--  INMATE FEATURES
-- ============================================

-- Low health escape TP
ui.NewCheckbox(TAB_MAIN, C_INMATE, "Low Health Escape TP")
ui.newSliderInt(TAB_MAIN, C_INMATE, "Health Threshold %", 5, 50, 25)
ui.NewDropdown(TAB_MAIN, C_INMATE, "Escape To", {"Criminal Base", "Outside Gate"}, 1)

-- Anti arrest TP (guard gets close, auto TP away)
ui.NewCheckbox(TAB_MAIN, C_INMATE, "Anti Arrest TP")
ui.newSliderFloat(TAB_MAIN, C_INMATE, "Guard Detect Range", 5.0, 20.0, 8.0)

-- ============================================
--  GUARD STATE
-- ============================================

local ARREST_CD        = 350   -- ms between arrest clicks
local last_arrest_click = 0
local last_tp_arrest    = 0
local last_reload_press = 0
local tp_arrest_target  = nil
local arrest_status     = "READY"
local arrest_active     = false
local last_arrest_success = 0  -- track when we last arrested someone

local escape_locations = {
    ["Criminal Base"] = Vector3.new(-974.4, 108.3, 2057.2),
    ["Outside Gate"]  = Vector3.new(491.4,  95.5,  2052.5),
}

local escape_names = { "Criminal Base", "Outside Gate" }

-- Find best arrest target
local function find_arrest_target(range)
    local hrp = get_hrp()
    if not hrp then return nil end
    local my_pos  = hrp.Position
    local players = entity.GetPlayers(true)
    local best, best_dist = nil, range

    for _, p in ipairs(players) do
        if p.IsAlive then
            -- Target criminals OR armed inmates
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

-- Auto Arrest logic
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
    local best  = find_arrest_target(range)

    if not best then
        arrest_active = false
        arrest_status = "NO TARGET"
        return
    end

    arrest_active = true
    arrest_status = "LOCKING: " .. best.Name

    if now - last_arrest_click >= ARREST_CD then
        last_arrest_click = now
        if aim_and_click(best) then
            -- Check if safety TP is on
            if ui.getValue(TAB_MAIN, C_GUARD, "Safety TP After Arrest") then
                last_arrest_success = now
            end
        end
    end
end

-- Safety TP after arrest
local function run_safety_tp()
    if not ui.getValue(TAB_MAIN, C_GUARD, "Safety TP After Arrest") then return end
    local now = utility.GetTickCount()
    -- TP to armory 1.5s after last arrest click
    if last_arrest_success > 0 and now - last_arrest_success >= 1500 then
        last_arrest_success = 0
        local hrp = get_hrp()
        if hrp then
            hrp.Position = Vector3.new(816.5, 100.7, 2227.9)
            print("[PLWare] Safety TP to armory!")
        end
    end
end

-- TP Arrest logic
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

    -- Save position when locking onto new target
    if tp_arrest_target ~= best.Name then
        tp_arrest_target = best.Name
        saved_x = hrp.Position.X
        saved_y = hrp.Position.Y
        saved_z = hrp.Position.Z
    end

    -- TP slightly behind target
    local target_pos = best.Position
    local dir_x = target_pos.X - hrp.Position.X
    local dir_z = target_pos.Z - hrp.Position.Z
    local mag   = math.sqrt(dir_x*dir_x + dir_z*dir_z)
    if mag > 0 then
        hrp.Position = Vector3.new(
            target_pos.X - (dir_x/mag) * 2.5,
            target_pos.Y,
            target_pos.Z - (dir_z/mag) * 2.5
        )
    end

    -- Click to arrest
    if now - last_arrest_click >= ARREST_CD then
        last_arrest_click = now
        aim_and_click(best)
    end
end

-- Fast Reload (R -> crouch -> wait 400ms -> uncrouch)
local function run_fast_reload()
    if not ui.getValue(TAB_MAIN, C_GUARD, "Fast Reload") then return end
    if not keyboard.IsPressed("r") then return end

    local now = utility.GetTickCount()
    if now - last_reload_press < 800 then return end
    last_reload_press = now

    -- Press R to start reload
    keyboard.Click("r", 30)
    wait_ms(80)
    -- Crouch to cancel animation
    keyboard.Press("c")
    wait_ms(400)
    keyboard.Release("c")
    wait_ms(50)
    -- Switch to slot 1 to re-equip
    keyboard.Click("1", 20)
end

-- ============================================
--  INMATE LOGIC
-- ============================================

local last_escape_tp   = 0
local last_anti_arrest = 0

local function run_low_health_escape()
    if not ui.getValue(TAB_MAIN, C_INMATE, "Low Health Escape TP") then return end

    local now = utility.GetTickCount()
    if now - last_escape_tp < 3000 then return end -- 3s cooldown

    local lp = entity.GetLocalPlayer()
    if not lp then return end

    local threshold = ui.getValue(TAB_MAIN, C_INMATE, "Health Threshold %")
    local health_pct = lp.MaxHealth > 0 and (lp.Health / lp.MaxHealth * 100) or 100

    if health_pct <= threshold then
        last_escape_tp = now
        local hrp = get_hrp()
        if hrp then
            local idx  = ui.getValue(TAB_MAIN, C_INMATE, "Escape To")
            local name = escape_names[idx + 1] or "Criminal Base"
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
    if now - last_anti_arrest < 2000 then return end

    local hrp = get_hrp()
    if not hrp then return end

    local my_pos  = hrp.Position
    local players = entity.GetPlayers()
    local range   = ui.getValue(TAB_MAIN, C_INMATE, "Guard Detect Range")

    for _, p in ipairs(players) do
        if p.IsAlive and not is_criminal(p) then
            local dist = (p.Position - my_pos).Magnitude
            if dist <= range then
                last_anti_arrest = now
                -- TP to criminal base
                hrp.Position = Vector3.new(-974.4, 108.3, 2057.2)
                print("[PLWare] Guard detected nearby! Anti-arrest TP!")
                break
            end
        end
    end
end

-- ============================================
--  DRAW INDICATORS
-- ============================================

local function draw_indicators()
    local sw, sh = cheat.getWindowSize()
    local cx = sw / 2
    local y  = 30

    local function draw_line(label, color)
        local tw, _ = draw.GetTextSize(label, "Verdana")
        draw.TextOutlined(label, cx - (tw/2), y, color, "Verdana")
        y = y + 20
    end

    -- Guard indicators
    if ui.getValue(TAB_MAIN, C_GUARD, "Auto Arrest") then
        if arrest_status == "EQUIP HANDCUFFS" then
            draw_line("AUTO ARREST: EQUIP HANDCUFFS", Color3.fromRGB(255, 200, 0))
        elseif arrest_status == "NO TARGET" then
            draw_line("AUTO ARREST: NO TARGET", Color3.fromRGB(100, 255, 100))
        elseif arrest_active then
            draw_line("AUTO ARREST: " .. arrest_status, Color3.fromRGB(255, 50, 50))
        else
            draw_line("AUTO ARREST: READY", Color3.fromRGB(100, 255, 100))
        end
    end

    if ui.getValue(TAB_MAIN, C_GUARD, "TP Arrest") then
        if not has_handcuffs() then
            draw_line("TP ARREST: EQUIP HANDCUFFS", Color3.fromRGB(255, 200, 0))
        elseif tp_arrest_target then
            draw_line("TP ARREST: CHASING " .. tp_arrest_target, Color3.fromRGB(255, 100, 0))
        else
            draw_line("TP ARREST: SEARCHING", Color3.fromRGB(100, 200, 255))
        end
    end

    if ui.getValue(TAB_MAIN, C_GUARD, "Fast Reload") then
        draw_line("FAST RELOAD: ON", Color3.fromRGB(255, 220, 50))
    end

    if ui.getValue(TAB_MAIN, C_GUARD, "Safety TP After Arrest") then
        draw_line("SAFETY TP: ON", Color3.fromRGB(150, 255, 150))
    end

    -- Inmate indicators
    if ui.getValue(TAB_MAIN, C_INMATE, "Low Health Escape TP") then
        local lp = entity.GetLocalPlayer()
        if lp then
            local hp_pct = lp.MaxHealth > 0 and math.floor(lp.Health / lp.MaxHealth * 100) or 100
            local threshold = ui.getValue(TAB_MAIN, C_INMATE, "Health Threshold %")
            local col = hp_pct <= threshold
                and Color3.fromRGB(255, 50, 50)
                or  Color3.fromRGB(100, 255, 100)
            draw_line(string.format("ESCAPE TP: %d%% HP (trigger: %d%%)", hp_pct, threshold), col)
        end
    end

    if ui.getValue(TAB_MAIN, C_INMATE, "Anti Arrest TP") then
        draw_line("ANTI ARREST: ACTIVE", Color3.fromRGB(200, 100, 255))
    end
end

-- ============================================
--  REGISTER CALLBACKS
-- ============================================

cheat.register("onSlowUpdate", cache_items)

cheat.register("onPaint", function()
    draw_cached_esp()
    draw_indicators()
end)

cheat.register("onUpdate", function()
    run_auto_arrest()
    run_tp_arrest()
    run_safety_tp()
    run_fast_reload()
    run_low_health_escape()
    run_anti_arrest()
end)

-- ============================================
print("[PrisonLifeWare] v2 loaded!")
