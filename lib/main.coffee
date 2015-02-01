ExpandSelectionView = require './expand-selection-view'
{CompositeDisposable, Range} = require 'atom'

module.exports =
  activate: ->
    @views = []
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      view = new ExpandSelectionView(editor)
      @views.push view

  deactivate: ->
    @subscriptions.dispose()
    view.remove() for view in @views
