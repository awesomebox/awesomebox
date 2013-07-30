require 'coffee-script'
ViewPipeline = require '../view-pipeline'

pipeline = new ViewPipeline(
  paths:
    template: __dirname + '/templates'
)

pipeline.render '/test.html',
# pipeline.render '/folder.html',
  type: 'html'
  data:
    names: [
      'Bill'
      'James'
      'Pete'
    ]
, (err, data) ->
  console.log data
