--!nocheck
--!nolint

-- PrisonLifeWare - Minimal (Only Auto Grab Guns + Remove Doors)
-- For Serotonin external menu

print("✅ PrisonLifeWare Minimal loaded!")

-- ==================== UI (exact same style as your other scripts) ====================
ui.newTab("PrisonLifeWare", "PrisonLifeWare")

ui.newContainer("PrisonLifeWare", "Features", "Features", {next = true})
ui.newCheckbox("PrisonLifeWare", "Features", "Auto Grab Guns", true)
ui.newCheckbox("PrisonLifeWare", "Features", "Remove Doors", false)

-- ==================== AUTO GRAB GUNS ====================
cheat.Register("onUpdate", function()
    if not ui.getValue("PrisonLifeWare", "Features", "Auto Grab Guns") then return end

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
    if not ui.getValue("PrisonLifeWare", "Features", "Remove Doors") then return end

    local ws = game.Workspace
    for _, obj in pairs(ws:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("door") or obj.Name:lower():find("gate") or obj.Name:lower():find("fence")) then
            obj.CanCollide = false
            obj.Transparency = 0.7
        end
    end
end)

print("Features registered. Toggle Auto Grab Guns and Remove Doors in the side menu.")
