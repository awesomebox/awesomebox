# syncr

syncr helps you deal with the details of remote file synchronization

## Installation
```
npm install syncr
```

## Usage

```javascript
var syncr = require('syncr');

syncr.create_manifest('./', function(err, manifest) {
  console.log(manifest);
  console.log(syncr.compute_delta(other_manifest));
});
```

## methods

#### sync.create_manifest(path, opts, callback)

Creates a manifest object from the path given.

```json
{
  "created_at": "Tue Aug 13 2013 02:34:09 GMT-0700 (PDT)",
  "hash": "b408eaf138f7f4138538c98b50723431caf4a265",
  "files": {
    "lib/manifest.coffee": "85c761ac1c5b3f62af68925d9bd41fdd9f3dc775",
    "package.json": "a1c283a135a050df22d26ca7e714be9b5182a9f4",
    "test/test-manifest.coffee": "f4f4121a29471d4faee14fca8bb114f3b91d23de"
  }
}
```

##### options

- all (Boolean, default false): Include all files (same as ls -a).
- aboslute_path (Boolean, default false): Use absolute paths in files hash.
- ignore (String or Array): Patterns to apply to files and directories to filter them out (uses [minimatch](https://npmjs.org/package/minimatch)).
- ignorefile (String): Path to the ignore file. This is the same as a .gitignore file.

#### sync.compute_delta(from_manifest, to_manifest)

Creates a delta object that specifies the steps needed to be taken to transform
`from_manifest` to `to_manifest`.

```json
{
  "add": [
    "lib/manifest.coffee",
    "test/test-manifest.coffee"
  },
  remove: [],
  change: [
    "package.json"
  ]
}
```

## License
Copyright (c) 2013 Matt Insler  
Licensed under the MIT license.
