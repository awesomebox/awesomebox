exports.user_data =
  success_format: '''
<% cfg = awesomebox.config %>

Domains
-------------
<% data.forEach(function(domain) { %>
<%= domain -%>
<% }) %>

'''

exports.args = 'domain'
exports.execute = (context, domain, callback) ->
  context.client().app(awesomebox.name).domains.remove(domain, callback)
