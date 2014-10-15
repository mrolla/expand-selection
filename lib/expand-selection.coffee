{Subscriber} = require 'emissary'

module.exports =
class ExpandSelection
    Subscriber.includeInto(this)

    stringScope = 'string.quoted.'
    whitespaces = /^[ \t]*/

    constructor: ->
        @subscribeToCommand atom.workspaceView, 'expand-selection:expand', =>
            if editor = atom.workspace.getActiveEditor()
                @expand(editor)

    destroy: ->
        @unsubscribe()

    expand: (editor) ->
        # First of all select the word under cursor if not already selected.
        if editor.getLastSelection().isEmpty()
            editor.selectWordsContainingCursors();
            return

        cursors = editor.getCursors()

        # Iterate over all cursors.
        for cursor in cursors
            # Go outward from the innermost scope and select the first one that includes unselected text
            cursorPosition = cursor.getBufferPosition()

            # TODO: This can be optimized for sure.
            # Select selection range.
            selection = null
            for range in editor.getSelectedBufferRanges()
                if range.containsPoint(cursorPosition, false)
                    selection = range
                    break

            return unless selection

            for scope in cursor.getScopes().slice().reverse()
                # FIXME: Using the display buffer directly may not be the best choice.
                scopeRange = editor.displayBuffer.bufferRangeForScopeAtPosition(scope, cursorPosition)
                fullRange = cursor.getCurrentLineBufferRange()

                # Expand to the string except the quotes.
                if scope.indexOf(stringScope) == 0 and !expandStringRange(selection, scopeRange)
                    scopeRange.start.column = scopeRange.start.column + 1
                    scopeRange.end.column = scopeRange.end.column - 1
                # Scope range is full row.
                else if scopeRange.containsRange(fullRange)
                    editor.scanInBufferRange whitespaces, scopeRange, ({range}) ->
                      scopeRange.start = range.end

                # Check we are not re-applying the same range and that the new range
                # does really contain the old one.
                if !scopeRange.isEqual(selection) and scopeRange.containsRange(selection)
                    editor.addSelectionForBufferRange(scopeRange)
                    break

    # Check if the range is a string range minus the quotes.
    expandStringRange = (range1, range2) ->
        range1.start.row == range2.start.row and range1.end.row == range2.end.row and
            range1.start.column - 1 == range2.start.column and range1.end.column + 1 == range2.end.column
