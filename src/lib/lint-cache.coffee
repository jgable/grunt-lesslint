grunt = require 'grunt'
CacheSwap = require 'cache-swap'
path = require 'path'

_ = require 'lodash'

# Grab the package info only once instead of on every instantiation
packageInfo = grunt.file.readJSON(path.resolve(path.join(__dirname, '..', '..', 'package.json')))

class LintCache extends CacheSwap
  @category = 'lesshashed'
  
  constructor: (opts) ->
    # Ensure the opts are an object; can be passed as true
    opts = {} unless _.isObject(opts)

    super

    # Key the directory off the version so upgrading causes fresh linting
    @options.cacheDirName = "lesslint-#{packageInfo.version}"

  clear: (done) ->
    super LintCache.category, done

  hasCached: (hash, done) ->
    super LintCache.category, hash, done

  getCached: (hash, done) ->
    super LintCache.category, hash, done

  addCached: (hash, done) ->
    super LintCache.category, hash, '', done

# Exporting an object so it isn't mistaken for a function
module.exports = { LintCache }
