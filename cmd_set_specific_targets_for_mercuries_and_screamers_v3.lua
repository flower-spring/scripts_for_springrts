function widget:GetInfo()
    return {
        name = "Set specific targets for mercuries and screamers",
        desc = "Set target to only some planes for mercuries and screamers, by order: 1.liche/krows, 2.bombers/seabombers, torpedo bombers, 3.radarst2planes 4.brawlers, 5.planes constructors",
        author = "Silver, at least",
        version = "v3",
        date = "?, and at least 2020",
        license = "Probably GNU GPL, v2 or later, at the beginning",
        layer = 4588,
        enabled = true,
    }
end

---For disable some targets for screamers and mercuries, you could just comment the line(s) with the unit name you want disable: for example to prevent t2 arm builder from being targeted, change the line "[UnitDefNames.armaca.id] = 5, -- t2 arm builder" to "--[UnitDefNames.armaca.id] = 5, -- t2 arm builder" (just add "--").

--- v3 version : if stockpile == 5/5, screamer and/or mercury is (are) on "fire at will". Widget impact screamer/mercury only if projectile stockpile of the screamer/mercury is < 5.

local GetUnitPosition = Spring.GetUnitPosition
local GetUnitDefID = Spring.GetUnitDefID
local GetMyPlayerID = Spring.GetMyPlayerID
local GetPlayerInfo = Spring.GetPlayerInfo
local GetUnitSeparation = Spring.GetUnitSeparation
local GiveOrderToUnit = Spring.GiveOrderToUnit
local ENEMY_UNITS = Spring.ENEMY_UNITS
local GetUnitsInSphere = Spring.GetUnitsInSphere
local spGetTeamUnits = Spring.GetTeamUnits
local CMD_UNIT_SET_TARGET = 34923
local spGetUnitStockpile = Spring.GetUnitStockpile
local weaponsTable
local enemiesTable
local screamerMaxWeaponRange
local mercuryMaxWeaponRange

local ba10 = (string.find(Game.gameVersion, '10'))
local ba_test = (string.find(Game.gameVersion, 'test'))
if ba10 or ba_test then
    -- ba 10.24 or 10* or test/byar--
    weaponsTable = {
        [UnitDefNames.corscreamer.id] = true,
        [UnitDefNames.armmercury.id] = true,
    }
    enemiesTable = {
        --arm
        [UnitDefNames.armliche.id] = 1, -- t2 arm liche atomic bomber
        [UnitDefNames.armpnix.id] = 2, -- t2 arm bomber
        [UnitDefNames.armsb.id] = 2, -- seaplane arm bomber
        [UnitDefNames.armlance.id] = 2, --t2 seatorpedo arm plane
        [UnitDefNames.armawac.id] = 3, -- t2 arm radar
        [UnitDefNames.armsehak.id] = 3, -- seaplane radar
        [UnitDefNames.armbrawl.id] = 4, -- t2 arm brawler gunship
        [UnitDefNames.armthund.id] = 4, -- t1 arm bomber
        [UnitDefNames.armblade.id] = 4, -- t2 arm blade gunship
        [UnitDefNames.armstil.id] = 4, -- t2 arm EMP bomber
        [UnitDefNames.armsaber.id] = 4, -- seaplane arm brawler
        [UnitDefNames.armaca.id] = 5, -- t2 arm builder
        [UnitDefNames.armca.id] = 5, -- t1 arm builder
        [UnitDefNames.armcsa.id] = 5, -- sea builder
        [UnitDefNames.armatlas.id] = 5, -- t1 trans
        [UnitDefNames.armdfly.id] = 5, -- t2 trans

        --core
        [UnitDefNames.corcrw.id] = 1, -- t2 core krow
        [UnitDefNames.corhurc.id] = 2, -- t2 core bomber
        [UnitDefNames.corsb.id] = 2, -- seaplane core bomber
        [UnitDefNames.cortitan.id] = 2, --t2 seatorpedo plane
        [UnitDefNames.corawac.id] = 3, -- t2 core radar
        [UnitDefNames.corhunt.id] = 3, -- radar seaplane
        [UnitDefNames.corape.id] = 4, -- t2 core gunship
        [UnitDefNames.corshad.id] = 4, -- t1 core bomber
        [UnitDefNames.corcut.id] = 4, -- seaplane core brawler
        [UnitDefNames.coraca.id] = 5, -- t2 builder
        [UnitDefNames.corca.id] = 5, -- t1 builder
        [UnitDefNames.corcsa.id] = 5, -- t1 sea builder
        [UnitDefNames.corvalk.id] = 5, -- t1 trans
        [UnitDefNames.corseah.id] = 5, -- t2 trans

    }
    screamerMaxWeaponRange = UnitDefNames.corscreamer.maxWeaponRange
    mercuryMaxWeaponRange = UnitDefNames.armmercury.maxWeaponRange

