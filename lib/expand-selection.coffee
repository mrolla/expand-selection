{Subscriber} = require 'emissary'

module.exports =
class ExpandSelection
    Subscriber.includeInto(this)

    stringScope: 'string.quoted.'
    whitespaces: /^[ \t]*/

    constructor: ->
        @subscribeToCommand atom.workspaceView, 'expand-selection:expand', =>
            if editor = atom.workspace.getActiveEditor()
                @expand(editor)

    destroy: ->
        @unsubscribe()

    expand: (editor) ->
        # First of all select the word under cursor if not already selected.
        return editor.selectWordsContainingCursors() if editor.getLastSelection().isEmpty()

        cursors = editor.getCursors()

        # Iterate over all cursors.
        for cursor in cursors
            selection = @getSelectionOnCursor(editor, cursor)
            break if not selection?

            cursorPosition = cursor.getBufferPosition()
            fullRange = cursor.getCurrentLineBufferRange()

            return editor.selectAll() if fullRange.isEqual(selection)

            for scope in cursor.getScopes().slice().reverse()
                # FIXME: Using the display buffer directly may not be the best choice.
                scopeRange = editor.displayBuffer.bufferRangeForScopeAtPosition(scope, cursorPosition)

                # Expand to the string except the quotes.
                if scope.indexOf(@stringScope) is 0
                    @getStringRange(selection, scopeRange)
                # Scope range is full row.
                else if scopeRange.containsRange(fullRange)
                    editor.scanInBufferRange @whitespaces, scopeRange,
                        ({range}) -> scopeRange.start = range.end
                    scopeRange = fullRange if scopeRange.isEqual(selection)

                # Check we are not re-applying the same range and that the new range
                # does really contain the old one.
                if not scopeRange.isEqual(selection) and scopeRange.containsRange(selection)
                    editor.addSelectionForBufferRange(scopeRange)
                    break

    getStringRange: (selection, scope) ->
        if not @expandStringRange(selection, scope)
            scope.start.column = scope.start.column + 1
            scope.end.column = scope.end.column - 1
        scope

    # TODO: This can be optimized for sure.
    # Select selection range.
    getSelectionOnCursor: (editor, cursor) ->
        for range in editor.getSelectedBufferRanges()
            return range if range.containsPoint(cursor.getBufferPosition(), no)

    # Check if the range is a string range minus the quotes.
    expandStringRange: (range1, range2) ->
        range1.start.row is range2.start.row and range1.end.row is range2.end.row and
            range1.start.column - 1 is range2.start.column and range1.end.column + 1 is range2.end.column
