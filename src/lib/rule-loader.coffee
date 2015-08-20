{CSSLint} = require 'csslint'
path = require 'path'
_ = require 'lodash'

module.exports = class RuleLoaderFactory
  instance = null

  @getRuleLoader: (grunt) ->
    # This is a singleton since CSSLint is a singleton
    if !instance
      instance = new RuleLoader(grunt, require)
    return instance


# Export for testing purposes only
module.exports.RuleLoader = class RuleLoader

  constructor: (@grunt, @require) ->
    @rulesPerFile = {}

  configureRules: (options) ->
    enabledRules = @enableConfiguredRuleFiles options
    @getDisabledRules enabledRules, options

  enableConfiguredRuleFiles: (options) ->
    enabledRules = []
    customRules = options.customRules
    if customRules?
      ruleFiles = @grunt.file.expand customRules
      for id, ruleFile of ruleFiles
        enabledRules = _.union enabledRules, @enableRuleFile ruleFile
    enabledRules

  enableRuleFile: (ruleFile) ->
    unless ruleFile of @rulesPerFile
      @grunt.verbose.writeln 'Loading custom rules from ' + ruleFile.cyan
      rulesBefore = @getCurrentRuleNames()
      @require path.resolve(ruleFile)
      newRules = @getNewRuleNames rulesBefore
      @rulesPerFile[ruleFile] = newRules
    else
      newRules = @rulesPerFile[ruleFile]
    newRules

  getCurrentRuleNames: ->
    _.keys CSSLint.getRuleset()

  getNewRuleNames: (previousRuleNames) ->
    _.difference @getCurrentRuleNames(), previousRuleNames

  getDisabledRules: (enabledRules, options) ->
    configuredRules = _.keys(options.csslint)
    _(@rulesPerFile).values().flatten().filter((rule) ->
      rule not in enabledRules and rule not in configuredRules
    ).value()
