{CSSLint} = require 'csslint'

CSSLint.addRule

  id: 'lowercase-properties'
  name: 'use only lowercase properties'
  desc: 'Properties should be in lowercase.'
  browsers: 'All'

  init: (parser, reporter) ->
    rule = this
    parser.addListener('property', (event) ->
      if /([A-Z])/.test(event.property.text)
        reporter.report('Uppercase letters looks bad.', event.line, event.col, rule)
    )



