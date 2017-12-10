sub Init()
    m.poster  = m.top.FindNode("poster")
    m.lblText = m.top.FindNode("lblText")
    m.attachLeft  = m.top.FindNode("attachLeft")
    m.attachRight = m.top.FindNode("attachRight")
end sub

sub ChangedAttach()
    if(m.top.attach = "left") then
        m.attachLeft.visible  = true
        m.attachRight.visible = false
    else
        m.attachLeft.visible  = false
        m.attachRight.visible = true
    end if
end sub

sub ChangedText()
    m.lblText.text = m.top.text
end sub
