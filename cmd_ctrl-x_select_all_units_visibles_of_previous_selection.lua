function widget:GetInfo()
    return {
        name = "Ctrl+x select all units visibles same of prev selection",
        desc = "Select all units visibles with same unitDefID of previous selection, with ctr+x",
        author = "flower",
        date = "29 dec 2020",
        license = "",
        layer = 292020,
        enabled = true --  loaded by default?
    }
end

local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetUnitDefID = Spring.GetUnitDefID
local spSelectUnitArray = Spring.SelectUnitArray
local spGetVisibleUnits = Spring.GetVisibleUnits
local spGetGameSeconds = Spring.GetGameSeconds
local frameAtGameStart = { "true" }
local spSendCommands = Spring.SendCommands
local spGetGameFrame = Spring.GetGameFrame

include("keysym.h.lua")

function widget:Initialize()
    spSendCommands('unbindkeyset Any+x')
    spSendCommands('unbindkeyset Ctrl+0x078')
end

function widget:GameStart()
    frameAtGameStart = spGetGameFrame()
end

function widget:GameFrame(frame)
    if (spGetGameSeconds() == 2) and frameAtGameStart then
        spSendCommands('unbindkeyset Any+x')
        spSendCommands('unbindkeyset Ctrl+0x078')
    end
    frameAtGameStart = nil
end

function widget:KeyPress(key, modifier, isRepeat)
    if (key == KEYSYMS.X) and modifier.ctrl then
        local visible_units = spGetVisibleUnits()
        local selected_unitID = spGetSelectedUnits()
        local units_selected = {}
        if selected_unitID[1] ~= nil and (visible_units[1] == nil) then
            for k, v in pairs(selected_unitID) do
                units_selected[k] = v
            end
            spSelectUnitArray(units_selected)
        else
            --at least one unit is visible
            for k, unitID in pairs(visible_units) do
                local unitDefID_of_each_unit = spGetUnitDefID(unitID)
                for _, unitIDselected in pairs(selected_unitID) do
                    local unitDefID_units_selected = spGetUnitDefID(unitIDselected)
                    if unitDefID_of_each_unit == unitDefID_units_selected then
                        units_selected[k] = unitID
                    end
                end
            end
            spSelectUnitArray(units_selected)
        end
    end
end