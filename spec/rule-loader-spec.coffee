grunt = require 'grunt'
path = require 'path'
_ = require 'lodash'
{CSSLint} = require 'csslint'
RuleLoaderFactory = require '../tasks/lib/rule-loader'

describe 'rule-loader', ->
  describe 'RuleLoader', ->
    loader = null
    requireFunction = null
    fileRules = {}
    loadedRules = null

    beforeEach ->
      loadedRules = []
      requireFunction = createSpy 'require'
      loader = new RuleLoaderFactory.RuleLoader grunt, requireFunction

    it 'should require the configured rule file', ->
      givenRuleFilesForPattern ['rules/*.coffee'], ['rules/rule1.coffee']

      loader.configureRules {customRules: ['rules/*.coffee']}

      expect(requireFunction).toHaveBeenCalledWith path.resolve('rules/rule1.coffee')

    it 'should only require a configured rule file once', ->
      givenRuleFilesForPattern ['rules/*.coffee'], ['rules/rule1.coffee']

      loader.configureRules {customRules: ['rules/*.coffee']}
      loader.configureRules {customRules: ['rules/*.coffee']}

      expect(requireFunction.callCount).toEqual 1

    it 'should require all matched rule files', ->
      givenRuleFilesForPattern ['rules/*.coffee'], ['rules/rule1.coffee', 'rules/rule2.coffee']

      loader.configureRules {customRules: ['rules/*.coffee']}

      expect(requireFunction).toHaveBeenCalledWith path.resolve('rules/rule1.coffee')
      expect(requireFunction).toHaveBeenCalledWith path.resolve('rules/rule2.coffee')

    it 'should disable rules from previous runs', ->
      givenRuleFileLoadsRules 'rules/rule1.coffee', ['rule1']
      givenRuleFilesForPattern ['rules/*.coffee'], ['rules/rule1.coffee']
      givenPreviousRunWithOptions {customRules: ['rules/*.coffee']}

      options = {}
      loader.configureRules options

      expect(options.csslint).toEqual {rule1: false}

    it 'should not remove existing CSSLint configuration when disabling rules from previous runs', ->
      givenRuleFileLoadsRules 'rules/rule1.coffee', ['rule1']
      givenRuleFilesForPattern ['rules/*.coffee'], ['rules/rule1.coffee']
      givenPreviousRunWithOptions {customRules: ['rules/*.coffee']}

      options = {
        csslint: {
          configured: true
        }
      }
      loader.configureRules options

      expect(options.csslint).toEqual objectContaining({configured: true})

    it 'should not overwrite existing CSSLint configuration when disabling rules from previous runs', ->
      givenRuleFileLoadsRules 'rules/rule1.coffee', ['rule1']
      givenRuleFilesForPattern ['rules/*.coffee'], ['rules/rule1.coffee']
      givenPreviousRunWithOptions {customRules: ['rules/*.coffee']}

      options = {
        csslint: {
          rule1: true
        }
      }
      loader.configureRules options

      expect(options.csslint).toEqual {rule1: true}

    it 'should not disable rules from previous runs when enabled', ->
      givenRuleFileLoadsRules 'rules/rule1.coffee', ['rule1']
      givenRuleFilesForPattern ['rules/*.coffee'], ['rules/rule1.coffee']

      # Previous run
      loader.configureRules {customRules: ['rules/*.coffee']}

      # Current run
      options = {
        customRules: ['rules/*.coffee']
      }
      loader.configureRules options

      expect(options.csslint).toEqual {}

    givenRuleFilesForPattern = (expectedPatterns, files) ->
      spyOn(grunt.file, 'expand').andCallFake (actualPatterns) ->
        return files

    givenRuleFileLoadsRules = (relativeFilePath, ruleNames) ->
      fileRules[path.resolve(relativeFilePath)] = ruleNames

      requireFunction.andCallFake (absoluteFilePath) ->
        if absoluteFilePath of fileRules
          Array::push.apply loadedRules, fileRules[absoluteFilePath]

      spyOn(CSSLint, 'getRuleset').andCallFake ->
        convertToRuleset = (ruleset, rule) ->
          ruleset[rule] = createSpy 'rule: ' + rule
        _.transform loadedRules, convertToRuleset, {}

    givenPreviousRunWithOptions = (options) ->
      loader.configureRules options
