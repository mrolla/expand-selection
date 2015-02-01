_ = require 'underscore-plus'

startPairMatches =
  '(': ')'
  '[': ']'
  '{': '}'

endPairMatches =
  ')': '('
  ']': '['
  '}': '{'

pairRegexes = {}
for startPair, endPair of startPairMatches
  pairRegexes[startPair] =
    new RegExp("[#{_.escapeRegExp(startPair + endPair)}]", 'g')

# Bracket matching regexes.
combinedRegExp: /[\(\[\{\)\]\}]/g
startPairRegExp: /[\(\[\{]/g
endPairRegExp: /[\)\]\}]/g

# Find a suitable open bracket in the editor from a given position backward.
# Borrowed some code from the atom's bracket-matcher package.
findAnyStartPair: (editor, fromPosition) ->
  scanRange = new Range([0, 0], fromPosition)
  startPosition = null
  unpairedCount = 0
  editor.backwardsScanInBufferRange combinedRegExp, scanRange,
    ({match, range, stop}) ->
      if match[0].match(endPairRegExp)
        unpairedCount++
      else if match[0].match(startPairRegExp)
        unpairedCount--
        startPosition = range.start
        stop() if unpairedCount < 0
  startPosition

# Find a matching closed bracket in the editor from a given position.
# Borrowed some code from the atom's bracket-matcher package.
findMatchingEndPair: (editor, fromPosition, startPair) ->
  endPair = startPairMatches[startPair]
  scanRange = new Range(fromPosition, editor.buffer.getEndPosition())
  endPairPosition = null
  unpairedCount = 0
  editor.scanInBufferRange pairRegexes[startPair], scanRange,
    ({match, range, stop}) ->
      switch match[0]
        when startPair
          unpairedCount++
        when endPair
          unpairedCount--
          if unpairedCount < 0
            endPairPosition = range.start
            stop()

  endPairPosition?.add([0, 1])



findMatchingQuotes: (editor) ->
