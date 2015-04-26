FinderTool = require './finder-tool'
{CompositeDisposable} = require 'atom'
FileInfo = require './file-info'
xorTap = require './doubleTap.js/xorTap'
open = null
fs = null

module.exports = TreeViewFinder =
  config:
    debugTreeViewFinder:
      type: 'boolean'
      default: true
      title: 'Enable debug information from tree-view-finder.coffee'
    debugFinderTool:
      type: 'boolean'
      default: true
      title: 'Enable debug information from finder-tool.coffee'
    debugFileInfo:
      type: 'boolean'
      default: true
      title: 'Enable debug information from file-info.coffee'

  subscriptions: null
  treeView: null
  visible: false

  activate: (state) ->
    @finderTool = new FinderTool()
    @fileInfo = new FileInfo()
    @updateDebugFlags()
    console.log 'tree-view-finder: activate' if @debug

    @subscriptions = new CompositeDisposable

    treeViewPkg = atom.packages.getLoadedPackage('tree-view')
    console.log 'tree-view-finder: create TreeView' if @debug
    @treeView = treeViewPkg.mainModule.createView()

    @finderTool.initialize(this)
    @fileInfo.initialize(@treeView)
    @handleEvents()

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'tree-view-finder:toggle': => @toggle()

  deactivate: ->
    console.log 'tree-view-finder: deactivate' if @debug
    @subscriptions.dispose()
    @finderTool.destroy()

  serialize: ->
    #treeViewFinderViewState: @treeViewFinderView.serialize()

  toggle: ->
    if @visible
      @hide();
    else
      @show();

  show: ->
    console.log 'tree-view-finder: show()' if @debug

    # XXX, check if there is the tree-view
    if not @treeView.panel
      console.log 'tree-view-finder: show(): @treeView.panel =', @treeView.panel
      return 

    @visible = true
    @finderTool.attach()

    workspaceElement = atom.views.getView(atom.workspace)
    workspaceElement.querySelector('atom-workspace-axis.vertical').classList.add('tree-view-finder-fit')

    @fileInfo.show()
    @fitWidth()
    window.onresize = () =>
      console.log 'Window innerWidth:', window.innerWidth if @debug
      @fitWidth()

  hide: ->
    console.log 'tree-view-finder: hide()' if @debug
    @visible = false
    @fileInfo.hide()
    workspaceElement = atom.views.getView(atom.workspace)
    workspaceElement.querySelector('atom-workspace-axis.vertical').classList.remove('tree-view-finder-fit')
    @finderTool.detach()
    @unfitWidth()

  fitWidth: ->
    return if not @visible
    if !@resizer
      @resizer = atom.views.getView(atom.workspace).querySelector('.tree-view-resizer')
      @resizerOriginalWidth = @resizer.style.width
    @resizer.style.width = window.innerWidth + 'px'

  unfitWidth: ->
    if @resizer
      @resizer.style.width = @resizerOriginalWidth
      @resizer = null

  handleEvents: ->
    console.log 'tree-view-finder: handleEvents: install click handler' if @debug
    @treeView.off 'click'
    xorhandler = new xorTap(
      (e) =>
        console.log 'tree-view-finder: click!', e if @debug
        @treeView.entryClicked(e)
        @fileInfo.update()
      ,
      (e) =>
        console.log 'tree-view-finder: double click!', e, e.currentTarget.classList if @debug
        if e.currentTarget.classList.contains('directory')
          console.log 'tree-view-finder: double click: directory' if @debug
          console.log 'tree-view-finder: cd ' + e.target.dataset.path if @debug
          atom.project.setPaths [e.target.dataset.path]
        else if e.currentTarget.classList.contains('file')
          console.log 'tree-view-finder: double click: file' if @debug
          @openUri(e.target.dataset.path)
      )
    click_ts = 0
    @treeView.on 'click', '.entry', (e) =>
      #console.log 'tree-view-finder: click event', e if @debug
      if (click_ts != e.timeStamp)
        click_ts = e.timeStamp
        return if e.target.classList.contains('entries')
        return if e.shiftKey or e.metaKey or e.ctrlKey
        xorhandler(e)
    console.log 'tree-view-finder: handleEvents: on click...done' if @debug

    @subscriptions.add atom.project.onDidChangePaths =>
      @updateRoots()

    @subscriptions.add atom.config.onDidChange 'tree-view-finder.debugTreeViewFinder', =>
      @updateDebugFlags()
    @subscriptions.add atom.config.onDidChange 'tree-view-finder.debugFinderTool', =>
      @updateDebugFlags()
    @subscriptions.add atom.config.onDidChange 'tree-view-finder.debugFileInfo', =>
      @updateDebugFlags()

  updateRoots: ->
    console.log 'tree-view-finder: updateRoots' if @debug
    for projectPath in atom.project.getPaths()
      console.log "updateRoots: " + path.basename(projectPath) if @debug
    @fileInfo.update()

  openUri: (uri) ->
    console.log 'openUrl: ' + uri if @debug
    fs ?= require 'fs'
    fs.exists uri, (exists) ->
      if (exists)
        open ?= require 'open'
        open uri

  updateDebugFlags: ->
      @debug = atom.config.get('tree-view-finder.debugTreeViewFinder')
      @fileInfo.debug = atom.config.get('tree-view-finder.debugFinderTool')
      @finderTool.debug = atom.config.get('tree-view-finder.debugFileInfo')
