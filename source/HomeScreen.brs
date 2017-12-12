function HomeScreen_Create(bg_image="", bg_color="0x1F1F1FFF", queue=invalid)
    home_screen = { screen: CreateObject("roSGScreen") }
    home_screen.scene = home_screen.screen.CreateScene("HomeScreen")
    home_screen.scene.backgroundURI   = bg_image
    home_screen.scene.backgroundColor = bg_color
    home_screen.queue = queue
    if(queue = invalid) then home_screen.queue = CreateObject("roMessagePort")

    home_screen.screen.SetMessagePort(home_screen.queue)
    home_screen.screen.Show()

    home_screen.title_bar = home_screen.scene.FindNode("titleBar")
    home_screen.title_bar.title = "Main Menu"

    home_screen.row_list = home_screen.scene.FindNode("rowList")
    home_screen.balloon  = home_screen.scene.FindNode("balloon")

    home_screen.Loop     = HomeScreen_Loop
    home_screen.Populate = HomeScreen_Populate
    home_screen._Populate_LibraryRow  = HomeScreen_Populate_LibraryRow
    home_screen._Populate_Links       = HomeScreen_Populate_Links
    home_screen._AddRowContent        = HomeScreen_AddRowContent
    home_screen._RowList_ItemFocused  = HomeScreen_RowList_ItemFocused
    home_screen._RowList_ItemSelected = HomeScreen_RowList_ItemSelected

    return home_screen
end function

sub HomeScreen_RowList_ItemFocused()
    focus = m.row_list.rowItemFocused
    if((focus[0] = -1) or (focus[1] = -1)) then
        m.balloon.visible = false
        return
    end if

    ' TODO: here be magic numbers, some of these translations seem change if the rowList translation changes???
    if((m.balloon_row = invalid) or (m.balloon_row <> focus[0])) then
        m.balloon_row = focus[0]
        cell_height = m.row_list.rowHeights[m.balloon_row]
        cell_width = m.row_list.rowItemSize[m.balloon_row][0] + m.row_list.rowItemSpacing[0][0]
        m.balloon.translation = [ cell_width+8, cell_height+30 ]
    end if

    cell_width = m.row_list.rowItemSize[m.balloon_row][0] + m.row_list.rowItemSpacing[0][0]
    row_item_count = m.row_list.content.GetChild(focus[0]).GetChildCount()
    row_width = row_item_count * cell_width
    if(row_width < 1280) then
        m.balloon.visible = false ' don't update between moving and changing text
        attach_translation_x = 8 + (cell_width * (focus[1] + 1))
        if(attach_translation_x > 640) then
            m.balloon.attach = "right"
            attach_translation_x = attach_translation_x - (512 + 8) + 12
        else
            m.balloon.attach = "left"
        end if
        m.balloon.translation = [attach_translation_x, m.balloon.translation[1]]
    else
        m.balloon.attach = "left"
    end if
    
    content = m.row_list.content.GetChild(focus[0]).getChild(focus[1])
    m.balloon.text = content.title

    m.balloon.visible = true
end sub

sub HomeScreen_RowList_ItemSelected()
    selection = m.row_list.rowItemSelected
    if((selection[0] = -1) or (selection[1] = -1)) then return
    selected_item = m.row_list.content.GetChild(selection[0]).getChild(selection[1])

    Print("SELECTED: " + selected_item.ShortDescriptionLine1 + ", " + selected_item.ShortDescriptionLine2 + ", " + selected_item.FHDPosterUrl + ", " + selected_item.Title)
    if((selected_item.ShortDescriptionLine1 = "Section") or (selected_item.ShortDescriptionLine1 = "Directory")) then
        if(selected_item.ShortDescriptionLine2 <> "artist") then ' TODO: fix music support
            section_screen = SectionScreen_Create(selected_item.FHDPosterUrl, selected_item.Title)
            section_screen.Loop()
        end if
    elseif(selected_item.ShortDescriptionLine1 = "Video") then
        resume_position = selected_item.BookmarkPosition
        if(resume_position = invalid) then resume_position = 0
        PlaybackScreen_Create(selected_item.FHDPosterUrl, resume_position)
    end if
