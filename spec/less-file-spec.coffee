path = require 'path'
grunt = require 'grunt'
{LessFile, LessImportFile, LessCachedFile} = require '../tasks/lib/less-file'

describe 'less-file', ->
  describe 'LessFile', ->
    filePath = path.join(__dirname, 'fixtures', 'valid.less')
    file = null

    beforeEach ->
      file = new LessFile(filePath, {}, grunt)

    it 'can load contents', ->
      contents = file.getContents()
      expect(contents).toBe grunt.file.read(filePath)

    it 'can get a hash', ->
      hash = file.getDigest()
      expect(hash).toNotBe null
      expect(hash.length).toBeGreaterThan 0

    it 'can lint a file', (done) ->
      file.lint (err, result, less, css) ->
        expect(err).toBe null
        expect(result).toBe undefined
        expect(less).toNotBe undefined
        expect(less.length).toBeGreaterThan 0
        expect(css).toNotBe undefined
        expect(css.length).toBeGreaterThan 0

        done()

  describe 'LessImportFile', ->
    filePath = path.join(__dirname, 'fixtures', 'valid.less')
    file = null

    beforeEach ->
      file = new LessImportFile(filePath, {}, grunt)

    it 'does not read from disk if already loaded before', ->

      spyOn(grunt.file, 'read').andCallFake (filePath) -> 'some fake file content'

      hash = file.getDigest()

      expect(grunt.file.read).toHaveBeenCalled()

      otherFile = new LessImportFile(filePath, {}, grunt)
      otherHash = otherFile.getDigest()

      # There is no toHaveBeenCalled 1, so we check the calls length here
      expect(grunt.file.read.calls.length).toBe 1
      expect(hash).toBe otherHash

  describe 'LessCachedFile', ->
    filePath = path.join(__dirname, 'fixtures', 'valid.less')
    file = null

    beforeEach ->
      file = new LessCachedFile(filePath, {}, grunt)

    it 'can load contents', ->
      contents = file.getContents()
      expect(contents).toBe grunt.file.read(filePath)

    it 'can get a hash', ->
      hash = file.getDigest()
      expect(hash).toNotBe null
      expect(hash.length).toBeGreaterThan 0

    it 'can lint a file', (done) ->
      # See if we read the file
      spyOn(file, 'getCss').andCallThrough()
      # Force no caching
      spyOn(file.cache, 'hasCached').andCallFake (hash, cb) -> cb(false)
      spyOn(file.cache, 'addCached').andCallFake (hash, cb) -> cb(null)

      file.lint (err, result, less, css) ->
        expect(file.getCss).toHaveBeenCalled()
        expect(err).toBe null
        expect(result).toBe undefined
        expect(less).toNotBe undefined
        expect(less.length).toBeGreaterThan 0
        expect(css).toNotBe undefined
        expect(css.length).toBeGreaterThan 0

        done()

    it 'does not parse less if previously cached successful run', (done) ->
      # See if we read the file
      spyOn(file, 'getCss').andCallThrough()
      # Force cache hit
      spyOn(file.cache, 'hasCached').andCallFake (hash, cb) -> cb(true)
      spyOn(file.cache, 'addCached').andCallFake (hash, cb) -> cb(null)

      file.lint (err, result, less, css) ->
        expect(file.getCss).not.toHaveBeenCalled()

        done()

    it 'uses imports from config option as a cache key so changes in import files cause re-linting', (done) ->
      file.options.imports = ['spec/fixtures/file.less']
      # See if we read the file
      spyOn(file, 'getCss').andCallThrough()

      hashKey = null
      spyOn(file.cache, 'hasCached').andCallFake (hash, cb) ->
        hashKey = hash
        cb false
      
      spyOn(file.cache, 'addCached').andCallFake (hash, cb) -> cb(null)
      
      # Stub the getContents so we can change it on subsequent runs through
      contentsCalls = 0
      spyOn(file, 'getImportsContents').andCallFake ->
        contentsCalls += 1
        ["body { margin: #{contentsCalls}px; }"]

      file.lint (err, result, less, css) ->
        expect(file.getCss).toHaveBeenCalled()
        expect(contentsCalls).toBe 1
        expect(err).toBe null
        expect(result).toBe undefined

        otherFile = new LessCachedFile(filePath, {}, grunt)
        otherFile.options.imports = ['spec/fixtures/file.less']

        spyOn(otherFile, 'getCss').andCallThrough()
        
        otherHashKey = null
        spyOn(otherFile.cache, 'hasCached').andCallFake (hash, cb) ->
          otherHashKey = hash
          cb false
        
        spyOn(otherFile.cache, 'addCached').andCallFake (hash, cb) -> cb(null)
        spyOn(otherFile, 'getImportsContents').andCallFake ->
          contentsCalls += 1
          ["body { margin: #{contentsCalls}px; }"]

        otherFile.lint (err, otherResult, less, css) ->
          expect(otherFile.getCss).toHaveBeenCalled()
          expect(contentsCalls).toBe 2
          expect(otherHashKey).not.toBe hashKey
          
          done()