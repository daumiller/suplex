'===================================================================================================================================
''' section SETUP
'===================================================================================================================================
''' function SectionScreen_Create(key, title)
''' return          section_screen assocarray, or invalid on error (check return value)
''' parameter=key   key of section to load
''' parameter=title title of section to load, set to title bar
''' description     create and show section screen
function SectionScreen_Create(key, title)
    this = {
        "screen"                  : CreateObject("roSGScreen"),
        "queue"                   : GlobalLoop().queue,
        "title"                   : title,
        "Handle_Message"          : SectionScreen_Handle_Message,
        "_Populate"               : SectionScreen_Populate,
        "_PressedKey"             : SectionScreen_PressedKey,
        "_PosterGrid_ItemSelected": SectionScreen_PosterGrid_ItemSelected
    }

    this["scene"] = this.screen.CreateScene("SectionScreen")
    this.scene.backgroundURI   = Registry_Read("preferences", "background-image", "")
    this.scene.backgroundColor = Registry_Read("preferences", "background-color", "0x1F1F1FFF")
    GlobalLoop().Screen_Push(this)
    this.screen.SetMessagePort(this.queue)
    this.screen.Show()

    this.scene.FindNode("titleBar").title = title
    this["poster_grid"]     = this.scene.FindNode("posterGrid")
    this["media_container"] = Plex_MediaContainer(key)
    if(this.media_container = invalid) then
        ' TODO: show some kind of error dialog
        Print("ERROR: SectionScreen_Create() -- failed loading MediaContainer")
        Print("       for '" + title + "', '" + key + "'")
        this.screen.Close()
        return invalid
    end if

    if(this.media_container.viewGroup = "secondary") then
        ' only "secondary" views we should be loading here are root library sections (currently)
        this["section_type"] = "section"

        all_found = false
        all_match = key + "/all"
        for each child in this.media_container.children
            if(child.key = all_match) then
                all_found = true
                this.media_container = Plex_MediaContainer(child.key)
                exit for
            end if
        end for
        if(not all_found) then
            ' TODO: show some kind of error dialog
            Print("ERROR: SectionScreen_Create() -- failed finding all key for root library section")
            Print("       for '" + title + "', '" + key + "'")
            this.screen.Close()
            return invalid
        end if
    elseif(this.media_container.viewGroup = "season") then
        this["section_type"] = "season"
    elseif(this.media_container.viewGroup = "episode") then
        ' set special poster grid layout for episode wide thumbnails
        this["section_type"] = "episode"
        this.poster_grid.basePosterSize   = [240, 128]
        this.poster_grid.loadingBitmapUri = "pkg:/image/loading-wide.png"
        this.poster_grid.numColumns       = 4
        this.poster_grid.numRows          = 4
        this.poster_grid.itemSpacing      = [64,32]
        this.poster_grid.translation      = [64,72]
    else
        ' TODO: show some kind of error dialog
        Print("ERROR: SectionScreen_Create() -- Unknown viewGroup type '" + this.media_container.viewGroup + "'")
        Print("       for '" + title + "', '" + key + "'")
        this.screen.Close()
        return invalid
    end if

    this._Populate()
    this.poster_grid.ObserveField("itemSelected", this.queue)
    this.scene.ObserveField("pressedKey", this.queue)
    return this
end function

