exports.user_data =
  success_format: '''
<% cfg = awesomebox.config %>

Versions
-------------
<% data.forEach(function(version) { %>
<%= version.running ? '*' : ' ' %><%= version.instance.is_blessed ? '-' : ' ' %> <%= version.instance.version_name -%>: <%= new Date(version.instance.created_at) -%>
<% }) %>

'''

exports.execute = (context, callback) ->
  context.client().app(awesomebox.name).versions.list(callback)
