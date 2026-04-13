-- ============================================
--  PrisonLifeWare v2
--  github.com/loXxiyt/PrisonLifeWare
-- ============================================

local TAB_MAIN = "PLWare"
local C_ESP    = "ItemESP"
local C_TP     = "Teleports"
local C_MISC   = "Misc"

ui.newTab(TAB_MAIN, "PrisonLifeWare")
ui.NewContainer(TAB_MAIN, C_ESP,  "Item ESP",  { autosize = true, next = true })
ui.NewContainer(TAB_MAIN, C_TP,   "Teleports", { autosize = true, next = true })
ui.NewContainer(TAB_MAIN, C_MISC, "Misc",      { autosize = true })

-- ============================================
--  HELPERS
-- ============================================

local function get_hrp()
    local lp = game.LocalPlayer
    local char = lp and lp.Character
    return char and char:FindFirstChild("HumanoidRootPart")
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
    local char = game.LocalPlayer.Character
    if not char then return false end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return false end
    local name = string.lower(tool.Name)
    return name == "handcuffs" or name == "menottes"
end

-- Check if player is a criminal by team
local function is_criminal(player)
    local team = player.Team
    if not team then return false end
    local t = string.lower(team)
    return string.find(t, "criminal") ~= nil
end

-- Check if player is already cuffed/arrested
local function is_cuffed(player)
    if not player.IsAlive then return true end
    -- Check for cuffed state via character
    local char = game.LocalPlayer.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    -- If health is 0 or very low they're down
    if player.Health <= 0 then return true end
    return false
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

local CARD_NAMES = {
    ["Key card"] = true,
    ["Key Card"] = true,
}

local GUN_NAMES = {
    ["AK-47"]         = true,
    ["Remington 870"] = true,
    ["Taser"]         = true,
    ["M9"]            = true,
    ["FAL"]           = true,
    ["M700"]          = true,
    ["MP5"]           = true,
    ["M4A1"]          = true,
    ["Revolver"]      = true,
    ["C4 Explosive"]  = true,
    ["Riot Shield"]   = true,
    ["Crude Knife"]   = true,
    ["Hammer"]        = true,
    ["EBR"]           = true,
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

    local ok, children = pcall(function()
        return game.Workspace:GetChildren()
    end)
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
                        table.insert(cached_cards, { pos = pos, dist = dist, name = obj.Name })
                    elseif gun_on and GUN_NAMES[obj.Name] then
                        table.insert(cached_guns, { pos = pos, dist = dist, name = obj.Name })
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

    local cc_raw  = ui.getValue(TAB_MAIN, C_ESP, "Card Color")
    local gc_raw  = ui.getValue(TAB_MAIN, C_ESP, "Gun Color")
    local card_col = Color3.fromRGB(cc_raw.r, cc_raw.g, cc_raw.b)
    local gun_col  = Color3.fromRGB(gc_raw.r,  gc_raw.g,  gc_raw.b)

    local function draw_entry(entry, label, color)
        local sx, sy, on_screen = utility.WorldToScreen(entry.pos)
        if not on_screen then return end

        draw.Rect(sx - 15, sy - 15, 30, 30, color, 1.5)

        local tw, th = draw.GetTextSize(label)
        draw.TextOutlined(label, sx - (tw / 2), sy - 20 - th, color)

        local dist_text = string.format("%.0fm", entry.dist)
        local dw, _    = draw.GetTextSize(dist_text)
        draw.TextOutlined(dist_text, sx - (dw / 2), sy + 18, Color3.fromRGB(200, 200, 200))
    end

    if card_on then
        for _, entry in pairs(cached_cards) do
            draw_entry(entry, "KEY CARD", card_col)
        end
    end
    if gun_on then
        for _, entry in pairs(cached_guns) do
            draw_entry(entry, entry.name, gun_col)
        end
    end
end

-- ============================================
--  TELEPORTS
-- ============================================

local location_names = {
    "Armory",
    "Criminal Base",
    "Prison Yard",
    "Cells",
    "Cafeteria",
    "Outside Gate",
}

-- All coords confirmed in-game
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
    if not hrp then print("[PLWare] No character.") return end

    local raw_index = ui.getValue(TAB_MAIN, C_TP, "Location")
    local name = location_names[raw_index + 1]
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
        print(string.format("[PLWare] Position saved: %.1f, %.1f, %.1f", saved_x, saved_y, saved_z))
    end
end)

