{CSSLint} = require 'csslint'
path = require 'path'
defaultRules = null


module.exports = class RuleLoaderFactory
  instance = null

  @getRuleLoader: (grunt) ->
    # This is a singleton since CSSLint is a singleton
    if !instance
      instance = new RuleLoader(grunt)
    return instance


class RuleLoader

  constructor: (@grunt) ->

  configureRules: (options) ->
    customRules = options.customRules
    if customRules?
      ruleFiles = @grunt.file.expand customRules
      for id, ruleFile of ruleFiles
        require path.resolve(ruleFile)
