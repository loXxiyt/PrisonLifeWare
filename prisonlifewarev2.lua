-- ============================================
--  Prison Life - Remove Doors
-- ============================================

local TAB = "PrisonLife"
local CONT = "Doors"

ui.newTab(TAB, "Prison Life")
ui.NewContainer(TAB, CONT, "Doors", { autosize = true })

-- Checkbox to toggle
ui.NewCheckbox(TAB, CONT, "Remove Doors")

-- Door name patterns to target
local DOOR_NAMES = {
    "Door", "door", "Gate", "gate", "Cell", "Bars"
}

local removed_doors = {}

local function set_door_state(part, removed)
    if removed then
        part.Transparency = 1
        part.CanCollide = false
    else
        part.Transparency = 0
        part.CanCollide = true
    end
end

local function find_and_toggle_doors(remove)
    for _, descendant in ipairs(game.Workspace:GetDescendants()) do
        if descendant.ClassName == "Part" or descendant.ClassName == "UnionOperation" then
            for _, keyword in ipairs(DOOR_NAMES) do
                if string.find(descendant.Name, keyword) then
                    local addr = descendant.Address
                    if remove then
                        -- Save original state
                        if not removed_doors[addr] then
                            removed_doors[addr] = {
                                part = descendant,
                                transparency = descendant.Transparency,
                                canCollide = descendant.CanCollide
                            }
                        end
                        set_door_state(descendant, true)
                    else
                        -- Restore
                        if removed_doors[addr] then
                            descendant.Transparency = removed_doors[addr].transparency
                            descendant.CanCollide = removed_doors[addr].canCollide
                            removed_doors[addr] = nil
                        end
                    end
                    break
                end
            end
        end
    end
end

-- Slow update to respect the checkbox
cheat.register("onSlowUpdate", function()
    local enabled = ui.getValue(TAB, CONT, "Remove Doors")
    find_and_toggle_doors(enabled)
end)

print("[Prison Life] Remove Doors loaded.")