ui.NewButton(TAB_MAIN, C_TP, "Grab Gun (TP + Jiggle)", function()
    local hrp = get_hrp()
    if not hrp then return end

    saved_x = hrp.Position.X
    saved_y = hrp.Position.Y
    saved_z = hrp.Position.Z

    local Y = 100.7
    local Z = 2227.9

    hrp.Position = Vector3.new(817.0, Y, Z)
    wait_ms(200)
    hrp.Position = Vector3.new(820.3, Y, Z)
    wait_ms(250)
    hrp.Position = Vector3.new(813.8, Y, Z)
    wait_ms(200)
    hrp.Position = Vector3.new(820.3, Y, Z)
    wait_ms(250)
    hrp.Position = Vector3.new(819.0, Y, Z)
    wait_ms(150)

    print("[PLWare] Jiggle done! Returning in 1 second...")
    wait_ms(1000)

    local hrp2 = get_hrp()
    if hrp2 and saved_x then
        hrp2.Position = Vector3.new(saved_x, saved_y, saved_z)
        print("[PLWare] Auto returned!")
    end
end)

ui.NewButton(TAB_MAIN, C_TP, "Return to Saved", function()
    local hrp = get_hrp()
    if not hrp then return end
    if saved_x then
        hrp.Position = Vector3.new(saved_x, saved_y, saved_z)
        print("[PLWare] Returned.")
    else
        print("[PLWare] No saved position yet.")
    end
end)

ui.NewButton(TAB_MAIN, C_TP, "TP to Key Card", function()
    local hrp = get_hrp()
    if not hrp then return end

    if #cached_cards == 0 then
        print("[PLWare] No key cards found. Enable Card ESP first.")
        return
    end

    local best      = nil
    local best_dist = math.huge
    local my_pos    = hrp.Position

    for _, card in ipairs(cached_cards) do
        local dist = (card.pos - my_pos).Magnitude
        if dist < best_dist then
            best_dist = dist
            best      = card
        end
    end

    if best then
        saved_x = hrp.Position.X
        saved_y = hrp.Position.Y
        saved_z = hrp.Position.Z
        hrp.Position = Vector3.new(best.pos.X, best.pos.Y + 3, best.pos.Z)
        print(string.format("[PLWare] TP'd to Key Card (%.0fm away)", best_dist))
    end
end)

-- ============================================
--  MISC - PREMIUM ARREST SYSTEM
-- ============================================

ui.NewCheckbox(TAB_MAIN, C_MISC, "Auto Arrest")
ui.newSliderFloat(TAB_MAIN, C_MISC, "Arrest Range", 5.0, 30.0, 12.0)
ui.NewCheckbox(TAB_MAIN, C_MISC, "TP Arrest")
ui.newSliderFloat(TAB_MAIN, C_MISC, "TP Arrest Range", 50.0, 500.0, 150.0)

-- ── State tracking ──────────────────────────
local auto_arrest_active  = false
local auto_arrest_status  = "READY"  -- READY / LOCKING / NO HANDCUFFS / NO TARGET
local last_arrest_click   = 0
local last_tp_arrest      = 0
local tp_arrest_target    = nil  -- track current TP arrest target

-- Arrest click cooldown — Prison Life handcuff animation is ~800ms
-- We click every 300ms which is fast enough without being too spammy
local ARREST_CLICK_CD = 300

-- ── Find best criminal target ────────────────
local function find_best_criminal(max_range)
    local hrp = get_hrp()
    if not hrp then return nil end

    local my_pos    = hrp.Position
    local players   = entity.GetPlayers(true)
    local best      = nil
    local best_dist = max_range

    for _, player in ipairs(players) do
        if player.IsAlive and is_criminal(player) and not is_cuffed(player) then
            local dist = (player.Position - my_pos).Magnitude
            if dist < best_dist then
                best_dist = dist
                best      = player
            end
        end
    end

    return best
end

