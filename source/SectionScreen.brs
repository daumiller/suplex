' http://192.168.0.2:32400/library/metadata/493/children
' SectionScreen_Create will handle Sections/Series/Seasons
' set basePosterSize/Rows/Columns based on type (Sections-Tall, Series-Tall, Seasons-Wide)
' MediaContainer.viewGroup = "secondary", -> all -> MediaContainer.viewGroup = "show/movie/..."
' MediaContainer.viewGroup = "season", MediaContainer.viewGroup = "episode"

function SectionScreen_Create(key, title, bg_image="", bg_color="0x1F1F1FFF", queue=invalid)
    plex_server = GetGlobalAA().plex_server
    if(plex_server = invalid) then return invalid

    section_screen = { screen: CreateObject("roSGScreen") }
    section_screen.scene = section_screen.screen.CreateScene("SectionScreen")
    section_screen.scene.backgroundURI   = bg_image
    section_screen.scene.backgroundColor = bg_color
    section_screen.queue = queue
    if(queue = invalid) then section_screen.queue = CreateObject("roMessagePort")

    section_screen.screen.SetMessagePort(section_screen.queue)
    section_screen.screen.Show()

    section_screen.title_bar = section_screen.scene.FindNode("titleBar")
    section_screen.title_bar.title = title

    section_screen.poster_grid = section_screen.scene.FindNode("posterGrid")

    section_screen.Loop                     = SectionScreen_Loop
    section_screen.SetContentView           = SectionScreen_SetContentView
    section_screen._PosterGrid_ItemSelected = SectionScreen_PosterGrid_ItemSelected
    section_screen._OptionsKey              = SectionScreen_OptionsKey

    section_screen.content_views = PlexServer_LoadLibrary_MediaContainer(plex_server, key)
    section_screen.content_view_index = -1
    target_key = key + "/all"
    for index = 0 to (section_screen.content_views.Count() - 1) step 1
        section_screen.content_views[index].index = index
        if(section_screen.content_views[index].key = target_key) then section_screen.content_view_index = index
    end for
    if(section_screen.content_view_index = -1) then
        Print("ERROR: SectionScreen_Create() -- Couldn't find 'all' view for section '" + title + "' (" + key + ")")
        stop
    end if

    section_screen.SetContentView(section_screen.content_view_index)
    section_screen.poster_grid.ObserveField("itemSelected", section_screen.queue)

    section_screen.scene.ObserveField("optionsKey", section_screen.queue)
    return section_screen
end function

function SectionScreen_OptionsKey()
    Print("OPTIONS")
end function

sub SectionScreen_SetContentView(index)
    plex_server = GetGlobalAA().plex_server
    
    m.content_view_index = index
    if(index = -1) then
        m.poster_grid.content = invalid
        return
    end if

    view_meta  = m.content_views[index]
    view_items = PlexServer_LoadLibrary_MediaContainer(plex_server, view_meta.key)
    content_container = CreateObject("roSGNode", "ContentNode")
    poster_dimensions = m.poster_grid.basePosterSize

    for each view_item in view_items
        content_item = CreateObject("roSGNode", "ContentNode")

        content_item.SetFields({
            ' https://sdkdocs.roku.com/display/sdkdoc/PosterGrid#PosterGrid-DataBindings
            "HDPosterUrl"          : view_item["thumb"],
            "HDGridPosterUrl"      : PlexServer_TranscodeImage(plex_server, view_item["thumb"], poster_dimensions[0], poster_dimensions[1]),
            "ShortDescriptionLine1": view_item["title"],
            "Description"          : view_item["key"],
            "Title"                : view_item["type"],
            "TitleSeason"          : view_item["subtype"],
            "BookmarkPosition"     : view_item["time_current"],
            "Length"               : view_item["time_total"]
        })

        content_container.AppendChild(content_item)
    end for

    m.poster_grid.content = content_container
    m.poster_grid.SetFocus(true)
end sub

sub SectionScreen_PosterGrid_ItemSelected()
    index = m.poster_grid.itemSelected
    if(index < 0) then return

    item = m.poster_grid.content.GetChild(index)
    ' type, subtype, key, title
    Print("SELECTED: " + item.Title + ", " + item.TitleSeason + ", " + item.Description + ", " + item.ShortDescriptionLine1)
end sub

sub SectionScreen_Loop()
    while(true)
        message = Wait(0, m.queue)
        message_type = Type(message)
        if(message_type = "roSGScreenEvent") then
            if(message.IsScreenClosed()) then return
        elseif(message_type = "roSGNodeEvent") then
            message_node  = message.GetNode()
            message_field = message.GetField()
            if(message_node = "") then
                if(message_field = "optionsKey") then m._OptionsKey()
            elseif(message_node = "posterGrid") then
                if(message_field = "itemSelected") then m._PosterGrid_ItemSelected()
            end if
        end if
    end while
end sub
