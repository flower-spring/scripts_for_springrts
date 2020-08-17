--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--  file:    cmd_auto_selfd_the_mines.lua
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
    return {
        name = "Auto self-d the mines except with fast units",
        desc = "Should resolve mines which sometimes didn't explode with BA 9 (from years). This widget give a self-d command for mines when an enemy is near, except if enemy speed > 120, (for example the jeffys or fleas or planes) or except if the mine is put on wait",
        author = "tulipe",
        version = "v1",
        date = "first published 20 july 2020",
        license = "",
        layer = 5448,
        enabled = true
    }
end

local GetUnitDefID = Spring.GetUnitDefID
local mines = {}
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local GetMyTeamID = Spring.GetMyTeamID
local spGetUnitCommands = Spring.GetUnitCommands
local spGetUnitNearestEnemy = Spring.GetUnitNearestEnemy
local spGetUnitSeparation = Spring.GetUnitSeparation
local CMD_SELF_D = CMD.SELFD
local CMD_FIRE_STATE = CMD.FIRE_STATE

function widget:Initialize()
    local allUnits = Spring.GetAllUnits()
    for _, unitID in pairs(allUnits) do
        local uDID = GetUnitDefID(unitID)
        if uDID then
            local name = UnitDefs[uDID].name
            if name == "armmine1" or name == "armmine2" or name == "armmine3" or name == "cormine1" or name == "cormine2" or name == "cormine3" or name == "armfmine3" or name == "corfmine3" or name == "cormine4" then
                mines[unitID] = uDID
            end
        end
    end
end

function widget:UnitCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOpts, cmdTag)
    local name = UnitDefs[unitDefID].name
    if name == "armmine1" or name == "armmine2" or name == "armmine3" or name == "cormine1" or name == "cormine2" or name == "cormine3" or name == "armfmine3" or name == "corfmine3" or name == "cormine4" then
        local uCmds = spGetUnitCommands(unitID, 2)
        if uCmds and (#uCmds == 1) and cmdID == 5 then
            ---mine unwait
            mines[unitID] = unitDefID
        elseif uCmds and (#uCmds == 0) and cmdID == 5 then
            ---mine put on wait
            mines[unitID] = nil
        end
    end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
    local ud = UnitDefs[unitDefID]
    if unitTeam == Spring.GetMyTeamID() and (ud ~= nil and (ud.name == "armmine1" or ud.name == "armmine2" or ud.name == "armmine3" or ud.name == "cormine1" or ud.name == "cormine2" or ud.name == "cormine3" or ud.name == "armfmine3" or ud.name == "corfmine3" or ud.name == "cormine4")) then
        mines[unitID] = unitDefID
        spGiveOrderToUnit(unitID, CMD_FIRE_STATE, { 0 }, {})
    end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
    mines[unitID] = nil
end

function widget:UnitTaken(unitID, unitDefID, old_team, new_team)
    local name = UnitDefs[unitDefID].name
    if (name == "armmine1" or name == "armmine2" or name == "armmine3" or name == "cormine1" or name == "cormine2" or name == "cormine3" or name == "armfmine3" or name == "corfmine3" or name == "cormine4") and new_team == GetMyTeamID() then
        mines[unitID] = unitDefID
    else
        mines[unitID] = nil
    end
end

function widget:GameFrame(frame)
    if ((frame % 10) < 1) then
        for unitID, unitDefID in pairs(mines) do
            local nearestUnitID = spGetUnitNearestEnemy(unitID, 200, false)
            if nearestUnitID then
                local unitDefIDNearestUnit = GetUnitDefID(nearestUnitID)
                if unitDefIDNearestUnit then
                    local getUnitSeparationBetweenMineAndNearestEnemy = spGetUnitSeparation(unitID, nearestUnitID)
                    local enemySpeed = UnitDefs[unitDefIDNearestUnit].speed
                    if enemySpeed and getUnitSeparationBetweenMineAndNearestEnemy < 55 and enemySpeed < 120 and enemySpeed ~= 0 then
                        spGiveOrderToUnit(unitID, CMD_SELF_D, {}, {})
                        mines[unitID] = nil
                    end
                end
            end
        end
    end
end

function widget:GameStart()
    maybeRemoveSelf()
end

function widget:PlayerChanged(playerID)
    maybeRemoveSelf()
end

function maybeRemoveSelf()
    if Spring.GetSpectatingState() then
        widgetHandler:RemoveWidget(self)
    end
end
