url                   = require 'url'
{CompositeDisposable} = require 'atom'

ArtPreviewView       = require './flying-art-preview-view'

module.exports =
  config:
    triggerOnSave:
      type: 'boolean'
      description: 'Watch will trigger on save.'
      default: false
    preserveWhiteSpaces:
      type: 'boolean'
      description: 'Preserve white spaces and line endings.'
      default: false
    fileEndings:
      type: 'array'
      title: 'Preserve file endings'
      description: 'File endings to preserve'
      default: ["c", "h"]
      items:
        type: 'string'
    enableMathJax:
      type: 'boolean'
      description: 'Enable MathJax inline rendering \\f$ \\pi \\f$'
      default: false

  htmlPreviewView: null

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      @subscriptions.add editor.onDidSave =>
        if htmlPreviewView? and htmlPreviewView instanceof ArtPreviewView
          htmlPreviewView.renderHTML()

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'flying-art-preview:toggle': => @toggle()

    atom.workspace.addOpener (uriToOpen) ->
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        return

      return unless protocol is 'flying-art-preview:'

      try
        pathname = decodeURI(pathname) if pathname
      catch error
        return

      if host is 'editor'
        @htmlPreviewView = new ArtPreviewView(editorId: pathname.substring(1))
      else
        @htmlPreviewView = new ArtPreviewView(filePath: pathname)

      return htmlPreviewView

  toggle: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    uri = "flying-art-preview://editor/#{editor.id}"

    previewPane = atom.workspace.paneForURI(uri)
    if previewPane
      previewPane.destroyItem(previewPane.itemForURI(uri))
      return

    previousActivePane = atom.workspace.getActivePane()
    atom.workspace.open(uri, split: 'right', searchAllPanes: true).done (htmlPreviewView) ->
      if htmlPreviewView instanceof ArtPreviewView
        htmlPreviewView.renderHTML()
        previousActivePane.activate()

  deactivate: ->
    @subscriptions.dispose()
