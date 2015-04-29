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
      @updateWidth()

  updateWidth: (nameWidth = @nameWidth, sizeWidth = @sizeWidth, mdateWidth = @mdateWidth) ->
    console.log 'file-info: updateWidth:', nameWidth, sizeWidth, mdateWidth if @debug
    @nameWidth = nameWidth
    @sizeWidth = sizeWidth
    @mdateWidth = mdateWidth

    if @treeView and @visible
      ol = @treeView.element.querySelector '.tree-view'
      if @debug
        console.log "file-info: updateWidth: querySelector('.tree-view') =",
          ol, ol.getBoundingClientRect()
      @offset = ol.getBoundingClientRect().left
      @fileEntries = @treeView.element.querySelectorAll '.file.entry.list-item'
      @fileEntryIndex = 0
      clearInterval(@timer)
      console.log 'file-info: update thread...' if @debug
      console.log 'file-info: update thread...', @updateThread if @debug
      @timer = setInterval(@updateThread, 1)

  updateThread: =>
      if not @treeView or not @visible
        clearInterval(@timer)
        @timer = null
        @fileEntries = null
        return

      cost = 0
      while fileEntry = @fileEntries[@fileEntryIndex++]
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
          size.textContent = @toSizeString(stat.size)
          size.classList.add('file-info-added')
          size.classList.add('file-info-size')
          size.classList.add('file-info-debug') if @debug
          name.parentNode.appendChild(size)

          date = document.createElement('span')
          date.textContent = @toDateString(stat.mtime)
          date.classList.add('file-info-added')
          date.classList.add('file-info-mdate')
          date.classList.add('file-info-debug') if @debug
          name.parentNode.appendChild(date)

        name = fileEntry.querySelector 'span.name'
        [padding] = name.parentNode.querySelectorAll '.file-info-padding'
        [size] = name.parentNode.querySelectorAll '.file-info-size'
        [mdate] = name.parentNode.querySelectorAll '.file-info-mdate'

        rect = name.getBoundingClientRect()
        margin = @nameWidth - (rect.left - @offset + rect.width)
        if margin < 10
          padding.style.marginRight = margin + 'px'
          padding.style.width = '0px'
        else
          padding.style.marginRight = '0px'
          padding.style.width = margin + 'px'
        if @debug
          console.log 'file-info: updateWidth:', @fileEntryIndex-1 + ':',
            padding.style.width, padding.style.marginRight,
            '(' + @nameWidth + ' - ' + (rect.left - @offset) + ' - ' + rect.width + ')'
        size.style.width = @sizeWidth + 'px'
        mdate.style.width = @mdateWidth+ 'px'
        if 50 < ++cost
          return

      console.log 'file-info: update thread...done' if @debug
      clearInterval(@timer)

  toSizeString: (size) ->
    if size < 1
      return 'Zero bytes'
    if size < 2
      return '1 byte'
    if size < 1000
      return size + ' bytes'
    if size < 999500
      return Math.round(size/1000)/1 + ' KB'
    if size < 999950000
      return Math.round(size/100000)/10 + ' MB'
    return Math.round(size/10000000)/100 + ' GB'

  toDateString: (date) ->
    shortMonth = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    res = new Date(date + '')
    shortMonth[res.getMonth()] + ' ' + res.getDate() + ', ' + 
      res.getFullYear() + ', ' + res.getHours() + ':' + res.getMinutes()
