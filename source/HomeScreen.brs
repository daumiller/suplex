'===================================================================================================================================
''' section SETUP
'===================================================================================================================================
''' function HomeScreen_Create(bg_image="" as string, bg_color="0x1F1F1FFF" as string) as object
''' return      home_screen assocarray
''' description create and show home screen
function HomeScreen_Create() as object
    this = {
        "screen"               : CreateObject("roSGScreen"),
        "queue"                : CreateObject("roMessagePort"),
        "Populate"             : HomeScreen_Populate,
        "Loop"                 : HomeScreen_Loop,
        "_Populate_Library"    : HomeScreen_Populate_Library,
        "_Populate_Functions"  : HomeScreen_Populate_Functions,
        "_Populate_AddRow"     : HomeScreen_Populate_AddRow,
        "_RowList_ItemFocused" : HomeScreen_RowList_ItemFocused,
        "_RowList_ItemSelected": HomeScreen_RowList_ItemSelected,
        "_RowList_Translate"   : HomeScreen_RowList_Translate
    }

    this["scene"] = this.screen.CreateScene("HomeScreen")
    this.scene.backgroundURI   = Registry_Read("preferences", "background-image", "")
    this.scene.backgroundColor = Registry_Read("preferences", "background-color", "0x1F1F1FFF")
    this.screen.SetMessagePort(this.queue)
    this.screen.Show()

    this.scene.FindNode("titleBar").title = "Main Menu"
    this["row_list"] = this.scene.FindNode("rowList")
    this["balloon"]  = this.scene.FindNode("balloon")

    return this
end function

'===================================================================================================================================
''' section LOOP_EVENTS
'===================================================================================================================================
''' sub HomeScreen_Loop()
''' description run home screen event loop; control will not return from this procedure
sub HomeScreen_Loop()
    while(true)
        message = Wait(0, m.queue)
        message_type = Type(message)

        if(message_type = "roSGScreenEvent") then
            if(message.IsScreenClosed()) then return
        elseif(message_type = "roSGNodeEvent") then
            message_node = message.GetNode()
            if(message_node = "rowList") then
                message_field = message.GetField()
                if(message_field = "rowItemFocused" ) then m._RowList_ItemFocused()
                if(message_field = "rowItemSelected") then m._RowList_ItemSelected()
                if(message_field = "scrollingStatus") then
                    if(m.row_list.scrollingStatus) then m.balloon.visible = false
                end if
            end if
        end if
    end while
end sub

'- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

' event: RowList focused item changes
sub HomeScreen_RowList_ItemFocused()
    indices = m.row_list.rowItemFocused
    focus = m._RowList_Translate(indices[0], indices[1])
    if(focus = invalid) then
        m.balloon.visible = false
        return
    end if

    ' TODO: here be magic numbers, some of these translations seem to change if the rowList translation changes???
    if((m.balloon_row = invalid) or (m.balloon_row <> indices[0])) then
        m.balloon_row = indices[0]
        cell_height = m.row_list.rowHeights[m.balloon_row]
        cell_width  = m.row_list.rowItemSize[m.balloon_row][0] + m.row_list.rowItemSpacing[0][0]
        m.balloon.translation = [ cell_width+8, cell_height+30 ]
    end if

    cell_width = m.row_list.rowItemSize[m.balloon_row][0] + m.row_list.rowItemSpacing[0][0]
    row_item_count = m.row_list.content.GetChild(indices[0]).GetChildCount()
    row_width = row_item_count * cell_width
    if(row_width < 1280) then
        m.balloon.visible = false ' don't update between moving and changing text
        attach_translation_x = 8 + (cell_width * (indices[1] + 1))
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
    
    m.balloon.text = focus.title
    m.balloon.visible = true
end sub

'- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

' event: RowList handled an OK button press while item focused
sub HomeScreen_RowList_ItemSelected()
    selection = m._RowList_Translate(m.row_list.rowItemSelected[0], m.row_list.rowItemSelected[1])
    if(selection = invalid) then return

    Print("SELECTED: " + selection["tagName"] +", "+ selection["type"] +", "+ selection.["key"] +", "+ selection["title"])

    if(selection.tagName = "Directory") then
        if(selection.type <> "artist") then ' TODO: music support
            section_screen = SectionSCreen_Create(selection.key, selection.title)
            section_screen.Loop()
        end if
    elseif(selection.tagName = "Video") then
        if(selection.viewOffset = invalid) then selection.viewOffset = 0
        PlaybackScreen_Create(selection.key, selection.viewOffset)
    end if
end sub

'- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

' helper: translate ContentNode fields to Plex fields (full mapping in HomeScreen_Populate_Library())
function HomeScreen_RowList_Translate(x as integer, y as integer) as object
    if(x = -1) then return invalid
    if(y = -1) then return invalid

    content_node = m.row_list.content.GetChild(x).GetChild(y)
    translation = {
        "tagName"   : content_node.ShortDescriptionLine1,
        "type"      : content_node.ShortDescriptionLine2,
        "key"       : content_node.FHDPosterUrl,
        "title"     : content_node.Title,
        "viewOffset": content_node.BookmarkPosition
    }

    return translation
end function

'===================================================================================================================================
''' section POPULATION
'===================================================================================================================================
''' sub HomeScreen_Populate()
''' description populate home screen items; this is a separate call to allow for the sequence [ HomeScreen.Create, PlexServer.Find, HomeScreen.Populate ]
sub HomeScreen_Populate()
    server = Plex_Server_Current()
    if(server <> invalid) then
        library = Plex_MediaContainer("/library", server)
        if(library <> invalid) then
            for each item in library.children
                m._Populate_Library(StringOrBlank(item.title), item.key, server)
            end for
        end if
    end if

    m._Populate_Functions()

    ' wait to focus and observe until fully populated
    m.row_list.SetFocus(true)
    m.row_list.ObserveField("rowItemFocused" , m.queue)
    m.row_list.ObserveField("rowItemSelected", m.queue)
    m.row_list.ObserveField("scrollingStatus", m.queue)
    m._RowList_ItemFocused() ' initial focus item ([0][0])
