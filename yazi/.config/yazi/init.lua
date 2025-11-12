-- optional component for the file listing (will show both file size and modification time)
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

-- show user@host in the top header
Header:children_add(function()
    if ya.target_family() ~= "unix" then
        return ""
    end
    return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("blue")
end, 500, Header.LEFT)

-- show symlink targets in the bottom status
Status:children_add(function(self)
	local h = self._current.hovered
	if h and h.link_to then
		return " -> " .. tostring(h.link_to)
	else
		return ""
	end
end, 3300, Status.LEFT)

-- show user:group in the bottom status
Status:children_add(function()
	local h = cx.active.current.hovered
	if not h or ya.target_family() ~= "unix" then
		return ""
	end

	return ui.Line {
		ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
		":",
		ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
		" ",
	}
end, 500, Status.RIGHT)

-- show file modification date in the bottom status
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

-- show file modification date in the bottom status
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