'===================================================================================================================================
''' section LOOP_EVENTS
'===================================================================================================================================
' event: message
function SectionScreen_Handle_Message(message as object) as boolean
    message_type = Type(message)

    if(message_type = "roSGScreenEvent") then
        if(message.IsScreenClosed()) then GlobalLoop().Screen_Pop()
        return true
    elseif(message_type = "roSGNodeEvent") then
        message_node  = message.GetNode()
        message_field = message.GetField()
        if(message_node = "") then
            if(message_field = "pressedKey") then m._PressedKey()
        elseif(message_node = "posterGrid") then
            if(message_field = "itemSelected") then m._PosterGrid_ItemSelected()
        end if
        return true
    end if

    return false
end function

'- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

' event: poster grid item selected
sub SectionScreen_PosterGrid_ItemSelected()
    index = m.poster_grid.itemSelected
    if(index < 0) then return

    child = m.media_container.children[index]
    Print("SELECTED: " + StringOrBlank(child.tagName) +", "+ StringOrBlank(child["type"]) +", "+ StringOrBlank(child.key) +", "+ StringOrBlank(child.title))
    if(child.tagName = "Directory") then
        child_title = child.title
        if(m.media_container.viewGroup = "season") then child_title = m.title + ": " + child.title
        SectionScreen_Create(child.key, child_title)
    elseif(child.tagName = "Video") then
        Print("PlaybackScreen_Create(" + child.key + ")")
    end if
end sub

'- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

' event: unhandled key pressed
sub SectionScreen_PressedKey()
    Print("Pressed Key: " + m.scene.pressedKey)
end sub

'===================================================================================================================================
''' section POPULATION
'===================================================================================================================================
' helper: populate section
sub SectionScreen_Populate()
    content_node = CreateObject("roSGNode", "ContentNode")
    poster_dimensions = m.poster_grid.basePosterSize

    ' TODO: s/loading/missing/
    missing_poster = "pkg:/image/loading-tall.png"
    if(m.section_type = "episode") then missing_poster = "pkg:/image/loading-wide.png"

    ' section split (ex: viewing all episodes of a series split into season sections)
    section_split = true
    section_parents = {}
    for each child in m.media_container.children
        if(not StringHasContent(child.parentKey)) then
            section_split = false
            exit for
        end if
        if(section_parents.DoesExist(child.parentKey) = false) then
            parent_data = Plex_MediaContainer(child.parentKey)
            if((parent_data = invalid) or (parent_data.children.Count() < 1)) then
                Print("ERROR: SectionScreen_Populate() -- Couldn't parse parentKey '" + child.parentKey + "'")
                section_split = false
                exit for
            end if
            section_parents[child.parentKey] = parent_data.children[0].title
        end if
    end for

    if(section_split = false) then section_parents = {} ' free AA
    section_key  = invalid
    section_node = invalid
    image_transcoder = Plex_Path_Transcode_Image_Init(poster_dimensions[0], poster_dimensions[1])

    for each child in m.media_container.children
        child_content = CreateObject("roSGNode", "ContentNode")

        poster_thumb = invalid
        ' for section screen, prefer episode thumb, but pull season or series if needed
        if(StringHasContent(child.grandparentThumb)) then poster_thumb = child.grandparentThumb
        if(StringHasContent(child.parentThumb     )) then poster_thumb = child.parentThumb
        if(StringHasContent(child.thumb           )) then poster_thumb = child.thumb
        if(not StringHasContent(poster_thumb      )) then poster_thumb = m.media_container.thumb
        if(not StringHasContent(poster_thumb)) then
            poster_thumb = missing_poster
        else
            poster_thumb = Plex_Path_Transcode_Image_Next(image_transcoder, poster_thumb)
        end if

        child_content.SetFields({
            ' https://sdkdocs.roku.com/display/sdkdoc/PosterGrid#PosterGrid-DataBindings
            "HDGridPosterUrl"      : poster_thumb,
            "ShortDescriptionLine1": child.title,
            "Description"          : child.key
        })

        if(not section_split) then
            content_node.AppendChild(child_content)
        else
            if(section_key = child.parentKey) then
                section_node.AppendChild(child_content)
            else
                section_key = child.parentKey
                if(section_node <> invalid) then content_node.AppendChild(section_node)
                section_node = CreateObject("roSGNode", "ContentNode")
                section_node.SetFields({
                    "ContentType": "SECTION",
                    "Title"      : section_parents[section_key]
                })
                section_node.AppendChild(child_content)
            end if
        end if
    end for

    if(section_split and (section_node <> invalid)) then
        content_node.AppendChild(section_node)
    end if

    m.poster_grid.content = content_node
    m.poster_grid.SetFocus(true)
end sub
