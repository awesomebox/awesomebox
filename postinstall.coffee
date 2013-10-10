_ = require 'underscore'
{exec} = require 'child_process'
{Engines} = require 'tubing-view'
NPM_PATH = require.resolve('tubing-view/node_modules/.bin/npm')

packages = _.chain(Engines.engines_by_ext)
  .values()
  .map((e) -> e.dependencies)
  .flatten()
  .sort()
  .uniq()
  .compact()
  .value()

console.log 'INSTALLING DEPENDENCIES', packages
console.log NPM_PATH + ' install --production ' + packages.join(' '), {cwd: __dirname + '/node_modules/tubing-view'}
exec NPM_PATH + ' install --production ' + packages.join(' '), {cwd: __dirname + '/node_modules/tubing-view'}, (err) ->
  return console.log(err.stack) if err?
  console.log 'DONE'
