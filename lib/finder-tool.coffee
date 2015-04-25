{CompositeDisposable, Disposable} = require 'event-kit'
{AncestorsMethods, SpacePenDSL, EventsDelegation} = require 'atom-utils'

class FinderTool extends HTMLElement
  EventsDelegation.includeInto(this)
  SpacePenDSL.includeInto(this)

  @content: ->
    @tag 'atom-panel', class: 'tree-view-finder-tool tool-panel', =>
      @div outlet: 'finderToolElement', class: 'btn-group', =>
        @div class: 'btn disable', id: 'back', '<'
        @div class: 'btn disable', id: 'forth', '>'
        @div class: 'btn disable', id: 'home', 'Home'
        @div outlet: 'name', class: 'btn', id: 'name', ' '
        @div outlet: 'size', class: 'btn', id: 'size', 'Size'
        @div outlet: 'mdate', class: 'btn', id: 'mdate', 'Date Modified'

  initialize: ->
    @subscriptions = new CompositeDisposable

    workspaceElement = atom.views.getView(atom.workspace)
    @treeViewResizer = workspaceElement.querySelector('.tree-view-resizer')
    @treeViewScroller = workspaceElement.querySelector('.tree-view-scroller')

    @subscriptions.add @subscribeTo @finderToolElement, '.btn',
      'click': (e) =>
        console.log "finder-tool: clieck:", e.target.id, e
    @name.style.width = '190px'
    @size.style.width = '80px'
    @mdate.style.width = '250px'

  attach: ->
    @treeViewResizer.insertBefore(this, @treeViewResizer.firstChild)
    @treeViewScroller.classList.add('with-finder')
    @attached = true

  detach: ->
    @treeViewResizer.removeChild(this) if @parentNode? and @parentNode is @treeViewResizer
    @treeViewScroller.classList.remove('with-finder')
    @attached = false

  destroy: ->
    @detach()

module.exports = FinderTool = document.registerElement 'tree-view-finder-tool', prototype: FinderTool.prototype