end sub

sub HomeScreen_Loop()
    while(true)
        msg = Wait(0, m.queue)
        msg_type = Type(msg)
        if(msg_type = "roSGScreenEvent") then
            if(msg.IsScreenClosed()) then return
        elseif(msg.GetNode() = "rowList") then
            field = msg.GetField()
            if(field = "rowItemFocused" ) then m._RowList_ItemFocused()
            if(field = "rowItemSelected") then m._RowList_ItemSelected()
            if(field = "scrollingStatus") then
                if(m.row_list.scrollingStatus) then m.balloon.visible = false
            end if
        end if
    end while
end sub

sub HomeScreen_Populate()
    plex_server = GetGlobalAA().plex_server
    if(plex_server <> invalid) then
        library_container = PlexServer_LoadLibrary_MediaContainer(plex_server, "/library")
        if(library_container <> invalid) then
            library_rows = library_container.media
            if(library_rows <> invalid) then
                for each item in library_rows
                    m._Populate_LibraryRow(item.title, item.key, plex_server)
                end for
            end if
        end if
    end if
    m._Populate_Links()

    m.row_list.SetFocus(true)
    m.row_list.ObserveField("rowItemFocused" , m.queue)
    m.row_list.ObserveField("rowItemSelected", m.queue)
    m.row_list.ObserveField("scrollingStatus", m.queue)
    m._RowList_ItemFocused()
end sub

sub HomeScreen_AddRowContent(content, width=192, height=192, padding_y=64)
    row_heights = CreateObject("roArray", m.row_list.rowHeights.Count() + 1, true)
    row_heights.Append(m.row_list.rowHeights)
    row_heights.Push(height + padding_y)
    m.row_list.rowHeights = row_heights

    row_item_size = CreateObject("roArray", m.row_list.rowItemSize.Count() + 1, true)
    row_item_size.Append(m.row_list.rowItemSize)
    row_item_size.Push([width,height])
    m.row_list.rowItemSize = row_item_size

    if(m.row_list.content = invalid) then m.row_list.content = CreateObject("roSGNode", "ContentNode")
    m.row_list.content.AppendChild(content)
end sub

