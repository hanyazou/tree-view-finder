FinderTool = require './finder-tool'
{CompositeDisposable} = require 'atom'
FileInfo = require './file-info'
xorTap = require './doubleTap.js/xorTap'
open = null
fs = null

module.exports = TreeViewFinder =
  subscriptions: null
  treeView: null
  debug: true
  visible: false

  activate: (state) ->
    console.log 'tree-view-finder: activate' if @debug
    @finderTool = new FinderTool()
    @finderTool.initialize()
    @fileInfo = new FileInfo()

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'tree-view-finder:toggle': => @toggle()

    @subscriptions.add atom.config.onDidChange 'tree-view-finder.debug', =>
      debug = atom.config.get('tree-view-finder.debug')

    atom.packages.activatePackage('tree-view').then (treeViewPkg) =>
      console.log 'tree-view-finder: create TreeView' if @debug
      @treeView = treeViewPkg.mainModule.createView()
      @fileInfo.initialize(@treeView)
      @alterTreeView()
      @handleEvents()

  deactivate: ->
    console.log 'tree-view-finder: deactivate' if @debug
    @subscriptions.dispose()
    @finderTool.destroy()

  serialize: ->
    #treeViewFinderViewState: @treeViewFinderView.serialize()

  toggle: ->
    console.log 'TreeViewFinder was toggled!'

    if @visible
      @hide();
    else
      @show();

  show: ->
    console.log 'tree-view-finder: show()' if @debug
    @visible = true
    @finderTool.attach()

    @fileInfo.show()
    @fitWidth()
    window.onresize = () =>
      console.log 'Window innerWidth:', window.innerWidth if @debug
      @fitWidth()

  hide: ->
    console.log 'tree-view-finder: hide()' if @debug
    @visible = false
    @fileInfo.hide()
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

  alterTreeView: ->
    console.log 'tree-view-finder: alterTreeView', @treeView.roots if @debug

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
