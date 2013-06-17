{CSSLint} = require 'csslint'
{Parser} = require 'less'
_ = require 'underscore'
{findLessLineNumber, findPropertyLineNumber, getPropertyName} = require './lint-utils'

defaultLessOptions =
  compress: false
  dumpLineNumbers: 'comments'
  optimization: null
  syncImport: true
  yuicompress: false

module.exports = (grunt) ->
  grunt.registerMultiTask 'lesslint', 'Validate LESS files with CSS Lint', ->
    configLessOptions = @options.less ? grunt.config.get('less.options')
    lessOptions = grunt.util._.extend({}, configLessOptions, defaultLessOptions)
    parser = new Parser(lessOptions)

    fileCount = 0
    errorCount = 0

    rules = {}
    CSSLint.getRules().forEach ({id}) -> rules[id] = 1

    cssLintOptions = @options.csslint ? grunt.config.get('csslint.options')
    for id, enabled of cssLintOptions
      if cssLintOptions[id]
        rules[id] = cssLintOptions[id]
      else
        delete rules[id]

    @filesSrc.forEach (file) ->
      grunt.verbose.write("Linting '#{file}'")
      fileCount++

      less = grunt.file.read(file)
      return unless less

      parser.parse less, (error, tree) ->
        if error?
          errorCount++
          grunt.log.writeln("Error parsing #{file.yellow}")
          grunt.log.writeln(error.message)
        else
          css = tree.toCSS()
          return unless css

          results = CSSLint.verify(css, rules)
          return unless results.messages?.length > 0

          grunt.log.writeln("#{file.yellow} (#{results.messages.length})")

          lessLines = less.split('\n')
          cssLines = css.split('\n')

          messages = _.groupBy results.messages, (message) -> message.message
          for ruleMessage, ruleMessages of messages
            rule = ruleMessages[0].rule
            fullRuleMessage = "#{ruleMessage} "
            fullRuleMessage += "#{rule.desc} " if rule.desc and rule.desc isnt ruleMessage
            grunt.log.writeln(fullRuleMessage + "(#{rule.id})".grey)

            for {line, message, rule} in ruleMessages
              line--
              continue unless line >= 0

              lessLineNumber = findLessLineNumber(cssLines, line)
              if lessLineNumber >= 0
                if cssPropertyName = getPropertyName(cssLines[line])
                  propertyNameLineNumber = findPropertyLineNumber(lessLines, lessLineNumber, cssPropertyName)
                  lessLineNumber = propertyNameLineNumber if propertyNameLineNumber >=0

                errorCount++
                errorPrefix = "#{lessLineNumber + 1}:".yellow
                grunt.log.error("#{errorPrefix} #{lessLines[lessLineNumber].trim()}")
              else
                errorPrefix = "#{line + 1}:".yellow
                grunt.log.error("#{errorPrefix} #{cssLines[line].trim()}")
                grunt.log.writeln("Failed to find map CSS line #{line + 1} to a LESS line.".yellow)

    if errorCount is 0
      grunt.log.ok("#{fileCount} #{grunt.util.pluralize(fileCount, 'file/files')} lint free.")
    else
      grunt.log.writeln()
      grunt.log.error("#{errorCount} linting #{grunt.util.pluralize(errorCount, 'error/errors')} in #{fileCount} #{grunt.util.pluralize(fileCount, 'file/files')}.")
      false
