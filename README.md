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

## The `awe` Object

The `awe` object is always available from your templates and contains special methods that link you into the
awesomebox system.  The most notable of these is the `awe.content` method.  This can be used by layouts to render
the main template for the current route or to render partials.  There are also other properties available on the
`awe` object, such as the current view and current route.

## Partials

Partials are rendered using the `awe.content` method from within templates.  Partial filenames _MUST_ start with
the `_` character.  Partial resolution is the same as page resolution, except that partials are resolved either
relative to the template it is being called from or absolutely from the `html` directory.

For instance, if the layout at `/layout/default.html.ejs` wants to include a footer partial, it can reference a
partial at `/layout/partials/_footer.html.ejs` by including this:

```erb
<%- awe.content('partials/footer') %>
```

However, if the partial was located at `/html/_footer.html.ejs`, then the layout should include this:

```erb
<%- awe.content('/footer') %>
```

## Layouts

Layouts are used to abstract away all the headers and footers and general page structure that all pages tend to
share.  They are not necessary whatsoever but definitely make life much easier.

Layouts are resolved in a very specific way.  For any page, the applicable layout will be the directory name for
that page.  For instance, for a page at `/foo/bar/baz`, the resolution order would be
- /layout/foo/bar.html
- /layout/foo.html
- /layout/default.html
- No Layout

Layouts can use the `awe.content()` method to place the content of the rendered page.

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
