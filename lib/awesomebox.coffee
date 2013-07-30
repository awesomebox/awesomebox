walkabout = require 'walkabout'

awesomebox = {
  root: walkabout(__dirname).join('..')
  path: {
    root: walkabout()
  }
}

awesomebox.Server = require './server'
awesomebox.Route = require './route'
awesomebox.View = require './view'
awesomebox.ViewPipeline = require './view_pipeline'

module.exports = awesomebox
