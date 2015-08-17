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
    @disableNonEnabledCustomRules enabledRules, options

  enableConfiguredRuleFiles: (options) ->
    enabledRules = []
    customRules = options.customRules
    if customRules?
      ruleFiles = @grunt.file.expand customRules
      for id, ruleFile of ruleFiles
        enabledRules = _.union enabledRules, @enableRuleFile ruleFile
    enabledRules

  disableNonEnabledCustomRules: (enabledRules, options) ->

    disabledRules = @getDisabledRules enabledRules
    disabledOption = _.transform disabledRules, @convertDisabledRulesToCsslintConfiguration, {}
    options.csslint = _.merge disabledOption, options.csslint

  enableRuleFile: (ruleFile) ->
    unless ruleFile of @rulesPerFile
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

  getDisabledRules: (enabledRules) ->
    _(@rulesPerFile).values().flatten().xor(enabledRules).value()

  convertDisabledRulesToCsslintConfiguration: (transformResult, rule) ->
    transformResult[rule] = false
