tubing = require '../lib/tubing'

TwitterSource = (emit) ->
  tweet = -> emit(tweet: 'Hello @mattinsler, you should check out http://awesomebox.es')
  setInterval(tweet, 5000)
  tweet()

LogSink = (err, cmd) ->
  console.log 'LogSink!'
  console.log arguments

TweetTokenizer = (cmd, done) ->
  cmd.tokens = cmd.tweet.split(/\s+/)
  done()

extract_urls = (cmd, done) ->
  d = @defer()
  
  setTimeout ->
    cmd.urls = cmd.tokens.filter (token) ->
      /^https?:\/\/?[\/\.a-zA-Z0-9]+/.test(token)
    d.resolve()
  , 2000
  
  d.promise

shorten_urls = (cmd, done) ->
  done()

extract_names = (cmd, done) ->
  cmd.names = cmd.tokens.filter (token) ->
    token[0] is '@' and token.length > 1
  done()


exit_early = (cmd, done) ->
  @exit_pipeline()


UrlExtractionPipeline = tubing.pipeline('URL Extracter')
  .then(extract_urls)
  .then(shorten_urls)

TwitterPipeline = tubing.pipeline('Twitter Pipeline')
  .then(tubing.exit_unless_config_true('process'))
  # .then(tubing.exit_if('tweet'))
  # .then(tubing.exit_if_config((c) -> c.process is false))
  # .then(tubing.exit_if('not tweet'))
  # .then(tubing.exit_if_config((c) -> c.process is false))
  # .then(exit_early)
  .then(TweetTokenizer)
  .then(extract_names, UrlExtractionPipeline)


tweet = 'Hello @mattinsler, you should check out http://awesomebox.es'

sink = tubing.sink(LogSink)
source = tubing.source(TwitterSource)

pipeline = TwitterPipeline.configure(
  process: true
)

pipeline.publish_to(sink)
source.publish_to(pipeline)
