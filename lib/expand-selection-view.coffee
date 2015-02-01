_ = require 'underscore-plus'
{CompositeDisposable, Range} = require 'atom'
{View} = require 'atom-space-pen-views'
{findAnyStartPair, findMatchingEndPair} = require './utils'

module.exports =
class ExpandSelectionView extends View
  stringsRegex: /^string.quoted/
  sourceRegex: /^source./
  whitespaces: /^[ \t]*/

  stringMatchRegex: /(["'])(?:(?=(\\?))\2.)*?\1/gmi

  constructor: (@editor) ->
    @disposables = new CompositeDisposable
    @disposables.add atom.commands.add 'atom-workspace',
      'expand-selection:expand': =>
        # FIXME: There should be another way of reacting only in the current
        # text editor.
        @expand() if atom.workspace.getActiveTextEditor() == @editor

  destroy: ->
    @disposables.dispose()

  expand: ->
    # First of all select the word under cursor if not already selected.
    if (@editor.getLastSelection().isEmpty())
      @editor.selectWordsContainingCursors()
    else
      # Iterate over all cursors.
      for cursor in @editor.getCursors()
        @expandUnderCursor(cursor)

  # Expand the selection under the cursor.
  expandUnderCursor: (cursor) ->
    selection = @getSelectionOnCursor(@editor, cursor)
    return if not selection?

    testRange = @expandToQuotes(selection)
    return unless testRange?

    @editor.addSelectionForBufferRange(testRange)

  expandToQuotes: (selection) ->
    result = null
    @editor.scan @stringMatchRegex,
      (object) =>
        quotes = object.range
        return if quotes.end.isLessThan(selection.start)

        if quotes.start.isGreaterThan(selection.end)
          object.stop()
          return

        if selection.isEqual(quotes)
          object.stop()
          return

        quotesContent = @shrinkRange(quotes, 1)
        if selection.isEqual(quotesContent)
          result = quotes
          object.stop()
        else if quotes.containsRange(selection)
          result = quotesContent
          object.stop()

    return result

  skipScope: (scope) ->
    scope.isEmpty() or (scope.isSingleLine() and
      scope.end.column - scope.start.column < 2)

  # TODO: This can be optimized for sure.
  # Select selection range.
  getSelectionOnCursor: (editor, cursor) ->
    for range in editor.getSelectedBufferRanges()
      return range if range.containsPoint(cursor.getBufferPosition(), false)

  # Shrink a range by a given amount.
  shrinkRange: (range, amount) ->
    new Range(range.start.add([0, amount]), range.end.add([0, -amount]))

  # Check if range1 is a shrinked version of range2 by a given amount.
  isShrinkedRange: (range1, range2, amount) ->
    range1.start.add([0, -amount]).isEqual(range2.start) and
    range1.end.add([0, amount]).isEqual(range2.end)
