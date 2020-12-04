--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unit_smart_area_reclaim+.lua
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
        name = "SmartAreaReclaim+",
        desc = "Area reclaims only metal or energy depending on the center feature. And only resuscitable or not.",
        author = "aegis, flower",
        date = "Jun 25, 2010, 2020",
        license = "Public Domain",
        layer = 0,
        enabled = true
    }
end

-----------------------------------------------------------------
-- manually generated locals because I don't have trepan's script
-----------------------------------------------------------------
local maxUnits = Game.maxUnits
local GetSelectedUnits = Spring.GetSelectedUnits
local GetUnitDefID = Spring.GetUnitDefID
local GetUnitCommands = Spring.GetUnitCommands
local GetUnitPosition = Spring.GetUnitPosition
local GetFeaturesInRectangle = Spring.GetFeaturesInRectangle
local GetFeaturePosition = Spring.GetFeaturePosition
local GetFeatureRadius = Spring.GetFeatureRadius
local GetFeatureResources = Spring.GetFeatureResources
local GiveOrderToUnit = Spring.GiveOrderToUnit

local WorldToScreenCoords = Spring.WorldToScreenCoords
local TraceScreenRay = Spring.TraceScreenRay

local sort = table.sort

local RECLAIM = CMD.RECLAIM
local MOVE = CMD.MOVE
local OPT_SHIFT = CMD.OPT_SHIFT

local abs = math.abs
local sqrt = math.sqrt
local atan2 = math.atan2
-----------------------------------------------------------------
-- end locals----------------------------------------------------
-----------------------------------------------------------------

