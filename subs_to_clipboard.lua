--- ___Usage___:
--- toggle-copy-subs: Automatically copy subtitles to clipboard as they appear. Works on mac 10.13 and windows 10

_G.autocopysubs = false

--- platform detection taken from: github.com/rossy/mpv-repl/blob/master/repl.lua
function detect_platform()
    local o = {}
    if mp.get_property_native('options/vo-mmcss-profile', o) ~= o then
        return 'windows'
    elseif mp.get_property_native('options/cocoa-force-dedicated-gpu', o) ~= o then
        return 'macos'
    end
    return 'linux'
end

_G.platform = detect_platform()
if _G.platform == 'windows' then
    _G.utils = require 'mp.utils'
end
--- end platform detection code

function escape(s)
  return (s:gsub('\'', '\'\\\'\''))
end

function copy_sub(prop, subtext)
    if subtext and subtext ~= '' then
        if _G.platform == 'macos' then
            os.execute("export LANG=en_US.UTF-8; echo '" .. escape(subtext) .. "' | pbcopy")
        elseif _G.platform == 'windows' then
            --windows copy taken from hsyong, github.com/mpv-player/mpv/issues/4695
            local escapedtext = string.gsub(mp.get_property("sub-text"), "'", "")
            local res = _G.utils.subprocess({ args = {
                'powershell', '-NoProfile', '-Command', string.format([[& {
                    Trap {
                        Write-Error -ErrorRecord $_
                        Exit 1
                    }
                    Add-Type -AssemblyName PresentationCore
                    [System.Windows.Clipboard]::SetText('%s')
                }]], escapedtext)
            } })
        end
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