function OnKeyEvent(key, press)
    if(press = false) then return false

    if(key = "play") then
        m.top.pressedKey = "play"
    elseif(key = "replay") then
        m.top.pressedKey = "replay"
    elseif(key = "options") then
        m.top.pressedKey = "options"
    else
        return false
    end if

    return true
end function
