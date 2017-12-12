' == LOOKUP/STORAGE ================================================================================================================
function PlexServer_SerializeServer(server_hash)
    return server_hash["Name"] + "|" + server_hash["Host"] + "|" + server_hash["Port"] + "|" + server_hash["Resource-Identifier"]
end function

function PlexServer_DeserializeServer(server_string)
    server_components = server_string.Tokenize("|")
    if(server_components.Count() <> 4) then return invalid

    return {
        "Name": server_components[0],
        "Host": server_components[1],
        "Port": server_components[2],
        "Resource-Identifier": server_components[3]
    }
end function

function PlexServer_Default(current_scene, timeout_ms=15000)
    server = Registry_Read("preferences", "server-default")
    if(server <> invalid) then return PlexServer_DeserializeServer(server)

    server_list = PlexServer_Discover(current_scene, timeout_ms)
    if(server_list = invalid)   then return invalid
    if(server_list.Count() = 0) then return invalid

    server = server_list.Next()
    Registry_Write("preferences", "server-default", PlexServer_SerializeServer(server))
    return server
end function

' == TRANSCODE URLs ================================================================================================================
function PlexServer_TranscodeImage(server, path, width, height)
    base_roku = "http://" + server["Host"] + ":" + server["Port"]
    base_plex = "http://127.0.0.1:" + server["Port"]
    return Network_EncodeURL(base_roku + "/photo/:/transcode", {
        "url":     base_plex + path,
        "width":   width.ToStr()
        "height":  height.ToStr()
        "minSize": "0" ' 0:scaleNotLargerThan, 1:scaleNotSmallerThan
    })
end function

' == LOAD LIBRARY ==================================================================================================================
function PlexServer_LoadLibrary_MediaContainer(server, path)
    url_base      = "http://" + server["Host"] + ":" + server["Port"]
    url_container = url_base + path
    response = Network_HttpGet(url_container)

    if(response = invalid) then
        Print("ERROR: PlexServer_LoadLibrary_MediaContainer() -- invalid response")
        Print("       for " + url_container)
        return invalid
    end if
    if((response.response_code <> 200) or (response.failure_reason <> "OK")) then
        Print("ERROR: PlexServer_LoadLibrary_MediaContainer() -- received " + response.response_code.ToStr() + " '" + response.failure_reason + "'")
        Print("       for " + url_container)
        return invalid
    end if

    xml_root = CreateObject("roXMLElement")
    if(xml_root.Parse(response.content) = false) then
        Print("ERROR: PlexServer_LoadLibrary_MediaContainer() -- failed parsing response XML")
        Print("       for " + url_container)
        return invalid
    end if

    if(xml_root.GetName() <> "MediaContainer") then
        Print("ERROR: PlexServer_LoadLibrary_MediaContainer() -- expected MediaContainer, found '" + xml_root.GetName() + "'")
        Print("       for " + url_container)
        return invalid
    end if

    xml_entries = xml_root.GetChildElements()
    if(xml_entries = invalid)   then return []
    if(xml_entries.Count() = 0) then return []

    ' type: section, directory, entry
    ' subtype: movie, season, episode, ...
    ' key: full-path (prepend /library/sections/ to type.section)
    ' title: (grandparentTitle + ": " +) (parentTitle + ": " + ) title
    ' thumb: grandparentThumb || parentThumb || thumb
    ' time_current: viewOffset
    ' time_total: duration
    ' uuid: section-uuid

    ' Directory
    '     key="10"
    '     type="movie"
    '     title="Animated Movies"
    '     thumb="/:/resources/movie.png"
    '     uuid="..."

    ' Directory
    '     librarySectionID="7"
    '     key="/library/metadata/29126/children"
    '     type="season"
    '     title="Season 1"                                 parentTitle="The Orville"
    '     thumb="/library/metadata/29126/thumb/1512105373" parentThumb="/library/metadata/29125/thumb/1512105373"

    ' Video
    '     key="/library/metadata/28477"
    '     type="episode"
    '     title="Will the Universe Expand Forever"         grandparentTitle="PBS Space Time"
    '     thumb="/library/metadata/28477/thumb/1493299680" grandparentThumb="/library/metadata/28074/thumb/1493299681"
    '     viewOffset="169185" duration="790013"

    entry_list = CreateObject("roList")
    for each xml_entry in xml_entries
        item = {
            "key"             : xml_entry@key,
            "subtype"         : xml_entry@type,
            "title"           : xml_entry@title,
            "thumb"           : xml_entry@thumb,
            "parentThumb"     : xml_entry@parentThumb,
            "grandparentThumb": xml_entry@grandparentThumb,
            "parentTitle"     : xml_entry@parentTitle,
            "grandparentTitle": xml_entry@grandparentTitle,
            "parentIndex"     : xml_entry@parentIndex,
            "parentKey"       : xml_entry@parentKey
        }

        ' relative -> absolute paths
        if(item["key"].Left(1) <> "/") then item["key"] = path + "/" + item["key"]

        xml_entry_type = xml_entry.GetName()
        if(xml_entry_type = "Directory") then
            if(xml_entry@uuid = invalid) then
                item["type"]      = "Directory"
                item["search"]    = xml_entry@search
                item["prompt"]    = xml_entry@prompt
                item["secondary"] = (xml_entry@secondary = "1")
            else
                item["type"] = "Section"
                item["uuid"] = xml_entry@uuid
            end if
        elseif(xml_entry_type = "Video") then
            item["type"] = "Video"
            if(xml_entry.HasAttribute("viewOffset")) then item["time_current"] = (xml_entry@viewOffset).ToInt() / 1000
            if(xml_entry.HasAttribute("duration"  )) then item["time_total"  ] = (xml_entry@duration).ToInt()   / 1000
        else
            Print("ERROR: PlexServer_LoadLibrary_MediaContainer() -- skipping unsupported type " + xml_entry_type)
            stop
        end if

        entry_list.AddTail(item)
    end for

    entry_list.Reset()

    root_thumb = xml_root@thumb
    if(StringHasContent(root_thumb) = false) then
        if(xml_root.HasAttribute("parentThumb"     )) then root_thumb = xml_root@parentThumb
        if(xml_root.HasAttribute("grandparentThumb")) then root_thumb = xml_root@grandparentThumb
    end if

    return {
        view : xml_root@viewGroup,
        thumb: root_thumb,
        media: entry_list
    }
