function widget:GetInfo()
    return {
        name = "Ctrl+x",
        desc = "Select all units visibles with same unitDefID of previous selection, with ctrl+x",
        author = "flower",
        date = "29 dec 2020",
        license = "",
        layer = 292020,
        enabled = true --  loaded by default?
    }
end

local spSendCommands = Spring.SendCommands

function widget:GameStart()
    spSendCommands('bind Ctrl+x select Visible+_InPrevSel+_ClearSelection_SelectAll+')
end
