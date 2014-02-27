
crypto = require 'crypto'
LessParser = require './less-parser'
CssLinter = require './css-linter'
{LintCache} = require './lint-cache'

# Base Class representing a file to be linted
class LessFile
  constructor: (@filePath, @options = {}, @grunt) ->

  lint: (callback) ->
    # Parse the LESS into CSS
    @getCss (err, css) =>
      return callback(new Error("Error parsing #{@filePath.yellow}: #{err.message}")) if err

      # Lint the css
      @lintCss css, (err, result) =>
        return callback(new Error("Error linting #{@filePath.yellow}: #{err.message}")) if err

        callback null, result, @getContents(), css

  # Broken out for extension/stubbing
  lintCss: (css, callback) ->
    linter = new CssLinter(@options, @grunt)

    # Lint the CSS
    linter.lint css, callback

  getContents: (forced) ->
    return @contents if @contents? and not forced

    @contents = @grunt.file.read @filePath

  getDigest: ->
    crypto.createHash('sha256').update(@getContents()).digest('base64')

  getCss: (callback) ->
    @getTree (err, tree) ->
      return callback(err) if err

      callback null, tree.toCSS()

  # Just in case someone needs just the tree for something later
  getTree: (callback) ->
    contents = @getContents()

    # Bug out early if no LESS content
    return callback null, '' unless contents

    parser = new LessParser(@filePath, @options)

    parser.parse contents, callback

# Extended LessFile with some logic for caching
class LessCachedFile extends LessFile
  constructor: (@filePath, @options = {}, @grunt) ->
    super

    @cache = new LintCache(@options.cache)

  lint: (callback) ->
    hash = @getDigest()

    @cache.hasCached hash, (isCached, cachedPath) =>
      if isCached
        @grunt.event.emit 'lesslint.cache.hit', @filePath, cachedPath, hash
        return callback()

      # Call the super, not sure if I can use super() here since I'm in a callback
      LessFile.prototype.lint.call @, (err, result, less, css) =>
        return callback(err) if err

        # If there were errors found, pass them back and don't cache
        return callback(null, result, less, css) if result?

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
    (new LessFile(importFilePath, {}, @grunt).getDigest() for importFilePath in @grunt.file.expand(@options.imports))

module.exports = { LessFile, LessCachedFile }
