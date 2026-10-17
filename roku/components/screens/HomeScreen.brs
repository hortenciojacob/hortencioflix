' Início: destaque do título focado, "Continuar a ver", biblioteca e catálogos

sub init_x()
    m.menu = m.top.findNode("menu")
    m.rows = m.top.findNode("rows")
    m.status = m.top.findNode("status")
    m.account = m.top.findNode("account")
    m.skeleton = m.top.findNode("skeleton")
    m.heroBg = m.top.findNode("heroBg")
    m.heroLogo = m.top.findNode("heroLogo")
    m.heroTitle = m.top.findNode("heroTitle")
    m.heroInfo = m.top.findNode("heroInfo")
    m.heroDesc = m.top.findNode("heroDesc")
    m.heroTimer = m.top.findNode("heroTimer")
    m.heroFade = m.top.findNode("heroFade")
    m.top.findNode("logo").color = accentColor()
    m.menu.observeField("buttonSelected", "onMenu")
    m.rows.observeField("rowItemSelected", "onRowSelected")
    m.rows.observeField("rowItemFocused", "onRowFocused")
    m.heroTimer.observeField("fire", "updateHero")
    m.heroBg.observeField("loadStatus", "onHeroBgLoaded")
    m.heroLogo.observeField("loadStatus", "onHeroLogoLoaded")
    m.top.observeField("focusedChild", "onFocusedChild")
    m.focusTarget = m.menu
    m.catalogRows = invalid
    m.calRecent = []
    m.calUpcoming = []
    m.traktRows = []
    m.heroKey = ""
    ' arranque rápido: mostra os catálogos guardados da última vez enquanto atualiza
    cached = ReadAsciiFile("cachefs:/home_rows.json")
    if cached <> ""
        rows = ParseJson(cached)
        if rows <> invalid and type(rows) = "roArray" and rows.Count() > 0
            m.catalogRows = rows
            render()
        end if
    end if
    load()
end sub
sub init()
    try
        init_x()
    catch e
        reportCrash("HomeScreen.init", e)
    end try
end sub

sub load_x()
    updateAccount()
    if m.catalogRows = invalid
        m.skeleton.visible = true
        m.skeleton.active = true
    end if
    if m.global.hasField("syncState") and m.global.syncState = "running"
        return
    end if
    m.task = startAddonTask({ kind: "home" }, "onHomeLoaded")
    loadExtras()
end sub
sub load()
    try
        load_x()
    catch e
        reportCrash("HomeScreen.load", e)
    end try
end sub

sub updateAccount()
    email = cfgRead("stremioEmail", "")
    prof = "Perfil: " + strOr(currentProfile().n) + "   ·   "
    if stremioLinked()
        if email = "" then email = "conta ligada"
        m.account.text = prof + "Stremio: " + email + "   ·   v" + appVersion()
    else
        m.account.text = prof + "v" + appVersion()
    end if
end sub

' Novos episódios das séries da biblioteca e recomendações Trakt
sub loadExtras()
    if isKidProfile() then return
    series = []
    for each it in libraryRowItems()
        if it.type = "series" and Left(it.id, 2) = "tt" and series.Count() < 25 then series.Push({ id: it.id })
    end for
    if series.Count() > 0 then m.calTask = startAddonTask({ kind: "calendar", items: series }, "onCalendar")
    token = cfgRead("traktToken", "")
    if token <> ""
        t = CreateObject("roSGNode", "TraktTask")
        t.request = { kind: "recs", clientId: cfgRead("traktId", ""), token: token }
        t.observeField("result", "onTrakt")
        t.control = "run"
        m.traktTask = t
    end if
end sub

sub onCalendar_x(event as object)
    res = event.getData()
    if res.recent <> invalid then m.calRecent = res.recent
    if res.upcoming <> invalid then m.calUpcoming = res.upcoming
    render()
end sub
sub onCalendar(event as object)
    try
        onCalendar_x(event)
    catch e
        reportCrash("HomeScreen.onCalendar", e)
    end try
end sub

sub onTrakt_x(event as object)
    res = event.getData()
    if res.ok and res.rows <> invalid then m.traktRows = res.rows
    render()
end sub
sub onTrakt(event as object)
    try
        onTrakt_x(event)
    catch e
        reportCrash("HomeScreen.onTrakt", e)
    end try
end sub

sub onHomeLoaded_x(event as object)
    res = event.getData()
    storeManifests(res)
    if res.rows <> invalid and res.rows.Count() > 0
        m.catalogRows = res.rows
        WriteAsciiFile("cachefs:/home_rows.json", FormatJson(res.rows))
    else if m.catalogRows = invalid
        m.catalogRows = []
        logEvent("Início: nenhum catálogo carregou")
    end if
    render()
end sub
sub onHomeLoaded(event as object)
    try
        onHomeLoaded_x(event)
    catch e
        reportCrash("HomeScreen.onHomeLoaded", e)
    end try
end sub

