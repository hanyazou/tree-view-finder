TreeViewFinder = require '../lib/tree-view-finder'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "TreeViewFinder", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('tree-view-finder')
    waitsForPromise ->
      atom.packages.activatePackage('tree-view')

  describe "when the tree-view-finder:toggle event is triggered", ->
    it "hides and shows the tool bar", ->
      # Before the activation event the view is not on the DOM, and no panel
      # has been created
      expect(workspaceElement.querySelector('.tree-view-finder-tool')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'tree-view-finder:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(workspaceElement.querySelector('.tree-view-finder-tool')).toExist()

        finderTool = workspaceElement.querySelector('tree-view-finder-tool')
        expect(finderTool).toExist()
        treeViewFinder = finderTool.treeViewFinder
        expect(treeViewFinder).not.toBe null

        expect(treeViewFinder.visible).toBe true
        atom.commands.dispatch workspaceElement, 'tree-view-finder:toggle'
        expect(treeViewFinder.visible).toBe false
