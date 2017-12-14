' registry { preferences: { plex-server-default, plex-server-count, plex-server-0, plex-server-1, ... } }
' globals  { plex-server-current }
' plex-server-assocarray { name, host, port, id }

'===================================================================================================================================
''' section SERVER_STORAGE
'===================================================================================================================================
''' function Plex_Server_Current(write_value=invalid as object) as object
''' return                        current plex server, or invalid if not set
''' parameter=write_value=invalid server to set as current, or invalid to read only
''' description                   get or set current plex server, stored in global aa
function Plex_Server_Current(write_value=invalid as object) as object
    globals = GetGlobalAA()
    if(write_value = invalid) then return globals["plex-server-current"]
    globals["plex-server-current"] = write_value
    return write_value
end function

'- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

''' function Plex_Server_Default(write_value=invalid as object) as object
''' return                        default plex server, or invalid if not set
''' parameter=write_value=invalid server to set as default, or invalid to read only
''' description                   get or set default plex server, stored in registry
function Plex_Server_Default(write_value=invalid as object) as object
    if(write_value = invalid) then
        read_value = Registry_Read("preferences", "plex-server-default")
        return Plex_Server_Deserialize(StringOrBlank(read_value))
    end if

    Registry_Write("preferences", "plex-server-default", Plex_Server_Serialize(write_value))
    return write_value
end function

'- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

''' function Plex_Server_Serialize(server_aa as object) as string
''' return              serialized server, as string
''' parameter=server_aa server to serialize, as assocarray
''' description         serialize a plex server, from assocarray to string
function Plex_Server_Serialize(server_aa as object) as string
    return server_aa.name +"|"+ server_aa.host +"|"+ server_aa.port +"|"+ server_aa.id
end function

'- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

''' function Plex_Server_Deserialize(server_str as string) as object
''' return               deserialized server, as assocarray, or invalid on failure
''' parameter=server_str server to deserialize, as string
''' description          deserialize a plex server, from string to assocarray
function Plex_Server_Deserialize(server_str as string) as object
    components = server_str.Tokenize("|")
    if(components.Count() <> 4) then return invalid

    return {
        name: components[0],
        host: components[1],
        port: components[2],
        id  : components[3]
    }
end function

'- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

''' function Plex_Server_List(write_value=invalid as object) as object
''' return                        list of servers stored in registry, deserialized
''' parameter=write_value=invalid list of servers to store in registry, or invalid to read only
''' description                   get or set list of plex servers stored in registry
function Plex_Server_List(write_value=invalid as object) as object
    registry_section = CreateObject("roRegistrySection", "preferences")

    server_count = Registry_Read("preferences", "plex-server-count")
    server_count = StrToI(StringOrBlank(read_value))
    server_list = CreateObject("roArray", server_count, true)
    for index=0 to (server_count-1) step 1
        server_curr = Registry_Read("preferences", "plex-server-"+index.ToStr())
        server_list.Push(Plex_Server_Deserialize(StringOrBlank(server_curr)))
    end for
    if(write_value = invalid) then return server_list

    ' erase old values that we're not overwriting
    for index=write_value.Count() to (server_count-1) step 1
        Registry_Delete("preferences", "plex-server-"+index.ToStr(), false)
    end for

    server_count = write_value.Count()
    for index=0 to (server_count-1) step 1
        Registry_Write("preferences", "plex-server-"+index.ToStr(), Plex_Server_Serialize(write_value[index]), false)
    end for

    ' only flush=true on final write
    Registry_Write("preferences", "plex-server-count", server_count.ToStr(), true)
end function

'===================================================================================================================================
''' section SERVER_DISCOVERY
'===================================================================================================================================
''' function Plex_Server_Discover(ui_scene as object, first_only=false as boolean, timeout_ms=5000 as integer)
''' return                     list of servers discovered, an empty list if none found, or invalid on error
''' parameter=ui_scene         current UI scene to display searching dialog with, or invalid for no dialog
''' parameter=first_only=false set true to stop when first server found, false to find all servers available until timeout
''' parameter=timeout_ms=5000  length of search period before timing out, in milliseconds
''' description                search for local plex servers
function Plex_Server_Discover(ui_scene as object, first_only=false as boolean, timeout_ms=5000 as integer)
    socket = CreateObject("roDataGramSocket")
    socket.SetBroadcast(true)
    socket.NotifyReadable(true)
    queue = CreateObject("roMessagePort")
    socket.SetMessagePort(queue)

    broadcast_address = CreateObject("roSocketAddress")
    broadcast_address.SetHostName("239.255.255.250")
    broadcast_address.SetPort(32414)
    if(socket.SetSendToAddress(broadcast_address) = false) then
        Print("ERROR: Plex_Server_Discover() -- roDataGramSocket.SetSendToAddress() failed")
        return invalid
    end if

    bytes_wrote = socket.SendStr("M-SEARCH * HTTP/1.1" + chr(13)+chr(10) + chr(13)+chr(10))
    if((bytes_wrote < 1) or (socket.eOK() = false)) then
        Print("ERROR: Plex_Server_Discover() -- roDataGramSocket.SendStr() failed")
        return invalid
    end if

    wait_ui = invalid
    if(ui_scene <> invalid) then
        wait_ui         = CreateObject("roSGNode", "ProgressDialog")
        wait_ui.title   = "Searching for Plex Servers..."
        ui_scene.dialog = wait_ui
    end if

    time_clock    = CreateObject("roTimespan")
    time_began    = time_clock.TotalMilliseconds()
    server_lookup = {}
    server_list   = CreateObject("roList")

    while(true)
        if(timeout_ms < 10) then exit while

        message = Wait(timeout_ms, queue)        
        if(message = invalid) then exit while

        if(Type(message) = "roSocketEvent") then
            server = Plex_Server_Discover_Parse(message, socket)
            if(server <> invalid) then
                if(not server_lookup.DoesExist(server["Resource-Identifier"])) then
                    'Print("Found Server")
                    'Print("    Host " + server["Host"               ].ToStr())
                    'Print("    Type " + server["Content-Type"       ].ToStr())
                    'Print("    Name " + server["Name"               ].ToStr())
                    'Print("    Port " + server["Port"               ].ToStr())
                    'Print("    RID  " + server["Resource-Identifier"].ToStr())
                    'Print("    Date " + server["Updated-At"         ].ToStr())
                    'Print("    Ver  " + server["Version"            ].ToStr())
                    server_list.Push({
                        name: StringOrBlank(server["Name"]),
                        host: StringOrBlank(server["Host"]),
                        port: StringOrBlank(server["Port"]),
                        id  : StringOrBlank(server["Resource-Identifier"])
                    })
                    server_lookup[server["Resource-Identifier"]] = true
                    if(first_only) then exit while
                end if
            end if
        end if

        time_curr  = time_clock.TotalMilliseconds()
        timeout_ms = timeout_ms - (time_curr - time_began)
        time_began = time_curr
    end while

    socket.Close()
    if(wait_ui <> invalid) then wait_ui.close = true

    server_list.Reset()
    return server_list