else
    -- ba 9.*--
    weaponsTable = {
        [UnitDefNames.screamer.id] = true,
        [UnitDefNames.mercury.id] = true
    }
    enemiesTable = {
        --arm
        [UnitDefNames.armcybr.id] = 1, -- t2 arm liche atomic bomber
        [UnitDefNames.armpnix.id] = 2, -- t2 arm bomber
        [UnitDefNames.armsb.id] = 2, -- seaplane arm bomber
        [UnitDefNames.armlance.id] = 2, --t2 seatorpedo arm plane
        [UnitDefNames.armawac.id] = 3, -- t2 arm radar
        [UnitDefNames.armsehak.id] = 3, -- seaplane radar
        [UnitDefNames.armbrawl.id] = 4, -- t2 arm brawler gunship
        [UnitDefNames.armthund.id] = 4, -- t1 arm bomber
        [UnitDefNames.blade.id] = 4, -- t2 arm blade gunship
        [UnitDefNames.corgripn.id] = 4, -- t2 arm EMP bomber
        [UnitDefNames.armsaber.id] = 4, -- seaplane arm brawler
        [UnitDefNames.armaca.id] = 5, -- t2 arm plane builder
        [UnitDefNames.armca.id] = 5, -- t1 arm plane builder
        [UnitDefNames.armcsa.id] = 5, -- sea plane builder
        [UnitDefNames.armatlas.id] = 5, -- t1 trans
        [UnitDefNames.armdfly.id] = 5, -- t2 trans

        --core
        [UnitDefNames.corcrw.id] = 1, -- t2 core krow
        [UnitDefNames.corhurc.id] = 2, -- t2 core bomber
        [UnitDefNames.corsb.id] = 2, -- seaplane core bomber
        [UnitDefNames.cortitan.id] = 2, --t2 seatorpedo plane
        [UnitDefNames.corawac.id] = 3, -- t2 core radar
        [UnitDefNames.corhunt.id] = 3, -- radar seaplane
        [UnitDefNames.corape.id] = 4, -- t2 core gunship
        [UnitDefNames.corshad.id] = 4, -- t1 core bomber
        [UnitDefNames.corcut.id] = 4, -- seaplane core brawler
        [UnitDefNames.coraca.id] = 5, -- t2 plane builder
        [UnitDefNames.corca.id] = 5, -- t1 plane builder
        [UnitDefNames.corcsa.id] = 5, -- sea plane builder
        [UnitDefNames.corvalk.id] = 5, -- t1 trans
        [UnitDefNames.armsl.id] = 5, -- t2 trans

    }
    screamerMaxWeaponRange = UnitDefNames.screamer.maxWeaponRange
    mercuryMaxWeaponRange = UnitDefNames.mercury.maxWeaponRange
end

local WeaponUnitlist = {}
local myPlayerID = GetMyPlayerID()

