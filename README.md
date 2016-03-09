# LESS Lint Grunt plugin
[![Build Status](https://travis-ci.org/jgable/grunt-lesslint.svg)](https://travis-ci.org/jgable/grunt-lesslint)
[![Dependency Status](https://david-dm.org/jgable/grunt-lesslint.svg)](https://david-dm.org/jgable/grunt-lesslint)
[![devDependency Status](https://david-dm.org/jgable/grunt-lesslint/dev-status.svg)](https://david-dm.org/jgable/grunt-lesslint#info=devDependencies)

Lint your [LESS](http://lesscss.org/) files using
[CSS Lint](http://csslint.net/) from [Grunt](http://gruntjs.com/).

This plugin compiles your LESS files, runs the generated CSS through CSS Lint,
and outputs the offending LESS line for any CSS Lint errors found.

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

Then run `grunt lesslint` to lint all the `.less` files under `src/`.

By default the plugin uses the `less` and `csslint` config settings to
configure the LESS parser and the CSS Lint validator.

### CSS Lint

You can configure the CSS Lint validator, such as for disabling certain rules
or loading a `.csslintrc` file, by adding a `csslint` option value:

```coffeescript
lesslint:
  src: ['less/*.less']
  options:
    csslint:
      'known-properties': false
      csslintrc: '.csslintrc'
```

### Allow lint warnings without failing the grunt task

The `failOnWarning` configuration option is now available to allow any failing
lint rules set to "warn" to not fail the grunt task.

To maintain backwards-compatibility: 
- This option's value is defaulted to `failOnWarning: true`, which will continue 
   to fail the grunt task on *any* failed rule. When using the default option, the 
   following example output shows the task failure due to failed lint rules 
   configured as "warnings":

```
      >> 58 lint issues in 167 files (0 errors, 58 warnings)
      Warning: Task "lesslint" failed. Use --force to continue.
```

- Setting `failOnError: false` will act as a **complete** override for both 
   settings: don't fail grunt task if EITHER lint rule __warning(s)__ or __error(s)__ 
   are found. Example Config:

```coffeescript
      lesslint:
        src: ['less/*.less']
        options:
          csslint:
            'known-properties': true
            csslintrc: '.csslintrc'
          failOnError: false
```

By setting `failOnWarning: false`, any failing rule configured
to "warn" will no longer fail the grunt task:

```coffeescript
lesslint:
  src: ['less/*.less']
  options:
    csslint:
      'known-properties': true
      csslintrc: '.csslintrc'
    failOnWarning: false
```

This example's task output shows the task completing without
failure, even when there are failed lint rules configured as "warnings":

```
>> 58 lint issues in 167 files (0 errors, 58 warnings)
Done, without errors.
```

__Notes:__

The new task summary output is borrowed from equivalent output used by eslint:
```
✖ 31 problems (0 errors, 31 warnings)
```

This option is meant to afford large projects the recourse of a staged adoption
strategy of specific CSS rules. New rules may be activated to trigger a warning
notification across teams without breaking the build and deployment. Once
existing infractions are addressed, those rules would then be configured from
"warning" setting to "error", to finalize their enforcement (by blocking any
subsequent build attempts).


### LESS

You can configure the LESS parser, such as for adding include paths,
by adding a `less` option value:

```coffeescript
lesslint:
  src: ['less/*.less']
  options:
    less:
      paths: ['includes']
```

### Linting imports

By default, this plugin does not include any lint errors from imported files
in the output.

You can enable this by adding an `imports` configuration option:

```coffeescript
lesslint:
  src: ['src/**/*.less']
  options:
    imports: ['imports/**/*.less']
```

### Generating reports

This plugin provides the same output formatter options as the CSS Lint plugin
and can be configured similarly:

```coffeescript
lesslint:
  options:
    formatters: [
      id: 'csslint-xml'
      dest: 'report/lesslint.xml'
    ]
```

### Using custom rules

It is possible to create and use your own custom rules. To create rules, please refer to the [official CSSLint guidelines](https://github.com/CSSLint/csslint/wiki/Working-with-Rules). The only addition is that each custom rule file must import `CSSLint` using `CSSLint = require('grunt-lesslint').CSSLint`.

You can enable your custom rules by adding a `customRules` configuration option:

```coffeescript
lesslint:
  options:
    customRules: ['lint-rules/less/**/*.coffee']
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

## Breaking changes

- In v3.0.0 `options` is no longer passed to the LESS compiler. `options.less` is passed instead, as described by the documentation.
- In v2.0.0 the LESS compiler was updated to v2.5.3