end sub

'- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

' helper: add a ContentRow node to RowList, also adjusting RowList fields [ rowHeight, rowItemSize ]
sub HomeScreen_Populate_AddRow(content as object, width=192 as integer, height=192 as integer, padding_y=64 as integer)
    row_heights = CreateObject("roArray", m.row_list.rowHeights.Count()+1, true)
    row_heights.Append(m.row_list.rowHeights)
    row_heights.Push(height + padding_y)
    m.row_list.rowHeights = row_heights

    row_item_size = CreateObject("roArray", m.row_list.rowItemSize.Count()+1, true)
    row_item_size.Append(m.row_list.rowItemSize)
    row_item_size.Push([width,height])
    m.row_list.rowItemSize = row_item_size

    if(m.row_list.content = invalid) then m.row_list.content = CreateObject("roSGNode", "ContentNode")
    m.row_list.content.AppendChild(content)
end sub

'- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

' helper: populate non-library special functions [ Search, Settings ]
sub HomeScreen_Populate_Functions()
    row_container = CreateObject("roSGNode", "ContentNode")
    row_container.SetField("title", "Functions")
    row_item_size = [192, 192]

    func_search = CreateObject("roSGNode", "ContentNode")
    func_search.SetFields({
        "ShortDescriptionLine1": "Function",
        "ShortDescriptionLine2": "search",
        "HDPosterUrl"          : "pkg:/image/link-search.png",
        "Title"                : "Search",
        "MinBandwidth"         : row_item_size[0],
        "MaxBandwidth"         : row_item_size[1],
        "BookmarkPosition"     : 0
    })
    row_container.AppendChild(func_search)

    func_settings = CreateObject("roSGNode", "ContentNode")
    func_settings.SetFields({
        "ShortDescriptionLine1": "Function",
        "ShortDescriptionLine2": "settings",
        "HDPosterUrl"          : "pkg:/image/link-settings.png",
        "Title"                : "Settings",
        "MinBandwidth"         : row_item_size[0],
        "MaxBandwidth"         : row_item_size[1],
        "BookmarkPosition"     : 0
    })
    row_container.AppendChild(func_settings)

    m._Populate_AddRow(row_container, row_item_size[0], row_item_size[1])
