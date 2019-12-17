--- ___Usage___:
--- toggle-dialogue-only-mode: Auto-seek to only play subtitled dialogue.
---                             External srt subs required.
---                             Fiddling with sub delay while toggled on desyncs subidx.

_G.dialogueonlymode = false
_G.subsvidpath = false
_G.substarts = {}
_G.subidx = 1

_G.startpadding = 0.1 -- seconds
_G.endpadding = 0.1 -- seconds
_G.noskipthresh = _G.startpadding + _G.endpadding + 0.1

_G.abloopavoidjankpause = false

function to_seconds(timestamp)
    local hour, min, sec, msec = timestamp:match("(%d%d):(%d%d):(%d%d),(%d%d%d)")
    return hour * 3600 + min * 60 + sec + msec / 1000
end

function extract_substarts(subfile)
    local contents = subfile:read("*all")
    contents = contents:gsub("\r\n", "\n")

    for substart, subend, subtext in contents:gmatch("(%d%d:%d%d:%d%d,%d%d%d) %-%-> (%d%d:%d%d:%d%d,%d%d%d)\n(.-)\n\n") do
        table.insert(_G.substarts, to_seconds(substart))
    end
    
end

function load_subs()
    if _G.subsvidpath and _G.subsvidpath == mp.get_property("path") then return true end
    
    local video_path = mp.get_property("path")
    local sub_path = video_path:match("^(.+)%..+$") .. ".srt"

    local subfile = io.open(sub_path, "r")
    if not subfile then
        return false
    end
    extract_substarts(subfile)
    subfile:close()

    _G.subsvidpath = mp.get_property("path")
    return true
end

function seek_on_sub_end(prop, subtext)
    if subtext and subtext == '' then
        local suboffset = mp.get_property("sub-delay")
        local relativepos = mp.get_property_number("time-pos") - suboffset

        while _G.subidx < #_G.substarts and _G.substarts[_G.subidx] < relativepos do
          _G.subidx  = _G.subidx + 1
        end

        substart = _G.substarts[_G.subidx]
        if substart - relativepos > _G.noskipthresh then
            os.execute("sleep " .. _G.endpadding)
            _G.seeking = true
            mp.set_property_number("time-pos", _G.substarts[_G.subidx] + suboffset - _G.startpadding)
            mp.add_timeout(0.1, reset_seeking_state) -- For race condition w/ seek events
        end
    end
end

function reset_seeking_state()
    _G.seeking = false
end

function stop_dialogue_only_mode()
    if _G.abloopavoidjankpause == true then
        _G.abloopavoidjankpause = false
        return
    end
    if not _G.seeking then
        mp.osd_message("End dialogue-only mode", 1)

        _G.subidx = 1
        mp.unobserve_property(seek_on_sub_end)
        mp.unregister_event(stop_dialogue_only_mode)
        mp.unobserve_property(stop_dialogue_only_mode)

        _G.dialogueonlymode = false
    end
end

function toggle_dialogue_only_mode(unused1, unused2)
    if _G.dialogueonlymode then
        stop_dialogue_only_mode()
        return
    end

    if not load_subs() then
        mp.osd_message("No subs found", 3)
        return
    end

    mp.osd_message("Dialogue-only mode", 9999)
    mp.observe_property("sub-text", "string", seek_on_sub_end)
    mp.register_event("seek", stop_dialogue_only_mode)

    mp.set_property("ab-loop-a", "no")
    mp.set_property("ab-loop-b", "no")
    _G.abloopavoidjankpause = true
    mp.observe_property("ab-loop-b", number, stop_dialogue_only_mode)

    _G.dialogueonlymode = true
end

mp.add_key_binding(nil, "toggle-dialogue-only-mode", toggle_dialogue_only_mode)