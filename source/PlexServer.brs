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

' == LOAD SECTIONS =================================================================================================================
function PlexServer_LibrarySections(server)
    url_base     = "http://" + server["Host"] + ":" + server["Port"]
    url_sections = url_base + "/library/sections"
    response = Network_HttpGet(url_sections)
    if(response = invalid) then
        Print("ERROR: PlexServer_LibrarySections() -- invalid response for " + url)
        return invalid
    end if
    if((response.response_code <> 200) or (response.failure_reason <> "OK")) then
        Print("ERROR: PlexServer_LibrarySections() -- received " + response.response_code.ToStr() + " '" + response.failure_reason + "'")
        return invalid
    end if

    xml = CreateObject("roXMLElement")
    if(xml.Parse(response.content) = false) then
        Print("ERROR: PlexServer_LibrarySections() -- failed parsing response XML")
        return invalid
    end if

    directories = xml.GetChildElements()
    if(directories = invalid)   then return []
    if(directories.Count() = 0) then return []

    library_sections = CreateObject("roList")
    for each directory in directories
        library_sections.AddTail({
            "title"     : directory@title,
            "media_type": directory@type,
            "key"       : directory@key,
            "thumb"     : url_base + directory@thumb
        })
    end for

    library_sections.Reset()
    return library_sections
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
