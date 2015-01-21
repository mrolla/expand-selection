ExpandSelectionView = require './expand-selection-view'

module.exports =
  activate: ->
    @view = new ExpandSelectionView()

  deactivate: ->
    @view?.destroy()
