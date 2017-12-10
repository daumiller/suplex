function Registry_CacheSection(section)
    globals = GetGlobalAA()
    if(globals.registry_cache          = invalid) then globals.registry_cache          = {}
    if(globals.registry_cache[section] = invalid) then globals.registry_cache[section] = {}
    return globals.registry_cache[section]
end function

function Registry_Read(section, key, default=invalid)
    cache_section = Registry_CacheSection(section)
    if(cache_section[key] <> invalid) then return cache_section[key]

    registry_section = CreateObject("roRegistrySection", section)
    if(registry_section.Exists(key) = false) then return invalid

    cache_section[key] = registry_section.Read(key)
    return cache_section[key]
end function

sub Registry_Write(section, key, value, flush=true)
    cache_section = Registry_CacheSection(section)
    cache_section[key] = value

    registry_section = CreateObject("roRegistrySection", section)
    registry_section.Write(key, value)
    if(flush) then registry_section.Flush()
end sub
