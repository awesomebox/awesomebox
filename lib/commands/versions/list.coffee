exports.user_data =
  success_format: '''
<% cfg = awesomebox.config %>

Versions
-------------
<% data.forEach(function(version) { %>
<%= version.version_name -%>: <%= new Date(version.created_at) -%>
<% }) %>

'''

exports.execute = (context, callback) ->
  config = awesomebox.config
  
  context.client().app(config.name).versions.list(callback)
