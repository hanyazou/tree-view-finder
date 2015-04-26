{requirePackages} = require 'atom-utils'
fs = require 'fs-plus'

module.exports =
class FileInfo
  visible: false
  debug: false

  constructor: () ->

  destroy: ->

  initialize: ->
    console.log 'file-info: initialize' if @debug

  show: (treeView) ->
    console.log 'file-info: show: treeView =', treeView if @debug
    return if not treeView
    @treeView = treeView
    @visible = true
    @update()

  hide: ->
    console.log 'file-info: hide' if @debug
    @visible = false
    @update()
    @treeView = null

  update: ->
    if @treeView?
      if @visible
        @add()
      else
        @delete()

  delete:->
    console.log 'file-info: delete' if @debug
    elements = @treeView.element.querySelectorAll '.file.entry.list-item .file-info'
    for element in elements
      element.classList.remove('file-info')
      element.classList.remove('file-info-debug') if @debug
    elements = @treeView.element.querySelectorAll '.file.entry.list-item .file-info-added'
    for element in elements
      element.remove()

  add: ->
      console.log 'file-info: add' if @debug
      fileEntries = @treeView.element.querySelectorAll '.file.entry.list-item'
      for fileEntry in fileEntries
        name = fileEntry.querySelector 'span.name'
        if not name.classList.contains('file-info')
          name.classList.add('file-info')
          name.classList.add('file-info-debug') if @debug
          stat = fs.statSyncNoException(name.dataset.path)

          padding = document.createElement('span')
          padding.textContent = '\u00A0'  # XXX
          padding.classList.add('file-info-added')
          padding.classList.add('file-info-padding')
          padding.classList.add('file-info-debug') if @debug
          name.parentNode.appendChild(padding)

          size = document.createElement('span')
          size.textContent = stat.size
          size.classList.add('file-info-added')
          size.classList.add('file-info-size')
          size.classList.add('file-info-debug') if @debug
          name.parentNode.appendChild(size)

          date = document.createElement('span')
          date.textContent = stat.mtime
          date.classList.add('file-info-added')
          date.classList.add('file-info-mdate')
          date.classList.add('file-info-debug') if @debug
          name.parentNode.appendChild(date)

      console.log 'file-info: add...done' if @debug
      @updateWidth()

  updateWidth: (nameWidth = @nameWidth, sizeWidth = @sizeWidth, mdateWidth = @mdateWidth) ->
    console.log 'file-info: updateWidth', nameWidth, sizeWidth, mdateWidth if @debug
    @nameWidth = nameWidth
    @sizeWidth = sizeWidth
    @mdateWidth = mdateWidth
    console.log 'file-info: updateWidth' if @debug
    if @treeView and @visible
      fileEntries = @treeView.element.querySelectorAll '.file.entry.list-item'
      for fileEntry in fileEntries
        name = fileEntry.querySelector 'span.name'
        [padding] = name.parentNode.querySelectorAll '.file-info-padding'
        [size] = name.parentNode.querySelectorAll '.file-info-size'
        [mdate] = name.parentNode.querySelectorAll '.file-info-mdate'

        padding.style.width = @nameWidth - name.getBoundingClientRect().left - name.getBoundingClientRect().width + 'px'
        console.log 'updateWidth:', padding.style.marginRight, @nameWidth, name.getBoundingClientRect().left, name.getBoundingClientRect().width + 'px' if @debug
        size.style.width = @sizeWidth + 'px'
        mdate.style.width = @mdateWidth+ 'px'
