sub Init()
    m.poster = m.top.FindNode("poster")
end sub

sub ChangedContent()
    if(m.top.itemType = "library-section") then
        m.poster.width  = 192
        m.poster.height = 192
    else
        m.poster.width  = 192
        m.poster.height = 274
    end if

    ' available m.top.itemContent fields: https://sdkdocs.roku.com/display/sdkdoc/Content+Meta-Data   
    m.poster.uri     = m.top.itemContent.HDPosterUrl
    m.top.itemName   = m.top.itemContent.Title
    m.top.itemType   = m.top.itemContent.ShortDescriptionLine1
    m.top.itemAction = m.top.itemContent.ShortDescriptionLine2
end sub
