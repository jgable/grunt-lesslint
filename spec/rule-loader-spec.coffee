grunt = require 'grunt'
path = require 'path'
_ = require 'lodash'
{CSSLint} = require 'csslint'
RuleLoaderFactory = require '../tasks/lib/rule-loader'

describe 'rule-loader', ->
  describe 'RuleLoader', ->
    loader = null
    requireFunction = null
    patternFiles = null
    fileRules = null
    loadedRules = null

    beforeEach ->
      patternFiles = {}
      fileRules = {}
      loadedRules = []
      requireFunction = createSpy 'require'
      loader = new RuleLoaderFactory.RuleLoader grunt, requireFunction

    it 'should require the configured rule file', ->
      givenPatternMatchesRuleFiles 'rules/*.coffee', ['rules/rule1.coffee']

      loader.configureRules customRules: ['rules/*.coffee']

      expect(requireFunction).toHaveBeenCalledWith path.resolve('rules/rule1.coffee')

    it 'should only require a configured rule file once', ->
      givenPatternMatchesRuleFiles 'rules/*.coffee', ['rules/rule1.coffee']

      loader.configureRules customRules: ['rules/*.coffee']
      loader.configureRules customRules: ['rules/*.coffee']

      expect(requireFunction.callCount).toEqual 1

    it 'should require all matched rule files', ->
      givenPatternMatchesRuleFiles 'rules/*.coffee', ['rules/rule1.coffee', 'rules/rule2.coffee']

      loader.configureRules customRules: ['rules/*.coffee']

      expect(requireFunction).toHaveBeenCalledWith path.resolve('rules/rule1.coffee')
      expect(requireFunction).toHaveBeenCalledWith path.resolve('rules/rule2.coffee')

    it 'should disable rules from previous runs', ->
      givenRuleFileLoadsRules 'rules/rule1.coffee', ['rule1']
      givenPatternMatchesRuleFiles 'rules/*.coffee', ['rules/rule1.coffee']
      givenPreviousRunWithOptions customRules: ['rules/*.coffee']

      disabledRules = loader.configureRules {}

      expect(disabledRules).toEqual ['rule1']

    it 'should disable rules for all files from previous runs', ->
      givenRuleFileLoadsRules 'rules/rule1.coffee', ['rule1']
      givenRuleFileLoadsRules 'rules/rule2.coffee', ['rule2']
      givenPatternMatchesRuleFiles 'rules/*.coffee', ['rules/rule1.coffee', 'rules/rule2.coffee']
      givenPreviousRunWithOptions customRules: ['rules/*.coffee']

      disabledRules = loader.configureRules {}

      expect(disabledRules).toEqual ['rule1', 'rule2']

    it 'should not disable rules existing in CSSLint configuration when disabling rules from previous runs', ->
      givenRuleFileLoadsRules 'rules/rule1.coffee', ['rule1']
      givenPatternMatchesRuleFiles 'rules/*.coffee', ['rules/rule1.coffee']
      givenPreviousRunWithOptions customRules: ['rules/*.coffee']

      disabledRules = loader.configureRules csslint: rule1: true

      expect(disabledRules).toEqual []

    it 'should not disable other rules in CSSLint configuration when disabling rules from previous runs', ->
      givenRuleFileLoadsRules 'rules/rule1.coffee', ['rule1']
      givenPatternMatchesRuleFiles 'rules/*.coffee', ['rules/rule1.coffee']
      givenPreviousRunWithOptions customRules: ['rules/*.coffee']

      disabledRules = loader.configureRules csslint: rule2: true

      expect(disabledRules).toEqual ['rule1']

    it 'should not disable rules from previous runs when the same custom rule file is configured', ->
      givenRuleFileLoadsRules 'rules/rule1.coffee', ['rule1']
      givenPatternMatchesRuleFiles 'rules/*.coffee', ['rules/rule1.coffee']
      givenPreviousRunWithOptions customRules: ['rules/*.coffee']

      disabledRules = loader.configureRules customRules: ['rules/*.coffee']

      expect(disabledRules).toEqual []

    it 'should only disable rules from previous runs for files not configured', ->
      givenRuleFileLoadsRules 'rules/rule1.coffee', ['rule1']
      givenRuleFileLoadsRules 'rules/rule2.coffee', ['rule2']
      givenPatternMatchesRuleFiles 'rules/*.coffee', ['rules/rule1.coffee', 'rules/rule2.coffee']
      givenPatternMatchesRuleFiles 'rules/rule1.coffee', ['rules/rule1.coffee']
      givenPreviousRunWithOptions customRules: ['rules/*.coffee']

      disabledRules = loader.configureRules customRules: ['rules/rule1.coffee']

      expect(disabledRules).toEqual ['rule2']

    givenPatternMatchesRuleFiles = (expectedPattern, matchedFiles) ->
      patternFiles[expectedPattern] = matchedFiles

      if not grunt.file.expand.isSpy?
        spyOn(grunt.file, 'expand').andCallFake (actualPatterns) ->
          for pattern, files of patternFiles
            if pattern == actualPatterns[0] and actualPatterns.length == 1
              return files
          throw Error(actualPatterns + ' not found in ' + patternFiles)

    givenRuleFileLoadsRules = (relativeFilePath, ruleNames) ->
      fileRules[path.resolve(relativeFilePath)] = ruleNames

      requireFunction.andCallFake (absoluteFilePath) ->
        if absoluteFilePath of fileRules
          Array::push.apply loadedRules, fileRules[absoluteFilePath]

      if not CSSLint.getRuleset.isSpy?
        spyOn(CSSLint, 'getRuleset').andCallFake ->
          convertToRuleset = (ruleset, rule) ->
            ruleset[rule] = createSpy 'rule: ' + rule
          _.transform loadedRules, convertToRuleset, {}

    givenPreviousRunWithOptions = (options) ->
      loader.configureRules options
