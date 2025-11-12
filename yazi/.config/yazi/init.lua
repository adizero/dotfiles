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

-- Status:children_add(function()
--     local h = cx.active.current.hovered
--     if not h then
--         return nil
--     end
--     return ui.Line({
--         ui.Span(os.date(_, tostring(h.cha.mtime):sub(1, 10))):fg("blue"),
--         ui.Span(" "),
--     })
-- end, 500, Status.RIGHT)

Status:children_add(function()
    local h = cx.active.current.hovered
    local elements = {}

    -- possible addition/alternative would be to show also birth time (h.cha.btime)
    local mtime_formatted = nil
    if h and h.cha and h.cha.mtime then
        local timestamp_num = tonumber(h.cha.mtime)
        if timestamp_num and timestamp_num > 0 then
            mtime_formatted = os.date("%Y-%m-%d %H:%M", math.floor(timestamp_num))
        end
    end

    if mtime_formatted then
        -- table.insert(elements, ui.Span("M:"):fg("cyan"))
        table.insert(elements, ui.Span(mtime_formatted.. " "):fg("blue"))
    end

    return ui.Line(elements)
end, 500, Status.RIGHT)
