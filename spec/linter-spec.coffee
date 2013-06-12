fs = require 'fs'
path = require 'path'
linter = require '../tasks/linter'

describe "linter", ->
  describe ".findLessLineNumber()", ->
    css = fs.readFileSync(path.join(__dirname, 'fixtures', 'file.css'), 'utf8')
    expect(linter.findLessLineNumber(css, 0)).toBe 0
    expect(linter.findLessLineNumber(css, 5)).toBe 6
