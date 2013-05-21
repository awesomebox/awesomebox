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
  context.client().app(awesomebox.name).domains.list(callback)
