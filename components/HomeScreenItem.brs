sub Init()
    m.poster    = m.top.FindNode("poster")
    m.watched   = m.top.FindNode("rectWatched")
    m.unwatched = m.top.FindNode("rectUnwatched")
end sub

sub ChangedContent()
    ' see HomeScreen.brs -> HomeScreen_Populate_LibraryRow() for mapping context
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

    if(m.top.itemContent.MaxBandwidth = m.top.itemContent.MinBandwidth) then
        m.poster.loadingBitmapUri = "pkg:/image/loading-square.png"
    else
        m.poster.loadingBitmapUri = "pkg:/image/loading-poster.png"
    end if

    m.poster.width    = m.top.itemContent.MinBandwidth
    m.poster.height   = m.top.itemContent.MaxBandwidth
    m.poster.uri      = m.top.itemContent.SDPosterUrl
    m.top.itemName    = m.top.itemContent.Title
    m.top.itemType    = m.top.itemContent.ShortDescriptionLine1
    m.top.itemSubtype = m.top.itemContent.ShortDescriptionLine2
    m.top.itemKey     = m.top.itemContent.FHDPosterUrl
    m.top.itemResume  = m.top.itemContent.BookmarkPosition

    if((m.top.itemContent.BookmarkPosition > 0) and (m.top.itemContent.Length > 0)) then
        m.unwatched.translation = [0, m.poster.height-16]
        m.watched.translation   = [0, m.poster.height-16]
        m.unwatched.height      = 16
        m.watched.height        = 16
        m.unwatched.width       = m.poster.width
        m.watched.width         = Cint(Cdbl(m.top.itemContent.BookmarkPosition) / Cdbl(m.top.itemContent.Length) * Cdbl(m.poster.width))
        m.unwatched.visible     = true
        m.watched.visible       = true
    else
        m.unwatched.visible = false
        m.watched.visible   = false
    end if
end sub
