# awesomebox

The box that is awesome

## Installation

```bash
$ npm install -g awesomebox
```

## Plugins

To use plugins, add an `awesomebox.json` file to the root of your project.

Then add the names of the plugins you'd like to load to the plugins array.  Please note that the plugins are loaded in the order specified.

```json
{
  "plugins": [
    "awesomebox-bower",
    "awesomebox-livereload"
  ]
}
```

### Current List

- [Bower](https://github.com/mattinsler/awesomebox-bower)
- [Livereload](https://github.com/mattinsler/awesomebox-livereload)

## License
Copyright (c) 2013 Matt Insler  
Licensed under the MIT license.
