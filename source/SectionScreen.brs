' Section: http://192.168.0.2:32400/library/sections/6
' Series:  http://192.168.0.2:32400/library/metadata/26640/children
' Season:  http://192.168.0.2:32400/library/metadata/26655/children
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
    section_screen.Populate                 = SectionScreen_Populate
    section_screen._PosterGrid_ItemSelected = SectionScreen_PosterGrid_ItemSelected
    section_screen._PressedKey              = SectionScreen_PressedKey

    section_screen.media_container = PlexServer_LoadLibrary_MediaContainer(plex_server, key)

    if(section_screen.media_container.view = "secondary")
        ' only MediaContainers.viewGroup="secondary" we should be loading here are root Library Sections
        section_screen.section_type    = "section"
        section_screen.view_container  = section_screen.media_container
        section_screen.view_index      = -1
        section_screen.media_container = invalid

        all_key_match = key + "/all"
        view_items = section_screen.view_container.media
        for index=0 to (view_items.Count() - 1) step 1
            view_items[index].index = index ' store an 'index' attribute (TODO: where is this used?)
            if(view_items[index].key = all_key_match) then
                section_screen.view_index = index
                section_screen.media_container = PlexServer_LoadLibrary_MediaContainer(plex_server, view_items[index].key)
            end if
        end for
        if(section_screen.view_index = -1) then
            Print("ERROR: SectionScreen_Create() -- Couldn't find 'all' view for section '" + title + "' (" + key + ")")
            stop
        end if
    elseif(section_screen.media_container.view = "season") then
        section_screen.section_type = "season"
    elseif(section_screen.media_container.view = "episode") then
        ' set special PosterGrid layout for episdodes wide view
        section_screen.section_type = "episode"
        section_screen.poster_grid.basePosterSize   = [240, 128]
        section_screen.poster_grid.loadingBitmapUri = "pkg:/image/loading-wide.png"
        section_screen.poster_grid.numColumns       = 4
        section_screen.poster_grid.numRows          = 4
        section_screen.poster_grid.itemSpacing      = [64,32]
        section_screen.poster_grid.translation      = [64,72]
    else
        Print("ERROR: SectionScreen_Create() -- Unknown view group type '" + section_screen.media_container.view + "' for '" + title + "' (" + key + ")")
        stop
    end if

    section_screen.Populate()

    section_screen.poster_grid.ObserveField("itemSelected", section_screen.queue)
    section_screen.scene.ObserveField("pressedKey", section_screen.queue)
    return section_screen
end function

sub SectionScreen_PressedKey()
    Print("Pressed Key: " + m.scene.pressedKey)
end sub

sub SectionScreen_Populate()
    plex_server = GetGlobalAA().plex_server
    
    content_container = CreateObject("roSGNode", "ContentNode")
    poster_dimensions = m.poster_grid.basePosterSize

    ' TODO: s/loading/missing/
    missing_poster = "pkg:/image/loading-tall.png"
    if(m.section_type = "episode") then missing_poster = "pkg:/image/loading-wide.png"

    ' Section split (ex: viewing all episodes of a series split into season sections)
    section_split = true
    section_parents = {}
    for each media_item in m.media_container.media
        if(StringHasContent(media_item.parentKey) = false) then
            section_split = false
            exit for
        end if
        if(section_parents.DoesExist(media_item.parentKey) = false) then
            parent_data = PlexServer_LoadLibrary_MediaContainer(plex_server, media_item.parentKey)
            if((parent_data = invalid) or (parent_data.media = invalid) or (parent_data.media.Count() < 1)) then
                Print("ERROR: SectionScreen_Populate - Couldn't find parentKey '" + media_item.parentKey + "'")
                section_split = false
                exit for
            end if
            section_parents[media_item.parentKey] = parent_data.media[0].title
        end if
    end for
    if(section_split = false) then section_parents = {} ' free AA
    section_key  = invalid
    section_node = invalid

    for each media_item in m.media_container.media
        content_item = CreateObject("roSGNode", "ContentNode")

        use_thumb = invalid
        ' For section screen, we prefer episode thumb, but will pull a season or series if needed

        if(StringHasContent(media_item["grandparentThumb"])) then use_thumb = media_item["grandparentThumb"]
        if(StringHasContent(media_item["parentThumb"     ])) then use_thumb = media_item["parentThumb"     ]
        if(StringHasContent(media_item["thumb"           ])) then use_thumb = media_item["thumb"           ]
        if(StringHasContent(use_thumb) = false) then use_thumb = m.media_container.thumb
        if(StringHasContent(use_thumb) = false) then
            use_thumb = missing_poster
        else
            use_thumb = PlexServer_TranscodeImage(plex_server, use_thumb, poster_dimensions[0], poster_dimensions[1])
        end if

        content_item.SetFields({
            ' https://sdkdocs.roku.com/display/sdkdoc/PosterGrid#PosterGrid-DataBindings
            "HDGridPosterUrl"      : use_thumb,
            "ShortDescriptionLine1": media_item["title"],
            "Description"          : media_item["key"],
        })

        if(section_split = false) then
            content_container.AppendChild(content_item)
        else
            if(section_key = media_item["parentKey"]) then
                section_node.AppendChild(content_item)
            else
                section_key = media_item["parentKey"]
                if(section_node <> invalid) then content_container.AppendChild(section_node)
                section_node = CreateObject("roSGNode", "ContentNode")
                section_node.SetFields({
                    "ContentType": "SECTION",
                    "Title"      : section_parents[section_key]
                })
                section_node.AppendChild(content_item)
            end if
        end if
    end for

    if((section_split = true) and (section_node <> invalid)) then
        content_container.AppendChild(section_node)
    end if

    m.poster_grid.content = content_container
    m.poster_grid.SetFocus(true)
end sub

sub SectionScreen_PosterGrid_ItemSelected()
    index = m.poster_grid.itemSelected
    if(index < 0) then return

    media_item = m.media_container.media[index]
    Print("SELECTED: " + StringOrBlank(media_item["type"]) +","+ StringOrBlank(media_item["subtype"]) +","+ StringOrBlank(media_item["key"]) +","+ StringOrBlank(media_item["title"]) )
    if(media_item["type"] = "Directory") then
        child_screen = SectionScreen_Create(media_item["key"], media_item["title"])
        child_screen.Loop()
    elseif(media_item["type"] = "Video") then
        PlaybackScreen_Create(media_item["key"])
    end if
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
                if(message_field = "pressedKey") then m._PressedKey()
            elseif(message_node = "posterGrid") then
                if(message_field = "itemSelected") then m._PosterGrid_ItemSelected()
            end if
        end if
    end while
end sub
