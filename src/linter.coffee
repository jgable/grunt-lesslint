_ = require 'underscore'

getLessLineNumber = (cssLine='') ->
  if match = /^\s*\/\* line (\d+), .* \*\/\s*$/.exec(cssLine)
    parseInt(match[1]) - 1
  else
    -1

getPropertyName = (line='') ->
  line = line.trim()
  colon = line.indexOf(':')
  if colon > 0
    line.substring(0, colon)
  else
    null

findLessLineNumber = (css='', lineNumber=0) ->
  if _.isString(css)
    lines = css.split('\n')
  else
    lines = css

  lineNumber = Math.max(0, Math.min(lineNumber, lines.length - 1))

  commentLine = lineNumber
  lessLineNumber = -1
  while commentLine >= 0
    lessLineNumber = getLessLineNumber(lines[commentLine])
    if lessLineNumber >= 0
      return lessLineNumber
    else
      commentLine--
  -1

findPropertyLineNumber = (contents='', lineNumber=0, propertyName='') ->
  return -1 unless contents and propertyName

  if _.isString(contents)
    lines = contents.split('\n')
  else
    lines = contents

  lineNumber = Math.max(0, Math.min(lineNumber, lines.length - 1))
  while lineNumber < lines.length
    return lineNumber if propertyName is getPropertyName(lines[lineNumber])
    lineNumber++
  -1

module.exports = {getPropertyName, findLessLineNumber, findPropertyLineNumber}