local function tsp(rList, tList, dx, dz)
    dx = dx or 0
    dz = dz or 0
    tList = tList or {}

    if (rList == nil) then
        return
    end

    local closestDist
    local closestItem
    local closestIndex

    for i = 1, #rList do
        local item = rList[i]
        if (item ~= nil) and (item ~= 0) then
            local distx, distz, uid, fid = item[1] - dx, item[2] - dz, item[3], item[4]
            local dist = abs(distx) + abs(distz)
            if (closestDist == nil) or (dist < closestDist) then
                closestDist = dist
                closestItem = item
                closestIndex = i
            end
        end
    end

    if (closestItem == nil) then
        return tList
    end

    tList[#tList + 1] = closestItem
    rList[closestIndex] = 0
    return tsp(rList, tList, closestItem[1], closestItem[2])
end

local function stationary(rList)
    local sList = {}
    local sKeys = {}

    local lastKey, lastItem

    for i = 1, #rList do
        local item = rList[i]
        local dx, dz = item[1], item[2]

        local theta = atan2(dx, dz)
        if (lastKey ~= theta) then
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

local function issue(rList, shift)
    local opts = {}
    for i = 1, #rList do
        local item = rList[i]
        local uid, fid = item[3], item[4]
        local opt = {}
        if (opts[uid] ~= nil) or (shift) then
            opt = OPT_SHIFT
        end
        GiveOrderToUnit(uid, RECLAIM, { fid + maxUnits }, opt)
        opts[uid] = 1
    end
end

function widget:CommandNotify(id, params, options)
    if (id == RECLAIM) then
        local mobiles, stationaries = {}, {}
        local mobileb, stationaryb = false, false
        local rezzers = {}
        local selectedUnits = GetSelectedUnits()
        for i = 1, #selectedUnits do
            local selectedUnitsIDs = selectedUnits[i]
            local udid = GetUnitDefID(selectedUnitsIDs)
            local unitDef = UnitDefs[udid]
            if (unitDef.canReclaim == true) then
                if (unitDef.canMove == false) then
                    stationaries[selectedUnitsIDs] = unitDef
                    stationaryb = true
                else
                    mobiles[selectedUnitsIDs] = unitDef
                    mobileb = true
                end
                local ux, uy, uz = GetUnitPosition(selectedUnitsIDs)
                if (options.shift) then
                    local cmds = GetUnitCommands(selectedUnitsIDs, 100)
                    for ci = #cmds, 1, -1 do
                        local cmd = cmds[ci]
                        if (cmd.id == MOVE) then
                            ux, uy, uz = cmd.params[1], cmd.params[2], cmd.params[3]
                            break
                        end
                    end
                end
                rezzers[#rezzers + 1] = { uid = selectedUnitsIDs, ux = ux, uz = uz }
            end
        end

        if (#rezzers > 0) then
            local len = #params
            local ret = {}
            local rmt = {}
            if (len == 4) then
                local x, y, z, radius = params[1], params[2], params[3], params[4]
                local xmin, xmax, zmin, zmax = (x - radius), (x + radius), (z - radius), (z + radius)
                local rx, rz = (xmax - xmin), (zmax - zmin)
                local unitsToRezOrSuckInRectangle = GetFeaturesInRectangle(xmin, zmin, xmax, zmax)
                local mouseX, mousey, mousez = WorldToScreenCoords(x, y, z)
                local ct, id = TraceScreenRay(mouseX, mousey)
                if (ct == "feature") then

                    local uniqueIDOfWhatShouldBeToReclaim = id
                    local isRessurectable = 2
                    local featureDefuniqueIDOfWhatShouldBeToReclaim = Spring.GetFeatureDefID(uniqueIDOfWhatShouldBeToReclaim)
                    local isResurractble = FeatureDefs[featureDefuniqueIDOfWhatShouldBeToReclaim].resurrectable

                    for i = 1, #unitsToRezOrSuckInRectangle, 1 do
                        local uid = unitsToRezOrSuckInRectangle[i]
                        local ux, _, uz = GetFeaturePosition(uid)
                        local featureRadius = GetFeatureRadius(uid)
                        local urx, urz = abs(ux - x), abs(uz - z)
                        local ud = sqrt((urx * urx) + (urz * urz)) - featureRadius * .5
                        local featureDefID = Spring.GetFeatureDefID(unitsToRezOrSuckInRectangle[i])
                        local resurrectable = FeatureDefs[featureDefID].resurrectable
                        if resurrectable == 0 then
                            isRessurectable = 0
                        else
                            isRessurectable = 1
                        end
                        if (ud < radius) then
                            local mr, _, er, _, _ = GetFeatureResources(uid)
                            if (mr > 0) and isRessurectable == 0 and isResurractble == 0 then
                                rmt[#rmt + 1] = uid
                            elseif (mr > 0) and isRessurectable == 1 and isResurractble == -1 then
                                rmt[#rmt + 1] = uid
                            elseif (er > 0) then
                                ret[#ret + 1] = uid
                            end
                        end
                    end

                    local mr, _, er, _, _ = GetFeatureResources(uniqueIDOfWhatShouldBeToReclaim)
                    -- if (mr > 0)and(er > 0) then return end
                    local mList, sList = {}, {}
                    local source = {}
                    if (#rmt > 0) and (mr > 0) then
                        source = rmt
                    elseif (#ret > 0) and (er > 0) then
                        source = ret
                    end
                    for i = 1, #source do
                        local fid = source[i]
                        if (fid ~= nil) then
                            local fx, _, fz = GetFeaturePosition(fid)
                            for ui = 1, #rezzers do
                                local unit = rezzers[ui]
                                local uid, ux, uz = unit.uid, unit.ux, unit.uz
                                local dx, dz = ux - fx, uz - fz
                                local dist = dx + dz
                                local item = { dx, dz, uid, fid }
                                if (mobiles[uid] ~= nil) then
                                    mList[#mList + 1] = item
                                elseif (stationaries[uid] ~= nil) then
                                    if (sqrt((dx * dx) + (dz * dz)) <= stationaries[uid].buildDistance) then
                                        sList[#sList + 1] = item
                                    end
                                end
                            end
                        end
                    end

                    local issued = false
                    if (mobileb == true) then
                        mList = tsp(mList)
                        issue(mList, options.shift)
                        issued = true
                    end

                    if (stationaryb == true) then
                        sList = stationary(sList)
                        issue(sList, options.shift)
                        issued = true
                    end

                    return issued
                end
            end
        end
    end
    return false
end
