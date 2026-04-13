-- ============================================
--  PrisonLifeWare - SirHurt Edition
--  github.com/loXxiyt/PrisonLifeWare
--  Standard Roblox Lua - works on most executors
-- ============================================

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer   = Players.LocalPlayer

-- ============================================
--  HELPERS
-- ============================================

local function get_char()
    return LocalPlayer.Character
end

local function get_hrp()
    local char = get_char()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function get_humanoid()
    local char = get_char()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function notify(msg)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title   = "PLWare",
        Text    = msg,
        Duration = 3
    })
end

-- ============================================
--  SIMPLE GUI (no external library needed)
-- ============================================

-- Remove existing GUI if reloading
local existing = LocalPlayer.PlayerGui:FindFirstChild("PLWareGui")
if existing then existing:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PLWareGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer.PlayerGui

-- Main frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 420)
MainFrame.Position = UDim2.new(0, 20, 0, 100)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Corner rounding
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = MainFrame

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(0, 180, 180)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -10, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "PrisonLifeWare"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Minimize button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -32, 0, 4)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 14
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0
MinBtn.Parent = TitleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 4)
minCorner.Parent = MinBtn

-- Content frame
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -10, 1, -46)
Content.Position = UDim2.new(0, 5, 0, 41)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 6)
ContentLayout.Parent = Content

-- Minimize toggle
local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    Content.Visible = not isMinimized
    MainFrame.Size = isMinimized
        and UDim2.new(0, 280, 0, 40)
        or  UDim2.new(0, 280, 0, 420)
end)

-- ── UI Helper functions ─────────────────────

local function make_section(title)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = "── " .. title .. " ──"
    lbl.TextColor3 = Color3.fromRGB(0, 200, 200)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = Content
    return lbl
end

local function make_toggle(label, default, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = default
        and Color3.fromRGB(0, 160, 160)
        or  Color3.fromRGB(50, 50, 65)
    btn.BorderSizePixel = 0
    btn.Text = label .. ": " .. (default and "ON" or "OFF")
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.Parent = Content

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 5)
    bc.Parent = btn

    local state = default or false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state
            and Color3.fromRGB(0, 160, 160)
            or  Color3.fromRGB(50, 50, 65)
        btn.Text = label .. ": " .. (state and "ON" or "OFF")
        if callback then callback(state) end
    end)

    return btn, function() return state end
end

local function make_button(label, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    btn.BorderSizePixel = 0
    btn.Text = label
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.Parent = Content

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 5)
    bc.Parent = btn

    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    return btn
end

-- ============================================
--  STATE
-- ============================================

local state = {
    esp_cards    = false,
    esp_guns     = false,
    auto_arrest  = false,
    fast_punch   = false,
}

local saved_x, saved_y, saved_z = nil, nil, nil
local cached_cards = {}
local cached_guns  = {}
local last_cache   = 0
local last_punch   = 0
local last_arrest  = 0

-- ============================================
--  ITEM NAMES
-- ============================================

local CARD_NAMES = {
    ["Key card"] = true,
    ["Key Card"] = true,
}

local GUN_NAMES = {
    ["AK-47"]          = true,
    ["Remington 870"]  = true,
    ["Taser"]          = true,
    ["M9"]             = true,
    ["FAL"]            = true,
    ["M700"]           = true,
    ["MP5"]            = true,
    ["M4A1"]           = true,
    ["Revolver"]       = true,
    ["C4 Explosive"]   = true,
    ["Riot Shield"]    = true,
    ["Crude Knife"]    = true,
    ["Hammer"]         = true,
}

local function get_part(obj)
    return obj:FindFirstChild("Handle")
        or obj:FindFirstChild("Mesh")
        or obj:FindFirstChildOfClass("MeshPart")
        or obj:FindFirstChildOfClass("Part")
end

-- ============================================
--  ESP (BillboardGui on each item)
-- ============================================

local esp_folder = Instance.new("Folder")
esp_folder.Name = "PLWare_ESP"
esp_folder.Parent = game.Workspace

local function clear_esp()
    for _, v in ipairs(esp_folder:GetChildren()) do
        v:Destroy()
    end
end

local function make_billboard(part, label, color)
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 80, 0, 30)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = part
    bb.Parent = esp_folder

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.5
    bg.BorderSizePixel = 0
    bg.Parent = bb

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 4)
    bc.Parent = bg

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Text = label
    txt.TextColor3 = color
    txt.TextSize = 12
    txt.Font = Enum.Font.GothamBold
    txt.Parent = bg
end

local function cache_and_draw_esp()
    clear_esp()
    cached_cards = {}
    cached_guns  = {}

    if not state.esp_cards and not state.esp_guns then return end

    local ok, children = pcall(function()
        return game.Workspace:GetChildren()
    end)
    if not ok then return end

    for _, obj in ipairs(children) do
        local cn = obj.ClassName
        if cn == "Model" or cn == "Tool" then
            local part = get_part(obj)
            if part then
                if state.esp_cards and CARD_NAMES[obj.Name] then
                    make_billboard(part, "KEY CARD", Color3.fromRGB(0, 255, 255))
                elseif state.esp_guns and GUN_NAMES[obj.Name] then
                    make_billboard(part, obj.Name, Color3.fromRGB(255, 150, 0))
                end
            end
        end
    end
