function OnKeyEvent(key, press)
    if(press = false) then return false

    if(key = "play") then
        m.top.pressedKey = "play"
    elseif(key = "replay") then
        m.top.pressedKey = "replay"
    elseif(key = "options") then
        m.top.pressedKey = "options"
    elseif(key = "rewind") then
        m.top.pressedKey = "rewind"
    elseif(key = "fastforward") then
        m.top.pressedKey = "fastforward"
    elseif(key = "left") then
        m.top.pressedKey = "left"
    elseif(key = "right") then
        m.top.pressedKey = "right"
    else
        return false
    end if

    return true
end function
