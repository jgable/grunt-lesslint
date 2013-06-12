# LESS Lint Grunt plugin [![Build Status](https://travis-ci.org/kevinsawicki/grunt-lesslint.png)](https://travis-ci.org/kevinsawicki/grunt-lesslint)

Lint your [LESS](http://lesscss.org/) files using
[CSS Lint](http://csslint.net/) from [Grunt](http://gruntjs.com/).

This plugin compiles LESS files to CSS and then runs the CSS through CSS Lint
and then maps the error output from CSS Lint back to the original LESS
line number.

## Installing

```sh
npm install grunt-lesslint
```

## Building
  * Clone the repository
  * Run `npm install`
  * Run `grunt` to compile the CoffeeScript code
  * Run `grunt test` to run the specs
  
## Configuring

Add the following to your `Gruntfile.coffee`:

```coffeescript
grunt.initConfig
  lesslint:
    src: ['src/**/*.less']

grunt.loadNpmTasks('grunt-lesslint')
```

Then simply run `grunt lesslint` to lint all the `.less` files under `src/`.

By default the plugin uses the `less` and `csslint` config settings to
configure the LESS parser and the CSS Lint validator.

You can configure the CSS Lint validator, such as for disabling certain rules,
by adding a `csslint` config value:

```coffeescript
csslint:
  'known-properties': false
```

You can configure the LESS parser, such as for adding include paths,
by adding a `less` config value:

```coffeescript
less:
  paths: ['includes']
```

## Example output

```
> grunt lesslint
Running "lesslint" (lesslint) task
static/editor.less (1)
Values of 0 shouldn't have units specified. You don't need to specify units when a value is 0. (zero-units)
>> 14: line-height: 0px;

>> 1 linting error in 56 files.
```
