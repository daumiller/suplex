'===================================================================================================================================
''' section SETUP
'===================================================================================================================================
''' function VideoScreen_Create(title, key)
''' return          video_screen assocarray, or invalid on error
''' parameter=key   key of video to load
''' description     create and show video screen
function VideoScreen_Create(key, title)
    this = {
        "key"                     : key,
        "screen"                  : CreateObject("roSGScreen"),
        "queue"                   : GlobalLoop().queue,
        "parent"                  : GlobalLoop().screens.Peek(),
        "Populate"                : VideoScreen_Populate,
        "Scroll"                  : VideoScreen_Scroll,
        "Handle_Message"          : VideoScreen_Handle_Message,
        "_PressedKey"             : VideoScreen_PressedKey,
    }

    this["scene"] = this.screen.CreateScene("VideoScreen")
    this.scene.backgroundURI   = Registry_Read("preferences", "background-image", "")
    this.scene.backgroundColor = Registry_Read("preferences", "background-color", "0x1F1F1FFF")
    GlobalLoop().Screen_Push(this)
    this.screen.SetMessagePort(this.queue)
    this.screen.Show()

    this["media_container"] = Plex_MediaContainer(key)
    if((this.media_container = invalid) or (this.media_container.children = invalid) or (this.media_container.children.Count() <> 1) or (this.media_container.children[0].tagName <> "Video")) then
        ' TODO: show some kind of error dialog
        Print("ERROR: VideoScreen_Create() -- failed loading MediaContainer")
        Print("       for '" + key + "'")
        this.screen.Close()
        return invalid
    end if
    this.Populate()

    this.scene.FindNode("titleBar").title = title
    this.scene.FindNode("controls").SetFocus(true)
    this.scene.ObserveField("pressedKey", this.queue)
    return this
end function

'===================================================================================================================================
''' section LOOP_EVENTS
'===================================================================================================================================
' event: message
function VideoScreen_Handle_Message(message as object) as boolean
    message_type = Type(message)

    if(message_type = "roSGScreenEvent") then
        if(message.IsScreenClosed()) then GlobalLoop().Screen_Pop()
        return true
    elseif(message_type = "roSGNodeEvent") then
        message_node  = message.GetNode()
        message_field = message.GetField()
        if(message_node = "") then
            if(message_field = "pressedKey") then m._PressedKey()
        end if
        return true
    end if

    return false
end function

' event: unhandled key pressed
sub VideoScreen_PressedKey()
    key = m.scene.pressedKey
    if(key = "left") then
        m.Scroll(-1)
    elseif(key = "right") then
        m.Scroll(1)
    elseif(key = "rewind") then
        m.Scroll(-12)
    elseif(key = "fastforward") then
        m.Scroll(12)
    else
        Print("Unhandled VideoScreen Key: " + key)
    end if
end sub

function VideoScreen_Scroll(offset as integer) as string
    if(not m.DoesExist("parentScroll")) then m.parentScroll = m.parent.DoesExist("Scroll")
    if(not m.parentScroll) then return m.key
    key = m.parent.Scroll(offset)

    scroll_container = Plex_MediaContainer(key)
    if((scroll_container = invalid) or (scroll_container.children = invalid) or (scroll_container.children.Count() <> 1) or (scroll_container.children[0].tagName <> "Video")) then
        Print("ERROR: VideoScreen_Scroll() -- failed loading scroll sibling '" + key + "'")
        return key
    end if
    m.media_container = scroll_container

    m.Populate()
    return key
end function

'===================================================================================================================================
''' section POPULATION
'===================================================================================================================================
' helper: populate section
sub VideoScreen_Populate()
    video = m.media_container.children[0]

    ' Thumbnail
    thumbnail = video.thumb
    if(not StringHasContent(thumbnail)) then thumbnail = video.parentThumb
    if(not StringHasContent(thumbnail)) then thumbnail = video.grandparentThumb
    if(StringHasContent(thumbnail)) then
        thumbnail = Plex_Path_Transcode_Image(thumbnail, 320, 320)
        m.scene.FindNode("imgThumb").uri = thumbnail
    end if

    ' Title
    title = video.title
    if((not video.DoesExist("viewCount")) or (video.viewCount = "0")) then title = "• " + title
    m.scene.FindNode("lblTitle").text = title

    ' Tagline
    if(video["type"] = "episode") then
        if(video.DoesExist("index") and video.DoesExist("parentIndex")) then
            m.scene.FindNode("lblTagline").text = "S" + video.parentIndex + " : E" + video.index
        end if
    else
        if(video.DoesExist("tagline")) then
            m.scene.FindNode("lblTagline").text = video.tagline
        end if
    end if

    ' Details
    m.scene.FindNode("lblLength" ).text = TimeLengthString(StringOrBlank(video.duration))
    m.scene.FindNode("lblDate"   ).text = StringOrBlank(video.originallyAvailableAt)
    m.scene.FindNode("lblVideo"  ).text = VideoResolutionString(StringOrBlank(video.children[0].videoResolution))
    m.scene.FindNode("lblSummary").text = StringOrBlank(video.summary)
end sub

function TimeLengthString(duration as string) as string
    millis = StrToI(duration)
    if(millis = 0) then return "--"
    seconds  = millis / 1000.0
    hours    = Fix(seconds / 3600.0)
    seconds  = seconds - (hours * 3600)
    minutes  = Fix(seconds / 60.0)
    seconds  = seconds - (minutes * 60)
    seconds  = Fix(seconds)

    if(hours = 0) then
        return minutes.ToStr() + "m " + seconds.ToStr() + "s"
    else
        return hours.ToStr() + "h " + minutes.ToStr() + "m"
    end if
end function

function VideoResolutionString(resolution as string) as string
    if(resolution.Len() = 0) then return "--"
    if(StrToI(resolution).ToStr() = resolution) then return resolution + "p"
    return UCase(resolution)
end function
