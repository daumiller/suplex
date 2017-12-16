'===================================================================================================================================
''' section SETUP
'===================================================================================================================================
function GlobalLoop() as object
    globals = GetGlobalAA()
    if(globals.DoesExist("global-loop")) then return globals["global-loop"]

    this = {
        "queue"        : CreateObject("roMessagePort"),
        "screens"      : CreateObject("roArray", 4, true),
        "timers"       : {},
        "sockets"      : {},
        "servers"      : {}
        "Run"          : GlobalLoop_Run,
        "Screen_Push"  : GlobalLoop_Screen_Push,
        "Screen_Pop"   : GlobalLoop_Screen_Pop,
        "Current_Scene": GlobalLoop_Screen_Current_Scene,
        "Timer_Add"    : GlobalLoop_Timer_Add,
        "Timer_Remove" : GlobalLoop_Timer_Remove,
        "Socket_Add"   : GlobalLoop_Socket_Add,
        "Socket_Remove": GlobalLoop_Socket_Remove,
        "Server_Add"   : GlobalLoop_Server_Add,
        "Server_Remove": GlobalLoop_Server_Remove,
        "_Iterate"     : GlobalLoop_Iterate,
    }

    globals["global-loop"] = this
    return this
end function

'===================================================================================================================================
''' section SCREENS
'===================================================================================================================================
sub GlobalLoop_Screen_Push(screen as object)
    m.screens.Push(screen)
end sub

sub GlobalLoop_Screen_Pop()
    m.screens.Pop()

    screen_top = m.screens.Peek()
    if((screen_top <> invalid) and (screen_top.DoesExist("Reactivated"))) then screen_top.Reactivated()
end sub

function GlobalLoop_Screen_Current_Scene()
    current_screen = m.screens.Peek()
    if(current_screen = invalid) then return invalid
    return current_screen.scene
end function

'===================================================================================================================================
''' section TIMERS
'===================================================================================================================================
sub GlobalLoop_Timer_Add(timer as object)
end sub

function GlobalLoop_Timer_Remove(timer as object) as boolean
end function

'===================================================================================================================================
''' section SOCKETS
'===================================================================================================================================
sub GlobalLoop_Socket_Add(socket as object)
end sub

function GlobalLoop_Socket_Remove(socket as object)
end function

'===================================================================================================================================
''' section SERVERS
'===================================================================================================================================
sub GlobalLoop_Server_Add(server as object)
end sub

function GlobalLoop_Server_Remove(server as object) as boolean
end function

'===================================================================================================================================
''' section EVENT_LOOP
'===================================================================================================================================
sub GlobalLoop_Run()
    if(m.screens.Count() = 0) then
        Print("ERROR: GlobalLoop_Run() -- entered with empty screen stack")
        return
    end if

    timeout_ms = 0
    while(m.screens.Count() > 0)
        timeout_ms = m._Iterate(timeout_ms)
    end while
end sub

function GlobalLoop_Iterate(timeout_ms=0 as integer) as integer
    message = Wait(timeout_ms, m.queue)
    if(message <> invalid) ' if not expired
        processed = false
        if(not processed) then processed = m.screens.Peek().Handle_Message(message)
    end if
end function
