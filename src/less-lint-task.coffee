{CSSLint} = require 'csslint'
{Parser} = require 'less'
{findLessMapping, findPropertyLineNumber, getPropertyName} = require './lib/lint-utils'
{LintCache} = require './lib/lint-cache'
{LessFile, LessCachedFile} = require './lib/less-file'
async = require 'async'
path = require 'path'
crypto = require 'crypto'
stripPath = require 'strip-path'
_ = require 'underscore'
chalk = require 'chalk'

defaultLessOptions =
  cleancss: false
  compress: false
  dumpLineNumbers: 'comments'
  optimization: null
  syncImport: true

module.exports = (grunt) ->

  originalPositionFor = (css, less, file, line) ->
    cssLines = css.split('\n')
    return lineNumber: -1 unless 0 <= line < cssLines.length
    {lineNumber, filePath} = findLessMapping(cssLines, line)

    # Get imported source .less file.
    less = grunt.file.read(filePath) if filePath isnt path.resolve(process.cwd(), file)

    lessLines = less.split('\n')

    if 0 <= lineNumber < lessLines.length
      if cssPropertyName = getPropertyName(cssLines[line])
        propertyNameLineNumber = findPropertyLineNumber(lessLines, lineNumber, cssPropertyName)
        lineNumber = propertyNameLineNumber if propertyNameLineNumber >= 0

    if 0 <= lineNumber < lessLines.length
      lineNumber: lineNumber
      filePath: filePath
      less: less
    else
      lineNumber: -1
      filePath: filePath
      less: less

  isFileError = (file, css, line, importsToLint) ->
    {filePath} = findLessMapping(css, line)
    filePath is path.resolve(process.cwd(), file) or
      (filePath? and grunt.file.isMatch(importsToLint, stripPath(filePath, process.cwd())))

  writeToFormatters = (options, results) ->
    formatters = options.formatters
    return unless _.isArray(formatters)

    formatters.forEach ({id, dest}) ->
      return unless id and dest

      formatter = CSSLint.getFormatter(id)
      return unless formatter?

      formatterOutput = formatter.startFormat()
      for filePath, result of results
        formatterOutput += formatter.formatResults(result, filePath, {})
      formatterOutput += formatter.endFormat()
      grunt.file.write(dest, formatterOutput)

  # TODO: Refactor to a class somewhere
  processLintErrors = (file, importsToLint, result, less, css) ->
    messages = result.messages ? []
    messages = messages.filter (message) ->
      isFileError(file, css, message.line - 1, importsToLint)

    fileErrors = 0

    grunt.log.writeln("#{chalk.yellow(file)} (#{messages.length})")

    messages = _.groupBy messages, ({message}) -> message
    for ruleMessage, ruleMessages of messages
      rule = ruleMessages[0].rule
      fullRuleMessage = "#{ruleMessage} "
      fullRuleMessage += "#{rule.desc} " if rule.desc and rule.desc isnt ruleMessage
      grunt.log.writeln(fullRuleMessage + chalk.grey("(#{rule.id})"))

      for message in ruleMessages
        line = message.line
        line--
        fileErrors++
        continue if line < 0

        {lineNumber, filePath, less} = originalPositionFor(css, less, file, line)

        if lineNumber >= 0
          message.line = lineNumber
          errorPrefix = chalk.yellow("#{stripPath(filePath, process.cwd())} #{lineNumber + 1}:")

          grunt.log.error("#{errorPrefix} #{less.split('\n')[lineNumber].trim()}")
        else
          cssLine = css.split('\n')[line]
          if cssLine?
            errorPrefix = chalk.yellow("#{line + 1}:")
            grunt.log.error("#{errorPrefix} #{cssLine.trim()}")

          grunt.log.writeln(chalk.yellow("Failed to find map CSS line #{line + 1} to a LESS line."))

    fileErrors


  grunt.registerMultiTask 'lesslint', 'Validate LESS files with CSS Lint', ->
    options = @options
      # Default to the less task options
      less: grunt.config.get('less.options')
      # Default to csslint task options
      csslint: grunt.config.get('csslint.options')
      # Default to no imports
      imports: []
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

      lessFile.lint (err, lintResult, less, css) ->
        if err?
          errorCount++
          grunt.log.writeln(err.message)
          return callback()

        if lintResult
          # Save for later
          results[file] = lintResult
          # Show error messages
          fileLintErrors = processLintErrors(file, options.imports, lintResult, less, css)
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
