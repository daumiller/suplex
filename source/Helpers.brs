'===================================================================================================================================
''' section STRING_HELPERS
'===================================================================================================================================
''' function StringHasContent(input as dynamic) as boolean
''' return          false if invalid or length = 0, otherwise true
''' parameter=input string, or invalid, to test
''' description     test string for content
function StringHasContent(input as dynamic) as boolean
    if(input = invalid) then return false
    if(input.Len() = 0) then return false
    return true
end function

'- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

''' function StringOrBlank(str as dynamic) as string
''' return          input string if valid, blank string if invalid
''' parameter=input string, or invalid, to test
''' description     returns a valid string, either input string or blank string
function StringOrBlank(input as dynamic) as string
    if(input = invalid) then return ""
    return input
end function
