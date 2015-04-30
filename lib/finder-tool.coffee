{CompositeDisposable, Disposable} = require 'event-kit'
{AncestorsMethods, SpacePenDSL, EventsDelegation} = require 'atom-utils'

class FinderTool extends HTMLElement
  EventsDelegation.includeInto(this)
  SpacePenDSL.includeInto(this)

  debug: false
  nameWidth: 200
  sizeWidth: 80
  mdateWidth: 180
  minWidth: 40
  sortKey: 'name'
  sortOrder: 'ascent'

  @content: ->
    @tag 'atom-panel', class: 'tree-view-finder-tool tool-panel', =>
      @div outlet: 'toolBar', class: 'btn-group', =>
        @div outlet: 'backBtn', class: 'btn disable', id: 'back-btn', '<'
        @div outlet: 'forwBtn', class: 'btn disable', id: 'forw-btn', '>'
        @div outlet: 'homeBtn', class: 'btn disable', id: 'home-btn', 'Home'
        @div outlet: 'name', class: 'btn', id: 'name', =>
          @span class: 'finder-tool-btn-label', id: 'name-btn-label', 'Name'
        @div outlet: 'nameRsz', class: 'btn rsz', id: 'name-rsz', ''
        @div outlet: 'size', class: 'btn', id: 'size', =>
          @span class: 'finder-tool-btn-label', id: 'size-btn-label', 'Size'
        @div outlet: 'sizeRsz', class: 'btn rsz', id: 'size-rsz', ''
        @div outlet: 'mdate', class: 'btn', id: 'mdate', =>
          @span class: 'finder-tool-btn-label', id: 'mdate-btn-label', 'Date Modified'
        @div outlet: 'mdateRsz', class: 'btn rsz', id: 'mdate-rsz', ''

  initialize: (treeViewFinder) ->
    console.log "finder-tool: initialize", treeViewFinder if @debug
    @treeViewFinder = treeViewFinder
    @subscriptions = new CompositeDisposable
    @updateButtonStatus()

    @name.calcOptWidth = =>
      btnWidth = @backBtn.offsetWidth + @forwBtn.offsetWidth + 
        @homeBtn.offsetWidth
      optWidth = @treeViewFinder.fileInfo.calcOptWidthName()
      optWidth -= btnWidth
      if  optWidth < 0
        optWidth = 0
      optWidth
    @size.calcOptWidth = =>
      @treeViewFinder.fileInfo.calcOptWidthSize()
    @mdate.calcOptWidth = =>
      @treeViewFinder.fileInfo.calcOptWidthMdate()
    @name.sortKey = 'name'
    @size.sortKey = 'size'
    @mdate.sortKey = 'mdate'

    @subscriptions.add @subscribeTo @toolBar, '.btn',
      'click': (e) =>
        console.log "finder-tool: click:", e.target.id, e if @debug
        #
        # history, back and forth
        #
        if e.target == @backBtn
          @treeViewFinder.history.back()
        if e.target == @forwBtn
          @treeViewFinder.history.forw()
        if e.target == @homeBtn
          @treeViewFinder.history.goHome()
        #
        # sort by name, size and date
        #
        target = e.target
        if not target.classList.contains('btn')
          target = target.parentElement
        if target.sortKey
          e.stopPropagation()
          if target.sortKey is @sortKey
            if @sortOrder is 'ascent'
              @sortOrder = 'descent'
            else
              @sortOrder = 'ascent'
          else
            @sortKey = target.sortKey
        @updateButtonStatus()
        @treeViewFinder.fileInfo.sort(@sortKey, @sortOrder)

    state = treeViewFinder?.state?.finderTool
    if state
      console.log 'finde-tool: initiliaze: state =', state if @debug
      if state.nameWidth
        @nameWidth = state.nameWidth
      if state.sizeWidth
        @sizeWidth = state.sizeWidth
      if state.mdateWidth
        @mdateWidth = state.mdateWidth
      
    @name.style.width = @nameWidth + 'px'
    @size.style.width = @sizeWidth + 'px'
    @mdate.style.width = @mdateWidth + 'px'

    drag = null

    getTargetRsz = (e) =>
      return @name if e.target.id == 'name-rsz'
      return @size if e.target.id == 'size-rsz'
      return @mdate if e.target.id == 'mdate-rsz'
      return null
        
    @subscriptions.add @subscribeTo @toolBar, '.rsz',
      'dblclick': (e) =>
        console.log "finder-tool: double click:", e.target.id, e if @debug
        # optimize column width
        return if not target = getTargetRsz(e)
        if @debug
          console.log 'finder-tool: opt width:', target.id, 
            target.calcOptWidth()
        target.style.width = Math.max(target.calcOptWidth(), @minWidth) + 'px'
        @updateFileInfo()
      'mousedown': (e) =>
        console.log "finder-tool: drag:", e.target.id, e if @debug
        return if not target = getTargetRsz(e)
        drag = { 
          x: e.clientX, 
          y: e.clientY,
          target: target,
          originalWidth: target.offsetWidth,
        } 
    updateButtonWidths = (e) =>
      d = e.clientX - drag.x
      if drag.originalWidth + d < @minWidth
        d = @minWidth - drag.originalWidth
      drag.target.style.width = drag.originalWidth + d + 'px'

    document.onmousemove = (e) =>
      if drag
        updateButtonWidths(e)
        @updateFileInfo()

    document.onmouseup = (e) =>
      if drag
        updateButtonWidths(e)
        console.log "finder-tool: ", drag.target.id, drag.target.offsetLeft+ drag.target.offsetWidth if @debug
        @updateFileInfo()
        drag = null

  updateButtonStatus: ->
    if @debug
      console.log 'finder-tool: updateButtonStatus:',
        @treeViewFinder.history.canBack(),
        @treeViewFinder.history.canForw(),
        @treeViewFinder.history.canGoHome()
    if @treeViewFinder.history.canBack()
      @backBtn.classList.remove('disable')
    else
      @backBtn.classList.add('disable')
    if @treeViewFinder.history.canForw()
      @forwBtn.classList.remove('disable')
    else
      @forwBtn.classList.add('disable')
    if @treeViewFinder.history.canGoHome()
      @homeBtn.classList.remove('disable')
    else
      @homeBtn.classList.add('disable')

    if @debug
      console.log 'finder-tool: sort:',
        'key =', @sortKey, ', order =', @sortOrder
    for label in @toolBar.querySelectorAll('.finder-tool-btn-label')
      label.classList.remove('finder-tool-btn-label-ascent')
      label.classList.remove('finder-tool-btn-label-descent')
      label.classList.add('finder-tool-btn-label-nosort')
    if label = @toolBar.querySelector('#' + @sortKey + '-btn-label')
      label.classList.remove('finder-tool-btn-label-nosort')
      label.classList.add('finder-tool-btn-label-' + @sortOrder)

  serialize: ->
    return {} if not @attached
    nameWidth: @nameWidth
    sizeWidth: @sizeWidth
    mdateWidth: @mdateWidth

  updateFileInfo: ->
    @nameWidth = @size.offsetLeft - @name.offsetLeft
    @sizeWidth = @mdate.offsetLeft - @size.offsetLeft
    @mdateWidth = @mdate.offsetWidth
    console.log 'finder-tool: updateFileInfo: ', @nameWidth, @sizeWidth, @mdateWidth if @debug
    @treeViewFinder.fileInfo.updateWidth(
      @name.offsetLeft + @nameWidth,
      @sizeWidth,
      @mdateWidth)

  attach: ->
    console.log "finder-tool: attach" if @debug
    workspace = atom.views.getView(atom.workspace)
    @treeViewResizer = workspace.querySelector('.tree-view-resizer')
    @treeViewScroller = workspace.querySelector('.tree-view-scroller')
    @treeView = workspace.querySelector('.tree-view')
    return if not @treeViewResizer
    @treeViewResizer.insertBefore(this, @treeViewScroller)
    @treeViewScroller.classList.add('with-finder')
    @updateFileInfo()
    @attached = true
    @scrollSubscription = @subscribeTo @treeViewScroller,'.tree-view-scroller',
      'scroll': (e) =>
        treeViewScrollerLeft = @treeViewScroller.getBoundingClientRect().left
        treeViewLeft = @treeView.getBoundingClientRect().left
        @toolBar.style.left = treeViewLeft - treeViewScrollerLeft + 'px'

  detach: ->
    console.log "finder-tool: detach" if @debug
    return if not @treeViewResizer
    @scrollSubscription.dispose()
    @treeViewScroller.classList.remove('with-finder')
    @treeViewResizer.removeChild(this)
    @attached = false
    @treeViewResizer = null

  destroy: ->
    @detach()

module.exports = FinderTool = document.registerElement 'tree-view-finder-tool', prototype: FinderTool.prototype
