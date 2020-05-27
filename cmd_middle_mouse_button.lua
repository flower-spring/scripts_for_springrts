function widget:GetInfo()
    return {
        name = "Disable middle mouse click above the map",
        desc = "A widget to avoid camera like blocked or super fast, atfer an unmaintained middle click above the map",
        author = "",
        version = "2",
        date = "Published may 2020",
        license = "",
        layer = 90051,
        enabled = true,
    }
end

function widget:MousePress(mx, my, button)
    if (button == 2) and (not Spring.IsAboveMiniMap(mx, my)) then
        return true
    end
    return false
end
