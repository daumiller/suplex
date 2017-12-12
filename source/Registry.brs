'===================================================================================================================================
''' section REGISTRY_ACCESS
'===================================================================================================================================
''' function Registry_Read(section, key, default=invalid)
''' return                    value from registry.section.key, or default if not found
''' parameter=section         name of registry section to read from
''' parameter=key             name of registry key to read
''' parameter=default=invalid value to return if key not found, NOTE: default value will not be stored in registry or cache
''' description               read a value from the registry, via a cache, with default fallback value
function Registry_Read(section as string, key as string, default=invalid) as dynamic
    cache_section = Registry_CacheSection(section)
    if(cache_section.DoesExist(key)) then return cache_section[key]

    registry_section = CreateObject("roRegistrySection", section)
    if(registry_section.Exists(key) = false) then return default

    cache_section[key] = registry_section.Read(key)
    return cache_section[key]
end function

'- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

''' sub Registry_Write(section as string, key as string, value, flush=true)
''' parameter=section    name of registry section to write to
''' parameter=key        name of registry key to write
''' parameter=flush=true whether to flush registry values after writing; for bulk access, only flush on the last call
''' description          write a value to the registry, via a cache
sub Registry_Write(section as string, key as string, value as dynamic, flush=true as boolean)
    cache_section = Registry_CacheSection(section)
    cache_section[key] = value

    registry_section = CreateObject("roRegistrySection", section)
    registry_section.Write(key, value)
    if(flush) then registry_section.Flush()
end sub

'- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

''' sub Registry_Delete(section as string, key as string, flush=true as boolean)
''' parameter=section    name of registry section to delete from
''' parameter=key        name of registry key to delete
''' parameter=flush=true whether to flush registry values after deleting; for bulk access, only flush on the last call
''' description          delete a value from the registry, via cache
sub Registry_Delete(section as string, key as string, flush=true as boolean)
    cache_section = Registry_CacheSection(section)
    cache_section.Delete(key)

    registry_section = CreateObject("roRegistrySection", section)
    registry_section.Delete(key)
    if(flush) then registry_section.Flush()
end sub

'- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

''' function Registry_CacheSection(section as string) as object
''' return            cache assocarray for given registry section
''' parameter=section name of registry section to get cache of
''' description       registry helper function to get a section's current cache assocarray
function Registry_CacheSection(section as string) as object
    globals = GetGlobalAA()
    if(not globals.DoesExist("registry_cache"))       then globals.registry_cache          = {}
    if(not globals.registry_cache.DoesExist(section)) then globals.registry_cache[section] = {}
    return globals.registry_cache[section]
end function
