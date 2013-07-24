require 'colors'

module.exports =
  args: 'type'
  description: """Initialize a box in the current directory
  
  Box Types:
  - #{'foo'.yellow} This is a foo
  - #{'bar'.yellow}
  """
  
  execute: (context, type, callback) ->
    console.log type
    callback()
