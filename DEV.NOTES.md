# suplex notes #

## Bulk Transcode ##
Target: Direct Play for Roku + Chrome
    MP4, H.264, 
* Roku only supports up to 1080 for H.264, but only supports H.265 on 4K devices. (VP9 is also 4K only, as well as DASH streaming only)
* Roku
    * H.264
    * Up to 1920x1080
    * MP4 Format
    * Frame Rate: 24/25/30/50/60
    * Streaming HLS m3u8/ts
    * Profile: Main or High
    * Level: 4.1 or 4.2
    * Constrained VBR
    * Video Bit Rate up to 10 MBit
    * Key Frame Interval < 10s (<5 for live)
    * **AAC**, AC3, MP3 (NOTE: Test **AAC** vs AC3, was sure one of these doesn't actually work.)
    * "If content contains a surround sound track, AAC 2-channel stereo should be provided as a backup audio track"
* https://sdkdocs.roku.com/display/sdkdoc/Trick+Mode+Support
* https://github.com/sergey-dryabzhinsky/nginx-rtmp-module
    * Will this work with multiple concurrent streams?
* https://trac.ffmpeg.org/wiki/StreamingGuide
* https://sdkdocs.roku.com/display/sdkdoc/Content+Meta-Data#ContentMeta-Data-PlaybackConfigurationAttributes
    * xBifUrl

* Transcode Library
    * Have import wizard
    * Only ahead-of-time transcoding; only direct-play streaming
* Write Media Scanners (easy to create/modify, up-to-date)
* Maybe pull Plex metadata

## top ##
* GDM: https://github.com/NineWorlds/serenity-android/wiki/Good-Day-Mate

## Not Supported ##
* myPlex
* Plex Pass

## May Support Later in Development ##
* Channels

## Screens ##
* HomeScreen
* DirectoryScreen
* MovieScreen
* SeriesScreen
* SeasonScreen
* EpisodeScreen
* music_screen(s) (ArtistScreen/TrackScreen?)
* SearchScreen
* SettingsScreen -> ServerScreen, ...

## MediaContainer fields ##
* MediaContainer
    * allowSync
    * art
    * banner
    * content
    * grandparentIndex
    * grandparentThumb
    * grandparentTitle
    * key
    * librarySectionID
    * librarySectionTitle
    * librarySectionUUID
    * mixedParents
    * nocache
    * parentIndex
    * parentThumb
    * parentTitle
    * parentYear
    * size
    * summary
    * theme
    * thumb
    * title1
    * title2
    * viewGroup
* Directory
    * allowSync
    * art
    * grandparentIndex
    * grandparentKey
    * grandparentThumb
    * grandparentTitle
    * index
    * key
    * parentIndex
    * parentKey
    * parentRatingKey
    * parentThumb
    * parentTitle
    * prompt
    * ratingKey
    * refreshing
    * search
    * secondary
    * summary
    * thumb
    * title
    * type
    * year
* Video/Track
    * allowSync
    * art
    * contentRating
    * duration
    * grandparentArt
    * grandparentIndex
    * grandparentKey
    * grandparentRatingKey
    * grandparentThumb
    * grandparentTitle
    * guid
    * index
    * key
    * lastViewedAt
    * librarySectionID
    * librarySectionTitle
    * parentArt
    * parentIndex
    * parentKey
    * parentRatingKey
    * parentThumb
    * parentTitle
    * rating
    * ratingKey
    * sessionKey
    * summary
    * thumb
    * title
    * type
    * userRating
    * viewCount
    * viewOffset
    * year
* Media
    * aspectRatio
    * audioChannels
    * audioCodec
    * bitrate
    * container
    * duration
    * height
    * id
    * videoCodec
    * videoFrameRate
    * videoResolution
    * width

## SectionScreen Scratchpad ##

' Section: http://192.168.0.2:32400/library/sections/6
' Series:  http://192.168.0.2:32400/library/metadata/26640/children
' Season:  http://192.168.0.2:32400/library/metadata/26655/children
' SectionScreen_Create will handle Sections/Series/Seasons
' set basePosterSize/Rows/Columns based on type (Sections-Tall, Series-Tall, Seasons-Wide)
' MediaContainer.viewGroup = "secondary", -> all -> MediaContainer.viewGroup = "show/movie/..."
' MediaContainer.viewGroup = "season", MediaContainer.viewGroup = "episode"

## Transcoding URL Scratchpad ##

http://192.168.0.2:32400/video/:/transcode/universal/start.m3u8
    ?path=http%3A%2F%2F127.0.0.1%3A32400%2Flibrary%2Fmetadata%2F23471 -> http://127.0.0.1/library/metadata/23471
    &protocol=hls
    &mediaIndex=0
    &partIndex=0
    &offset=0
    &waitForSegments=1
    &directPlay=0
    &directStream=0
    &videoQuality=100
    &videoResolution=1280x720
    &maxVideoBitrate=4000
    &subtitleSize=125
    &audioBoost=100
    &X-Plex-Platform=Roku
    &add-limitation(scope=videoCodec&scopeName=h264&type=upperBound&name=video.level&value=41&isRequired=true)
    &add-limitation(scope%3DvideoCodec%26scopeName%3Dh264%26type%3DpperBound%26name%3Dvideo.level%26value%3D1%26isRequired%3Dtrue)

    http://192.168.0.2:32400/video/:/transcode/universal/start.m3u8?path=http%3A%2F%2F127.0.0.1%3A32400%2Flibrary%2Fmetadata%2F23471&protocol=hls&mediaIndex=0&partIndex=0&offset=0&waitForSegments=1&directPlay=0&directStream=0&videoQuality=100&videoResolution=1280x720&maxVideoBitrate=4000&subtitleSize=125&audioBoost=100&X-Plex-Platform=Roku&add-limitation(scope%3DvideoCodec%26scopeName%3Dh264%26type%3DpperBound%26name%3Dvideo.level%26value%3D1%26isRequired%3Dtrue)
    http://192.168.0.2:32400/video/:/transcode/universal/start.m3u8?path=http%3A%2F%2F127.0.0.1%3A32400%2Flibrary%2Fmetadata%2F23471&protocol=hls&mediaIndex=0&partIndex=0&offset=0&waitForSegments=1&directPlay=0&directStream=0&videoQuality=100&videoResolution=1280x720&maxVideoBitrate=4000&subtitleSize=125&audioBoost=100&X-Plex-Platform=Roku
-->
    http://192.168.0.2:32400/video/:/transcode/universal/session/c2f53584-c9ee-4757-b6a7-34b0fc33f85b/base/index.m3u8
    http://192.168.0.2:32400/video/:/transcode/universal/stop?session=c2f53584-c9ee-4757-b6a7-34b0fc33f85b

http://192.168.0.2:32400/video/:/transcode/universal/start.m3u8
    &fastSeek=1
    &directPlay=0
    &directStream=1
    &videoQuality=100
    &videoResolution=1280x720
    &maxVideoBitrate=4000
    &subtitleSize=100
    &audioBoost=100
    &X-Plex-Platform=Chrome

http://192.168.0.2:32400/video/:/transcode/universal/start.m3u8
    ?path=http%3A%2F%2F127.0.0.1%3A32400%2Flibrary%2Fmetadata%2F23471
    &mediaIndex=0
    &partIndex=0
    &protocol=hls
    &offset=0
    &fastSeek=1
    &directPlay=0
    &directStream=1
    &videoQuality=100
    &videoResolution=1280x720
    &maxVideoBitrate=4000
    &subtitleSize=100
    &audioBoost=100
    &X-Plex-Platform=Chrome

http://192.168.0.2:32400/video/:/transcode/universal/start.m3u8?path=http%3A%2F%2F127.0.0.1%3A32400%2Flibrary%2Fmetadata%2F$mediaId&mediaIndex=0&partIndex=0&protocol=hls&offset=0&fastSeek=1&directPlay=0&directStream=1&videoQuality=$qual&videoResolution=$res&maxVideoBitrate=$bitrate&subtitleSize=100&audioBoost=100&X-Plex-Platform=Chrome
