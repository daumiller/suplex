function StringHasContent(str)
    if(str = invalid) then return false
    if(str.Len() = 0) then return false
    return true
end function

function StringOrBlank(str)
    if(str = invalid) then return ""
    return str
end function

sub PlaybackScreen_Create(key, time_start=0)
    plex_server = GetGlobalAA().plex_server
    if(StringHasContent(plex_server["Host"]) = false) then return
    if(Type(time_start) = "Double" ) then time_start = Cint(time_start)
    if(Type(time_start) = "Integer") then time_start = time_start.ToStr()

    playback_screen = CreateObject("roSGScreen")
    playback_scene  = playback_screen.CreateScene("PlaybackScreen")
    playback_queue  = CreateObject("roMessagePort")
    playback_screen.SetMessagePort(playback_queue)
    playback_screen.Show()

    playback_video = playback_scene.FindNode("video")

    transcode_url = "http://" + plex_server["Host"] + ":" + plex_server["Port"] + "/video/:/transcode/universal/start.m3u8"
    transcode_url = Network_EncodeURL(transcode_url, {
        "path"           : "http://127.0.0.1" + plex_server["Port"] + key,
        "protocol"       : "hls",
        "mediaIndex"     : "0",
        "partIndex"      : "0",
        "offset"         : time_start,
        "waitForSegments": "1",
        "directPlay"     : "0",
        "directStream"   : "0",
        "videoQuality"   : "100",
        "videoResolution": "1280x720",
        "maxVideoBitrate": "4000",
        "subtitleSize"   : "125",
        "audioBoost"     : "100",
        "X-Plex-Platform": "Roku"
    })

    content_node = CreateObject("roSGNode", "ContentNode")
    content_node.title = "Playback Test" ' media_container.media[0].title
    content_node.streamformat = "hls"
    content_node.url = transcode_url

    playback_video.content = content_node
    playback_video.control = "play"
    playback_video.SetFocus(true)

    while(true)
        message = Wait(0, playback_queue)
        message_type = Type(message)
        if(message_type = "roSGScreenEvent") then
            if(message.IsScreenClosed()) then return
        end if
    end while

    ' video_item = PlexServer_LoadLibrary_VideoContainer(plex_server, key)
    ' MediaContainer > Video > Media > Part > Stream
    ' Video {
    '     type: "episode",
    '     title: "EpTitle",
    '     grandparentTitle: "ShowTitle",
    '     duration="3085127"
    ' }
    ' Media {
    '     videoResolution: "sd",
    '     bitrate: "889",
    '     width: "720", height:"404", aspectRatio:"1.78",
    '     audioChannels:"2", audioCodec:"aac",
    '     videoCodec:"h264", container:"mkv", videoFrameRate="24p"
    ' }

    ' video_content = CreateObject("roSGNode", "ContentNode")
    ' video_content.url = "http://192.168.0.2:32400/video/:/transcode/universal/start.m3u8?path=http%3A%2F%2F127.0.0.1%3A32400%2Flibrary%2Fmetadata%2F23471&protocol=hls&mediaIndex=0&partIndex=0&offset=0&waitForSegments=1&directPlay=0&directStream=0&videoQuality=100&videoResolution=1280x720&maxVideoBitrate=4000&subtitleSize=125&audioBoost=100&X-Plex-Platform=Roku"
    ' video_content.title = "Shrek"
    ' video_content.streamformat = "hls"
    ' videoPlayer.width = 1280
    ' videoPlayer.height = 720
    ' videoPlayer.content = video_content
    ' videoPlayer.control = "play"
    ' videoPlayer.SetFocus(true)

    ' http://192.168.0.2:32400/video/:/transcode/universal/start.m3u8?path=
    '     http%3A%2F%2F127.0.0.1%3A32400%2Flibrary%2Fmetadata%2F23471                -> http://127.0.0.1:32400/library/metadata/23471
    '     &protocol=hls&mediaIndex=0&partIndex=0&offset=0&waitForSegments=1
    '     &directPlay=0&directStream=0&videoQuality=100&videoResolution=1280x720
    '     &maxVideoBitrate=4000&subtitleSize=125&audioBoost=100&X-Plex-Platform=Roku
end sub

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
