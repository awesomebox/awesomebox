# awesomebox

The box that is awesome

## Installation

```bash
$ npm install -g awesomebox
```

## Directory Structure

```
- awesomebox.json                    # Awesomebox configuration file (optional)
  |- html
     |- index.html                   # Will be rendered for / or /index or /index.html
     |- posts
        |- index.html                # Will be rendered for /posts or /posts/index or /posts/index.html
        |- post-1.html
        |- post-2.html.ejs
  |- layout
     |- default.html.ejs             # Default layout
     |- posts.html.ejs               # Layout for posts directory
```

## Pages

Pages can be straight HTML or can use a view rendering engine.

Since awesomebox makes use of [consolidate](https://npmjs.org/package/consolidate), it supports all rendering
engines listed in the consolidate documentation.  The rendering engines and order is determined by the extensions
on the page filename.  For instance, if you have a file named `index.html.ejs.hogan`, the file will first be
run through the `hogan` rendering engine and then then `ejs` rendering engine.  The resulting data will be returned
to the browser as HTML.

## Layouts

Layouts are used to abstract away all the headers and footers and general page structure that all pages tend to
share.  They are not necessary whatsoever but definitely make life much easier.

Layouts are resolved in a very specific way.  For any page, the applicable layout will be the directory name for
that page.  For instance, for a page at `/foo/bar/baz`, the resolution order would be
- /layout/foo/bar.html
- /layout/foo.html
- /layout/default.html
- No Layout

Layouts can use the `content()` method to place the content of the rendered page.

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
