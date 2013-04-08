{spawn} = require 'child_process'
awesomebox = require './awesomebox'

program = require 'commander'
program.version(require('../package').version)

module.exports = (subcommand) ->
  context = awesomebox.commands
  context = context[subcommand] if subcommand?
  
  awesomebox.Plugins.initialize ->
    commands = Object.keys(context).sort()
  
    commands.forEach (command) ->
      if typeof context[command] is 'function'
        program
          .command(command)
          .description(context[command].description ? command)
          .action ->
            context[command](Array::slice.call(arguments, 0, -1).concat(->)...)
        awesomebox.Plugins.context.wrap(context, 'command.' + command, command)
      else
        program
          .command(command)
          .description(context[command].description ? command)
          .action ->
            a = process.argv
            spawn(a[0], ["#{a[1]}-#{a[2]}"].concat(a.slice(3)), stdio: 'inherit')
  
    o = program.parse(process.argv)
    
    program.help() if o?.args?.length is 0
