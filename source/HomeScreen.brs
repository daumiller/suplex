function HomeScreen_Create(bg_image="", bg_color="0x1F1F1FFF", queue=invalid)
    home_screen = { screen: CreateObject("roSGScreen") }
    home_screen.scene = home_screen.screen.CreateScene("HomeScreen")
    home_screen.scene.backgroundURI   = bg_image
    home_screen.scene.backgroundColor = bg_color
    home_screen.queue = queue
    if(queue = invalid) then home_screen.queue = CreateObject("roMessagePort")

    home_screen.screen.SetMessagePort(home_screen.queue)
    home_screen.screen.Show()

    home_screen.title_bar = home_screen.scene.FindNode("titleBar")
    home_screen.title_bar.title = "Main Menu"

    home_screen.row_list = home_screen.scene.FindNode("rowList")
    home_screen.balloon  = home_screen.scene.FindNode("balloon")

    home_screen.Loop     = HomeScreen_Loop
    home_screen.Populate = HomeScreen_Populate
    home_screen._Populate_LibrarySections = HomeScreen_Populate_LibrarySections
    home_screen._Populate_Dummy           = HomeScreen_Populate_Dummy
    home_screen._Populate_Empty           = HomeScreen_Populate_Empty
    home_screen._RowList_ItemFocused      = HomeScreen_RowList_ItemFocused

    return home_screen
end function

sub HomeScreen_RowList_ItemFocused()
    focus = m.row_list.rowItemFocused
    if((focus[0] = -1) or (focus[1] = -1)) then
        m.balloon.visible = false
        return
    end if

    ' TODO: here be magic numbers, some of these translations seem change if the rowList translation changes???
    if((m.balloon_row = invalid) or (m.balloon_row <> focus[0])) then
        m.balloon_row = focus[0]
        cell_height = m.row_list.rowHeights[m.balloon_row]
        cell_width = m.row_list.rowItemSize[m.balloon_row][0] + m.row_list.rowItemSpacing[0][0]
        m.balloon.translation = [ cell_width+8, cell_height+30 ]
    end if

    cell_width = m.row_list.rowItemSize[m.balloon_row][0] + m.row_list.rowItemSpacing[0][0]
    row_item_count = m.row_list.content.GetChild(focus[0]).GetChildCount()
    row_width = row_item_count * cell_width
    if(row_width < 1280) then
        m.balloon.visible = false ' don't update between moving and changing text
        attach_translation_x = 8 + (cell_width * (focus[1] + 1))
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
    
    content = m.row_list.content.GetChild(focus[0]).getChild(focus[1])
    m.balloon.text = content.title

    m.balloon.visible = true
end sub

sub HomeScreen_Loop()
    while(true)
        msg = Wait(0, m.queue)
        msg_type = Type(msg)
        if(msg_type = "roSGScreenEvent") then
            if(msg.IsScreenClosed()) then return
        elseif(msg.GetNode() = "rowList") then
            field = msg.GetField()
            if(field = "rowItemFocused" ) then m._RowList_ItemFocused()
            if(field = "scrollingStatus") then
                if(m.row_list.scrollingStatus) then m.balloon.visible = false
            end if
        end if
    end while
end sub

sub HomeScreen_Populate_LibrarySections(server)
    library_sections = PlexServer_LibrarySections(server)

    row_heights = CreateObject("roArray", m.row_list.rowHeights.Count() + 1, true)
    row_heights.Append(m.row_list.rowHeights)
    row_heights.Push(192 + 64)
    m.row_list.rowHeights = row_heights

    row_item_size = CreateObject("roArray", m.row_list.rowItemSize.Count() + 1, true)
    row_item_size.Append(m.row_list.rowItemSize)
    row_item_size.Push([192,192])
    m.row_list.rowItemSize = row_item_size

    library_section_row = CreateObject("roSGNode", "ContentNode")
    library_section_row.SetField("title", "Library Sections")
    for each section in library_sections
        library_section_item = CreateObject("roSGNode", "ContentNode")
        library_section_item.SetFields({
            ' from PlexServer.brs     -> PlexServer_LibrarySections()
            ' to   HomeScreenItem.brs -> ItemContentChanged()
            "HDPosterUrl"          : section.thumb,      ' Poster URL
            "Title"                : section.title,      ' Name
            "ShortDescriptionLine1": "library-section",  ' Type
            "ShortDescriptionLine2": section.key,        ' Action
        })
        library_section_row.AppendChild(library_section_item)
    end for

    if(m.row_list.content = invalid) then m.row_list.content = CreateObject("roSGNode", "ContentNode")
    m.row_list.content.AppendChild(library_section_row)
end sub

sub HomeScreen_Populate_Dummy(server, count)
    row_heights = CreateObject("roArray", m.row_list.rowHeights.Count() + 1, true)
    row_heights.Append(m.row_list.rowHeights)
    row_heights.Push(274 + 64)
    m.row_list.rowHeights = row_heights

    row_item_size = CreateObject("roArray", m.row_list.rowItemSize.Count() + 1, true)
    row_item_size.Append(m.row_list.rowItemSize)
    row_item_size.Push([192,274])
    m.row_list.rowItemSize = row_item_size

    dummy_row = CreateObject("roSGNode", "ContentNode")
    dummy_row.SetField("title", "Dummy Row")
    poster_url = PlexServer_TranscodeImage(server, "/library/metadata/29135/thumb/1510906164", 192, 274)
    for index = 1 to count step 1
        dummy_item = CreateObject("roSGNode", "ContentNode")
        dummy_item.SetFields({
            "HDPosterUrl"          : poster_url,
            "Title"                : "Dummy Item " + index.ToStr(),
            "ShortDescriptionLine1": "dummy",
            "ShortDescriptionLine2": "noop"
        })
        dummy_row.AppendChild(dummy_item)
    end for

    if(m.row_list.content = invalid) then m.row_list.content = CreateObject("roSGNode", "ContentNode")
    m.row_list.content.AppendChild(dummy_row)
end sub

sub HomeScreen_Populate_Empty()
    row_heights = CreateObject("roArray", m.row_list.rowHeights.Count() + 1, true)
    row_heights.Append(m.row_list.rowHeights)
    row_heights.Push(64 + 64)
    m.row_list.rowHeights = row_heights

    row_item_size = CreateObject("roArray", m.row_list.rowItemSize.Count() + 1, true)
    row_item_size.Append(m.row_list.rowItemSize)
    row_item_size.Push([64,64])
    m.row_list.rowItemSize = row_item_size

    empty_row = CreateObject("roSGNode", "ContentNode")
    empty_row.SetField("title", "Empty Row")

    if(m.row_list.content = invalid) then m.row_list.content = CreateObject("roSGNode", "ContentNode")
    m.row_list.content.AppendChild(empty_row)
end sub

sub HomeScreen_Populate(server)
    m._Populate_LibrarySections(server)
    m._Populate_Dummy(server, 10)
    m._Populate_Dummy(server, 5)
    m._Populate_Empty()

    m.row_list.SetFocus(true)
    m.row_list.ObserveField("rowItemFocused" , m.queue)
    m.row_list.ObserveField("scrollingStatus", m.queue)
    m._RowList_ItemFocused()
end sub
