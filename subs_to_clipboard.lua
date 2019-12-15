--- ___Usage___:
--- toggle-copy-subs: Automatically copy subtitles to clipboard as they appear
---                    input.conf example:
---                     * script-message-to subs-to-clipboard toggle-subs-to-clipboard

_G.autocopysubs = false

function escape(s)
  return (s:gsub('\'', '\'\\\'\''))
end

function copy_sub(prop, subtext)
    if subtext and subtext ~= '' then
        os.execute("export LANG=en_US.UTF-8; echo '" .. escape(subtext) .. "' | pbcopy")
    end
end


function stop_auto_copy_subs()
    mp.osd_message("Auto-copy subs disabled", 1)
    mp.unobserve_property(copy_sub)

    _G.autocopysubs = false
end

function toggle_subs_to_clipboard()
    if _G.autocopysubs then
        stop_auto_copy_subs()
        return
    end

    mp.osd_message("Auto-copy subs enabled", 1)
    mp.observe_property("sub-text", "string", copy_sub)

    _G.autocopysubs = true
end

mp.add_key_binding(nil, "toggle-subs-to-clipboard", toggle_subs_to_clipboard)