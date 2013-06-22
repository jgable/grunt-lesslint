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

parseLess = (grunt, file, options, callback) ->
  configLessOptions = options.less ? grunt.config.get('less.options')
  lessOptions = grunt.util._.extend({filename: file}, configLessOptions, defaultLessOptions)

  if less = grunt.file.read(file)
    parser = new Parser(lessOptions)
    parser.parse less, (error, tree) ->
      if error?
        callback(error)
      else
        callback(null, less, tree.toCSS())
  else
    callback(null, '', '')

lintCss = (grunt, css, options, callback) ->
  unless css
    callback(null, [])
    return

  rules = {}
  CSSLint.getRules().forEach ({id}) -> rules[id] = 1

  cssLintOptions = options.csslint ? grunt.config.get('csslint.options')
  for id, enabled of cssLintOptions
    if cssLintOptions[id]
      rules[id] = cssLintOptions[id]
    else
      delete rules[id]

  results = CSSLint.verify(css, rules)
  if results.messages?.length > 0
    callback(null, results.messages)
  else
    callback(null, [])

getLessLineNumber = (css, less, file, line) ->
  cssLines = css.split('\n')
  return -1 unless 0 <= line < cssLines.length

  {lineNumber, filePath} = findLessMapping(cssLines, line)
  return -1 unless filePath is path.resolve(process.cwd(), file)

  lessLines = less.split('\n')
  if 0 <= lineNumber < lessLines.length
    if cssPropertyName = getPropertyName(cssLines[line])
      propertyNameLineNumber = findPropertyLineNumber(lessLines, lineNumber, cssPropertyName)
      lineNumber = propertyNameLineNumber if propertyNameLineNumber >= 0

  if 0 <= lineNumber < lessLines.length
    lineNumber
  else
    -1

isFileError = (file, css, line) ->
  {filePath} = findLessMapping(css, line)
  filePath is path.resolve(process.cwd(), file)

module.exports = (grunt) ->
  grunt.registerMultiTask 'lesslint', 'Validate LESS files with CSS Lint', ->
    options = @options()
    fileCount = 0
    errorCount = 0

    queue = async.queue (file, callback) ->
      grunt.verbose.write("Linting '#{file}'")
      fileCount++

      parseLess grunt, file, options, (error, less, css) ->
        if error?
          errorCount++
          grunt.log.writeln("Error parsing #{file.yellow}")
          grunt.log.writeln(error.message)
          return

        lintCss grunt, css, options, (error, messages=[]) ->
          messages = messages.filter (message) ->
            isFileError(file, css, message.line - 1)

          if messages.length > 0
            grunt.log.writeln("#{file.yellow} (#{messages.length})")

            messages = grunt.util._.groupBy messages, ({message}) -> message
            for ruleMessage, ruleMessages of messages
              rule = ruleMessages[0].rule
              fullRuleMessage = "#{ruleMessage} "
              fullRuleMessage += "#{rule.desc} " if rule.desc and rule.desc isnt ruleMessage
              grunt.log.writeln(fullRuleMessage + "(#{rule.id})".grey)

              for {line} in ruleMessages
                line--
                errorCount++
                continue if line < 0

                lessLineNumber = getLessLineNumber(css, less, file, line)
                if lessLineNumber >= 0
                  errorPrefix = "#{lessLineNumber + 1}:".yellow
                  grunt.log.error("#{errorPrefix} #{less.split('\n')[lessLineNumber].trim()}")
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
      if errorCount is 0
        grunt.log.ok("#{fileCount} #{grunt.util.pluralize(fileCount, 'file/files')} lint free.")
        done()
      else
        grunt.log.writeln()
        grunt.log.error("#{errorCount} lint #{grunt.util.pluralize(errorCount, 'error/errors')} in #{fileCount} #{grunt.util.pluralize(fileCount, 'file/files')}.")
        done(false)
