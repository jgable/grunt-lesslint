
crypto = require 'crypto'
LessParser = require './less-parser'
CssLinter = require './css-linter'
{LintCache} = require './lint-cache'
chalk = require 'chalk'

# Base Class representing a file to be linted
class LessFile
  constructor: (@filePath, @options = {}, @grunt) ->

  lint: (callback) ->
    # Parse the LESS into CSS
    @getCss (err, css, sourceMap) =>
      return callback(new Error("Error parsing #{chalk.yellow(@filePath)}: #{err.message}")) if err

      # Lint the css
      @lintCss css, (err, lintResult) =>
        return callback(new Error("Error linting #{chalk.yellow(@filePath)}: #{err.message}")) if err

        result =
          file: @filePath
          less: @getContents()
          css: css
          sourceMap: sourceMap

        # Only set lint if it's not empty
        if lintResult?.messages?.length > 0
          result.lint = lintResult

        callback null, result

  # Broken out for extension/stubbing
  lintCss: (css, callback) ->
    linter = new CssLinter(@options, @grunt)

    # Lint the CSS
    linter.lint css, callback

  getContents: (forced) ->
    return @contents if @contents? and not forced

    @contents = @grunt.file.read @filePath

  getDigest: ->
    return @digest if @digest

    @digest = crypto.createHash('sha256').update(@getContents()).digest('base64')

    @digest

  getCss: (callback) ->
    @getTree (err, tree) ->
      return callback(err) if err

      sourceMap = ''
      css = tree.toCSS({
        sourceMap: true
        writeSourceMap: (output) -> sourceMap = output
      })

      callback null, css, sourceMap

  # Just in case someone needs just the tree for something later
  getTree: (callback) ->
    contents = @getContents()

    # Bug out early if no LESS content
    return callback null, '' unless contents

    parser = new LessParser(@filePath, @options)

    parser.parse contents, callback

# An in-memory hold of import contents and hashes
sharedImportsContents = {}

# Extended LessFile that keeps an in memory lookup of contents and hashes
# to speed of subsequent lookups.
class LessImportFile extends LessFile
  getContents: ->
    if sharedImportsContents[@filePath]?.contents
      return sharedImportsContents[@filePath].contents

    contents = super()

    sharedImportsContents[@filePath] ||= { }
    sharedImportsContents[@filePath].contents = contents

  getDigest: ->
    if sharedImportsContents[@filePath]?.digest
      return sharedImportsContents[@filePath].digest

    digest = super()

    sharedImportsContents[@filePath] ||= { }
    sharedImportsContents[@filePath].digest = digest

# Extended LessFile with some logic for caching
class LessCachedFile extends LessFile
  constructor: (@filePath, @options = {}, @grunt) ->
    super

    @cache = new LintCache(@options.cache)

  lint: (callback) ->
    hash = @getDigest()

    @cache.hasCached hash, (isCached, cachedPath) =>
      if isCached
        # Trigger an event; mostly for unit test listening
        @grunt.event.emit 'lesslint.cache.hit', @filePath, cachedPath, hash
        return callback()

      # Call the super, not sure if I can use super() here since I'm in a callback
      LessFile.prototype.lint.call @, (err, result, less, css) =>
        return callback(err) if err

        # If there were errors found, pass them back and don't cache
        return callback(null, result, less, css) if result.lint?

        # Otherwise, add to cache
        @cache.addCached hash, (err, cachedAddPath) =>
          return callback(err) if err

          @grunt.event.emit 'lesslint.cache.add', @filePath, hash, cachedAddPath
          callback(null, result, less, css)

  # Hash the cached files based on import contents
  getDigest: ->
    myHash = super()

    return myHash unless @options.imports?

    importsContents = @getImportsContents()

    crypto.createHash('sha256')
      .update(myHash)
      .update(importsContents.join(''))
      .digest('base64')

  getImportsContents: ->
    (new LessImportFile(importFilePath, {}, @grunt).getDigest() for importFilePath in @grunt.file.expand(@options.imports))

module.exports = { LessFile, LessImportFile, LessCachedFile }
