exports.user_data =
  success_format: '''
<% cfg = awesomebox.config %>

Apps
-------------
<% data.forEach(function(app) { %>
<%= cfg.user === app.user && cfg.name === app.name ? '*' : ' ' %> <%= app.user %> - <%= app.name -%>
<% }) %>

'''

exports.execute = (context, callback) ->
  context.client().apps.list(callback)
