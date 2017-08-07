gulp = require('gulp')
coffee = require('gulp-coffee')
autowatch = require('gulp-autowatch')
notifier = require('node-notifier')

paths =
  js: '_coffee/**/*.coffee'

gulp.task 'default', Object.keys(paths)

swallowError = (error) ->
  console.log error.toString()
  @emit 'end'
  notifier.notify
    title: "(gulp) Build error"
    message: error.toString()
  return

gulp.task 'js', ->
  gulp.src paths['js']
    .pipe coffee coffee: require('coffeescript')
    .on 'error', swallowError
    .pipe gulp.dest './'

gulp.task 'watch', [ 'default' ], ->
  autowatch gulp, paths
  return
