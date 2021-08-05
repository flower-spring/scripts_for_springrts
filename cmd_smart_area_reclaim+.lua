--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    cmd_smart_area_reclaim+.lua
--  brief:   Area reclaims only metal or energy depending on the center feature
--  original author: Ryan Hileman
--
--  Copyright (C) 2010.
--  Public Domain.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
    return {
        name = "Smart Area Reclaim+",
        desc = "Area reclaims only metal or energy depending on the center feature. And only resurrectable or not. With ctrl hold, only non rezzable metal should be sucked",
        author = "aegis, flower. Floris",
        date = "Jun 25, 2010, 2020 and 2021",
        license = "Public Domain",
        layer = 0,
        enabled = true
    }
end

local maxUnits = Game.maxUnits
local GetSelectedUnits = Spring.GetSelectedUnits
local GetUnitDefID = Spring.GetUnitDefID
local GetUnitCommands = Spring.GetUnitCommands
local GetUnitPosition = Spring.GetUnitPosition
local GetFeaturesInRectangle = Spring.GetFeaturesInRectangle
local GetFeaturePosition = Spring.GetFeaturePosition
local GetFeatureRadius = Spring.GetFeatureRadius
local GetFeatureResources = Spring.GetFeatureResources
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetGroundHeight = Spring.GetGroundHeight
local GetFeatureDefID = Spring.GetFeatureDefID

local WorldToScreenCoords = Spring.WorldToScreenCoords
local TraceScreenRay = Spring.TraceScreenRay

local sort = table.sort
local myTeamID = Spring.GetMyTeamID()

local RECLAIM = CMD.RECLAIM
local MOVE = CMD.MOVE
local OPT_SHIFT = CMD.OPT_SHIFT
local ATTACK = CMD.ATTACK

local abs = math.abs
local sqrt = math.sqrt
local atan2 = math.atan2

local constructorsAndNanosOfMyPlayerTableAndNecros = { uDefId = 0, maxWaterDepth = 0, minWaterDepth = 0 }

local featureResurrectable = {}
local featureTooltip = {}
for fDefID, fDef in pairs(FeatureDefs) do
    if fDef.resurrectable then
        featureResurrectable[fDefID] = true
    end
    if fDef.tooltip then
        featureTooltip[fDefID] = fDef.tooltip
    end
end

local isHovercraft = {}
local unitBuildDistance = {}
local unitCanReclaim = {}
local unitCanMove = {}
local unitIsBuilder = {}
local unitIsBuilding = {}
local unitCanResurrect = {}
local unitMaxWaterDepth = {}
local unitMinWaterDepth = {}
for uDefID, uDef in pairs(UnitDefs) do
    if uDef.minWaterDepth then
        unitMinWaterDepth[uDefID] = uDef.minWaterDepth
    end
    if uDef.maxWaterDepth then
        unitMaxWaterDepth[uDefID] = uDef.maxWaterDepth
    end
    if uDef.canResurrect then
        unitCanResurrect[uDefID] = true
    end
    if uDef.isBuilding then
        unitIsBuilding[uDefID] = true
    end
    if uDef.isBuilder then
        unitIsBuilder[uDefID] = true
    end
    if uDef.canReclaim then
        unitCanReclaim[uDefID] = true
    end
    if uDef.canMove then
        unitCanMove[uDefID] = true
    end
    if uDef.buildDistance > 0 then
        unitBuildDistance[uDefID] = uDef.buildDistance
    end
    if uDef["modCategories"]["hover"] and not uDef.isFactory then
        isHovercraft[uDefID] = true
    end
end

function widget:Initialize()
    for k, unitID in pairs(Spring.GetAllUnits()) do
        local unitDefID = Spring.GetUnitDefID(unitID)
        if unitDefID then
            widget:UnitCreated(unitID, unitDefID, myTeamID)
        end
    end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
    if unitTeam == myTeamID then
        if (unitIsBuilder[unitDefID] and not unitIsBuilding[unitDefID]) or unitCanResurrect[unitDefID] then
            constructorsAndNanosOfMyPlayerTableAndNecros[unitID] = { uDefId = unitDefID, maxWaterDepth = unitMaxWaterDepth[unitDefID], minWaterDepth = unitMinWaterDepth[unitDefID] }
        end
    end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
    constructorsAndNanosOfMyPlayerTableAndNecros[unitID] = nil
end

