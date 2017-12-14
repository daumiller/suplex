# suplex notes #

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
