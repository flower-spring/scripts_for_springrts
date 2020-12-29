function widget:GetInfo()
    return {
        name = "Ctrl+x select all units visibles of prev selection",
        desc = "Select all units visibles with same unitDefID of previous selection, with ctr+x",
        author = "flower",
        date = "29 dec 2020",
        license = "",
        layer = 292020,
        enabled = true --  loaded by default?
    }
end

local spGetAllUnits = Spring.GetAllUnits
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetUnitDefID = Spring.GetUnitDefID
local spSelectUnitArray = Spring.SelectUnitArray
local spGetVisibleUnits = Spring.GetVisibleUnits
local spGetGameSeconds = Spring.GetGameSeconds
local frameAtGameStart = { "true" }
local spSendCommands = Spring.SendCommands

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
        local all_units = spGetAllUnits()
        local visible_units = spGetVisibleUnits()
        local selected_unitID = spGetSelectedUnits()
        local team_selected = {}
        if selected_unitID[1] ~= nil and (visible_units[1] == nil) then
            for k, v in pairs(selected_unitID) do
                team_selected[k] = v
            end
            spSelectUnitArray(team_selected)
        else
            for k, unitID in pairs(visible_units) do
                local unitDefID_of_each_unit = spGetUnitDefID(unitID)
                for _, unitIDselected in pairs(selected_unitID) do
                    local unitDefID_units_selected = spGetUnitDefID(unitIDselected)
                    if unitDefID_of_each_unit == unitDefID_units_selected then
                        team_selected[k] = unitID
                    end
                end
            end
            spSelectUnitArray(team_selected)
        end
    end
end