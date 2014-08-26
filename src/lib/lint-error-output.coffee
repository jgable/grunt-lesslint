
path = require 'path'

{SourceMapConsumer} = require 'source-map'
_ = require 'lodash'
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
    file = path.resolve(@result.file)

    filePath = stripPath(file, process.cwd())
    fileContents = {}
    fileLines = {}

    # Filter out imports we didn't pass as options.import
    messages = messages.filter (message) =>
      # Account for 0 line and rollup errors (Too many selectors rules, global rules)
      return true if message.line == 0 or message.rollup

      {source} = sourceMap.originalPositionFor
        line: message.line,
        column: message.col

      # Skip if we couldnt find a source file for the error
      if source == null
        return false

      # Fix path delimiter issues
      if source
        source = path.resolve source

      isThisFile = source == file

      return isThisFile or @grunt.file.isMatch(importsToLint, stripPath(source, process.cwd()))

    # Bug out if only import errors we don't care about
    return 0 if messages.length < 1

    # Group the errors by message
    messageGroups = _.groupBy messages, ({message, rule}) ->
      fullMsg = "#{message}"
      fullMsg += " #{rule.desc}" if rule.desc and rule.desc isnt message
      fullMsg

    # Output how many rules broken
    @grunt.log.writeln("#{chalk.yellow(filePath)} (#{messages.length})")

    # For each rule message and messages
    for fullRuleMessage, ruleMessages of messageGroups
      # Parse the rule and description
      rule = ruleMessages[0].rule

      # Output the rule broken
      @grunt.log.writeln(fullRuleMessage + chalk.grey(" (#{rule.id})"))

      for message in ruleMessages
        errorCount += 1

        # Account for global errors and rollup errors, don't show source line
        continue if message.line == 0 or message.rollup

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
        @grunt.log.error(chalk.gray("#{filePath} [Line #{line}, Column #{column+1}]:\t")+ " #{lessSource.trim()}")

    errorCount

module.exports = LintErrorOutput
