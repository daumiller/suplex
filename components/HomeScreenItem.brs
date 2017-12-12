sub Init()
    m.poster    = m.top.FindNode("poster")
    m.watched   = m.top.FindNode("rectWatched")
    m.unwatched = m.top.FindNode("rectUnwatched")
end sub

sub ChangedContent()
    ' -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    ' see HomeScreen.brs -> HomeScreen_Populate_Library() for full mapping context
    ' -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    ' thumb.sized     -> HDPosterUrl            :  thumbnail resized to row_item_size url
    ' row_item_size.x -> MinBandwidth           :  resized thumbnail width
    ' row_item_size.y -> MaxBandwidth           :  resized thumbnail height
    ' viewOffset      -> BookmarkPosition       :  current position (on deck items)
    ' duration        -> Length                 :  total length     (on deck items)

    if(m.top.itemContent.MaxBandwidth = m.top.itemContent.MinBandwidth) then
        m.poster.loadingBitmapUri = "pkg:/image/loading-square.png"
    else
        m.poster.loadingBitmapUri = "pkg:/image/loading-tall.png"
    end if

    m.poster.width    = m.top.itemContent.MinBandwidth
    m.poster.height   = m.top.itemContent.MaxBandwidth
    m.poster.uri      = m.top.itemContent.HDPosterUrl

    viewOffset = m.top.itemContent.BookmarkPosition
    duration   = m.top.itemContent.Length

    if((viewOffset > 0) and (duration > 0)) then
        m.unwatched.translation = [0, m.poster.height-16]
        m.watched.translation   = [0, m.poster.height-16]
        m.unwatched.height      = 16
        m.watched.height        = 16
        m.unwatched.width       = m.poster.width
        m.watched.width         = Cint(Cdbl(viewOffset) / Cdbl(duration) * Cdbl(m.poster.width))
        m.unwatched.visible     = true
        m.watched.visible       = true
    else
        m.unwatched.visible = false
        m.watched.visible   = false
    end if
end sub
