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
                        table.insert(cached_cards, { pos = pos, dist = dist, name = obj.Name, part = part })
                    elseif gun_on and GUN_NAMES[obj.Name] then
                        table.insert(cached_guns, { pos = pos, dist = dist, name = obj.Name, part = part })
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

-- IMPORTANT: Serotonin dropdown is 0-indexed
-- location_names[1] = index 0, location_names[2] = index 1, etc.
local location_names = {
    "Armory",
    "Criminal Base",
    "Prison Yard",
    "Cells",
    "Cafeteria",
    "Outside Gate",
}

local LOCATIONS = {
    ["Armory"]        = Vector3.new(816.7,  100.7, 2227.8),
    ["Criminal Base"] = Vector3.new(-974.4, 108.3, 2057.2),
    ["Prison Yard"]   = Vector3.new(50,     5,     0),
    ["Cells"]         = Vector3.new(135,    5,     40),
    ["Cafeteria"]     = Vector3.new(100,    5,    -50),
    ["Outside Gate"]  = Vector3.new(0,      5,     80),
}

ui.NewDropdown(TAB_MAIN, C_TP, "Location", location_names, 1)

ui.NewButton(TAB_MAIN, C_TP, "Teleport", function()
    local hrp = get_hrp()
    if not hrp then print("[PLWare] No character.") return end

    -- Dropdown is 0-indexed so add 1 to get Lua table index
    local raw_index = ui.getValue(TAB_MAIN, C_TP, "Location")
    local name = location_names[raw_index + 1]

    if not name then
        print("[PLWare] Invalid location index:", raw_index)
        return
    end

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
    local Z = 2227.8

    -- Sweep across both confirmed pads
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

-- TP to nearest dropped keycard
ui.NewButton(TAB_MAIN, C_TP, "TP to Key Card", function()
    local hrp = get_hrp()
    if not hrp then return end

    if #cached_cards == 0 then
        print("[PLWare] No key cards found. Enable Card ESP first.")
        return
    end

    -- Find closest cached card
    local best     = nil
    local best_dist = math.huge
    local my_pos   = hrp.Position

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
--  MISC
-- ============================================

-- Auto Arrest (criminals only)
ui.NewCheckbox(TAB_MAIN, C_MISC, "Auto Arrest")
ui.newSliderFloat(TAB_MAIN, C_MISC, "Arrest Range", 5.0, 30.0, 12.0)

-- Auto TP + Arrest (tp to criminal then arrest)
ui.NewCheckbox(TAB_MAIN, C_MISC, "TP Arrest")
ui.newSliderFloat(TAB_MAIN, C_MISC, "TP Arrest Range", 50.0, 500.0, 150.0)

local auto_arrest_active  = false
local tp_arrest_cooldown  = 0

local function is_criminal(player)
    -- Only target criminals, not officers or inmates
    local team = player.Team
    if not team then return false end
    local t = string.lower(team)
    return t == "criminal" or t == "criminals"
end

local function do_arrest(player)
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

local function auto_arrest()
    if not ui.getValue(TAB_MAIN, C_MISC, "Auto Arrest") then
        auto_arrest_active = false
        return
    end

    local hrp = get_hrp()
    if not hrp then return end

    local range     = ui.getValue(TAB_MAIN, C_MISC, "Arrest Range")
    local my_pos    = hrp.Position
    local players   = entity.GetPlayers(true)
    local best      = nil
    local best_dist = range

    for _, player in ipairs(players) do
        if player.IsAlive and is_criminal(player) then
            local dist = (player.Position - my_pos).Magnitude
            if dist < best_dist then
                best_dist = dist
                best      = player
            end
        end
    end

    if best then
        auto_arrest_active = true
        do_arrest(best)
    else
        auto_arrest_active = false
    end
end

local function tp_arrest()
    if not ui.getValue(TAB_MAIN, C_MISC, "TP Arrest") then return end

    local now = utility.GetTickCount()
    if now - tp_arrest_cooldown < 3000 then return end -- 3s cooldown

    local hrp = get_hrp()
    if not hrp then return end

    local range   = ui.getValue(TAB_MAIN, C_MISC, "TP Arrest Range")
    local my_pos  = hrp.Position
    local players = entity.GetPlayers(true)
    local best    = nil
    local best_dist = range

    for _, player in ipairs(players) do
        if player.IsAlive and is_criminal(player) then
            local dist = (player.Position - my_pos).Magnitude
            if dist < best_dist then
                best_dist = dist
                best      = player
            end
        end
    end

    if best then
        tp_arrest_cooldown = now

        -- Save position
        saved_x = hrp.Position.X
        saved_y = hrp.Position.Y
        saved_z = hrp.Position.Z

        -- TP directly behind the criminal
        local target_pos = best.Position
        hrp.Position = Vector3.new(target_pos.X, target_pos.Y, target_pos.Z)
        wait_ms(100)

        -- Arrest them
        do_arrest(best)
        print("[PLWare] TP Arrested: " .. best.Name)
    end
end

-- ============================================
--  DRAW INDICATORS
-- ============================================

local function draw_indicators()
    local y = 30
    local screen_w = 1920

    if ui.getValue(TAB_MAIN, C_MISC, "Auto Arrest") then
        local color = auto_arrest_active
            and Color3.fromRGB(255, 50,  50)
            or  Color3.fromRGB(100, 255, 100)
        local label = auto_arrest_active and "AUTO ARREST: LOCKING" or "AUTO ARREST: READY"
        local tw, _ = draw.GetTextSize(label, "Verdana")
        draw.TextOutlined(label, (screen_w / 2) - (tw / 2), y, color, "Verdana")
        y = y + 18
    end

    if ui.getValue(TAB_MAIN, C_MISC, "TP Arrest") then
        local label = "TP ARREST: ON"
        local tw, _ = draw.GetTextSize(label, "Verdana")
        draw.TextOutlined(label, (screen_w / 2) - (tw / 2), y, Color3.fromRGB(255, 200, 0), "Verdana")
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
