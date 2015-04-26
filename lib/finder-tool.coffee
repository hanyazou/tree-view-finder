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
        @div class: 'btn disable', id: 'back', '<'
        @div class: 'btn disable', id: 'forth', '>'
        @div class: 'btn disable', id: 'home', 'Home'
        @div outlet: 'name', class: 'btn', id: 'name', ' '
        @div outlet: 'name-rsz', class: 'btn rsz', id: 'name-rsz', ''
        @div outlet: 'size', class: 'btn', id: 'size', 'Size'
        @div outlet: 'size-rsz', class: 'btn rsz', id: 'size-rsz', ''
        @div outlet: 'mdate', class: 'btn', id: 'mdate', 'Date Modified'
        @div outlet: 'mdate-rsz', class: 'btn rsz', id: 'mdate-rsz', ''

  initialize: (treeViewFinder) ->
    console.log "finder-tool: initialize", treeViewFinder if @debug
    @treeViewFinder = treeViewFinder
    @subscriptions = new CompositeDisposable

    @subscriptions.add @subscribeTo @toolBar, '.btn',
      'click': (e) =>
        console.log "finder-tool: click:", e.target.id, e if @debug

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
    @toolBar.style.width = @nameWidth + @sizeWidth + @mdateWidth + 106 + 'px'

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
          totalWidth: @toolBar.offsetWidth
        } 
    update = (e) =>
      d = e.clientX - drag.x
      if drag.originalWidth + d < 40
        d = 40 - drag.originalWidth
      drag.target.style.width = drag.originalWidth + d + 'px'
      @toolBar.style.width = drag.totalWidth + d + 'px'

    document.onmousemove = (e) =>
      if drag
        update(e)

    document.onmouseup = (e) =>
      if drag
        update(e)
        console.log "finder-tool: ", drag.target.id, drag.target.offsetLeft+ drag.target.offsetWidth if @debug
        @updateFileInfo()
        drag = null

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
    @treeViewScroller = workspace.querySelector('.tree-view-scroller')
    return if not @treeViewScroller
    @treeViewScroller.insertBefore(this, @treeViewScroller.firstChild)
    @updateFileInfo()
    @attached = true

  detach: ->
    console.log "finder-tool: detach" if @debug
    return if not @treeViewScroller
    @treeViewScroller.removeChild(this)
    @attached = false
    @treeViewScroller = null

  destroy: ->
    @detach()

module.exports = FinderTool = document.registerElement 'tree-view-finder-tool', prototype: FinderTool.prototype
