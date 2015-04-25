{CompositeDisposable, Disposable} = require 'event-kit'
{AncestorsMethods, SpacePenDSL, EventsDelegation} = require 'atom-utils'

class FinderTool extends HTMLElement
  EventsDelegation.includeInto(this)
  SpacePenDSL.includeInto(this)

  debug: false

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
    @treeViewFinder = treeViewFinder
    @subscriptions = new CompositeDisposable

    workspace = atom.views.getView(atom.workspace)
    @treeViewScroller = workspace.querySelector('.tree-view-scroller')

    @subscriptions.add @subscribeTo @toolBar, '.btn',
      'click': (e) =>
        console.log "finder-tool: click:", e.target.id, e if @debug
    @toolBar.style.width = '624px'
    @name.style.width = '190px'
    @size.style.width = '80px'
    @mdate.style.width = '250px'

    drag = null

    @subscriptions.add @subscribeTo @toolBar, '.rsz',
      'mousedown': (e) =>
        console.log "finder-tool: drag:", e.target.id, e if @debug
        if e.target.id == 'name-rsz'
          target = @name
        if e.target.id == 'size-rsz'
          target = @size
        if e.target.id == 'mdate-rsz'
          target = @mdate
        return if not target
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

  updateFileInfo: ->
    @treeViewFinder.fileInfo.updateWidth(
      @name.offsetLeft + @name.offsetWidth,
      @size.offsetWidth,
      @mdate.offsetWidth)

  attach: ->
    @treeViewScroller.insertBefore(this, @treeViewScroller.firstChild)
    @updateFileInfo()
    @attached = true

  detach: ->
    @treeViewScroller.removeChild(this)
    @attached = false

  destroy: ->
    @detach()

module.exports = FinderTool = document.registerElement 'tree-view-finder-tool', prototype: FinderTool.prototype
