{CompositeDisposable, Disposable} = require 'event-kit'
{AncestorsMethods, SpacePenDSL, EventsDelegation} = require 'atom-utils'

class FinderTool extends HTMLElement
  EventsDelegation.includeInto(this)
  SpacePenDSL.includeInto(this)

  debug: false
  nameWidth: 200
  sizeWidth: 80
  mdateWidth: 180

  @content: ->
    @tag 'atom-panel', class: 'tree-view-finder-tool tool-panel', =>
      @div outlet: 'toolBar', class: 'btn-group', =>
        @div outlet: 'backBtn', class: 'btn disable', id: 'back-btn', '<'
        @div outlet: 'forwBtn', class: 'btn disable', id: 'forw-btn', '>'
        @div outlet: 'homeBtn', class: 'btn disable', id: 'home-btn', 'Home'
        @div outlet: 'name', class: 'btn', id: 'name', ' '
        @div outlet: 'nameRsz', class: 'btn rsz', id: 'name-rsz', ''
        @div outlet: 'size', class: 'btn', id: 'size', 'Size'
        @div outlet: 'sizeRsz', class: 'btn rsz', id: 'size-rsz', ''
        @div outlet: 'mdate', class: 'btn', id: 'mdate', 'Date Modified'
        @div outlet: 'mdateRsz', class: 'btn rsz', id: 'mdate-rsz', ''

  initialize: (treeViewFinder) ->
    console.log "finder-tool: initialize", treeViewFinder if @debug
    @treeViewFinder = treeViewFinder
    @subscriptions = new CompositeDisposable
    @updateButtonStatus()

    @subscriptions.add @subscribeTo @toolBar, '.btn',
      'click': (e) =>
        console.log "finder-tool: click:", e.target.id, e if @debug
        if e.target == @backBtn
          @treeViewFinder.history.back()
        if e.target == @forwBtn
          @treeViewFinder.history.forw()
        if e.target == @homeBtn
          @treeViewFinder.history.goHome()
        @updateButtonStatus()

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
        # XXX, you can invoke some function here...
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
      if drag.originalWidth + d < 40
        d = 40 - drag.originalWidth
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
        @toolBar.style.left = @treeView.getBoundingClientRect().left + 'px'

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