sub render_x()
    if m.catalogRows = invalid then return
    rows = []
    cont = continueRowItems()
    if cont.Count() > 0 then rows.Push({ title: "Continuar a ver", items: cont })
    if m.calRecent.Count() > 0 then rows.Push({ title: "Novos episódios das tuas séries", items: m.calRecent })
    if not isKidProfile()
        lib = libraryRowItems()
        if lib.Count() > 0 then rows.Push({ title: "A minha biblioteca (Stremio)", items: lib })
        rows.Append(m.traktRows)
    end if
    if m.calUpcoming.Count() > 0 then rows.Push({ title: "Em breve nas tuas séries", items: m.calUpcoming })
    rows.Append(m.catalogRows)
    updateAccount()
    m.top.findNode("logo").color = accentColor()
    m.skeleton.visible = false
    m.skeleton.active = false
    if rows.Count() > 0
        m.status.visible = false
        m.rows.content = buildRowContent(rows)
        m.focusTarget = m.rows
        if m.top.isInFocusChain() and not m.menu.isInFocusChain() then m.rows.setFocus(true)
        m.heroKey = ""
        m.heroTimer.control = "start"
    else
        m.status.visible = true
        m.status.text = "Não foi possível carregar catálogos. Verifica a ligação ou os add-ons em Definições."
        m.rows.content = invalid
        m.focusTarget = m.menu
        if m.top.isInFocusChain() then m.menu.setFocus(true)
    end if
end sub
sub render()
    try
        render_x()
    catch e
        reportCrash("HomeScreen.render", e)
    end try
end sub

' ---------- Destaque ----------

sub onRowFocused_x()
    m.heroTimer.control = "stop"
    m.heroTimer.control = "start"
end sub
sub onRowFocused()
    try
        onRowFocused_x()
    catch e
        reportCrash("HomeScreen.onRowFocused", e)
    end try
end sub

sub updateHero_x()
    c = focusedContent(m.rows)
    if c = invalid then return
    id = strOr(c.metaId)
    if id = m.heroKey then return
    m.heroKey = id
    bg = strOr(c.bg)
    if bg = "" then bg = metahubBg(id)
    if bg = "" then bg = c.HDPosterUrl
    logo = strOr(c.logo)
    if logo = "" then logo = metahubLogo(id)
    m.heroTitle.text = c.title
    m.heroTitle.visible = true
    m.heroLogo.visible = false
    m.heroLogo.uri = logo
    info = strOr(c.info)
    t = strOr(c.metaType)
    if info = ""
        if t = "movie"
            info = "Filme"
        else if t = "series"
            info = "Série"
        end if
    end if
    if c.hasField("progress") and c.progress > 0.01 then info = info + "   ·   " + Int(c.progress * 100).ToStr() + "% visto"
    m.heroInfo.text = info
    m.heroDesc.text = cleanText(c.desc)
    if bg <> m.heroBg.uri
        m.heroBg.opacity = 0
        m.heroBg.uri = bg
    end if
end sub
sub updateHero()
    try
        updateHero_x()
    catch e
        reportCrash("HomeScreen.updateHero", e)
    end try
end sub

sub onHeroBgLoaded_x()
    if m.heroBg.loadStatus = "ready" then m.heroFade.control = "start"
end sub
sub onHeroBgLoaded()
    try
        onHeroBgLoaded_x()
    catch e
        reportCrash("HomeScreen.onHeroBgLoaded", e)
    end try
end sub

sub onHeroLogoLoaded_x()
    if m.heroLogo.loadStatus = "ready"
        ' ajusta o tamanho mantendo o logótipo alinhado à esquerda
        bw = m.heroLogo.bitmapWidth
        bh = m.heroLogo.bitmapHeight
        if bw > 0 and bh > 0
            sc = 620 / bw
            if 170 / bh < sc then sc = 170 / bh
            m.heroLogo.width = Int(bw * sc)
            m.heroLogo.height = Int(bh * sc)
            m.heroLogo.translation = [80, 150 + Int((170 - bh * sc) / 2)]
        end if
        m.heroLogo.visible = true
        m.heroTitle.visible = false
    else if m.heroLogo.loadStatus = "failed"
        m.heroLogo.visible = false
        m.heroTitle.visible = true
    end if
end sub
sub onHeroLogoLoaded()
    try
        onHeroLogoLoaded_x()
    catch e
        reportCrash("HomeScreen.onHeroLogoLoaded", e)
    end try
end sub

' ---------- Navegação ----------

sub onFocusedChild_x()
    if m.top.hasFocus() then m.focusTarget.setFocus(true)
end sub
sub onFocusedChild()
    try
        onFocusedChild_x()
    catch e
        reportCrash("HomeScreen.onFocusedChild", e)
    end try
end sub

sub onMenu_x()
    names = ["explore", "search", "iptv", "torbox", "settings"]
    idx = m.menu.buttonSelected
    if idx >= 0 and idx < names.Count() then m.top.menuSelected = names[idx]
end sub
sub onMenu()
    try
        onMenu_x()
    catch e
        reportCrash("HomeScreen.onMenu", e)
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
        reportCrash("HomeScreen.onRowSelected", e)
    end try
end sub

function onKeyEvent_x(key as string, press as boolean) as boolean
    if not press then return false
    if key = "options"
        m.top.menuSelected = "settings"
        return true
    end if
    if key = "up" and m.rows.hasFocus()
        m.focusTarget = m.menu
        m.menu.setFocus(true)
        return true
    else if key = "down" and m.menu.isInFocusChain() and m.rows.content <> invalid
        m.focusTarget = m.rows
        m.rows.setFocus(true)
        return true
    end if
    return false
end function
function onKeyEvent(key as string, press as boolean) as boolean
    handled = false
    try
        handled = onKeyEvent_x(key, press)
    catch e
        reportCrash("HomeScreen.onKeyEvent", e)
    end try
    return handled
end function
