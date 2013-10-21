{CSSLint} = require 'csslint'
{Parser} = require 'less'
{findLessMapping, findPropertyLineNumber, getPropertyName} = require './lint-utils'
async = require 'async'
path = require 'path'

defaultLessOptions =
  compress: false
  dumpLineNumbers: 'comments'
  optimization: null
  syncImport: true
  yuicompress: false

module.exports = (grunt) ->
  {stripPath} = require('grunt-lib-contrib').init grunt

  parseLess = (file, options, callback) ->
    configLessOptions = options.less ? grunt.config.get('less.options')
    lessOptions = grunt.util._.extend({filename: file}, configLessOptions, defaultLessOptions)

    if less = grunt.file.read(file)
      parser = new Parser(lessOptions)
      try
        parser.parse less, (error, tree) ->
          if error?
            callback(error)
          else
            callback(null, less, tree.toCSS())
      catch error
        callback(error)
    else
      callback(null, '', '')

  lintCss = (css, options, callback) ->
    unless css
      callback(null, [])
      return

    rules = {}
    externalOptions = {}
    CSSLint.getRules().forEach ({id}) -> rules[id] = 1

    cssLintOptions = options.csslint ? grunt.config.get('csslint.options')
    if cssLintOptions?.csslintrc
      externalOptions = grunt.file.readJSON cssLintOptions.csslintrc
      delete cssLintOptions.csslintrc

    grunt.util._.extend(cssLintOptions, externalOptions)

    for id, enabled of cssLintOptions
      if cssLintOptions[id]
        rules[id] = cssLintOptions[id]
      else
        delete rules[id]

    result = CSSLint.verify(css, rules)
    if result.messages?.length > 0
      callback(null, result)
    else
      callback()

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
    return unless grunt.util._.isArray(formatters)

    formatters.forEach ({id, dest}) ->
      return unless id and dest

      formatter = CSSLint.getFormatter(id)
      return unless formatter?

      formatterOutput = formatter.startFormat()
      for filePath, result of results
        formatterOutput += formatter.formatResults(result, filePath, {})
      formatterOutput += formatter.endFormat()
      grunt.file.write(dest, formatterOutput)


  grunt.registerMultiTask 'lesslint', 'Validate LESS files with CSS Lint', ->
    options = @options()
    importsToLint = options.imports ? []
    fileCount = 0
    errorCount = 0
    results = {}

    queue = async.queue (file, callback) ->
      grunt.verbose.write("Linting '#{file}'")
      fileCount++

      parseLess file, options, (error, less, css) ->
        if error?
          errorCount++
          grunt.log.writeln("Error parsing #{file.yellow}")
          grunt.log.writeln(error.message)
          callback()
          return

        lintCss css, options, (error, result={}) ->
          messages = result.messages ? []
          messages = messages.filter (message) ->
            isFileError(file, css, message.line - 1, importsToLint)

          if messages.length > 0
            results[file] = result
            grunt.log.writeln("#{file.yellow} (#{messages.length})")

            messages = grunt.util._.groupBy messages, ({message}) -> message
            for ruleMessage, ruleMessages of messages
              rule = ruleMessages[0].rule
              fullRuleMessage = "#{ruleMessage} "
              fullRuleMessage += "#{rule.desc} " if rule.desc and rule.desc isnt ruleMessage
              grunt.log.writeln(fullRuleMessage + "(#{rule.id})".grey)

              for message in ruleMessages
                line = message.line
                line--
                errorCount++
                continue if line < 0

                {lineNumber, filePath, less} = originalPositionFor(css, less, file, line)

                if lineNumber >= 0
                  message.line = lineNumber
                  errorPrefix = "#{stripPath(filePath, process.cwd())} #{lineNumber + 1}:".yellow

                  grunt.log.error("#{errorPrefix} #{less.split('\n')[lineNumber].trim()}")
                else
                  cssLine = css.split('\n')[line]
                  if cssLine?
                    errorPrefix = "#{line + 1}:".yellow
                    grunt.log.error("#{errorPrefix} #{cssLine.trim()}")

                  grunt.log.writeln("Failed to find map CSS line #{line + 1} to a LESS line.".yellow)

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