sub HomeScreen_Populate_LibraryRow(title, key, plex_server)
    parse_container = PlexServer_LoadLibrary_MediaContainer(plex_server, key)
    if(parse_container = invalid) then return
    parsed_items = parse_container.media
    if(parsed_items = invalid) then return

    if(parsed_items.Count() = 0) then
        empty_row = CreateObject("roSGNode", "ContentNode")
        empty_row.SetField("title", title)
        m._AddRowContent(empty_row)
        return
    end if

    row_container = CreateObject("roSGNode", "ContentNode")
    row_container.SetField("title", title)

    row_item_size = [192, 274]
    if(parsed_items[0]["type"] = "Section") then row_item_size = [192, 192]

    for each parsed_item in parsed_items
        ' /---------\
        ' | MAPPING |
        ' \---------/
        '
        ' from PlexServer.brs     -> PlexServer_LoadLibrary_MediaContainer
        ' to   HomeScreenItem.brs -> ItemContentChanged()
        ' fields must map to one of: https://sdkdocs.roku.com/display/sdkdoc/Content+Meta-Data
        '
        ' type            -> ShortDescriptionLine1  :  [ "Section", "Directory", "Video", ... ]
        ' subtype         -> ShortDescriptionLine2  :  [ "movie", "season", "episode", ... ]
        ' key             -> FHDPosterUrl           :  full, server-relative, path to entry
        ' thumb           -> HDPosterUrl            :  full-sized thumbnail url
        ' thumb.sized     -> SDPosterUrl            :  thumbnail resized to row_item_size url
        ' title           -> Title                  :  title
        ' row_item_size.x -> MinBandwidth           :  resized thumbnail width
        ' row_item_size.y -> MaxBandwidth           :  resized thumbnail height
        ' time_current    -> BookmarkPosition       :  current position (on deck items)
        ' time_total      -> Length                 :  total length     (on deck items)
        ' uuid            -> ReleaseDate            :  uuid             (section items)

        row_item = CreateObject("roSGNode", "ContentNode")

        use_thumb = invalid
        ' For home screen, we prefer parentThumb:Season over grandparentThumb:Series over thumb:Episode
        if(StringHasContent(parsed_item["thumb"           ])) then use_thumb = parsed_item["thumb"           ]
        if(StringHasContent(parsed_item["grandparentThumb"])) then use_thumb = parsed_item["grandparentThumb"]
        if(StringHasContent(parsed_item["parentThumb"     ])) then use_thumb = parsed_item["parentThumb"     ]
        if(use_thumb = invalid) then
            use_thumb = "pkg:/image/loading-tall.png" ' TODO: s/loading/missing/
        else
            use_thumb = PlexServer_TranscodeImage(plex_server, use_thumb, row_item_size[0], row_item_size[1])
        end if

        display_title = parsed_item["title"]
        if(StringHasContent(parsed_item["parentTitle"     ])) then display_title = parsed_item["parentTitle"     ] + ": " + display_title
        if(StringHasContent(parsed_item["grandparentTitle"])) then display_title = parsed_item["grandparentTitle"] + ": " + display_title

        row_item.SetFields({
            "ShortDescriptionLine1": parsed_item["type"],
            "ShortDescriptionLine2": parsed_item["subtype"],
            "FHDPosterUrl"         : parsed_item["key"],
            "HDPosterUrl"          : parsed_item["thumb"],
            "SDPosterUrl"          : use_thumb,
            "Title"                : display_title,
            "MinBandwidth"         : row_item_size[0],
            "MaxBandwidth"         : row_item_size[1],
            "BookmarkPosition"     : 0,
            "Length"               : 0
        })

        if(parsed_item.DoesExist("time_current")) then row_item.SetField("BookmarkPosition", parsed_item["time_current"])
        if(parsed_item.DoesExist("time_total"  )) then row_item.SetField("Length"          , parsed_item["time_total"  ])
        if(parsed_item.DoesExist("uuid"        )) then row_item.SetField("ReleaseDate"     , parsed_item["uuid"        ])

        row_container.AppendChild(row_item)
    end for

    m._AddRowContent(row_container, row_item_size[0], row_item_size[1])
end sub

sub HomeScreen_Populate_Links()
    row_container = CreateObject("roSGNode", "ContentNode")
    row_container.SetField("title", "Functions")
    row_item_size = [192, 192]

    link_search = CreateObject("roSGNode", "ContentNode")
    link_search.SetFields({
        "ShortDescriptionLine1": "Link",
        "ShortDescriptionLine2": "search",
        "SDPosterUrl"          : "pkg:/image/link-search.png",
        "Title"                : "Search",
        "MinBandwidth"         : row_item_size[0],
        "MaxBandwidth"         : row_item_size[1],
        "BookmarkPosition"     : 0
    })
    row_container.AppendChild(link_search)

    link_settings = CreateObject("roSGNode", "ContentNode")
    link_settings.SetFields({
        "ShortDescriptionLine1": "Link",
        "ShortDescriptionLine2": "settings",
        "SDPosterUrl"          : "pkg:/image/link-settings.png",
        "Title"                : "Settings",
        "MinBandwidth"         : row_item_size[0],
        "MaxBandwidth"         : row_item_size[1],
        "BookmarkPosition"     : 0
    })
    row_container.AppendChild(link_settings)

    m._AddRowContent(row_container, row_item_size[0], row_item_size[1])
end sub
