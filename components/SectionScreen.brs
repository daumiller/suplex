function OnKeyEvent(key, press)
    if(press = false)    then return false
    if(key <> "options") then return false
    m.top.optionsKey = not m.top.optionsKey
    return true
end function