end function

' helper function for Plex_Server_Discover
' reads response packet from plex server and parses out host parameters
function Plex_Server_Discover_Parse(message as object, socket as object) as object
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

'- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

''' function Plex_Server_Test(server=invalid as object) as boolean
''' return                   whether we can access Plex, and it responds as expected
''' parameter=server=invalid server assocarray to test, or invalid for Plex_Server_Current
''' description              test Plex server for connectivity/response
function Plex_Server_Test(server=invalid as object) as boolean
    if(server = invalid) then server = Plex_Server_Current()
    media_container = Plex_MediaContainer("/library", server)
    if(media_container = invalid) then return false
    if(not media_container.DoesExist("tagName")) then return false
    return (media_container.tagName = "MediaContainer")
end function

'===================================================================================================================================
''' section REMOTE_CONTROL
'===================================================================================================================================
' TODO: remote control requires us to
'       - run a GDM listener responding to requests
'       - run a webserver responding for specific endpoints ("/player/playback/playMedia", ...)

'===================================================================================================================================
''' section URL_COMPOSITION
'===================================================================================================================================
''' function Plex_Path_Transcode_Image(server as object, path as string, width as integer, height as integer) as string
''' return                   plex url for transcoded image
''' parameter=path           relative path of image to transcode
''' parameter=width          transcoder output width
''' paremeter=height         transcoder output height
''' parameter=server=invalid plex server, or invalid to use Plex_Server_Current()
''' description              compose path for a transcoded image
function Plex_Path_Transcode_Image(path as string, width as integer, height as integer, server=invalid as object) as string
    if(server = invalid) then server = Plex_Server_Current()

    base_roku = "http://" + server.host + ":" + server.port
    base_plex = "http://127.0.0.1:" + server.port
    return Network_Http_Compose(base_roku + "/photo/:/transcode", {
        url    : base_plex+path,
        width  : width.ToStr()
        height : height.ToStr()
        minSize: "0" ' 0:scaleNotLargerThan, 1:scaleNotSmallerThan
    })
end function

'- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

''' function Plex_Path_Transcode_Image_Init(width as integer, height as integer, server=invalid as object) as object
''' return                   an assocarray of data for use in calls to Plex_Path_Transcode_Image_Next
''' parameter=width          transcoder output width
''' paremeter=height         transcoder output height
''' parameter=server=invalid plex server, or invalid to use Plex_Server_Current()
''' description              create transcode_image data to retrieve multiple image transcoding paths
function Plex_Path_Transcode_Image_Init(width as integer, height as integer, server=invalid as object) as object
    if(server = invalid) then server = Plex_Server_Current()

    encoder = CreateObject("roUrlTransfer")
    partial = "http://" + server.host + ":" + server.port + "/photo/:/transcode"
    partial = partial + "?width="  + width.ToStr()
    partial = partial + "&height=" + height.ToStr()
    partial = partial + "&minSize=0"
    partial = partial + "&url=" + encoder.Escape("http://127.0.0.1:" + server.port)

    return { partial:partial, encoder:encoder }
end function

''' function Plex_Path_Transcode_Image_Next(image_set as object, path as string) as string
''' return              plex url for transcoded image
''' parameter=image_set data from initial call to Plex_Path_Transcode_Image_Init
''' parameter=path      relative path of image to transcode
''' description         compose path for a transcoded image, using shared, preset, parameters
function Plex_Path_Transcode_Image_Next(image_set as object, path as string) as string
    return image_set.partial + image_set.encoder.Escape(path)
