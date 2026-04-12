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

-- ============================================
--  ITEM ESP (guard cards + guns on ground)
-- ============================================

ui.NewCheckbox(TAB_MAIN, C_ESP, "Card ESP")
ui.NewCheckbox(TAB_MAIN, C_ESP, "Gun ESP")
ui.NewColorpicker(TAB_MAIN, C_ESP, "Card Color", { r=0,   g=255, b=255, a=255 })
ui.NewColorpicker(TAB_MAIN, C_ESP, "Gun Color",  { r=255, g=100, b=0,   a=255 })

local CARD_NAMES = {
    ["Guard Card"] = true,
    ["GuardCard"]  = true,
    ["Card"]       = true,
}

local GUN_NAMES = {
    ["Gun"]     = true,
    ["Pistol"]  = true,
    ["Rifle"]   = true,
    ["Shotgun"] = true,
    ["AK47"]    = true,
    ["M4"]      = true,
    ["Uzi"]     = true,
    ["Sniper"]  = true,
    ["Weapon"]  = true,
}

local function draw_item_esp(item, label, color)
    local handle = item:FindFirstChild("Handle")
    if not handle then return end

    local sx, sy, on_screen = utility.WorldToScreen(handle.Position)
    if not on_screen then return end

    draw.Rect(sx - 15, sy - 15, 30, 30, color, 1.5)

    local tw, th = draw.GetTextSize(label)
    draw.TextOutlined(label, sx - (tw / 2), sy - 20 - th, color)
end

cheat.register("onPaint", function()
    local card_on = ui.getValue(TAB_MAIN, C_ESP, "Card ESP")
    local gun_on  = ui.getValue(TAB_MAIN, C_ESP, "Gun ESP")
    if not card_on and not gun_on then return end

    local cc_raw = ui.getValue(TAB_MAIN, C_ESP, "Card Color")
    local gc_raw = ui.getValue(TAB_MAIN, C_ESP, "Gun Color")
    local card_color = Color3.fromRGB(cc_raw.r, cc_raw.g, cc_raw.b)
    local gun_color  = Color3.fromRGB(gc_raw.r, gc_raw.g, gc_raw.b)

    for _, obj in ipairs(game.Workspace:GetDescendants()) do
        local cn = obj.ClassName
        if cn == "Model" or cn == "Tool" then
            if card_on and CARD_NAMES[obj.Name] then
                draw_item_esp(obj, "CARD", card_color)
            elseif gun_on and GUN_NAMES[obj.Name] then
                draw_item_esp(obj, obj.Name, gun_color)
            end
        end
    end
end)

-- ============================================
--  TELEPORTS
-- ============================================

local LOCATIONS = {
    ["Armory"]        = Vector3.new(188,  17, -66),
    ["Criminal Base"] = Vector3.new(-246,  5,  -8),
    ["Prison Yard"]   = Vector3.new(50,    5,   0),
    ["Cells"]         = Vector3.new(135,   5,  40),
    ["Cafeteria"]     = Vector3.new(100,   5, -50),
    ["Outside Gate"]  = Vector3.new(0,     5,  80),
}

local location_names = {}
for k in pairs(LOCATIONS) do table.insert(location_names, k) end
table.sort(location_names)

ui.NewDropdown(TAB_MAIN, C_TP, "Location", location_names, 1)

ui.NewButton(TAB_MAIN, C_TP, "Teleport", function()
    local hrp = get_hrp()
    if not hrp then print("[PLWare] No character.") return end
    local selected = ui.getValue(TAB_MAIN, C_TP, "Location")
    local dest = LOCATIONS[selected]
    if dest then
        hrp.Position = dest
        print("[PLWare] Teleported to " .. selected)
    end
end)

-- Gun grab: save pos -> tp to armory -> return
local saved_pos = nil

ui.NewButton(TAB_MAIN, C_TP, "Save Position", function()
    local hrp = get_hrp()
    if hrp then
        saved_pos = Vector3.new(hrp.Position.X, hrp.Position.Y, hrp.Position.Z)
        print("[PLWare] Position saved.")
    end
end)

ui.NewButton(TAB_MAIN, C_TP, "Grab Gun (TP to Armory)", function()
    local hrp = get_hrp()
    if not hrp then return end
    saved_pos = Vector3.new(hrp.Position.X, hrp.Position.Y, hrp.Position.Z)
    hrp.Position = LOCATIONS["Armory"]
    print("[PLWare] At armory. Walk over gun then hit Return.")
end)

ui.NewButton(TAB_MAIN, C_TP, "Return to Saved", function()
    local hrp = get_hrp()
    if not hrp then return end
    if saved_pos then
        hrp.Position = saved_pos
        print("[PLWare] Returned.")
    else
        print("[PLWare] No saved position yet.")
    end
end)

-- ============================================
--  AUTO ARREST
-- ============================================

ui.NewCheckbox(TAB_MAIN, C_MISC, "Auto Arrest")
ui.newSliderFloat(TAB_MAIN, C_MISC, "Arrest Range", 5.0, 30.0, 12.0)

cheat.register("onUpdate", function()
    if not ui.getValue(TAB_MAIN, C_MISC, "Auto Arrest") then return end

    local hrp = get_hrp()
    if not hrp then return end

    local range   = ui.getValue(TAB_MAIN, C_MISC, "Arrest Range")
    local my_pos  = hrp.Position
    local players = entity.GetPlayers(true)

    for _, player in ipairs(players) do
        if player.IsAlive then
            local dist = (player.Position - my_pos).Magnitude
            if dist <= range then
                local bone_pos = player:GetBonePosition("HumanoidRootPart")
                             or player:GetBonePosition("Torso")
                             or player.Position
                local sx, sy, on_screen = utility.WorldToScreen(bone_pos)
                if on_screen then
                    game.SilentAim(sx, sy)
                    mouse.Click("leftmouse")
                end
                break
            end
        end
    end
end)

-- ============================================
print("[PrisonLifeWare] v2 loaded!")
