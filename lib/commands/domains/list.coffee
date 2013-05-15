exports.user_data =
  success_format: '''
<% cfg = awesomebox.config %>

Domains
-------------
<% data.forEach(function(domain) { %>
<%= domain -%>
<% }) %>

'''

exports.execute = (context, callback) ->
  config = awesomebox.config
  
  context.client().app(config.name).domains.list(callback)
