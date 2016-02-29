
path = require 'path'

_ = require 'lodash'
less = require 'less'

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
    opts = _.defaults(opts.less || {}, defaultLessOptions)
    paths = [path.dirname(path.resolve(fileName))]

    if opts and opts.paths
      paths = paths.concat(opts.less.paths)

    # Set the options and create the parser
    @opts = _.extend({
      filename: path.resolve(fileName),
      paths: paths,
      sourceMap: {}
    }, opts)

  render: (contents, callback) ->
    try
      less.render contents, @opts, (err, output) ->
        callback err, output?.css, output?.map
    catch err
      callback err
