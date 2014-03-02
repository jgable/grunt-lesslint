fs = require 'fs'
path = require 'path'
linter = require '../tasks/lib/lint-utils'

describe 'lint-utils', ->
  describe '.findLessMapping()', ->
    it 'returns the line number and path from the comment', ->
      css = fs.readFileSync(path.join(__dirname, 'fixtures', 'file.css'), 'utf8')
      expect(linter.findLessMapping(css, 0).lineNumber).toBe 0
      expect(linter.findLessMapping(css, 0).filePath).toBe '/repos/grunt-lesslint/spec/fixtures/file.less'
      expect(linter.findLessMapping(css, 5).lineNumber).toBe 6
      expect(linter.findLessMapping(css, 5).filePath).toBe '/repos/grunt-lesslint/spec/fixtures/imports.less'

  describe '.getPropertyName()', ->
    it 'returns the property on the given line', ->
      expect(linter.getPropertyName()).toBe null
      expect(linter.getPropertyName(null)).toBe null
      expect(linter.getPropertyName('')).toBe null

      css = fs.readFileSync(path.join(__dirname, 'fixtures', 'file.css'), 'utf8').split('\n')
      expect(linter.getPropertyName(css[0])).toBe null
      expect(linter.getPropertyName(css[1])).toBe null
      expect(linter.getPropertyName(css[2])).toBe 'padding'
      expect(linter.getPropertyName(css[3])).toBe 'margin'
      expect(linter.getPropertyName(css[4])).toBe null
      expect(linter.getPropertyName(css[5])).toBe null
      expect(linter.getPropertyName(css[6])).toBe null
      expect(linter.getPropertyName(css[7])).toBe 'border-width'
      expect(linter.getPropertyName(css[8])).toBe null

      less = fs.readFileSync(path.join(__dirname, 'fixtures', 'file.less'), 'utf8').split('\n')
      expect(linter.getPropertyName(less[0])).toBe null
      expect(linter.getPropertyName(less[1])).toBe 'padding'
      expect(linter.getPropertyName(less[2])).toBe null
      expect(linter.getPropertyName(less[3])).toBe null
      expect(linter.getPropertyName(less[4])).toBe 'margin'
      expect(linter.getPropertyName(less[5])).toBe null
      expect(linter.getPropertyName(less[6])).toBe null
      expect(linter.getPropertyName(less[7])).toBe 'border-width'
      expect(linter.getPropertyName(less[8])).toBe null
      expect(linter.getPropertyName(less[9])).toBe null
      expect(linter.getPropertyName(less[10])).toBe null
      expect(linter.getPropertyName(less[11])).toBe 'height'
      expect(linter.getPropertyName(less[12])).toBe null
      expect(linter.getPropertyName(less[13])).toBe null
      expect(linter.getPropertyName(less[14])).toBe 'width'

  describe '.findPropertyLineNumber()', ->
    it 'returns the line number of the next line with the given property name', ->
      less = fs.readFileSync(path.join(__dirname, 'fixtures', 'file.less'), 'utf8')
      expect(linter.findPropertyLineNumber(less, 0, 'padding')).toBe 1
      expect(linter.findPropertyLineNumber(less, 2, 'padding')).toBe -1
      expect(linter.findPropertyLineNumber(less, 4, 'margin')).toBe 4
      expect(linter.findPropertyLineNumber(less, null, 'border-width')).toBe 7
      expect(linter.findPropertyLineNumber(less, Infinity, 'border-width')).toBe -1
