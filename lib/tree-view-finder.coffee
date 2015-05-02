$ = require 'jquery'
FinderTool = require './finder-tool'
{CompositeDisposable} = require 'atom'
FileInfo = require './file-info'
xorTap = require './doubleTap.js/xorTap'
open = null
fs = null

module.exports = TreeViewFinder =
  config:
    entireWindow:
      type: 'boolean'
      default: false
      title: 'Use entire window'
    debugTreeViewFinder:
      type: 'boolean'
      default: false
      title: 'Enable debug information from tree-view-finder.coffee'
    debugFinderTool:
      type: 'boolean'
      default: false
      title: 'Enable debug information from finder-tool.coffee'
    debugFileInfo:
      type: 'boolean'
      default: false
      title: 'Enable debug information from file-info.coffee'
    debugHistory:
      type: 'boolean'
      default: false
      title: 'Enable debug information from history'

  subscriptions: null
  treeView: null
  visible: false
  xorhandler: null
  isFit: false
  history: null
  subscriptionOnPanelDestroy: null

  activate: (@state) ->
    @history = new history
    @finderTool = new FinderTool()
    @fileInfo = new FileInfo()
    @updateDebugFlags()
    if @debug
      console.log 'tree-view-finder: activate:',
        'should attach =', @state.shouldAttach
    @state.shouldAttach ?= false

    @subscriptions = new CompositeDisposable

    @history.initialize()
    @finderTool.initialize(this)
    @fileInfo.initialize()

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'tree-view-finder:toggle': => @toggle()

    # Install event handlers which don't depend on TreeView panel status.
    @subscriptions.add atom.project.onDidChangePaths =>
      @updateRoots()

    @subscriptions.add atom.config.onDidChange 'tree-view-finder.debugTreeViewFinder', =>
      @updateDebugFlags()
    @subscriptions.add atom.config.onDidChange 'tree-view-finder.debugFinderTool', =>
      @updateDebugFlags()
    @subscriptions.add atom.config.onDidChange 'tree-view-finder.debugFileInfo', =>
      @updateDebugFlags()
    @subscriptions.add atom.config.onDidChange 'tree-view-finder.debugHistory', =>
      @updateDebugFlags()

    @subscriptions.add atom.config.onDidChange 'tree-view-finder.entireWindow', =>
      @updateEntireWindowCongig()

    window.onresize = () =>
      console.log 'Window innerWidth:', window.innerWidth if @debug
      @updateWidth()

    atom.packages.activatePackage('tree-view').then (treeViewPkg) =>
      @treeView = treeViewPkg.mainModule.createView()
      if @debug
        console.log 'tree-view-finder: attaching on activation: should attach =',
          @state.shouldAttach
      @attach() if @state.shouldAttach
    $('body').on 'focus', '.tree-view', =>
      if @debug
        console.log 'tree-view-finder: .tree-view got focus: should attach =',
          @state.shouldAttach
      @attach() if @state.shouldAttach

  deactivate: ->
    console.log 'tree-view-finder: deactivate' if @debug
    @_hide()
    @subscriptions.dispose()
    @finderTool.destroy()

  serialize: ->
    if @debug
      console.log 'tree-view-finder: serialize:',
        'should attach =', @state.shouldAttach
    finderTool: @finderTool.serialize()
    shouldAttach: @state.shouldAttach

  toggle: ->
    return if not @treeView.isVisible()
    if @visible
      @detach()
    else
      @attach()

  attach: ->
    @state.shouldAttach = true
    @_show()

  detach: ->
    @state.shouldAttach = false
    @_hide()

  _show: ->
    console.log 'tree-view-finder: show()' if @debug

    treeViewPkg = atom.packages.getLoadedPackage('tree-view')
    console.log 'tree-view-finder: create TreeView' if @debug
    @treeView = treeViewPkg.mainModule.createView()

    # XXX, check if there is the tree-view
    if not @treeView.isVisible()
      console.log 'tree-view-finder: show(): @treeView.isVisiple() =',
        @treeView.isVisible() if @debug
      return 

    @visible = true
    @finderTool.attach()

    @fileInfo.show(@treeView)
    @updateEntireWindowCongig()
    @hookTreeViewEvents()

  _hide: ->
    console.log 'tree-view-finder: hide()' if @debug
    @visible = false
    @fileInfo.hide()
    @finderTool.detach()
    @unfitWidth()
    @unhookTreeViewEvents()

  fitWidth: ->
    console.log 'tree-view-finder: fitWidth...' if @debug
    return if not @visible
    return if @isFit
    @resizer = atom.views.getView(atom.workspace).querySelector('.tree-view-resizer')
    return if not @resizer
    ws = atom.views.getView(atom.workspace)
    vertical = ws.querySelector('atom-workspace-axis.vertical')
    vertical.classList.add('tree-view-finder-fit')
    @resizerOriginalWidth = @resizer.style.width
    @isFit = true
    console.log 'tree-view-finder: fitWidth...succeeded' if @debug
    @updateWidth()

  updateWidth: ->
    if @resizer and @isFit
      @resizer.style.width = window.innerWidth + 'px'

  unfitWidth: ->
    console.log 'tree-view-finder: unfitWidth' if @debug
    if @resizer and @isFit
      @resizer.style.width = @resizerOriginalWidth
    @resizer = null
    ws = atom.views.getView(atom.workspace)
    vertical = ws.querySelector('atom-workspace-axis.vertical')
    vertical.classList.remove('tree-view-finder-fit')
    @isFit = false

  hookTreeViewEvents: ->
    console.log 'tree-view-finder: hookTreeViewEvents: install click handler' if @debug
    @treeView.off 'click'
    @xorhandler ?= new xorTap(
      (e) =>
        console.log 'tree-view-finder: click!', e if @debug
        @treeView.entryClicked(e)
        @fileInfo.update()
      ,
      (e) =>
        console.log 'tree-view-finder: double click!', e, e.currentTarget.classList if @debug
        if e.currentTarget.classList.contains('directory') and
           not e.currentTarget.classList.contains('project-root')
          console.log 'tree-view-finder: cd ' + e.target.dataset.path if @debug
          targetPath = e.target.dataset.path
          oldPaths = atom.project.getPaths()
          p = e.target
          while not p.classList.contains('tree-view')
            if name = p.querySelector(':scope > div > span.name')
              if @debug
                console.log 'tree-view-finder:', p.tagName, name.dataset.path
            targetProject = p
            p = p.parentNode
          # p is ol.tree-view
          if p.children.length != oldPaths.length
            console.log 'ERROR:',
              'num of projects =', p.children.length, 
              ', num of nodes =', oldPaths.length if @debug
          i = 0
          newPaths = []
          for root in p.children
            if name = p.children[i].querySelector(':scope > div > span.name')
              if root is targetProject
                if @debug
                  console.log 'tree-view-finder:', i+':', name.dataset.path, 
                    '==> ' + targetPath
                newPaths.push targetPath
              else
                if @debug
                  console.log 'tree-view-finder:', i+':', name.dataset.path
                newPaths.push oldPaths[i]
            i++
          console.log 'tree-view-finder:' if @debug
          console.log '  old:', oldPaths if @debug
          console.log '  new:', newPaths if @debug
          @history.push newPaths
          @finderTool.updateButtonStatus()
        else if e.currentTarget.classList.contains('file')
          console.log 'tree-view-finder: double click: file' if @debug
          @openUri(e.target.dataset.path)
      )
    #click_ts = 0
    @treeView.on 'click', '.entry', (e) =>
      #console.log 'tree-view-finder: click event', e if @debug
      #if (click_ts != e.timeStamp)
      #  click_ts = e.timeStamp
        return if e.target.classList.contains('entries')
        return if e.shiftKey or e.metaKey or e.ctrlKey
        e.stopPropagation()
        if name = e.target.querySelector('.icon-file-directory')
          if @debug
            console.log 'tree-vire-finder: click w/o double click.',
              name.getBoundingClientRect().left, e.offsetX, 
              e.offsetX < name.getBoundingClientRect().left
          if e.offsetX < name.getBoundingClientRect().left
            @treeView.entryClicked(e)
            @fileInfo.update()
            return
        @xorhandler(e)

    # XXX, in case that @treeView.panel is not available. (I donno why.)
    panel = atom.workspace.panelForItem(@treeView)

    # hook destroy event of the panel to detect deatching the tree view.
    @subscriptionOnPanelDestroy = panel.onDidDestroy =>
      console.log 'tree-view-finder: treeView.panel was destroyed.' if @debug
      @_hide()

  unhookTreeViewEvents: ->
    console.log 'tree-view-finder: UnhookTreeViewEvents' if @debug
    @treeView.off 'click'
    #
    # XXX, this code was came from TreeView.handleEvents
    #
    @treeView.on 'click', '.entry', (e) =>
      return if e.target.classList.contains('entries')
      @treeView.entryClicked(e) unless e.shiftKey or e.metaKey or e.ctrlKey

    @subscriptionOnPanelDestroy.dispose()
    @subscriptionOnPanelDestroy = null

  updateRoots: ->
    oldPaths = @history.getCurrentPaths()
    newPaths = atom.project.getPaths()
    console.log 'tree-view-finder: updateRoots: ', oldPaths, newPaths if @debug
    oldi = newi = 0
    while oldi < oldPaths.length or newi < newPaths.length
      # console.log "updateRoots: ", oldi, oldPaths[oldi], newi, newPaths[newi]
      if oldPaths[oldi] isnt newPaths[newi]
        if oldPaths[oldi]
          if @debug
            console.log 'tree-view-finder: updateRoots:', 
              'REMOVE project folder:', oldi + ': ' + oldPaths[oldi]
          @history.removePath oldi
          newi--
        else
          if @debug
            console.log 'tree-view-finder: updateRoots:',
              'ADD project folder:', newPaths[newi]
          @history.addPath newPaths[newi]
          oldi--
        @finderTool.updateButtonStatus()
      oldi++
      newi++
    @fileInfo.update()

  openUri: (uri) ->
    console.log 'openUrl: ' + uri if @debug
    fs ?= require 'fs'
    fs.exists uri, (exists) ->
      if (exists)
        open ?= require 'open'
        open uri

  updateEntireWindowCongig: ->
    if atom.config.get('tree-view-finder.entireWindow')
      @fitWidth()
    else
      @unfitWidth()

  updateDebugFlags: ->
      @debug = atom.config.get('tree-view-finder.debugTreeViewFinder')
      @fileInfo.debug = atom.config.get('tree-view-finder.debugFileInfo')
      @finderTool.debug = atom.config.get('tree-view-finder.debugFinderTool')
      @history.debug = atom.config.get('tree-view-finder.debugHistory')

