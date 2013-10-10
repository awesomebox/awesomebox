(function() {
  var chalk;

  chalk = require('chalk');

  exports.help = function(cb) {
    this.logger.help(chalk.underline('Boxes'));
    this.logger.help('');
    this.logger.help(chalk.cyan('awesomebox save'));
    this.logger.help(chalk.gray("Save a new version of your box on the server."));
    this.logger.help('');
    this.logger.help(chalk.cyan('awesomebox load [box [version]]'));
    this.logger.help(chalk.gray("Load up a new version of your box from the server."));
    this.logger.help('');
    this.logger.help('');
    this.logger.help('');
    this.logger.help(chalk.underline('Users'));
    this.logger.help('');
    this.logger.help(chalk.cyan('awesomebox login'));
    this.logger.help(chalk.gray("Come on in! The water is great!"));
    this.logger.help('');
    this.logger.help(chalk.cyan('awesomebox logout'));
    this.logger.help(chalk.gray("If you really need to go, then fine. You can go."));
    this.logger.help('');
    this.logger.help(chalk.cyan('awesomebox reserve'));
    this.logger.help(chalk.gray("Not a user yet? Want to be?"));
    return cb();
  };

}).call(this);
