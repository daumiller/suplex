function StringHasContent(str)
    if(str = invalid) then return false
    if(str.Len() = 0) then return false
    return true
end function

function StringOrBlank(str)
    if(str = invalid) then return ""
    return str
end function

sub Main()
    home_screen = HomeScreen_Create()
    home_screen.scene.SetFocus(true)

    plex_server = PlexServer_Default(home_screen.scene, 5000)
    if(plex_server = invalid) then
        Print("No Plex server found...")
    else
        Print("Using Default Server: " + PlexServer_SerializeServer(plex_server))
    end if
    GetGlobalAA().plex_server = plex_server

    home_screen.Populate()
    home_screen.Loop()
end sub
