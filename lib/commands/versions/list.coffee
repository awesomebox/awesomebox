exports.user_data =
  success_format: '''
<% cfg = awesomebox.config %>

Versions
-------------
<% data.forEach(function(version) { %>
<%= new Date(version.created_at) %>: <%= version.version -%>
<% }) %>

'''

exports.execute = (context, callback) ->
  config = awesomebox.config
  
  context.client().app(config.name).versions.list(callback)