end function

' Plex_Path_Transcode_Video
' Plex_Path_Transcoder_Command
' Plex_Path_DirectPlay_Video


'===================================================================================================================================
''' section MEDIA_LOADING
'===================================================================================================================================
''' function Plex_MediaContainer(key as string, server=invalid as object) as object
''' return                   MediaContainer document assocarray, read for the given key
''' parameter=path           media item key/path
''' parameter=server=invalid plex server, or invalid to use Plex_Server_Current()
''' description              fetch a MediaContainer document from a library key
function Plex_MediaContainer(key as string, server=invalid as object) as object
    if(server = invalid) then server = Plex_Server_Current()

    media_url = "http://" + server.host + ":" + server.port + key
    response = Network_Http_Get(media_url)

    if(response = invalid) then
        Print("ERROR: Plex_MediaContainer() -- invalid response")
        Print("       for " + media_url)
        return invalid
    end if
    if((response.response_code <> 200) or (response.failure_reason <> "OK")) then
        Print("ERROR: Plex_MediaContainer() -- received " + response.response_code.ToStr() + " '" + StringOrBlank(response.failure_reason) + "'")
        Print("       for " + media_url)
        return invalid
    end if

    xml_root = CreateObject("roXMLElement")
    if(not xml_root.Parse(response.content)) then
        Print("ERROR: Plex_MediaContainer() -- failed parsing response XML")
        Print("       for " + media_url)
        return invalid
    end if

    if(xml_root.GetName() <> "MediaContainer") then
        Print("ERROR: Plex_MediaContainer() -- root element not MediaContainer, but '" + xml_root.GetName() + "'")
        Print("       for " + media_url)
        return invalid
    end if

    storage_tags = { "MediaContainer":true, "Directory":true, "Video":true, "Track":true, "Media":true }
    media_container = Plex_MediaContainer_ParseItem(key, storage_tags, xml_root)
    if(media_container = invalid) then
        Print("ERROR: Plex_MediaContainer() -- failed parsing XML document")
        Print("       for " + media_url)
        return invalid
    end if

    return media_container
end function

' helper function for Plex_MediaContainer
' parses a single node in a MediaContainer document
function Plex_MediaContainer_ParseItem(parent_key as string, storage_tags as object, xml_node as object) as object
    node_tag = xml_node.GetName()
    if(not storage_tags.DoesExist(node_tag)) then return invalid

    node_data = xml_node.GetAttributes()
    if(StringHasContent(node_data["key"])) then
        if(node_data["key"].Left(1) <> "/") then node_data["key"] = parent_key + "/" + node_data["key"]
    end if

    node_data["tagName"]  = node_tag
    node_data["children"] = []

    xml_children = xml_node.GetChildElements()
    if(xml_children = invalid)   then return node_data
    if(xml_children.Count() = 0) then return node_data

    node_children = CreateObject("roArray", xml_children.Count(), true)
    for each xml_child in xml_children
        child_data = Plex_MediaContainer_ParseItem(parent_key, storage_tags, xml_child)
        if(child_data <> invalid) then node_children.Push(child_data)
    end for

    node_data["children"] = node_children
    return node_data
end function