function widget:UnitTaken(unitID, unitDefID, _, newTeam)
    if newTeam == myTeamID then
        widget:UnitCreated(unitID, unitDefID)
    else
        widget:UnitDestroyed(unitID, unitDefID)
    end
end

function widget:UnitGiven(unitID, unitDefID, _, new_team)
    if new_team == myTeamID then
        widget:UnitCreated(unitID, unitDefID, new_team)
    end
end

local function tsp(reclaimersList, tList, dx, dz)
    dx = dx or 0
    dz = dz or 0
    tList = tList or {}

    if reclaimersList == nil then
        return
    end

    local closestDist
    local closestItem
    local closestIndex

    for i = 1, #reclaimersList do
        local item = reclaimersList[i]
        if item ~= nil and item ~= 0 then
            local distx, distz, uid, fid = item[1] - dx, item[2] - dz, item[3], item[4]
            local dist = abs(distx) + abs(distz)
            if closestDist == nil or dist < closestDist then
                closestDist = dist
                closestItem = item
                closestIndex = i
            end
        end
    end

    if closestItem == nil then
        return tList
    end

    tList[#tList + 1] = closestItem
    reclaimersList[closestIndex] = 0
    return tsp(reclaimersList, tList, closestItem[1], closestItem[2])
end

local function stationary(reclaimersList)
    local sList = {}
    local sKeys = {}

    local lastKey, lastItem

    for i = 1, #reclaimersList do
        local item = reclaimersList[i]
        local dx, dz = item[1], item[2]

        local theta = atan2(dx, dz)
        if lastKey ~= theta then
            sKeys[#sKeys + 1] = theta
            lastItem = { item }
            sList[theta] = lastItem
        else
            lastItem[#lastItem + 1] = item
            sList[theta] = lastItem
        end
    end

    local oList = {}
    sort(sKeys)
    for i = 1, #sKeys do
        local theta = sKeys[i]
        local values = sList[theta]
        for j = 1, #values do
            oList[#oList + 1] = values[j]
        end
    end
    return oList
end

local function issue(reclaimersList, shift, groundHeightAtFeaturePos)
    local opts = {}
    for i = 1, #reclaimersList do
        local item = reclaimersList[i]
        local uid, fid = item[3], item[4]
        local groundHeight4 = spGetGroundHeight(item[5], item[6])

        local udefId = GetUnitDefID(uid)
        if udefId and groundHeight4 and constructorsAndNanosOfMyPlayerTableAndNecros[uid] and constructorsAndNanosOfMyPlayerTableAndNecros[uid].maxWaterDepth and constructorsAndNanosOfMyPlayerTableAndNecros[uid].minWaterDepth and (((-(constructorsAndNanosOfMyPlayerTableAndNecros[uid].maxWaterDepth) <= groundHeight4) and (groundHeight4 < abs(constructorsAndNanosOfMyPlayerTableAndNecros[uid].minWaterDepth))) or isHovercraft[udefId]) then
            local opt = {}
            if opts[uid] ~= nil or shift then
                opt = OPT_SHIFT
            end
            spGiveOrderToUnit(uid, RECLAIM, { fid + maxUnits }, opt)
            opts[uid] = 1
        end
    end
end

local function issue2(reclaimersList, shift)
    local opts = {}
    for i = 1, #reclaimersList do
        local item = reclaimersList[i]
        local uid, fid = item[3], item[4]
        local opt = {}
        if opts[uid] ~= nil or shift then
            opt = OPT_SHIFT
        end
        local bpx, bpy, bpz = GetFeaturePosition(fid)
        spGiveOrderToUnit(uid, ATTACK, { bpx + 1, bpy, bpz + 1 }, opt)
        spGiveOrderToUnit(uid, ATTACK, { bpx + 16, bpy + 1, bpz + 16 }, opt)
        opts[uid] = 1
    end
end

include("keysym.h.lua")

function widget:CommandNotify(id, params, options)
    local CtrlOrNot = Spring.GetKeyState(KEYSYMS.LCTRL)
    if id == RECLAIM then
        local mobiles, stationaries = {}, {}
        local mobileBuilder, stationaryBuilder = false, false
        local rezzers = {}
        local selectedUnits = GetSelectedUnits()
        for i = 1, #selectedUnits do
            local selectedUnitsIDs = selectedUnits[i]
            local udid = GetUnitDefID(selectedUnitsIDs)
            if unitCanReclaim[udid] then
                if not unitCanMove[udid] then
                    stationaries[selectedUnitsIDs] = unitBuildDistance[udid]
                    stationaryBuilder = true
                else
                    mobiles[selectedUnitsIDs] = true
                    mobileBuilder = true
                end
                local ux, uy, uz = GetUnitPosition(selectedUnitsIDs)
                if options.shift then
                    local cmds = GetUnitCommands(selectedUnitsIDs, 100)
                    for ci = #cmds, 1, -1 do
                        local cmd = cmds[ci]
                        if cmd.id == MOVE then
                            ux, uy, uz = cmd.params[1], cmd.params[2], cmd.params[3]
                            break
                        end
                    end
                end
                rezzers[#rezzers + 1] = { uid = selectedUnitsIDs, ux = ux, uz = uz }
            end
        end

        if #rezzers > 0 then
            local len = #params
            local ret = {}
            local rmt = {}
            if len == 4 then
                local x, y, z, radius = params[1], params[2], params[3], params[4]
                local xmin, xmax, zmin, zmax = (x - radius), (x + radius), (z - radius), (z + radius)
                local rx, rz = (xmax - xmin), (zmax - zmin)
                local unitsToRezOrSuckInRectangle = GetFeaturesInRectangle(xmin, zmin, xmax, zmax)
                local mouseX, mousey, mousez = WorldToScreenCoords(x, y, z)
                local ct, id = TraceScreenRay(mouseX, mousey)
                if ct == "feature" then
                    local uniqueIDOfWhatShouldBeToReclaim = id
                    local isRessurectable = 2
                    local featureDefuniqueIDOfWhatShouldBeToReclaim = GetFeatureDefID(uniqueIDOfWhatShouldBeToReclaim)
                    local isResurractble = featureResurrectable[featureDefuniqueIDOfWhatShouldBeToReclaim]
                    for i = 1, #unitsToRezOrSuckInRectangle, 1 do
                        local uid = unitsToRezOrSuckInRectangle[i]
                        local ux, _, uz = GetFeaturePosition(uid)
                        local featureRadius = GetFeatureRadius(uid)
                        local urx, urz = abs(ux - x), abs(uz - z)
                        local ud = sqrt((urx * urx) + (urz * urz)) - featureRadius * .5
                        local featureDefID = GetFeatureDefID(unitsToRezOrSuckInRectangle[i])
                        local resurrectable = featureResurrectable[featureDefID]
                        if resurrectable == 0 then
                            isRessurectable = 0
                        else
                            isRessurectable = 1
                        end
                        if ud < radius then
                            local mr, _, er, _, _ = GetFeatureResources(uid)
                            if mr > 0 and isRessurectable == 0 and isResurractble == 0 then
                                rmt[#rmt + 1] = uid
                            elseif mr > 0 and isRessurectable == 1 and isResurractble == -1 then
                                rmt[#rmt + 1] = uid
                            elseif er > 0 then
                                ret[#ret + 1] = uid
                            end
                        end
                    end

                    local mr, _, er, _, _ = GetFeatureResources(uniqueIDOfWhatShouldBeToReclaim)
                    local mList, sList = {}, {}
                    local source = {}
                    if #rmt > 0 and mr > 0 then

                        source = rmt
                    elseif #ret > 0 and er > 0 then
                        source = ret
                    end
                    local fx, fz
                    for i = 1, #source do
                        local fid = source[i]
                        if fid ~= nil then
                            fx, _, fz = GetFeaturePosition(fid)
                            for ui = 1, #rezzers do
                                local unit = rezzers[ui]
                                local uid, ux, uz = unit.uid, unit.ux, unit.uz
                                local dx, dz = ux - fx, uz - fz
                                local item = { dx, dz, uid, fid, fx, fz }
                                if mobiles[uid] then
                                    mList[#mList + 1] = item
                                elseif stationaries[uid] ~= nil then
                                    if sqrt((dx * dx) + (dz * dz)) <= stationaries[uid] then
                                        sList[#sList + 1] = item
                                    end
                                end
                            end
                        end
                    end
                    local issued = false
                    if fx then
                        local groundHeightAtFeaturePos = spGetGroundHeight(fx, fz)
                        if mobileBuilder == true then
                            mList = tsp(mList)
                            issue(mList, options.shift, groundHeightAtFeaturePos)
                            issued = true
                        end
                        if stationaryBuilder == true then
                            sList = stationary(sList)
                            issue(sList, options.shift, groundHeightAtFeaturePos)
                            issued = true
                        end
                    end
                    return issued
                elseif ct == "ground" and CtrlOrNot then
                    local uniqIDOriginalOfWhatShouldBeReclaim = 0
                    local featuresInSphereFromGround = Spring.GetFeaturesInSphere(x, y, z, radius)
                    for k, v in pairs(featuresInSphereFromGround) do
                        local featureDefID = GetFeatureDefID(featuresInSphereFromGround[k])
                        local resurrectable = featureResurrectable[featureDefID]
                        local tooltip = featureTooltip[featureDefID]
                        local wreck_in_tooltip_name = false
                        local heap_in_tooltip_name = false
                        if string.find(tooltip, 'Wreck', nil, true) then
                            wreck_in_tooltip_name = true
                        end
                        if string.find(tooltip, 'Heap', nil, true) then
                            heap_in_tooltip_name = true
                        end
                        if resurrectable == -1 and wreck_in_tooltip_name == false then
                            local mr, _, er, _, _ = GetFeatureResources(v)
                            if mr > 0 then
                                uniqIDOriginalOfWhatShouldBeReclaim = v
                            end
                        end
                        if heap_in_tooltip_name then
                            local mr, _, er, _, _ = GetFeatureResources(v)
                            if mr > 0 then
                                uniqIDOriginalOfWhatShouldBeReclaim = v

                            end
                        end

                    end

                    if uniqIDOriginalOfWhatShouldBeReclaim ~= 0 then
                        local isRessurectable = 2
                        for i = 1, #unitsToRezOrSuckInRectangle, 1 do
                            local uid = unitsToRezOrSuckInRectangle[i]
                            local ux, _, uz = GetFeaturePosition(uid)
                            local featureRadius = GetFeatureRadius(uid)
                            local urx, urz = abs(ux - x), abs(uz - z)
                            local ud = sqrt((urx * urx) + (urz * urz)) - featureRadius * .5
                            local featureDefID = GetFeatureDefID(unitsToRezOrSuckInRectangle[i])
                            local tooltip = featureTooltip[featureDefID]
                            local wreck_in_tooltip_name = false
                            local heap_in_tooltip_name = false
                            if string.find(tooltip, 'Wreck', nil, true) then
                                wreck_in_tooltip_name = true
                            end
                            if string.find(tooltip, 'Heap', nil, true) then
                                heap_in_tooltip_name = true
                            end
                            if featureResurrectable[featureDefID] == 0 then
                                isRessurectable = 0
                            else
                                if wreck_in_tooltip_name then
                                    isRessurectable = 1
                                else
                                    isRessurectable = 0
                                end
                            end
                            if ud < radius then
                                local mr, _, er, _, _ = GetFeatureResources(uid)
                                if mr > 0 and isRessurectable == 0 then
                                    rmt[#rmt + 1] = uid
                                elseif er > 0 then
                                    ret[#ret + 1] = uid
                                end
                            end
                        end

                        local mr, _, er, _, _ = GetFeatureResources(uniqIDOriginalOfWhatShouldBeReclaim)
                        local mList, sList = {}, {}
                        local source = {}
                        if #rmt > 0 and mr > 0 then
                            source = rmt
                        elseif #ret > 0 and er > 0 then
                        end
                        local fx, _, fz
                        for i = 1, #source do
                            local fid = source[i]
                            if fid ~= nil then
                                fx, _, fz = GetFeaturePosition(fid)
                                for ui = 1, #rezzers do
                                    local unit = rezzers[ui]
                                    local uid, ux, uz = unit.uid, unit.ux, unit.uz
                                    local dx, dz = ux - fx, uz - fz
                                    local item = { dx, dz, uid, fid, fx, fz }
                                    if mobiles[uid] then
                                        mList[#mList + 1] = item
                                    elseif stationaries[uid] ~= nil then
                                        if sqrt((dx * dx) + (dz * dz)) <= stationaries[uid] then
                                            sList[#sList + 1] = item
                                        end
                                    end
                                end
                            end
                        end
                        local issued = false
                        if fx then
                            local groundHeightAtFeaturePos = spGetGroundHeight(fx, fz)
                            if mobileBuilder == true then
                                mList = tsp(mList)
                                issue(mList, options.shift, groundHeightAtFeaturePos)
                                issued = true
                            end

                            if stationaryBuilder == true then
                                sList = stationary(sList)
                                issue(sList, options.shift, groundHeightAtFeaturePos)
                                issued = true
                            end
                        end
                        return issued
                    end

                end
            end
        end
    end
    return false
end