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

    describe 'when the imported file is not included in the `imports` configuration option', ->
      it 'does not report error from imports', ->
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
