sub Main()
    home_screen = HomeScreen_Create()
    home_screen.scene.SetFocus(true)

    server = PlexServer_Default(home_screen.scene, 5000)
    if(server = invalid) then
        Print("No Plex server found...")
    else
        Print("Using Default Server: " + PlexServer_SerializeServer(server))
    end if

    home_screen.Populate(server)
    home_screen.Loop()
end sub
