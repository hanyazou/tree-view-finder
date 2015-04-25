{requirePackages} = require 'atom-utils'
fs = require 'fs-plus'

module.exports =
class FileInfo
  visible: false
  debug: false

  constructor: () ->

  destroy: ->

  initialize: (treeView) ->
    console.log 'file-info: initialize', treeView if @debug
    @treeView = treeView
    @update()

  show: ->
    console.log 'file-info: show' if @debug
    @visible = true
    @update()

  hide: ->
    console.log 'file-info: hide' if @debug
    @visible = false
    @update()

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
          stat = fs.statSyncNoException(name.dataset.path)

          padding = document.createElement('span')
          padding.classList.add('file-info-added')
          padding.classList.add('file-info-padding')
          name.parentNode.appendChild(padding)

          size = document.createElement('span')
          size.textContent = stat.size
          size.style.display = 'inline-block'
          size.classList.add('file-info-added')
          size.classList.add('file-info-size')
          name.parentNode.appendChild(size)

          date = document.createElement('span')
          date.textContent = stat.mtime
          date.style.display = 'inline-block'
          date.classList.add('file-info-added')
          date.classList.add('file-info-mdate')
          name.parentNode.appendChild(date)

          if @debug
            #name.style.borderStyle = 'solid'
            #name.style.borderWidth = '1px'
            #padding.style.borderStyle = 'solid'
            #padding.style.borderWidth = '1px'
            padding.textContent = '#'
            padding.style.backgroundColor = 'red'
            #size.style.borderStyle = 'solid'
            #size.style.borderWidth = '1px'
            size.style.backgroundColor = '#808080'
            #date.style.borderStyle = 'solid'
            #date.style.borderWidth = '1px'
            date.style.backgroundColor = '#A0A0A0'
            #end.style.borderStyle = 'solid'
            #end.style.borderWidth = '1px'
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

        padding.style.marginRight = @nameWidth - name.getBoundingClientRect().left - name.getBoundingClientRect().width + 'px'
        console.log 'updateWidth:', padding.style.marginRight, @nameWidth, name.getBoundingClientRect().left, name.getBoundingClientRect().width + 'px' if @debug
        size.style.width = @sizeWidth + 'px'
        mdate.style.width = @mdateWidth+ 'px'
