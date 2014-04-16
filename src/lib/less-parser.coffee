
path = require 'path'

_ = require 'underscore'
{Parser} = require 'less'

defaultLessOptions =
  cleancss: false
  compress: false
  dumpLineNumbers: 'comments'
  optimization: null
  syncImport: true

# LessParser encapsulates the options and defaults used when parsing LESS files.
module.exports = class LessParser
  constructor: (fileName, opts) ->
    # Make sure we have some default options if none passed
    opts = _.defaults(opts || {}, defaultLessOptions)

    # Set the options and create the parser
    @opts = _.extend({
      filename: path.resolve(fileName),
      paths: [path.dirname(path.resolve(fileName))]
      sourceMaps: true
    }, opts)
    @parser = new Parser(@opts)

  parse: (less, callback) ->
    try
      @parser.parse less, callback
    catch err
      callback err
