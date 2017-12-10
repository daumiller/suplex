' == SETUP =========================================================================================================================
sub Init()
    m.lblTitle = m.top.FindNode("lblTitle")
    m.lblClock = m.top.FindNode("lblClock")
    m.timer    = m.top.FindNode("timer")

    m.timer.ObserveField("fire", "ChangedTick")
    ChangedTick()
    ChangedClock()
end sub

' == EVENTS ========================================================================================================================
sub ChangedTick()
    m.lblClock.text = CurrentTime()
end sub

sub ChangedTitle()
    m.lblTitle.text = m.top.title
end sub

sub ChangedClock()
    if(m.top.clock = "start") then m.timer.control = "start"
    if(m.top.clock = "stop" ) then m.timer.control = "stop"
end sub

sub ChangedTwelve()
    ChangedTick()
end sub

' == HELPERS =======================================================================================================================
function CurrentTime()
    current_time = CreateObject("roDateTime")
    current_time.ToLocalTime()

    hours   = current_time.GetHours()
    minutes = current_time.GetMinutes()

    suffix = ""
    if(m.top.twelveHour) then
        if(hours >= 12) then
            if(hours > 12) then hours = hours - 12
            suffix = " PM"
        else
            suffix = " AM"
        end if
    end if

    hour_string = hours.ToStr()
    if(hours < 10) then hour_string = " " + hour_string

    minute_string = minutes.toStr()
    if(minutes < 10) then minute_String = "0" + minute_string

    return hour_string + ":" + minute_string + suffix
end function
