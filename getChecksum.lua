function widget:GetInfo()
    return {
        name      = "get checksum",
        desc      = "",
        author    = "flower",
        date      = "2020",
        license   = "",
        layer     = 0,
        enabled   = true  --  loaded by default?
    }
end

include("keysym.h.lua")

function widget:KeyPress(key, modifier, isRepeat)
    if (key == KEYSYMS.K) and (not modifier.ctrl) then
        local name = Game.gameName
        local archives = VFS.GetAllArchives()
        for k,v in pairs(archives) do
            if k==1 then
                local _,archiveChecksum  = VFS.GetArchiveChecksum(v)
                ("---------------------archiveChecksum for archive " .. archives[k]..": ".. archiveChecksum.."----")
            end
        end
    end
end
