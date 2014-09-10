
path = require 'path'

_ = require 'lodash'
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
    paths = [path.dirname(path.resolve(fileName))]

    if opts.less and opts.less.paths
      paths = paths.concat(opts.less.paths)

    # Set the options and create the parser
    @opts = _.extend({
      filename: path.resolve(fileName),
      paths: paths,
      sourceMaps: true
    }, opts)
    @parser = new Parser(@opts)

  parse: (less, callback) ->
    try
      @parser.parse less, callback
    catch err
      callback err