end function

' == DISCOVERY =====================================================================================================================
function PlexServer_Discover(current_scene, timeout_ms=15000)
    socket = CreateObject("roDataGramSocket")
    socket.SetBroadcast(true)
    socket.NotifyReadable(true)
    queue = CreateObject("roMessagePort")
    socket.SetMessagePort(queue)

    broadcast_address = CreateObject("roSocketAddress")
    broadcast_address.SetHostName("239.255.255.250")
    broadcast_address.SetPort(32414)
    if(socket.SetSendToAddress(broadcast_address) = false) then
        Print("ERROR: PlexServer_Discover() -- roDataGramSocket.SetSendToAddress() failed")
        return invalid
    end if

    bytes_wrote = socket.SendStr("M-SEARCH * HTTP/1.1" + chr(13) + chr(10) + chr(13) + chr(10))
    if((bytes_wrote < 1) or (socket.eOK() = false)) then
        Print("ERROR: PlexServer_Discover() -- roDataGramSocket.SendStr() failed")
        return invalid
    end if

    wait_ui = CreateObject("roSGNode", "ProgressDialog")
    wait_ui.title = "Searching for Plex Servers..."
    wait_ui.optionsDialog = true
    current_scene.dialog = wait_ui

    time_clock  = CreateObject("roTimespan")
    time_began  = time_clock.TotalMilliseconds()
    server_hash = {}
    server_list = CreateObject("roList")

    while(true)
        if(timeout_ms < 10) then exit while

        message = Wait(timeout_ms, queue)        
        if(message = invalid) then exit while

        if(Type(message) = "roSocketEvent") then
            server = PlexServer_Discover_Parse(message, socket)
            if(server <> invalid) then
                if(server_hash[server["Resource-Identifier"]] = invalid) then
                    'Print("Found Server")
                    'Print("    Host " + server["Host"               ].ToStr())
                    'Print("    Type " + server["Content-Type"       ].ToStr())
                    'Print("    Name " + server["Name"               ].ToStr())
                    'Print("    Port " + server["Port"               ].ToStr())
                    'Print("    RID  " + server["Resource-Identifier"].ToStr())
                    'Print("    Date " + server["Updated-At"         ].ToStr())
                    'Print("    Ver  " + server["Version"            ].ToStr())
                    server_list.AddTail(server)
                    server_hash[server["Resource-Identifier"]] = true
                end if
            end if
        end if

        time_curr  = time_clock.TotalMilliseconds()
        timeout_ms = timeout_ms - (time_curr - time_began)
        time_began = time_curr
    end while

    socket.Close()
    wait_ui.close = true
    server_list.Reset()
    return server_list
end function

function PlexServer_Discover_Parse(message, socket)
    if(message.GetSocketID() <> socket.GetID()) then return invalid
    if(socket.IsReadable() = false) then return invalid
    data = socket.ReceiveStr(4096)
    host = socket.GetReceivedFromAddress().GetHostName()

    server = {}
    server["Host"] = host

    lines = data.Tokenize(Chr(10))
    for each line in lines
        if(Right(line, 1) = Chr(13)) then line = Left(line, Len(line)-1)
        param = line.Tokenize(": ")
        if(param.Count() = 2) then server[param[0]] = param[1]
    next

    if(server["Content-Type"] <> "plex/media-server") then return invalid
    if(server["Port"] = invalid) then return invalid

    return server
end function
