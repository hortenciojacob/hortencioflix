' Ajudas de interface partilhadas

function buildRowContent(rows as object) as object
    root = CreateObject("roSGNode", "ContentNode")
    for each r in rows
        row = root.createChild("ContentNode")
        row.title = r.title
        for each it in r.items
            c = row.createChild("ContentNode")
            c.title = strOr(it.name)
            c.HDPosterUrl = strOr(it.poster)
            c.FHDPosterUrl = strOr(it.poster)
            prog = 0.0
            if it.progress <> invalid then prog = it.progress
            c.addFields({ metaId: strOr(it.id), metaType: strOr(it.type), videoId: strOr(it.videoId), progress: prog, bg: strOr(it.bg), logo: strOr(it.logo), desc: strOr(it.desc), info: strOr(it.info) })
        end for
    end for
    return root
end function

function itemFromRowList(rowList as object) as object
    sel = rowList.rowItemSelected
    if sel = invalid or rowList.content = invalid then return invalid
    row = rowList.content.getChild(sel[0])
    if row = invalid then return invalid
    c = row.getChild(sel[1])
    if c = invalid then return invalid
    return { id: c.metaId, type: c.metaType, name: c.title, poster: c.HDPosterUrl, videoId: c.videoId, bg: c.bg, logo: c.logo }
end function

function focusedTitle(rowList as object) as string
    f = rowList.rowItemFocused
    if f = invalid or rowList.content = invalid then return ""
    row = rowList.content.getChild(f[0])
    if row = invalid then return ""
    c = row.getChild(f[1])
    if c = invalid then return ""
    return c.title
end function

function labelContent(labels as object) as object
    root = CreateObject("roSGNode", "ContentNode")
    for each l in labels
        c = root.createChild("ContentNode")
        c.title = l
    end for
    return root
end function

sub showMessage(title as string, text as string)
    dlg = CreateObject("roSGNode", "StandardMessageDialog")
    dlg.title = title
    dlg.message = [text]
    dlg.buttons = ["OK"]
    dlg.observeFieldScoped("buttonSelected", "onMessageDialogClose")
    m.top.getScene().dialog = dlg
end sub

sub onMessageDialogClose_x()
    dlg = m.top.getScene().dialog
    if dlg <> invalid then dlg.close = true
end sub
sub onMessageDialogClose()
    try
        onMessageDialogClose_x()
    catch e
        reportCrash("Ui.onMessageDialogClose", e)
    end try
end sub

' Abre um MenuPanel (componente) com uma lista de opções
sub openMenu(panel as object, menuId as string, title as string, items as object, startIndex as integer)
    panel.menuId = menuId
    panel.title = title
    panel.startIndex = startIndex
    panel.items = items
    panel.visible = true
    panel.setFocus(true)
end sub

' Conteúdo do item focado numa RowList (para o destaque do Início)
function focusedContent(rowList as object) as dynamic
    f = rowList.rowItemFocused
    if f = invalid or rowList.content = invalid then return invalid
    row = rowList.content.getChild(f[0])
    if row = invalid then return invalid
    return row.getChild(f[1])
end function

' O ecrã está à frente (visível e o leitor não está em ecrã inteiro)?
function screenIsActive() as boolean
    if not m.top.visible then return false
    p = m.top.getParent()
    if p <> invalid and not p.visible then return false
    return true
end function
