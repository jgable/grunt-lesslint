fs = require 'fs'
path = require 'path'
crypto = require 'crypto'

grunt = require 'grunt'
tmp = require 'tmp'
{parseString} = require 'xml2js'
{LintCache} = require '../tasks/lib/lint-cache'

_ = require 'lodash'

describe 'LESS Lint task', ->
  it 'reports errors based on LESS line information', ->
    grunt.config.init
      pkg: grunt.file.readJSON(path.join(__dirname, 'fixtures', 'package.json'))

      lesslint:
        src: ['**/fixtures/file.less']

    grunt.loadTasks(path.resolve(__dirname, '..', 'tasks'))
    tasksDone = false
    grunt.registerTask 'done', 'done', -> tasksDone = true
    output = []
    spyOn(process.stdout, 'write').andCallFake (data='') ->
      output.push(data.toString())

    errorCount = 0
    grunt.task.options({
      error: ->
        errorCount++
    })
    grunt.task.run(['lesslint', 'done']).start()

    waitsFor -> tasksDone
    runs ->
      taskOutput = output.join('')
      expect(taskOutput).toContain 'padding: 0px;'
      expect(taskOutput).toContain 'margin: 0em;'
      expect(taskOutput).toContain 'border-width: 0pt;'
      expect(taskOutput).toContain '4 lint issues in 1 file (0 errors, 4 warnings)'
      # A little bit of a hack until csslint reports first id column instead of 0
      hasIdorBodyError = taskOutput.indexOf('#id {') > -1 || taskOutput.indexOf('body {') > -1
      expect(hasIdorBodyError).toBe true
      expect(errorCount).toBe 1

  it 'issues return code 0, if failOnError is set to false', ->
    grunt.config.init
      pkg: grunt.file.readJSON(path.join(__dirname, 'fixtures', 'package.json'))

      lesslint:
        src: ['**/fixtures/file.less']
        options:
          failOnError: false

    grunt.loadTasks(path.resolve(__dirname, '..', 'tasks'))
    tasksDone = false
    grunt.registerTask 'done', 'done',  -> tasksDone = true
    output = []
    spyOn(process.stdout, 'write').andCallFake (data='') ->
      output.push(data.toString())

    errorCount = 0
    grunt.task.options({
      error: ->
        errorCount++
    })
    grunt.task.run(['lesslint', 'done']).start()

    waitsFor -> tasksDone
    runs ->
      expect(errorCount).toBe 0

  it 'issues return code 0, if failOnWarning is set to false, with failed rule warnings', ->
    grunt.config.init
      pkg: grunt.file.readJSON(path.join(__dirname, 'fixtures', 'package.json'))

      lesslint:
        src: ['**/fixtures/imports.less']
        options:
          imports: ['**/fixtures/file.less']
          failOnWarning: false

    grunt.loadTasks(path.resolve(__dirname, '..', 'tasks'))
    tasksDone = false
    grunt.registerTask 'done', 'done',  -> tasksDone = true
    output = []
    spyOn(process.stdout, 'write').andCallFake (data='') ->
      output.push(data.toString())

    errorCount = 0
    grunt.task.options({
      error: ->
        errorCount++
    })
    grunt.task.run(['lesslint', 'done']).start()

    waitsFor -> tasksDone
    runs ->
      expect(errorCount).toBe 0

  it 'issues return code 1, if failOnWarning is set to false, with failed rule errors', ->
    grunt.config.init
      pkg: grunt.file.readJSON(path.join(__dirname, 'fixtures', 'package.json'))

      lesslint:
        src: ['**/fixtures/invalid.less']
        options:
          failOnWarning: false

    grunt.loadTasks(path.resolve(__dirname, '..', 'tasks'))
    tasksDone = false
    grunt.registerTask 'done', 'done',  -> tasksDone = true
    output = []
    spyOn(process.stdout, 'write').andCallFake (data='') ->
      output.push(data.toString())

    errorCount = 0
    grunt.task.options({
      error: ->
        errorCount++
    })
    grunt.task.run(['lesslint', 'done']).start()

    waitsFor -> tasksDone
    runs ->
      expect(errorCount).toBe 1

  describe 'when the less file is empty', ->
    it 'does not log an error', ->
      grunt.config.init
        pkg: grunt.file.readJSON(path.join(__dirname, 'fixtures', 'package.json'))

        lesslint:
          src: [
            '**/fixtures/empty.less',
            '**/fixtures/really-empty.less'
          ]

      grunt.loadTasks(path.resolve(__dirname, '..', 'tasks'))
      tasksDone = false
      grunt.registerTask 'done', 'done',  -> tasksDone = true
      output = []
      spyOn(process.stdout, 'write').andCallFake (data='') ->
        output.push(data.toString())
      grunt.task.run(['lesslint', 'done']).start()
      waitsFor -> tasksDone
      runs ->
        taskOutput = output.join('')
        expect(taskOutput).toContain '2 files lint free'

  describe 'when the file has imports', ->
    describe 'when the imported file is included in the `imports` configuration option', ->
      it 'reports the errors from the imports', ->
        grunt.config.init
          pkg: grunt.file.readJSON(path.join(__dirname, 'fixtures', 'package.json'))

          lesslint:
            src: ['**/fixtures/imports.less']
            options:
              imports: ['**/fixtures/file.less']

        grunt.loadTasks(path.resolve(__dirname, '..', 'tasks'))
        tasksDone = false
        grunt.registerTask 'done', 'done',  -> tasksDone = true
        output = []

        spyOn(process.stdout, 'write').andCallFake (data='') ->
          output.push(data.toString())

        grunt.task.run(['lesslint', 'done']).start()
        waitsFor -> tasksDone
        runs ->
          taskOutput = output.join('')
          expect(taskOutput).toContain 'padding: 0px;'
          expect(taskOutput).toContain 'margin: 0em;'
          expect(taskOutput).toContain 'border-width: 0pt;'
          expect(taskOutput).toContain '4 lint issues in 1 file (0 errors, 4 warnings)'
          expect(taskOutput).not.toContain 'Failed to find map CSS'

          # A little bit of a hack until csslint reports first id column instead of 0
          hasIdorBodyError = taskOutput.indexOf('#id {') > -1 || taskOutput.indexOf('body {') > -1
          expect(hasIdorBodyError).toBe true

      it 'reports the errors from the imports even if they are not given by a globbing pattern', ->
        grunt.config.init
          pkg: grunt.file.readJSON(path.join(__dirname, 'fixtures', 'package.json'))

          lesslint:
            src: ['**/fixtures/imports.less']
            options:
              imports: ['spec/fixtures/file.less']

        grunt.loadTasks(path.resolve(__dirname, '..', 'tasks'))
        tasksDone = false
        grunt.registerTask 'done', 'done',  -> tasksDone = true
        output = []

        spyOn(process.stdout, 'write').andCallFake (data='') ->
          output.push(data.toString())

        grunt.task.run(['lesslint', 'done']).start()
        waitsFor -> tasksDone
        runs ->
          taskOutput = output.join('')
          expect(taskOutput).toContain 'padding: 0px;'
          expect(taskOutput).toContain 'margin: 0em;'
          expect(taskOutput).toContain 'border-width: 0pt;'
          expect(taskOutput).toContain '4 lint issues in 1 file (0 errors, 4 warnings)'
          expect(taskOutput).not.toContain 'Failed to find map CSS'

          # A little bit of a hack until csslint reports first id column instead of 0
          hasIdorBodyError = taskOutput.indexOf('#id {') > -1 || taskOutput.indexOf('body {') > -1
          expect(hasIdorBodyError).toBe true

    describe 'when the imported file is not included in the `imports` configuration option', ->
      it 'does not report errors from imports', ->
        grunt.config.init
          pkg: grunt.file.readJSON(path.join(__dirname, 'fixtures', 'package.json'))

          lesslint:
            src: ['**/fixtures/imports.less']

        grunt.loadTasks(path.resolve(__dirname, '..', 'tasks'))
        tasksDone = false
        grunt.registerTask 'done', 'done',  -> tasksDone = true
        output = []
        spyOn(process.stdout, 'write').andCallFake (data='') ->
          output.push(data.toString())
        grunt.task.run(['lesslint', 'done']).start()
        waitsFor -> tasksDone
        runs ->
          taskOutput = output.join('')
          expect(taskOutput).toContain '1 file lint free'

  describe 'when a formatter is specified in the configuration options', ->
    reportFile = null

    beforeEach ->
      tmp.file (error, tempFile) -> reportFile = tempFile
      waitsFor -> reportFile?

    it 'outputs the lint errors to that formatter', ->
      expect(fs.statSync(reportFile).size).toBe 0

      grunt.config.init
        pkg: grunt.file.readJSON(path.join(__dirname, 'fixtures', 'package.json'))

        lesslint:
          src: ['**/fixtures/file.less']
          options:
            formatters: [
              id: 'csslint-xml'
              dest: reportFile
            ]

      grunt.loadTasks(path.resolve(__dirname, '..', 'tasks'))
      tasksDone = false
      grunt.registerTask 'done', 'done',  -> tasksDone = true
      output = []
      spyOn(process.stdout, 'write').andCallFake (data='') ->
        output.push(data.toString())
      grunt.task.run(['lesslint', 'done']).start()
      waitsFor -> tasksDone
      runs ->
        reportXml = fs.readFileSync(reportFile, 'utf8')
        expect(reportXml.length).toBeGreaterThan 0
        report = null
        parseString reportXml, (error, parsedReport) -> report = parsedReport
        errors = report.csslint.file[0].issue
        expect(errors.length).toBe 4
        expect(errors[0].$.line).toBe '1'
        expect(errors[1].$.line).toBe '4'
        expect(errors[2].$.line).toBe '7'

        # A little hack for csslint not reporting proper column on ids in selectors
        reportedEitherBodyOrIdLine = errors[3].$.line == '10' || errors[3].$.line == '0'
        expect(reportedEitherBodyOrIdLine).toBe true

  describe 'when the less file does not compile', ->
    it 'reports the compile errors for missing imports', ->
      grunt.config.init
        pkg: grunt.file.readJSON(path.join(__dirname, 'fixtures', 'package.json'))

        lesslint:
          src: ['**/fixtures/invalid.less']

      grunt.loadTasks(path.resolve(__dirname, '..', 'tasks'))
      tasksDone = false
      grunt.registerTask 'done', 'done',  -> tasksDone = true
      output = []
      spyOn(process.stdout, 'write').andCallFake (data='') ->
        output.push(data.toString())
      grunt.task.run(['lesslint', 'done']).start()
      waitsFor -> tasksDone
      runs ->
        taskOutput = output.join('')
        expect(taskOutput).toContain "'does-not-exist.less' wasn't found"
        expect(taskOutput).toContain '1 lint issue in 1 file (1 error, 0 warnings)'

    it 'reports the compile errors for missing functions', ->
      grunt.config.init
        pkg: grunt.file.readJSON(path.join(__dirname, 'fixtures', 'package.json'))

        lesslint:
          src: ['**/fixtures/missing-function.less']

      grunt.loadTasks(path.resolve(__dirname, '..', 'tasks'))
      tasksDone = false
      grunt.registerTask 'done', 'done',  -> tasksDone = true
      output = []
      spyOn(process.stdout, 'write').andCallFake (data='') ->
        output.push(data.toString())
      grunt.task.run(['lesslint', 'done']).start()
      waitsFor -> tasksDone
      runs ->
        taskOutput = output.join('')
        expect(taskOutput).toContain '.notAFunction is undefined'
        expect(taskOutput).toContain '1 lint issue in 1 file (1 error, 0 warnings)'

  describe 'when the file has less options', ->
    describe 'when the less options contains paths', ->
      it 'will respect the passed paths', ->
        grunt.config.init
          pkg: grunt.file.readJSON(path.join(__dirname, 'fixtures', 'package.json'))

          lesslint:
            src: ['**/fixtures/included-path.less']
            options:
              less:
                paths: ['spec/included-path']

        grunt.loadTasks(path.resolve(__dirname, '..', 'tasks'))
        tasksDone = false
        grunt.registerTask 'done', 'done',  -> tasksDone = true
        output = []

        spyOn(process.stdout, 'write').andCallFake (data='') ->
          output.push(data.toString())

        grunt.task.run(['lesslint', 'done']).start()
        waitsFor -> tasksDone
        runs ->
          taskOutput = output.join('')
          expect(taskOutput).toContain '1 file lint free.'

  describe 'when csslint option csslintrc is set', ->
    it 'reads css options from csslintrc file', ->
      grunt.config.init
        pkg: grunt.file.readJSON(path.join(__dirname, 'fixtures', 'package.json'))

        lesslint:
          options:
            csslint:
              csslintrc: 'spec/fixtures/.csslintrc'
          src: ['**/fixtures/csslintrc.less']

      grunt.loadTasks(path.resolve(__dirname, '..', 'tasks'))
      tasksDone = false
      grunt.registerTask 'done', 'done',  -> tasksDone = true
      output = []
      spyOn(process.stdout, 'write').andCallFake (data='') ->
        output.push(data.toString())
      grunt.task.run(['lesslint', 'done']).start()
      waitsFor -> tasksDone
      runs ->
        taskOutput = output.join('')
        expect(taskOutput).toContain 'margin: 0 !important'
        expect(taskOutput).toContain '1 lint issue in 1 file (0 errors, 1 warning)'

    it 'reads css options from csslintrc file and picks up other rules as well', ->
      grunt.config.init
        pkg: grunt.file.readJSON(path.join(__dirname, 'fixtures', 'package.json'))

        lesslint:
          options:
            csslint:
              important: false
              csslintrc: 'spec/fixtures/.csslintrc'
          src: ['**/fixtures/csslintrc.less']

      grunt.loadTasks(path.resolve(__dirname, '..', 'tasks'))
      tasksDone = false
      grunt.registerTask 'done', 'done',  -> tasksDone = true
      output = []
      spyOn(process.stdout, 'write').andCallFake (data='') ->
        output.push(data.toString())
      grunt.task.run(['lesslint', 'done']).start()
      waitsFor -> tasksDone
      runs ->
        taskOutput = output.join('')
        expect(taskOutput).toContain '1 file lint free'

    describe 'when csslintrc contains comments', ->
      it 'removes the comments before parsing the JSON', ->
        grunt.config.init
          pkg: grunt.file.readJSON(path.join(__dirname, 'fixtures', 'package.json'))

          lesslint:
            options:
              csslint:
                csslintrc: 'spec/fixtures/.csslintrc-comments'
            src: ['**/fixtures/csslintrc.less']

        grunt.loadTasks(path.resolve(__dirname, '..', 'tasks'))
        tasksDone = false
        grunt.registerTask 'done', 'done',  -> tasksDone = true
        output = []
        spyOn(process.stdout, 'write').andCallFake (data='') ->
          output.push(data.toString())
        grunt.task.run(['lesslint', 'done']).start()
        waitsFor -> tasksDone
        runs ->
          taskOutput = output.join('')
          expect(taskOutput).toContain 'margin: 0 !important'
          expect(taskOutput).toContain '1 lint issue in 1 file (0 errors, 1 warning)'

  describe 'when cache option is set', ->
    it 'caches previously linted files for faster performance', ->
      grunt.config.init
        pkg: grunt.file.readJSON(path.join(__dirname, 'fixtures', 'package.json'))

        lesslint:
          options:
            cache: true
          src: ['**/fixtures/valid.less']

      grunt.loadTasks(path.resolve(__dirname, '..', 'tasks'))
      taskCount = 0
      tasksDone = false

      addCacheHash = null
      cacheHits = 0
      addCacheHit = (filePath, cachePath) ->
        cacheHits += 1
      grunt.event.on 'lesslint.cache.hit', addCacheHit

      cacheAdds = 0
      addCacheAdd = (filePath, cacheHash) ->
        cacheAdds += 1
        addCacheHash = cacheHash
      grunt.event.on 'lesslint.cache.add', addCacheAdd

      grunt.registerTask 'done', 'done',  ->
        taskCount++

        if taskCount == 2
          return tasksDone = true

        grunt.task.run(['lesslint', 'done']).start()
      output = []
      spyOn(process.stdout, 'write').andCallFake (data='') ->
        output.push(data.toString())

      grunt.task.run(['lesslint', 'done']).start()
      waitsFor -> tasksDone
      runs ->
        # Remove the event listeners
        grunt.event.off 'lesslint.cache.hit', addCacheHit
        grunt.event.off 'lesslint.cache.add', addCacheAdd

        taskOutput = output.join('')
        expect(taskOutput).toContain '1 file lint free'
        # should be called both times
        expect(cacheHits).toBe(1)
        # should only be called the first time
        expect(cacheAdds).toBe(1)

        expect(addCacheHash).toNotEqual null
        expect(addCacheHash).toNotEqual ''

  describe 'when custom CSSLint rules configured', ->
    it 'finds a violation of a custom rule', ->
      grunt.config.init
        pkg: grunt.file.readJSON(path.join(__dirname, 'fixtures', 'package.json'))

        lesslint:
          options:
            customRules: ['**/fixtures/custom-rule.coffee']
          src: ['**/fixtures/custom-invalid.less']

      grunt.loadTasks(path.resolve(__dirname, '..', 'tasks'))
      tasksDone = false
      grunt.registerTask 'done', 'done', -> tasksDone = true
      output = []
      spyOn(process.stdout, 'write').andCallFake (data='') ->
        output.push(data.toString())

      errorCount = 0
      grunt.task.options({
        error: ->
          errorCount++
      })
      grunt.task.run(['lesslint', 'done']).start()

      waitsFor -> tasksDone
      runs ->
        taskOutput = output.join('')
        expect(taskOutput).toContain 'BACKGROUND-COLOR: #FFF;'
        expect(taskOutput).toContain 'Uppercase letters looks bad. Properties should be in lowercase. (lowercase-properties)'
        expect(taskOutput).toContain '1 lint issue in 1 file (0 errors, 1 warning)'
        expect(errorCount).toBe 1

    it 'does not disable the default CSSLint rule set', ->
      grunt.config.init
        pkg: grunt.file.readJSON(path.join(__dirname, 'fixtures', 'package.json'))

        lesslint:
          options:
            customRules: ['**/fixtures/custom-rule.coffee']
          src: ['**/fixtures/file.less']

      grunt.loadTasks(path.resolve(__dirname, '..', 'tasks'))
      tasksDone = false
      grunt.registerTask 'done', 'done', -> tasksDone = true
      output = []
      spyOn(process.stdout, 'write').andCallFake (data='') ->
        output.push(data.toString())

      errorCount = 0
      grunt.task.options({
        error: ->
          errorCount++
      })
      grunt.task.run(['lesslint', 'done']).start()

      waitsFor -> tasksDone
      runs ->
        taskOutput = output.join('')
        expect(taskOutput).toContain 'padding: 0px;'
        expect(taskOutput).toContain 'margin: 0em;'
        expect(taskOutput).toContain 'border-width: 0pt;'
        expect(taskOutput).toContain '4 lint issues in 1 file (0 errors, 4 warnings)'

        # A little bit of a hack until csslint reports first id column instead of 0
        hasIdorBodyError = taskOutput.indexOf('#id {') > -1 || taskOutput.indexOf('body {') > -1
        expect(hasIdorBodyError).toBe true
        expect(errorCount).toBe 1

    it 'does not allow custom rule configurations to affect on other targets executed later', ->
      grunt.config.init
        pkg: grunt.file.readJSON(path.join(__dirname, 'fixtures', 'package.json'))

        lesslint:
          customRulesEnabled:
            options:
              customRules: ['**/fixtures/custom-rule.coffee']
            src: ['**/fixtures/custom-invalid.less']
          customRulesDisabled:
            src: ['**/fixtures/custom-invalid.less', '**/fixtures/file.less']

      grunt.loadTasks(path.resolve(__dirname, '..', 'tasks'))
      tasksDone = false
      grunt.registerTask 'done', 'done', -> tasksDone = true
      output = []
      spyOn(process.stdout, 'write').andCallFake (data='') ->
        output.push(data.toString())

      errorCount = 0
      grunt.task.options({
        error: ->
          errorCount++
      })
      grunt.task.run(['lesslint:customRulesEnabled', 'lesslint:customRulesDisabled', 'done']).start()

      waitsFor -> tasksDone
      runs ->
        taskOutput = output.join('')
        expect(taskOutput).toContain '4 lint issues in 2 files (0 errors, 4 warnings)'
        expect(errorCount).toBe 2

    it 'allows the same custom rule configurations to be used on other targets executed later', ->
      grunt.config.init
        pkg: grunt.file.readJSON(path.join(__dirname, 'fixtures', 'package.json'))

        lesslint:
          customRuleEnabled1:
            options:
              customRules: ['**/fixtures/custom-rule.coffee']
            src: ['**/fixtures/custom-invalid.less']
          customRuleEnabled2:
            options:
              customRules: ['**/fixtures/custom-rule.coffee']
            src: ['**/fixtures/custom-invalid.less', '**/fixtures/valid.less']

      grunt.loadTasks(path.resolve(__dirname, '..', 'tasks'))
      tasksDone = false
      grunt.registerTask 'done', 'done', -> tasksDone = true
      output = []
      spyOn(process.stdout, 'write').andCallFake (data='') ->
        output.push(data.toString())

      errorCount = 0
      grunt.task.options({
        error: ->
          errorCount++
      })
      grunt.task.run(['lesslint:customRuleEnabled1', 'lesslint:customRuleEnabled2', 'done']).start()

      waitsFor -> tasksDone
      runs ->
        taskOutput = output.join('')
        expect(taskOutput).toContain '1 lint issue in 2 files (0 errors, 1 warning)'
        expect(errorCount).toBe 2
