{requirePackages} = require 'atom-utils'
fs = require 'fs-plus'

nameWidth = 300
sizeWidth = 80
dateWidth = 250

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
          padding.style.marginRight = nameWidth - name.getBoundingClientRect().left - name.getBoundingClientRect().width + 'px'
          padding.classList.add('file-info-added')
          name.appendChild(padding)

          size = document.createElement('span')
          size.textContent = stat.size
          size.style.display = 'inline-block'
          size.style.width = sizeWidth + 'px'
          size.classList.add('file-info-added')
          name.appendChild(size)

          date = document.createElement('span')
          date.textContent = stat.mtime
          date.style.display = 'inline-block'
          date.style.width = dateWidth+ 'px'
          date.classList.add('file-info-added')
          name.appendChild(date)

          if @debug
            end = document.createElement('span')
            end.textContent = ' ; '
            end.style.display = 'inline-block'
            end.style.width = '10px'
            name.appendChild(end)

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
