module.exports = function(grunt) {
  
  grunt.loadNpmTasks('grunt-contrib');
  // grunt.loadNpmTasks('grunt-simple-mocha');

  // Project configuration.
  grunt.initConfig({
    pkg: '<json:package.json>',
    clean: ['dist'],
    coffee: {
      compile: {
        files: {
          'dist/*.js': 'lib/**/*.coffee'
        }
      }
    },
    simplemocha: {
      all: {
        src: 'test/**/*.coffee'
      }
    }
  });
  
  // grunt.registerTask('test', 'simplemocha');
  // Default task.
  grunt.registerTask('default', ['clean', 'coffee']);
};