fs = require 'fs'
path = require 'path'

grunt = require 'grunt'
tmp = require 'tmp'
{parseString} = require 'xml2js'

describe 'LESS Lint task', ->
  it 'reports errors based on LESS line information', ->
    grunt.config.init
      pkg: grunt.file.readJSON(path.join(__dirname, 'fixtures', 'package.json'))

      lesslint:
        src: ['**/fixtures/file.less']

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
      expect(taskOutput).toContain '#id {'
      expect(taskOutput).toContain '4 lint errors in 1 file.'

  describe 'when the less file is empty', ->
    it 'does not log an error', ->
      grunt.config.init
        pkg: grunt.file.readJSON(path.join(__dirname, 'fixtures', 'package.json'))

        lesslint:
          src: ['**/fixtures/empty.less']

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
          expect(taskOutput).toContain '#id {'
          expect(taskOutput).toContain '4 lint errors in 1 file.'
          expect(taskOutput).not.toContain 'Failed to find map CSS'

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
          expect(taskOutput).toContain '#id {'
          expect(taskOutput).toContain '4 lint errors in 1 file.'
          expect(taskOutput).not.toContain 'Failed to find map CSS'

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
        expect(errors[3].$.line).toBe '10'

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
        expect(taskOutput).toContain '1 lint error in 1 file'

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
        expect(taskOutput).toContain '1 lint error in 1 file'

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
        expect(taskOutput).toContain '1 lint error in 1 file'

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
