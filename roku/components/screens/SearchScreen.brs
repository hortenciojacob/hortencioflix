' Pesquisa: histórico, teclado (com voz) e resultados dos add-ons.
' Também serve para a "filmografia" de um ator (campo query + TMDB opcional).

sub init_x()
    m.top.findNode("header").color = accentColor()
    m.rows = m.top.findNode("rows")
    m.history = m.top.findNode("history")
    m.status = m.top.findNode("status")
    m.header = m.top.findNode("header")
    m.skeleton = m.top.findNode("skeleton")
    m.focusTitle = m.top.findNode("focusTitle")
    m.rows.observeField("rowItemSelected", "onRowSelected")
    m.rows.observeField("rowItemFocused", "onRowFocused")
    m.history.observeField("itemSelected", "onHistorySelected")
    m.top.observeField("focusedChild", "onFocusedChild")
    m.lastQuery = ""
    m.focusTarget = m.rows
end sub
sub init()
    try
        init_x()
    catch e
        reportCrash("SearchScreen.init", e)
    end try
end sub

sub onFocusedChild_x()
    if m.top.hasFocus() then m.focusTarget.setFocus(true)
end sub
sub onFocusedChild()
    try
        onFocusedChild_x()
    catch e
        reportCrash("SearchScreen.onFocusedChild", e)
    end try
end sub

sub onStart_x()
    q = m.top.query
    if q <> ""
        ' página de ator/realizador
        m.header.text = q
        m.top.findNode("hint").text = "Filmografia (com chave TMDB) ou resultados de pesquisa pelo nome"
        m.skeleton.visible = true
        m.lastQuery = q
        m.task = startAddonTask({ kind: "person", name: q, tmdbKey: cfgRead("tmdbKey", "") }, "onResults")
        return
    end if
    showHistory()
end sub
sub onStart()
    try
        onStart_x()
    catch e
        reportCrash("SearchScreen.onStart", e)
    end try
end sub

sub showHistory()
    hist = getSearchHistory()
    if hist.Count() = 0
        openKeyboard()
        return
    end if
    labels = ["Nova pesquisa…"]
    for each h in hist
        labels.Push(strOr(h))
    end for
    m.history.content = labelContent(labels)
    m.history.visible = true
    m.rows.visible = false
    m.focusTitle.text = "Pesquisas recentes"
    m.focusTarget = m.history
    m.history.setFocus(true)
end sub

sub onHistorySelected_x()
    idx = m.history.itemSelected
    if idx = 0
        openKeyboard()
    else
        hist = getSearchHistory()
        if idx - 1 < hist.Count() then runSearch(strOr(hist[idx - 1]))
    end if
end sub
sub onHistorySelected()
    try
        onHistorySelected_x()
    catch e
        reportCrash("SearchScreen.onHistorySelected", e)
    end try
end sub

sub openKeyboard()
    dlg = CreateObject("roSGNode", "StandardKeyboardDialog")
    dlg.title = "Pesquisar filmes e séries"
    dlg.text = m.lastQuery
    dlg.buttons = ["Pesquisar", "Cancelar"]
    dlg.observeFieldScoped("buttonSelected", "onKeyboardButton")
    m.dialog = dlg
    m.top.getScene().dialog = dlg
end sub

sub onKeyboardButton_x()
    dlg = m.dialog
    idx = dlg.buttonSelected
    text = dlg.text.Trim()
    dlg.close = true
    if idx = 0 and text <> ""
        runSearch(text)
    else if m.rows.content = invalid and not m.history.visible
        m.top.closeRequest = true
    end if
end sub
sub onKeyboardButton()
    try
        onKeyboardButton_x()
    catch e
        reportCrash("SearchScreen.onKeyboardButton", e)
    end try
end sub

sub runSearch(text as string)
    m.lastQuery = text
    addSearchHistory(text)
    m.header.text = "Pesquisar: " + text
    m.history.visible = false
    m.rows.visible = true
    m.status.text = ""
    m.focusTitle.text = ""
    m.skeleton.visible = true
    m.rows.content = invalid
    m.task = startAddonTask({ kind: "search", query: text }, "onResults")
end sub

sub onResults_x(event as object)
    res = event.getData()
    storeManifests(res)
    m.skeleton.visible = false
    if res.rows = invalid or res.rows.Count() = 0
        m.status.text = "Sem resultados para " + Chr(34) + m.lastQuery + Chr(34) + "."
        m.status.visible = true
        return
    end if
    m.status.visible = false
    m.rows.visible = true
    m.rows.content = buildRowContent(res.rows)
    m.focusTarget = m.rows
    m.rows.setFocus(true)
end sub
sub onResults(event as object)
    try
        onResults_x(event)
    catch e
        reportCrash("SearchScreen.onResults", e)
    end try
end sub

sub onRowSelected_x()
    item = itemFromRowList(m.rows)
    if item <> invalid then m.top.itemSelected = item
end sub
sub onRowSelected()
    try
        onRowSelected_x()
    catch e
        reportCrash("SearchScreen.onRowSelected", e)
    end try
end sub

sub onRowFocused_x()
    m.focusTitle.text = focusedTitle(m.rows)
end sub
sub onRowFocused()
    try
        onRowFocused_x()
    catch e
        reportCrash("SearchScreen.onRowFocused", e)
    end try
end sub

function onKeyEvent_x(key as string, press as boolean) as boolean
    if press and key = "options"
        openKeyboard()
        return true
    end if
    return false
end function
function onKeyEvent(key as string, press as boolean) as boolean
    handled = false
    try
        handled = onKeyEvent_x(key, press)
    catch e
        reportCrash("SearchScreen.onKeyEvent", e)
    end try
    return handled
end function