end sub

'- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

' helper: add row for a root /library item ([sections, onDeck, recentlyAdded, ...])
sub HomeScreen_Populate_Library(title as string, key as string, server as object)
    media_container = Plex_MediaContainer(key, server)
    if(media_container = invalid) then return

    row_content = CreateObject("roSGNode", "ContentNode")
    row_content.SetField("title", title)

    if(media_container.children.Count() = 0) then
        m._Populate_AddRow(row_content)
        return
    end if

    row_item_size = [192, 274]
    if((key.Len() > 8) and (key.Right(8) = "sections")) then row_item_size = [192, 192]
    image_transcoder = Plex_Path_Transcode_Image_Init(row_item_size[0], row_item_size[1], server)

    for each child in media_container.children
        ' -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
        ' Mapping to HomeScreenItem.brs -> ItemContentChanged()
        ' fields must map to one of: https://sdkdocs.roku.com/display/sdkdoc/Content+Meta-Data
        ' -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
        ' tagName         -> ShortDescriptionLine1  :  [ "Directory", "Video", ... ]
        ' type            -> ShortDescriptionLine2  :  [ "movie", "season", "episode", ... ]
        ' key             -> FHDPosterUrl           :  key
        ' thumb.sized     -> HDPosterUrl            :  thumbnail resized to row_item_size url
        ' title           -> Title                  :  title
        ' row_item_size.x -> MinBandwidth           :  resized thumbnail width
        ' row_item_size.y -> MaxBandwidth           :  resized thumbnail height
        ' viewOffset      -> BookmarkPosition       :  current position (on deck items)
        ' duration        -> Length                 :  total length     (on deck items)

        row_item = CreateObject("roSGNode", "ContentNode")

        use_thumb = invalid
        ' For home screen, we prefer parentThumb/Season over grandparentThumb/Series over thumb/Episode (wide)
        if(StringHasContent(child["thumb"           ])) then use_thumb = child["thumb"           ]
        if(StringHasContent(child["grandparentThumb"])) then use_thumb = child["grandparentThumb"]
        if(StringHasContent(child["parentThumb"     ])) then use_thumb = child["parentThumb"     ]
        if(StringHasContent(use_thumb)) then
            use_thumb = Plex_Path_Transcode_Image_Next(image_transcoder, use_thumb)
        else
            use_thumb = "pkg:/image/loading-tall.png" ' TODO: s/loading/missing/
        end if

        display_title = child["title"]
        if(StringHasContent(child["parentTitle"     ])) then display_title = child["parentTitle"     ] + ": " + display_title
        if(StringHasContent(child["grandparentTitle"])) then display_title = child["grandparentTitle"] + ": " + display_title

        row_item.SetFields({
            "ShortDescriptionLine1": child["tagName"],
            "ShortDescriptionLine2": child["type"],
            "FHDPosterUrl"         : child["key"],
            "HDPosterUrl"          : use_thumb,
            "Title"                : display_title,
            "MinBandwidth"         : row_item_size[0],
            "MaxBandwidth"         : row_item_size[1],
            "BookmarkPosition"     : 0,
            "Length"               : 0
        })

        if(child.DoesExist("viewOffset")) then row_item.SetField("BookmarkPosition", child["viewOffset"])
        if(child.DoesExist("duration"  )) then row_item.SetField("Length"          , child["duration"  ])

        row_content.AppendChild(row_item)
    end for

    m._Populate_AddRow(row_content, row_item_size[0], row_item_size[1])
end sub
