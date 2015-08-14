
{CSSLint} = require 'csslint'
_ = require 'lodash'
RuleLoader = require './rule-loader'

module.exports = class CssLinter
  constructor: (@options, @grunt) ->

  lint: (css, callback) ->
    unless css
      return callback(null, [])

    externalOptions = {}

    RuleLoader.getRuleLoader(@grunt).configureRules(@options)

    rules = _.reduce CSSLint.getRules(), (memo, {id}) ->
      memo[id] = 1
      memo
    , {}

    cssLintOptions = @options.csslint
    if cssLintOptions?.csslintrc
      externalOptions = @grunt.file.readJSON cssLintOptions.csslintrc
      delete cssLintOptions.csslintrc

    _.extend(cssLintOptions, externalOptions)

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
