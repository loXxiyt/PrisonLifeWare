--!nocheck
--!nolint

-- PrisonLifeWare v3.3 - Minimal for Serotonin
-- Only Auto Grab Guns + Remove Doors

print("✅ PrisonLifeWare v3.3 loaded!")

-- ==================== UI SETUP ====================
ui.newTab("plw", "PrisonLifeWare")

ui.newContainer("plw", "feat", "Features", {next = true})
ui.newCheckbox("plw", "feat", "Auto Grab Guns", true)
ui.newCheckbox("plw", "feat", "Remove Doors", false)

-- ==================== AUTO GRAB GUNS ====================
cheat.Register("onUpdate", function()
    if not ui.getValue("plw", "feat", "Auto Grab Guns") then return end

    local ws = game.Workspace
    local prisonItems = ws:FindFirstChild("Prison_ITEMS")
    if not prisonItems then return end

    local giver = prisonItems:FindFirstChild("giver")
    if not giver then return end

    for _, v in pairs(giver:GetChildren()) do
        local pickup = v:FindFirstChild("ITEMPICKUP")
        if pickup then
            pcall(function()
                ws.Remote.ItemHandler:InvokeServer(pickup)
            end)
        end
    end
end)

-- ==================== REMOVE DOORS ====================
cheat.Register("onUpdate", function()
    if not ui.getValue("plw", "feat", "Remove Doors") then return end

    local ws = game.Workspace
    for _, obj in pairs(ws:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("door") or obj.Name:lower():find("gate") or obj.Name:lower():find("fence")) then
            obj.CanCollide = false
            obj.Transparency = 0.7
        end
    end
end)

print("Toggles ready. Use the PrisonLifeWare tab on the side.")
