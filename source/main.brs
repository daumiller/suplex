' DirectoryOpen / DirectoryPlay
' VideoOpen     / VideoPlay

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
    '
    ' Stream.streamType 1:video, 2:audio, 3:subs
    ' Multi-Stream Audio Sample: http://192.168.0.2:32400/library/metadata/1146

    ' http://192.168.0.2:32400/video/:/transcode/universal/start.m3u8?path=
    '     http%3A%2F%2F127.0.0.1%3A32400%2Flibrary%2Fmetadata%2F23471                -> http://127.0.0.1:32400/library/metadata/23471
    '     &protocol=hls&mediaIndex=0&partIndex=0&offset=0&waitForSegments=1
    '     &directPlay=0&directStream=0&videoQuality=100&videoResolution=1280x720
    '     &maxVideoBitrate=4000&subtitleSize=125&audioBoost=100&X-Plex-Platform=Roku

    ' http://192.168.0.2:32400/video/:/transcode/universal/start?
    '     path=http%3A%2F%2F127.0.0.1%3A32400%2Flibrary%2Fmetadata%2F29127
    '     &mediaIndex=0&partIndex=0&protocol=http&offset=0&fastSeek=1
    '     &directPlay=0&directStream=1
    '     &subtitleSize=100&audioBoost=100
    '     &session=sygwxs7mdw
    '     &subtitles=burn&copyts=1
    '     &Accept-Language=en&X-Plex-Chunked=1&X-Plex-Product=Plex+Web&X-Plex-Version=2.4.18
    '     &X-Plex-Client-Identifier=d2y4r252nfuuoj5n7kmzbmx6r
    '     &X-Plex-Platform=Chrome
    '     &X-Plex-Platform-Version=63.0
    '     &X-Plex-Device=OSX
    '     &X-Plex-Device-Name=Plex+Web+(Chrome)
    '
    ' http://192.168.0.2:32400/video/:/transcode/universal/stop?session=sygwxs7mdw
    ' http://192.168.0.2:32400/:/timeline?ratingKey=29127&key=%2Flibrary%2Fmetadata%2F29127&state=paused&playQueueItemID=92502&time=1184&duration=2644895
    ' http://192.168.0.2:32400/playQueues?type=video&uri=library%3A%2F%2Fb61573c1d5ddc5b62a112e6da6de160b9349cda2%2Fitem%2F%252Flibrary%252Fmetadata%252F29127&shuffle=0&repeat=0
    ' http://192.168.0.2:32400/status/sessions
    ' http://192.168.0.2:32400/video/:/transcode/universal/ping?session=bsug6ga2bnu
end sub

' helper: guarantee a valid Plex server before proceeding
sub GetPlex()
    server = Plex_Server_Default()
    if(server <> invalid) then
        Plex_Server_Current(server)
    else
        ' could just forward to ServerScreen here, but attempt zero-config first.
        discovery = Plex_Server_Discover(GlobalLoop().Current_Scene(), true, 10000)
        if((discovery = invalid) or (discovery.Count() = 0)) then
            ' TODO: forward to ServerScreen; only allow exit with a Plex_Server_Current or out of the app
            Print("ERROR: No Plex servers found...")
            stop
        else
            server = discovery[0]
            Plex_Server_Default(server)
            Plex_Server_Current(server)
        end if
    end if

    if(not Plex_Server_Test())
        ' TODO: forward to ServerScreen (it will run Plex_Server_Test before returning)
        Print("ERROR: No response from Plex server...")
        stop
    end if
end sub

sub Main()
    home_screen = HomeScreen_Create()
    home_screen.scene.SetFocus(true)

    GetPlex()
    Print("PLEX Server: " + Plex_Server_Serialize(Plex_Server_Current()))

    home_screen.Populate()
    GlobalLoop().Run()
end sub
