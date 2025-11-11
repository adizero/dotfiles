function Linemode:size_and_mtime()
    local time = math.floor(self._file.cha.mtime or 0)
    if time == 0 then
        time = ""
    elseif os.date("%Y", time) == os.date("%Y") then
        time = os.date("%b %d %H:%M", time)
    else
        time = os.date("%b %d  %Y", time)
    end

    local size = self._file:size()
    return string.format("%s %s", size and ya.readable_size(size) or "-", time)
end

Status:children_add(function()
    local h = cx.active.current.hovered
    return ui.Line({
        ui.Span(os.date(_, tostring(h.cha.mtime):sub(1, 10))):fg("blue"),
        ui.Span(" "),
    })
end, 500, Status.RIGHT)