-- ── Auto Arrest ──────────────────────────────
local function auto_arrest()
    if not ui.getValue(TAB_MAIN, C_MISC, "Auto Arrest") then
        auto_arrest_active = false
        auto_arrest_status = "OFF"
        return
    end

    -- Must have handcuffs equipped
    if not has_handcuffs() then
        auto_arrest_active = false
        auto_arrest_status = "NO HANDCUFFS"
        return
    end

    local now   = utility.GetTickCount()
    local range = ui.getValue(TAB_MAIN, C_MISC, "Arrest Range")
    local best  = find_best_criminal(range)

    if not best then
        auto_arrest_active = false
        auto_arrest_status = "NO TARGET"
        return
    end

    auto_arrest_active = true
    auto_arrest_status = "LOCKING: " .. best.Name

    -- Only click at the arrest cooldown rate
    if now - last_arrest_click >= ARREST_CLICK_CD then
        last_arrest_click = now
        aim_and_click(best)
    end
end

-- ── TP Arrest ────────────────────────────────
local function tp_arrest()
    if not ui.getValue(TAB_MAIN, C_MISC, "TP Arrest") then
        tp_arrest_target = nil
        return
    end

    if not has_handcuffs() then return end

    local now   = utility.GetTickCount()
    local hrp   = get_hrp()
    if not hrp then return end

    local range = ui.getValue(TAB_MAIN, C_MISC, "TP Arrest Range")
    local best  = find_best_criminal(range)

    if not best then
        tp_arrest_target = nil
        return
    end

    -- New target or target changed
    if tp_arrest_target ~= best.Name then
        tp_arrest_target = best.Name

        -- Save position before TPing
        saved_x = hrp.Position.X
        saved_y = hrp.Position.Y
        saved_z = hrp.Position.Z
    end

    -- TP slightly behind the criminal so we're in arrest range
    -- but not clipping inside them
    local target_pos = best.Position
    local offset = 2.5

    -- Calculate position slightly behind target relative to us
    local dir = (target_pos - hrp.Position)
    local mag = dir.Magnitude
    if mag > 0 then
        local nx = dir.X / mag
        local nz = dir.Z / mag
        hrp.Position = Vector3.new(
            target_pos.X - nx * offset,
            target_pos.Y,
            target_pos.Z - nz * offset
        )
    else
        hrp.Position = Vector3.new(target_pos.X, target_pos.Y, target_pos.Z)
    end

    -- Click to arrest at proper cooldown
    if now - last_arrest_click >= ARREST_CLICK_CD then
        last_arrest_click = now
        aim_and_click(best)
    end
end

-- ============================================
--  DRAW INDICATORS
-- ============================================

local function draw_indicators()
    local sw, sh = cheat.getWindowSize()
    local cx = sw / 2
    local y  = 30

    local function draw_status(label, color)
        local tw, _ = draw.GetTextSize(label, "Verdana")
        draw.TextOutlined(label, cx - (tw / 2), y, color, "Verdana")
        y = y + 20
    end

    -- Auto Arrest indicator
    if ui.getValue(TAB_MAIN, C_MISC, "Auto Arrest") then
        if auto_arrest_status == "NO HANDCUFFS" then
            draw_status("AUTO ARREST: EQUIP HANDCUFFS", Color3.fromRGB(255, 200, 0))
        elseif auto_arrest_status == "NO TARGET" then
            draw_status("AUTO ARREST: NO CRIMINAL IN RANGE", Color3.fromRGB(100, 255, 100))
        elseif auto_arrest_active then
            draw_status("AUTO ARREST: " .. auto_arrest_status, Color3.fromRGB(255, 50, 50))
        else
            draw_status("AUTO ARREST: READY", Color3.fromRGB(100, 255, 100))
        end
    end

    -- TP Arrest indicator
    if ui.getValue(TAB_MAIN, C_MISC, "TP Arrest") then
        if not has_handcuffs() then
            draw_status("TP ARREST: EQUIP HANDCUFFS", Color3.fromRGB(255, 200, 0))
        elseif tp_arrest_target then
            draw_status("TP ARREST: CHASING " .. tp_arrest_target, Color3.fromRGB(255, 100, 0))
        else
            draw_status("TP ARREST: SEARCHING...", Color3.fromRGB(100, 200, 255))
        end
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
    auto_arrest()
    tp_arrest()
end)

-- ============================================
print("[PrisonLifeWare] v2 loaded!")