function widget:Initialize()
    local _, _, spectator = GetPlayerInfo(myPlayerID)
    if spectator then
        widgetHandler:RemoveWidget()
    end
    for k, unitID in pairs(spGetTeamUnits(Spring.GetMyTeamID())) do
        if unitID then
            local unitDefID = GetUnitDefID(unitID)
            local newUnit = { unitID }
            local ba10 = (string.find(Game.gameVersion, '10'))
            local ba_test = (string.find(Game.gameVersion, 'test'))
            if ba10 or ba_test then
                if UnitDefs[unitDefID].name == "corscreamer" or UnitDefs[unitDefID].name == "armmercury" then
                    AddUnitsToList(newUnit, WeaponUnitlist)
                end
            else
                if UnitDefs[unitDefID].name == "screamer" or UnitDefs[unitDefID].name == "mercury" then
                    AddUnitsToList(newUnit, WeaponUnitlist)
                end
            end
        end
    end
end

function widget:GameFrame(f)
    if (f % 10 < 1) then
        checkTargets()
    end
end

function checkTargets()
    local WeaponRange = {}
    local WeaponAirLos = {}
    local Range = {}
    if #WeaponUnitlist > 0 then
        for i = 1, #WeaponUnitlist do
            local WeaponID = WeaponUnitlist[i]
            if WeaponID then
                if spGetUnitStockpile(WeaponID) then
                    if spGetUnitStockpile(WeaponID) < 5 then
                        GiveOrderToUnit(WeaponID, CMD.FIRE_STATE, { 0 }, {})
                    end
                    if spGetUnitStockpile(WeaponID) == 5 then
                        GiveOrderToUnit(WeaponID, CMD.FIRE_STATE, { 2 }, {})
                    end
                end
                local uidid = GetUnitDefID(WeaponID)
                local udefs = UnitDefs[uidid]
                if udefs then
                    if udefs.maxWeaponRange then
                        WeaponRange[i] = udefs.maxWeaponRange or 0
                    end
                    if udefs.airLosRadius then
                        WeaponAirLos[i] = udefs.airLosRadius or 0
                    end
                else
                    WeaponRange[i] = screamerMaxWeaponRange
                    WeaponAirLos[i] = mercuryMaxWeaponRange
                end
                if WeaponRange[i] > WeaponAirLos[i] then
                    Range[i] = WeaponRange[i]
                else
                    Range[i] = WeaponAirLos[i]
                end
                local x, y, z = GetUnitPosition(WeaponID, true, false)
                if x then
                    if Range[i] then
                        local EnemyUnitsInRange = GetUnitsInSphere(x, y, z, Range[i], ENEMY_UNITS)
                        local UnitSeparation_1 = {}
                        local UnitSeparation_2 = {}
                        local UnitSeparation_3 = {}
                        local UnitSeparation_4 = {}
                        local UnitSeparation_5 = {}
                        local j, k, l, m, n = 0, 0, 0, 0, 0
                        for i = 1, #EnemyUnitsInRange do
                            EnemyUnitID = EnemyUnitsInRange[i]
                            EnemyUnitDefID = GetUnitDefID(EnemyUnitID)
                            if enemiesTable[EnemyUnitDefID] == 1 then
                                j = j + 1
                                UnitSeparation_1[j] = { GetUnitSeparation(WeaponID, EnemyUnitID, true), EnemyUnitID, }
                            end
                            if enemiesTable[EnemyUnitDefID] == 2 then
                                k = k + 1
                                UnitSeparation_2[k] = { GetUnitSeparation(WeaponID, EnemyUnitID, true), EnemyUnitID, }
                            end
                            if enemiesTable[EnemyUnitDefID] == 3 then
                                l = l + 1
                                UnitSeparation_3[l] = { GetUnitSeparation(WeaponID, EnemyUnitID, true), EnemyUnitID, }
                            end
                            if enemiesTable[EnemyUnitDefID] == 4 then
                                m = m + 1
                                UnitSeparation_4[m] = { GetUnitSeparation(WeaponID, EnemyUnitID, true), EnemyUnitID, }
                            end
                            if enemiesTable[EnemyUnitDefID] == 5 then
                                n = n + 1
                                UnitSeparation_5[n] = { GetUnitSeparation(WeaponID, EnemyUnitID, true), EnemyUnitID, }
                            end
                        end
                        if #UnitSeparation_1 > 0 then
                            if UnitSeparation_1[1] then
                                table.sort(UnitSeparation_1, compare)
                                EnemyUnitID = UnitSeparation_1[1][2]
                                GiveOrderToUnit(WeaponID, CMD_UNIT_SET_TARGET, { EnemyUnitID }, { "alt" });
                            end
                        elseif #UnitSeparation_2 > 0 then
                            if UnitSeparation_2[1] then
                                table.sort(UnitSeparation_2, compare)
                                EnemyUnitID = UnitSeparation_2[1][2]
                                GiveOrderToUnit(WeaponID, CMD_UNIT_SET_TARGET, { EnemyUnitID }, { "alt" });
                            end
                        elseif #UnitSeparation_3 > 0 then
                            if UnitSeparation_3[1] then
                                table.sort(UnitSeparation_3, compare)
                                EnemyUnitID = UnitSeparation_3[1][2]
                                GiveOrderToUnit(WeaponID, CMD_UNIT_SET_TARGET, { EnemyUnitID }, { "alt" });
                            end
                        elseif #UnitSeparation_4 > 0 then
                            if UnitSeparation_4[1] then
                                table.sort(UnitSeparation_4, compare)
                                EnemyUnitID = UnitSeparation_4[1][2]
                                GiveOrderToUnit(WeaponID, CMD_UNIT_SET_TARGET, { EnemyUnitID }, { "alt" });
                            end
                        elseif #UnitSeparation_5 > 0 then
                            if UnitSeparation_5[1] then
                                table.sort(UnitSeparation_5, compare)
                                EnemyUnitID = UnitSeparation_5[1][2]
                                GiveOrderToUnit(WeaponID, CMD_UNIT_SET_TARGET, { EnemyUnitID }, { "alt" });
                            end
                        end
                    end
                end
            end
        end
    end