history = ->
  index: 0
  stack: []
  debug: false

  initialize: ->
    @stack.push atom.project.getPaths()
    console.log 'tree-view-finder: history.initialize:' if @debug
    @printStatus '  stack:' if @debug

  push: (paths) ->
    console.log 'tree-view-finder: history.push:' if @debug
    @printStatus '  stack:' if @debug
    @stack.length = @index + 1  # truncate forward history
    @stack.push paths
    @index = @stack.length - 1
    atom.project.setPaths paths
    @printStatus '     ==>' if @debug

  canBack: ->
    return 0 < @index
  back: ->
    console.log 'tree-view-finder: history.back:' if @debug
    @printStatus '  stack:' if @debug
    if @canBack()
      @index--
      atom.project.setPaths @stack[@index]
      @printStatus '     ==>' if @debug

  canForw: ->
    return @index < @stack.length - 1
  forw: ->
    console.log 'tree-view-finder: history.forw:' if @debug
    @printStatus '  stack:' if @debug
    if @canForw()
      @index++
      atom.project.setPaths @stack[@index]
      @printStatus '     ==>' if @debug

  canGoHome: ->
    return 0 < @index
  goHome: ->
    console.log 'tree-view-finder: history.goHome:' if @debug
    @printStatus '  stack:' if @debug
    if @canGoHome()
      @index = 0
      atom.project.setPaths @stack[@index]
      @printStatus '     ==>' if @debug

  addPath: (path) ->
    console.log 'tree-view-finder: history.addPath:' if @debug
    @printStatus '  stack:' if @debug
    for paths in @stack
      paths.push(path)
    @printStatus '     ==>' if @debug

  removePath: (idx) ->
    console.log 'tree-view-finder: history.removePath:' if @debug
    @printStatus '  stack:' if @debug
    for paths in @stack
      paths.splice(idx, 1)
    @printStatus '     ==>' if @debug

  getCurrentPaths: ->
    return @stack[@index].slice(0)  # return clone of the array

  printStatus: (header) ->
    console.log header,
      'length =', @stack.length, ', index=', @index, ', @stack =', @stack