end

-- ============================================
--  TELEPORT LOCATIONS
-- ============================================

local LOCATIONS = {
    ["Armory"]        = Vector3.new(816.7,  100.7, 2227.8),
    ["Criminal Base"] = Vector3.new(-974.4, 108.3, 2057.2),
    ["Prison Yard"]   = Vector3.new(50,     5,     0),
    ["Cells"]         = Vector3.new(135,    5,     40),
    ["Cafeteria"]     = Vector3.new(100,    5,    -50),
    ["Outside Gate"]  = Vector3.new(0,      5,     80),
}

local function tp_to(pos)
    local hrp = get_hrp()
    if hrp then
        hrp.CFrame = CFrame.new(pos)
    end
end

-- ============================================
--  BUILD UI
-- ============================================

-- ESP Section
make_section("Item ESP")
make_toggle("Card ESP", false, function(on)
    state.esp_cards = on
    cache_and_draw_esp()
end)
make_toggle("Gun ESP", false, function(on)
    state.esp_guns = on
    cache_and_draw_esp()
end)

-- Teleport Section
make_section("Teleports")

local loc_names = {}
for k in pairs(LOCATIONS) do table.insert(loc_names, k) end
table.sort(loc_names)

for _, name in ipairs(loc_names) do
    local n = name
    make_button("TP: " .. n, function()
        tp_to(LOCATIONS[n])
        notify("Teleported to " .. n)
    end)
end

make_button("Save Position", function()
    local hrp = get_hrp()
    if hrp then
        saved_x = hrp.Position.X
        saved_y = hrp.Position.Y
        saved_z = hrp.Position.Z
        notify("Position saved!")
    end
end)

make_button("Return to Saved", function()
    local hrp = get_hrp()
    if hrp and saved_x then
        hrp.CFrame = CFrame.new(saved_x, saved_y, saved_z)
        notify("Returned!")
    else
        notify("No saved position yet.")
    end
end)

make_button("Grab Gun (TP + Jiggle)", function()
    local hrp = get_hrp()
    if not hrp then return end

    saved_x = hrp.Position.X
    saved_y = hrp.Position.Y
    saved_z = hrp.Position.Z

    local Y = 100.7
    local Z = 2227.8

    local steps = {
        Vector3.new(817.0, Y, Z),
        Vector3.new(820.3, Y, Z),
        Vector3.new(813.8, Y, Z),
        Vector3.new(820.3, Y, Z),
        Vector3.new(819.0, Y, Z),
    }

    local i = 0
    local function do_step()
        i = i + 1
        if i <= #steps then
            hrp.CFrame = CFrame.new(steps[i])
            task.delay(0.2, do_step)
        else
            notify("Jiggle done! Returning in 1s...")
            task.delay(1, function()
                local h = get_hrp()
                if h and saved_x then
                    h.CFrame = CFrame.new(saved_x, saved_y, saved_z)
                    notify("Auto returned!")
                end
            end)
        end
    end
    do_step()
end)

-- Misc Section
make_section("Misc")

make_toggle("Auto Arrest", false, function(on)
    state.auto_arrest = on
end)

make_toggle("Fast Punch", false, function(on)
    state.fast_punch = on
end)

-- ============================================
--  MAIN LOOP
-- ============================================

-- Cache ESP every 1 second
RunService.Heartbeat:Connect(function()
    local now = tick()

    -- Refresh ESP cache every 1s
    if now - last_cache >= 1 then
        last_cache = now
        if state.esp_cards or state.esp_guns then
            cache_and_draw_esp()
        else
            clear_esp()
        end
    end

    -- Auto Arrest
    if state.auto_arrest and now - last_arrest >= 0.1 then
        last_arrest = now
        local hrp = get_hrp()
        if hrp then
            local my_pos  = hrp.Position
            local best    = nil
            local best_d  = 15 -- stud range

            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local their_hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if their_hrp and hum and hum.Health > 0 then
                        local dist = (their_hrp.Position - my_pos).Magnitude
                        if dist < best_d then
                            best_d = dist
                            best   = p
                        end
                    end
                end
            end

            if best and best.Character then
                local target_hrp = best.Character:FindFirstChild("HumanoidRootPart")
                if target_hrp then
                    -- Fire arrest remote
                    pcall(function()
                        game.Workspace.Remote.ArrestEvent:FireServer(best)
                    end)
                end
            end
        end
    end

    -- Fast Punch
    if state.fast_punch and now - last_punch >= 0.1 then
        last_punch = now
        local hrp = get_hrp()
        if hrp then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local their_hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if their_hrp and hum and hum.Health > 0 then
                        local dist = (their_hrp.Position - hrp.Position).Magnitude
                        if dist <= 8 then
                            pcall(function()
                                game.Workspace.Remote.PunchEvent:FireServer(p)
                            end)
                        end
                    end
                end
            end
        end
    end
end)

print("[PrisonLifeWare SirHurt] Loaded!")
notify("PrisonLifeWare loaded!")
