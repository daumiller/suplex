'===================================================================================================================================
''' section HTTP
'===================================================================================================================================
''' function Network_Http_Get(url as string, is_plex=true as boolean, timeout_ms=5000 as integer) as object
''' return                    response body of HTTP GET request, or invalid on error
''' parameter=url             url to fetch
''' parameter=is_plex=true    if set, add Plex-specific headers to request
''' parameter=timeout_ms=5000 timeout value for GET request, in milliseconds
''' description               perform an HTTP GET request and return response body as string
function Network_Http_Get(url as string, is_plex=true as boolean, timeout_ms=5000 as integer) as object
    transfer = CreateObject("roUrlTransfer")
    queue    = CreateObject("roMessagePort")
    transfer.SetPort(queue)
    transfer.SetUrl(url)
    transfer.AddHeader("Content-Type", "application/x-www-form-urlencoded")
    if(is_plex) then
        transfer.AddHeader("X-Plex-Platform"         , "Roku")          ' TODO: adjust these fields
        transfer.AddHeader("X-Plex-Version"          , "1.0.0")         ' GetGlobal("appVersionStr")
        transfer.AddHeader("X-Plex-Client-Identifier", "bidness,nunya") ' GetGlobal("rokuUniqueID")
        transfer.AddHeader("X-Plex-Platform-Version" , "unknown")       ' GetGlobal("rokuVersionStr", "unknown")
        transfer.AddHeader("X-Plex-Product"          , "suplex")        ' "Plex for Roku"
        transfer.AddHeader("X-Plex-Device"           , "Roku 2")        ' GetGlobal("rokuModel"))
        transfer.AddHeader("X-Plex-Device-Name"      , "Dev Roku")      ' RegRead("player_name", "preferences", GetGlobalAA().Lookup("rokuModel")))
    end if

    transfer.EnableFreshConnection(true)
    if(transfer.AsyncGetToString() = false) then return invalid

    event = Wait(timeout_ms, queue)
    if(event = invalid) then
        ' timed out
        transfer.AsyncCancel()
        return invalid
    end if

    if(Type(event) = "roUrlEvent") then
        return {
            "response_code" : event.GetResponseCode(),
            "failure_reason": event.GetFailureReason(),
            "content"       : event.GetString()
        }
    end if

    ' didn't time out, but had some other event/error
    return invalid
end function

'- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

''' function Network_Http_Compose(url as string, parameters as object) as string
''' return               fully-formed, encoded, url
''' parameter=url        base url, without parameters
''' parameter=parameters assocarray of parameters to encode and append to url
''' description          compose an encoded url from a base address + set of parameters
function Network_Http_Compose(url as string, parameters as object) as string
    globals = GetGlobalAA()
    if(globals.url_encoder = invalid) then globals.url_encoder = CreateObject("roUrlTransfer")
    encoder = globals.url_encoder

    first = true
    for each key in parameters
        if first then
            first = false
            url = url + "?" + key + "=" + encoder.Escape(parameters[key])
        else
            url = url + "&" + key + "=" + encoder.Escape(parameters[key])
        end if
    end for

    return url
end function
