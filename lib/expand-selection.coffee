module.exports =
  activate: (state) ->
    atom.workspaceView.command "expand-selection:expand", => @expand()

  expand: ->
    editor = atom.workspace.activePaneItem
    cursors = editor?.getCursors()

    # Give up if this happens, there may not be an open editor
    return unless cursors

    # First of all select the word under cursor if not already selected.
    if editor.getLastSelection().isEmpty()
        editor.selectWordsContainingCursors();
        return

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
            if scope.indexOf("string.quoted.") == 0 and !expandStringRange(selection, scopeRange)
                scopeRange.start.column = scopeRange.start.column + 1
                scopeRange.end.column = scopeRange.end.column - 1

            # Scope range is full row.
            if scopeRange.containsRange(fullRange)
                editor.scanInBufferRange /^[ \t]*/, scopeRange, ({range}) ->
                  scopeRange.start = range.end

            # Check we are not re-applying the same range and that the new range
            # does really contain the old one.
            if !scopeRange.isEqual(selection) and scopeRange.containsRange(selection)
                editor.addSelectionForBufferRange(scopeRange)
                break

# Check if the range is a string range minus the quotes.
expandStringRange = (range1, range2) ->
    range1.start.row == range2.start.row && range1.end.row == range2.end.row &&
        range1.start.column - 1 == range2.start.column && range1.end.column + 1 == range2.end.column
