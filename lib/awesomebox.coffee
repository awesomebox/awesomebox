# process.on 'uncaughtException', (err) ->
#   console.log(err.stack)

walkabout = require 'walkabout'

awesomebox = {
  root: walkabout(__dirname).join('..')
  path: {
    root: walkabout()
  }
}

awesomebox.version = require('../package').version
awesomebox.Server = require './server'
awesomebox.Route = require './route'
awesomebox.View = require './view'
awesomebox.ViewPipeline = require './view_pipeline'

module.exports = awesomebox
