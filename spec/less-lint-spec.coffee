path = require 'path'
grunt = require 'grunt'

describe 'LESS Lint task', ->
  it 'reports errors based on LESS line information', ->
    grunt.config.init
      pkg: grunt.file.readJSON(path.join(__dirname, 'fixtures', 'package.json'))

      lesslint:
        src: ['**/fixtures/*.less']

    grunt.loadTasks(path.resolve(__dirname, '..', 'tasks'))
    called = false
    grunt.registerTask 'done', 'done',  ->
      called = true
    output = []
    spyOn(process.stdout, 'write').andCallFake (data='') ->
      output.push(data.toString())
    grunt.task.run(['lesslint', 'done']).start()
    waitsFor -> called
    runs ->
      taskOutput = output.join('')
      expect(taskOutput).toContain 'padding: 0px;'
      expect(taskOutput).toContain 'margin: 0em;'
      expect(taskOutput).toContain 'border-width: 0pt;'
      expect(taskOutput).toContain '#id {'
      expect(taskOutput).toContain '4 linting errors in 1 file.'
