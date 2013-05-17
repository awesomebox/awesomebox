_ = require 'underscore'
walkabout = require 'walkabout'

class Commandment
  constructor: (@name, @version) ->
    @root = {children: {}}
  
  create_path: (parts) ->
    o = @root
    for p in parts
      o.children[p] ?= {name: p, children: {}, parent: o}
      o = o.children[p]
    o
  
  get_path: (parts) ->
    o = @root
    for x in [0...parts.length]
      p = parts[x]
      return {node: o, args: parts[x...]} unless o.children[p]?
      o = o.children[p]
    {node: o, args: []}
  
  parse: (path) ->
    root = walkabout(path)
    root_path = root.absolute_path
    
    parse_file = (file) =>
      # console.log 'FILE ' + file.absolute_path
      try
        o = require file.absolute_path
      catch e
        console.log e.stack
        return
      
      command = o.command or file.basename
      parts = _(file.absolute_path.slice(root_path.length).split('/')).compact()[0...-1]
      parts.push(command) if file.basename isnt 'index'
      node = @create_path(parts)
      
      for k in ['execute', 'description', 'alias', 'args', 'opts', 'user_data']
        node[k] = o[k] if o[k]
    
    parse_dir = (dir) ->
      # console.log 'DIR ' + dir.absolute_path
      for file in dir.readdir_sync()
        if file.is_directory_sync()
          parse_dir(file)
        else
          parse_file(file)
    
    return parse_dir(root) if root.is_directory_sync()
    parse_file(root)
  
  help: (cmd) ->
    cmd = (cmd or '').split(new RegExp(' +')) unless Array.isArray(cmd)
    cmd = _(cmd).compact()
    
    {node} = @get_path(cmd)
    return unless node?
    
    pad_right = (str, count) ->
      str += ' ' while str.length < count
      str
    
    print_node = (node) ->
      for k in _(node.children).keys().sort()
        current_node = node.children[k]
        
        args = current_node.args
        args = [args] unless Array.isArray(args)
        args = _(args).compact()
        args = args.map((a) -> "[#{a}]") if current_node.args isnt '...'
        
        console.log '    ' + pad_right([current_node.name].concat(args).join(' '), 20) + (current_node.description or '')
    
    console.log()
    console.log "  ===== #{@name} v#{@version} ====="
    console.log()
    console.log "  Usage: #{@name} #{cmd.join(' ')} [options] [commands]"
    console.log()
    console.log '  Commands:'
    console.log()
    print_node(node)
    console.log()
    # console.log '  Options:'
    # console.log()
    # 
    # console.log()
  
  execute: (cmd) ->
    delete @current_node
    delete @current_args
    delete @current_opts
    
    check_args = (node, args) ->
      return true if !node.args? and args.length is 0
      return true if node.args is '...'
      node_args = node.args
      node_args = [node_args] unless Array.isArray(node_args)
      node_args = _(node_args).compact().filter (a) -> a[0] isnt '~'
      return true if node_args.length is args.length
      false
    
    execute = (node, args, opts) =>
      @context.commandment = @
      
      args ?= []
      args = [args] unless Array.isArray(args)
      args = [args] if node.args is '...'
      
      data = [@context].concat(args).concat((err, data) =>
        if err?
          return @on_error(err) if @on_error?
          return console.log(err.message)
        return @on_success(data, node) if @on_success?
      )
      
      node.execute.apply(node, data)
    
    cmd = (cmd or '').split(new RegExp(' +')) unless Array.isArray(cmd)
    cmd = _(cmd).compact()
    
    # parse out options
    
    {node, args} = @get_path(cmd)
    @current_node = node
    @current_args = args
    
    # console.log @current_node
    # console.log @current_args
    # console.log @current_opts
    
    @current_node = @current_node.children[@current_node.alias] if !@current_node?.execute? and @current_node.alias? and @current_node.children[@current_node.alias]?
    return @help() unless @current_node?.execute?
    return @help(cmd) unless check_args(@current_node, @current_args)
    execute(@current_node, @current_args, @current_opts)

module.exports = Commandment
