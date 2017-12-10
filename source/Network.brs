function Network_HttpGet(url, is_plex=true, timeout_ms=5000)
    transfer = CreateObject("roUrlTransfer")
    queue    = CreateObject("roMessagePort")
    transfer.SetPort(queue)
    transfer.SetUrl(url)
    transfer.AddHeader("Content-Type", "application/x-www-form-urlencoded")
    if(is_plex) then
        transfer.AddHeader("X-Plex-Platform"         , "Roku")
        transfer.AddHeader("X-Plex-Version"          , "1.0.0")         ' GetGlobal("appVersionStr")
        transfer.AddHeader("X-Plex-Client-Identifier", "bidness,nunya") ' GetGlobal("rokuUniqueID")
        transfer.AddHeader("X-Plex-Platform-Version" , "unknown")       ' GetGlobal("rokuVersionStr", "unknown")
        transfer.AddHeader("X-Plex-Product"          , "suplex")        ' "Plex for Roku"
        transfer.AddHeader("X-Plex-Device"           , "Roku 2")        ' GetGlobal("rokuModel"))
        transfer.AddHeader("X-Plex-Device-Name"      , "Dev Roku")      ' RegRead("player_name", "preferences", GetGlobalAA().Lookup("rokuModel")))
    end if

    transfer.EnableFreshConnection(true)
    if(transfer.AsyncGetToString() = false) then return invalid

    event = wait(timeout_ms, queue)
    if(Type(event) = "roUrlEvent") then
        data = CreateObject("roAssociativeArray")
        data.response_code  = event.GetResponseCode()
        data.failure_reason = event.GetFailureReason()
        data.content        = event.GetString()
        return data
    end if
    if(event = invalid) then transfer.AsyncCancel()
    return invalid
end function

function Network_EncodeURL(url, parameters)
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