end

function compare(a, b)
    if a then
        if b then
            return a[1] < b[1]
        else

        end
    end
end

function AddUnitsToList(UnitsIds, unitlistName)
    for i = 1, #UnitsIds do
        local unitID = UnitsIds[i]
        local unitExist = false
        for o = 1, #unitlistName do
            local uid = unitlistName[o]
            if unitID == uid then
                unitExist = true
            end
        end
        if not unitExist then
            unitlistName[#unitlistName + 1] = unitID
        end
    end
end

function RemoveUnitsFromList(UnitsIds, unitlistName)
    local newUnitList = {}
    for p = 1, #unitlistName do
        local unitID = unitlistName[p]
        local unitExist = false
        for q = 1, #UnitsIds do
            local uid = UnitsIds[q]
            if unitID == uid then
                unitExist = true
            end
        end
        if not unitExist then
            newUnitList[#newUnitList + 1] = unitID
        end
    end
    return newUnitList
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
    if weaponsTable[unitDefID] and unitTeam == Spring.GetMyTeamID() then
        local newUnit = { unitID }
        AddUnitsToList(newUnit, WeaponUnitlist)
    end
end

function widget:UnitGiven(unitID, unitDefID, oldTeam, newTeam)
    if weaponsTable[unitDefID] and newTeam == Spring.GetMyTeamID() then
        local newUnit = { unitID }
        AddUnitsToList(newUnit, WeaponUnitlist)
    end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
    local destrUnit = { unitID }
    if unitTeam == Spring.GetMyTeamID() then
        WeaponUnitlist = RemoveUnitsFromList(destrUnit, WeaponUnitlist)
    end
end