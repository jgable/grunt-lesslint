
{SourceMapConsumer} = require 'source-map'
_ = require 'underscore'
chalk = require 'chalk'
stripPath = require 'strip-path'

class LintErrorOutput
  constructor: (@result, @grunt) ->

  display: (importsToLint) ->
    sourceMap = new SourceMapConsumer(@result.sourceMap)
    
    # Keep track of number of errors displayed
    errorCount = 0

    # Shorthand references to result values
    messages = @result.lint.messages
    less = @result.less
    file = @result.file

    fileContents = {}
    fileLines = {}

    # Filter out imports we didn't pass as options.import
    messages = messages.filter (message) =>
      # Grab the original contents
      {source} = sourceMap.originalPositionFor
        line: message.line,
        column: message.col

      isThisFile = source == file

      return isThisFile or @grunt.file.isMatch importsToLint, source

    # Bug out if only import errors we don't care about
    return 0 if messages.length < 1

    # Group the errors by message
    messageGroups = _.groupBy messages, ({message}) -> message

    # Output how many rules broken
    @grunt.log.writeln("#{chalk.yellow(file)} (#{messages.length})")

    # For each rule message and messages
    for ruleMessage, ruleMessages of messageGroups
      # Parse the rule and description
      rule = ruleMessages[0].rule
      fullRuleMessage = "#{ruleMessage} "
      fullRuleMessage += "#{rule.desc} " if rule.desc and rule.desc isnt ruleMessage

      # Output the rule broken
      @grunt.log.writeln(fullRuleMessage + chalk.grey("(#{rule.id})"))

      for message in ruleMessages
        errorCount += 1

        # Grab the original contents
        {line, column, source} = sourceMap.originalPositionFor
          line: message.line,
          column: message.col

        isThisFile = source == file

        # Store this for later access by reporters
        message.lessLine = { line, column }
        
        # Get the contents and split into lines if not already done
        unless fileContents[source]
          if isThisFile
            # We can avoid a file read if this is our current file
            fileContents[source] = less
          else
            # Otherwise, read from disk
            fileContents[source] = @grunt.file.read source

          # Pre-emptively split into lines
          fileLines[source] = fileContents[source].split('\n')

        filePath = stripPath(file, process.cwd())
        lessSource = fileLines[source][line-1].slice(column)

        # Output the source line
        @grunt.log.error(chalk.gray("[Line #{line}, Column #{column+1}]:\t")+ " #{lessSource.trim()}")

    errorCount

module.exports = LintErrorOutput
