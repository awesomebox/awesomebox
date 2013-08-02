# awesomebox

Concentrate on building your site, not managing it

## Installation

```bash
$ npm install -g awesomebox
```

## Directory Structure

To use awesomebox, you never need to change the directory structure that you're currently using. Just run awesomebox in
your project's directory and it'll work!

```
- index.html                      # Will be rendered for / or /index or /index.html
- posts
  |- index.html.ejs               # Will be rendered for /posts or /posts/index or /posts/index.html
  |- post-1.html
  |- post-2.html
- css
  |- style.css.less
- js
  |- app.js.coffee
```

If you'd like to take advantage of some of the features that awesomebox provides, all you need to do is create a
`content` directory and it'll get picked up automatically. Now you'll have access to layouts and data file access.

```
- content
  |- index.html                   # Will be rendered for / or /index or /index.html
  |- posts
    |- index.html.ejs             # Will be rendered for /posts or /posts/index or /posts/index.html
    |- post-1.html
    |- post-2.html
  |- css
    |- style.css.less
  |- js
    |- app.js.coffee
- layouts
  |- default.html.ejs             # Default layout
  |- posts.html.ejs               # Layout for posts directory
- data
  |- identity.yml
  |- blog_posts.json
```

## The `box` Object

The `box` object is always available from your templates and contains special methods that link you into the
awesomebox system.  The most notable of these is the `box.content` method.  This can be used by layouts to render
the main template for the current route or to render partials.  There are also other properties available on the
`box` object, such as the current view and current route.

## Content

Content can be straight HTML or can use a view rendering engine.

Since awesomebox makes use of [consolidate](https://npmjs.org/package/consolidate), it supports all rendering
engines listed in the consolidate documentation.  The rendering engines and order is determined by the extensions
on the page filename.  For instance, if you have a file named `index.html.ejs.hogan`, the file will first be
run through the `hogan` rendering engine and then then `ejs` rendering engine.  The resulting data will be returned
to the browser as HTML.

## Partials

Partials are rendered using the `box.content` method from within templates.  Partial filenames _MUST_ start with
the `_` character.  Partial resolution is the same as page resolution, except that partials are resolved either
relative to the template it is being called from or absolutely from the `html` directory.

For instance, if the layout at `/layouts/index.html.ejs` wants to include a footer partial, it can reference a
partial at `/layouts/partials/_footer.html.ejs` by including this:

```erb
<%- box.content('partials/footer') %>
```

However, if the partial was located at `/html/_footer.html.ejs`, then the layout should include this:

```erb
<%- box.content('/footer') %>
```

Passing data into partials is very easy.  You can either pass in an object, like this:

```erb
<%- box.content('print_my_name', {name: 'Matt'}) %>
```

Or you could provide the path to a data file, like this:

```erb
<%- box.content('print_my_name', 'name_data') %>
```

The above example will find the data file named `name_data.{extension}`, parse it, and pass it into the `print_my_name` partial.

## Layouts

Layouts are used to abstract away all the headers and footers and general page structure that all pages tend to
share. They are not necessary whatsoever but definitely make life much easier. It is important to note that layouts
are only available for html pages.

Layouts are resolved in a very specific way. For any page, the applicable layout will be the directory name for
that page. For instance, for a page at `/foo/bar/baz.html{.engine?}`, the resolution order would be
- /layouts/foo/bar.html{.engine?}
- /layouts/foo.html{.engine?}
- /layouts/index.html{.engine?}
- No Layout

Layouts can use the `box.content()` method to place the content of the rendered page.

## Data

`box.data()`
`box.data.raw()`

## License
Copyright (c) 2013 Matt Insler  
Licensed under the MIT license.
