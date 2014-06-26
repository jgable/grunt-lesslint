{CSSLint} = require 'csslint'
{Parser} = require 'less'
{findLessMapping, findPropertyLineNumber, getPropertyName} = require './lib/lint-utils'
{LintCache} = require './lib/lint-cache'
{LessFile, LessCachedFile} = require './lib/less-file'
LintErrorOutput = require './lib/lint-error-output'
async = require 'async'
path = require 'path'
crypto = require 'crypto'
stripPath = require 'strip-path'
_ = require 'lodash'
chalk = require 'chalk'

defaultLessOptions =
  cleancss: false
  compress: false
  dumpLineNumbers: 'comments'
  optimization: null
  syncImport: true

module.exports = (grunt) ->

  writeToFormatters = (options, results) ->
    formatters = options.formatters
    return unless _.isArray(formatters)

    formatters.forEach ({id, dest}) ->
      return unless id and dest

      formatter = CSSLint.getFormatter(id)
      return unless formatter?

      formatterOutput = formatter.startFormat()
      for filePath, result of results
        # Update the source lines from source map info
        for message in result.messages
          if message.lessLine
            # We are subtracting 1 for backward compatibility, but I'm skeptical we should be
            message.line = message.lessLine.line - 1
            message.col = message.lessLine.column - 1

        formatterOutput += formatter.formatResults(result, filePath, {})
      formatterOutput += formatter.endFormat()
      grunt.file.write(dest, formatterOutput)

	if 0 is this.filesSrc.length
		return grunt.log.error("No files to process")

  grunt.registerMultiTask 'lesslint', 'Validate LESS files with CSS Lint', ->
    options = @options
      # Default to the less task options
      less: grunt.config.get('less.options')
      # Default to csslint task options
      csslint: grunt.config.get('csslint.options')
      # Default to no imports
      imports: undefined
      # Default to no caching
      cache: false

    fileCount = 0
    errorCount = 0
    results = {}

    queue = async.queue (file, callback) ->
      grunt.verbose.write("Linting '#{file}'")
      fileCount++

      unless options.cache
        lessFile = new LessFile(file, options, grunt)
      else
        lessFile = new LessCachedFile(file, options, grunt)

      lessFile.lint (err, result) ->
        if err?
          errorCount++
          grunt.log.writeln(err.message)
          return callback()

        result ||= {}

        lintResult = result.lint

        if lintResult
          # Save for later use in formatters
          results[file] = lintResult
          # Show error messages and get error count back
          errorOutput = new LintErrorOutput(result, grunt)
          fileLintErrors = errorOutput.display(options.imports)

          errorCount += fileLintErrors

        callback()

    @filesSrc.forEach (file) -> queue.push(file)

    done = @async()
    queue.drain = ->
      writeToFormatters(options, results)

      if errorCount is 0
        grunt.log.ok("#{fileCount} #{grunt.util.pluralize(fileCount, 'file/files')} lint free.")
        done()
      else
        grunt.log.writeln()
        grunt.log.error("#{errorCount} lint #{grunt.util.pluralize(errorCount, 'error/errors')} in #{fileCount} #{grunt.util.pluralize(fileCount, 'file/files')}.")
        done(false)

  grunt.registerTask 'lesslint:clearCache', ->
    done = @async()

    cache = new LintCache()

    cache.clear (err) ->
      grunt.log.error(err.message) if err

      done()
