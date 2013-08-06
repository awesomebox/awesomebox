# awesomebox

Effortless HTML, CSS, JS development in the flavor of your choice

## Installation

You'll have to have node.js installed first. The easiest way to do this is going to [nodejs.org](http://nodejs.org/)
and clicking the big INSTALL button. Once node.js is installed, open up a terminal and and run the following.

```bash
$ npm install -g awesomebox
```

You may need to sudo in order to install awesomebox. Alternatively you can grant yourself permissions to `/usr/local`
running `sudo chown $USER -R /usr/local` first.

## Usage

Then to run awesomebox, just change directory into your project's directory and run awesomebox from there. That's it!

```bash
$ cd /path/to/my/project
$ awesomebox
```

## Features

- Automatic Transpilation of HTML, CSS, and Javascript dialects
- Automatic Transpilation of `<script>` and `<style>` tags
- Layouts
- Partials
- Data Files (JSON and YAML)

## Currently Supported Dialects

### HTML

##### [atpl](https://github.com/soywiz/atpl.js)
`filename.html.atpl`

##### [dust](http://akdubya.github.io/dustjs/)
`filename.html.dust`

##### [eco](https://github.com/sstephenson/eco)
`filename.html.eco`

##### [ect](http://ectjs.com/)
`filename.html.ect`

##### [ejs](https://github.com/visionmedia/ejs)
`filename.html.ejs`

##### [haml](http://haml.info/)
`filename.html.haml`

##### [haml-coffee](https://github.com/9elements/haml-coffee)
`filename.html.haml-coffee`

##### [handlebars](http://handlebarsjs.com/)
`filename.html.handlebars`

##### [hogan](http://twitter.github.io/hogan.js/)
`filename.html.hogan`

##### [jade](http://jade-lang.com/)
`filename.html.jade`

##### [jazz](https://github.com/shinetech/jazz)
`filename.html.jazz`

##### [jqtpl](https://github.com/kof/jqtpl)
`filename.html.jqtpl`

##### [JUST](https://github.com/baryshev/just)
`filename.html.just`

##### [liquor](https://github.com/chjj/liquor)
`filename.html.liquor`

##### [markdown](https://github.com/chjj/marked) using [pygmentize](https://github.com/rvagg/node-pygmentize-bundled)
`filename.html.md` or `filename.html.markdown`

##### [mustache](http://mustache.github.io/)
`filename.html.mustache`

##### [QEJS](https://github.com/jepso/QEJS)
`filename.html.qejs`

##### [swig](http://paularmstrong.github.io/swig/)
`filename.html.swig`

##### [templayed](http://archan937.github.io/templayed.js/)
`filename.html.templayed`

##### [toffee](https://github.com/malgorithms/toffee)
`filename.html.toffee`

##### [underscore](http://documentcloud.github.io/underscore/#template)
`filename.html.underscore`

##### [walrus](http://documentup.com/jeremyruppel/walrus/)
`filename.html.walrus`

##### [whiskers](https://github.com/gsf/whiskers.js/)
`filename.html.whiskers`

### CSS

##### [less](http://lesscss.org/)
`filename.css.less` or `<style type="text/less"></style>`

##### [sass/scss](http://sass-lang.com/)
`filename.css.sass` or `<style type="text/sass"></style>`

##### [stylus](http://learnboost.github.io/stylus/)
`filename.css.styl` or `<style type="text/stylus"></style>`

### Javascript

##### [coffee-script](http://coffeescript.org/)
`filename.js.coffee` or `<script type="text/coffeescript"></script>`

##### [React.js](http://facebook.github.io/react/index.html)
`filename.js.jsx` or `<script type="text/jsx"></script>`

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

For example, you could create a simple layout that uses partials for the header and footer, and inserts the page
content between them.

##### `/layouts/index.html.ejs`
```erb
<!DOCTYPE html>
<html>
<head>
  <title>My Amazing Project<%- typeof(title) !== 'undefined' ? ' | ' + title : '' %></title>
</head>
<body>
  <%- box.content('/partials/header') %>
  <%- box.content() %>
  <%- box.content('/partials/footer') %>
</body>
</html>
```

This example also shows how you can share variables between the rendered content and the layout since the content
is rendered first, then the layout is rendered.

##### `/content/index.html.ejs`
```erb
<% title = 'Welcome!' %>

<h1>Welcome to my awesome project!</h1>

<p>
  I hope you have a nice stay. Look around for a bit.
</p>
```

## Data

Data files can be used for a lot of different things, like configuration, example data, lists of information, etc.
These files can either be read in as raw files or parsed for you to use in your templates. Currently recognized formats
are `JSON` and `YAML` files with extensions `.json`, `.yaml`, `.yml`. All data files should reside in the `data` directory
and will be resolved within that directory.

For example, let's say that you want to display a list of names and pictures on your team page. You could maintain
that list in a data file and reference it from your template with `box.data(...)`.

##### `/data/team.json`
```json
[{
  "name": "Matt Insler",
  "email": "matt.insler@gmail.com",
  "website": "http://www.mattinsler.com",
  "picture": "http://www.gravatar.com/avatar/45d9a0f5a6e7dae520a768d615e54a74.png"
}, {
  "name": "Boo Boo Insler",
  "email": "i.am.a.cute.dog@gmail.com",
  "website": "http://www.dailypuppy.com/",
  "picture": "http://cdn-www.dailypuppy.com/dog-images/oliver-the-dalmatian_71956_2013-07-29_w450.jpg"
}]
```

##### `/content/team.html.ejs`
```erb
<h1>Our Awesome Team</h1>

<ul class="unstyled">
<% box.data('/team').forEach(function(person) { %>
  <li>
    <h3><%= person.name %> <small><a href="mailto:<%- person.email %>"><%= person.email %></a></small></h3>
    <img src="<%- person.picture %>">
    <p>Check out my work at <a href="<%- person.website %>" target="_blank"><%= person.website %></a></p>
  </li>
<% }) %>
</ul>
```

You can also read the data raw with `box.data.raw(...)`. This is great for debugging data files too.

```erb
Check out my data.
<pre><%- box.data.raw('/team') %></pre>
```

## Deploying

If you'd like to run awesomebox on your own server, you're more than welcome to!

However, if you want something a little easier, you can deploy your project to Heroku with almost no work at all.
Just use the [Awesomebox Heroku Buildpack](https://github.com/awesomebox/heroku-buildpack-awesomebox) (follow the link
for instructions).

## License
Copyright (c) 2013 Matt Insler  
Licensed under the MIT license.
