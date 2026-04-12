-- ============================================
--  PrisonLifeWare v2
--  github.com/loXxiyt/PrisonLifeWare
-- ============================================

local TAB  = "PLWare"
local MISC = "Misc"
local DOOR = "Doors"

-- Setup UI
ui.newTab(TAB, "PrisonLifeWare")
ui.NewContainer(TAB, DOOR, "Doors",  { autosize = true, next = true })
ui.NewContainer(TAB, MISC, "Misc",   { autosize = true })

-- ============================================
--  REMOVE DOORS
-- ============================================

ui.NewCheckbox(TAB, DOOR, "Remove Doors")

local DOOR_NAMES = {
    gate    = true,
    a_door  = true,
    b_door  = true,
    hitbox  = true,
}

local saved_doors = {}

local function toggle_doors(remove)
    for _, desc in ipairs(game.Workspace:GetDescendants()) do
        local cn = desc.ClassName
        if cn == "Part" or cn == "UnionOperation" or cn == "Union" then
            if DOOR_NAMES[desc.Name] then
                local addr = tostring(desc.Address)
                if remove then
                    if not saved_doors[addr] then
                        saved_doors[addr] = {
                            part         = desc,
                            transparency = desc.Transparency,
                            canCollide   = desc.CanCollide,
                        }
                    end
                    desc.Transparency = 1
                    desc.CanCollide   = false
                else
                    if saved_doors[addr] then
                        desc.Transparency = saved_doors[addr].transparency
                        desc.CanCollide   = saved_doors[addr].canCollide
                        saved_doors[addr] = nil
                    end
                end
            end
        end
    end
end

cheat.register("onSlowUpdate", function()
    local enabled = ui.getValue(TAB, DOOR, "Remove Doors")
    toggle_doors(enabled)
end)

-- ============================================

print("[PrisonLifeWare] Loaded successfully!")
