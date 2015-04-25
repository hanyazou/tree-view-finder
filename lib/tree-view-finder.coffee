TreeViewFinderView = require './tree-view-finder-view'
{CompositeDisposable} = require 'atom'

module.exports = TreeViewFinder =
  treeViewFinderView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @treeViewFinderView = new TreeViewFinderView(state.treeViewFinderViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @treeViewFinderView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'tree-view-finder:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @treeViewFinderView.destroy()

  serialize: ->
    treeViewFinderViewState: @treeViewFinderView.serialize()

  toggle: ->
    console.log 'TreeViewFinder was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
