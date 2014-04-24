fs = require 'fs'
path = require 'path'
grunt = require 'grunt'
_ = require 'lodash'

LintErrorOutput = require '../tasks/lib/lint-error-output'

exampleErrorResult = JSON.parse(fs.readFileSync(path.join(__dirname, 'fixtures', 'lintresult.json')))

describe 'lint-error-output', ->
  describe 'LintErrorOutput', ->
    
    it 'can process errors with no lines', (done) ->
      testResult = _.clone(exampleErrorResult)
      testResult.sourceMap = JSON.parse(testResult.sourceMap)
      output = new LintErrorOutput(testResult, grunt)

      results = ''
      addResults = (msg) -> results += msg + '\n'
      
      spyOn(grunt.log, 'writeln').andCallFake addResults
      spyOn(grunt.log, 'error').andCallFake addResults
      spyOn(grunt.file, 'isMatch').andCallFake -> return
      spyOn(grunt.file, 'read').andCallFake -> ''

      output.display()

      expect(results).toContain('selector-max')
      expect(results).toContain('selector-max-approaching')
      expect(results).toContain('font-sizes')
      expect(results).toContain('font-faces')
      expect(results).toContain('floats')

      done()