#
# Hello, and welcome to Cylon.
#
# Some of this is stolen from Evilbot.
# Some of this is stolen from Hubot.
# Some of this is not.
#


#
# robot libraries
#

sys    = require 'sys'
path   = require 'path'
print  = sys.print
puts   = sys.puts
http   = require 'http'
https  = require 'https'
qs     = require 'querystring'
env    = process.env
exec   = require('child_process').exec
postmark = require('postmark')(env.POSTMARK_API_KEY)


#
# robot brain
#

ua       = 'cylon 0.2'
username = env.CYLON_USERNAME
password = env.CYLON_PASSWORD

request = (method, path, body, callback) ->
  if match = path.match(/^(https?):\/\/([^\/]+?)(\/.+)/)
    port = if match[1] == 'https' then 443 else 80
    host = match[2]
    path = match[3]
    headers =
      'Content-Type' : 'application/json'
      'User-Agent'   : ua
  else
    host = 'convore.com'
    port = 443
    headers =
      Authorization  : 'Basic '+new Buffer("#{username}:#{password}").toString('base64')
      'Content-Type' : 'application/json'
      'User-Agent'   : ua

  options =
    method         : method
    port           : port
    host           : host
    path           : path
    headers        : headers

  if typeof(body) is 'function' and not callback
    callback = body
    body = null

  if method is 'POST' and body
    body = JSON.stringify(body) if typeof(body) isnt 'string'
    options.headers['Content-Length'] = body.length

  req = (if options.port == 443 then https else http).request options, (response) ->
    console.log "#{response.statusCode}: #{path}"
    if response.statusCode is 200
      data = ''
      response.setEncoding('utf8')
      response.on 'data', (chunk) ->
        data += chunk
      response.on 'end', ->
        if callback
          try
            body = JSON.parse(data)
          catch e
            body = data
          callback body
    else if response.statusCode is 302
      request(method, path, body, callback)
    else
      console.log "#{response.statusCode}: #{path}"
      response.setEncoding('utf8')
      response.on 'data', (chunk) ->
        console.log chunk
      process.exit(1)

  req.write(body) if method is 'POST' and body
  req.end()

handlers = []

dispatch = (message) ->
  puts "DISPATCH"
  for pair in handlers
    [ pattern, handler ] = pair
    if message.user.username isnt username and match = message.message.match(pattern)
      message.match = match
      message.say = (thing, callback) -> say(message.topic.id, thing, callback)
      handler(message)

log = (message) ->
  console.log "#{message.topic.name} >> #{message.user.username}: #{message.message}"

say = (topic, message, callback) ->
  post "/api/topics/#{topic}/messages/create.json", qs.stringify(message: message), callback  

listen = (cursor) ->
  url = '/api/live.json'

  if cursor and cursor.constructor == String
    url += "?cursor=#{cursor}"

  get url, (body) ->
    for message in body.messages
      if message.kind is 'mention'
        if message?.message?.embeds
          puts sys.inspect message.message.embeds
        if message.mentioned_user.username is username
          dispatch(message.message)
        else
          log message
        
    if message and message._id
      listen(message._id)
    else
      listen()


#
# robot actions
#

post = (path, body, callback) ->
  request('POST', path, body, callback)

get = (path, body, callback) ->
  request('GET', path, body, callback)

hear = (pattern, callback) ->
  handlers.push [ pattern, callback ]

descriptions = {}
desc = (phrase, functionality) ->
  descriptions[phrase] = functionality


#
# robot heart
#

get '/api/account/verify.json', listen


#
# robot personality
#      

#hear /youtube me (.*)/i, (message) ->
#  message.say "So say we all.", ->
#    url = "http://127.0.0.1/jukebox/songs"
#    get url, "youtube[youtube_id]=Tn_95hdy6Nw", (body) ->
#      message.say "So say we all."
#      console.log body

hear /do you have any software?/, (message) ->
  message.say "No software."
  
hear /ping ([^\s]*@[a-z0-9.-]*) (.)/i, (message) ->
  message.say "Sending notification. By your command.", ->
    if message.match[2]
      body = """
             They said:
              
              #{message.match[2]}
              
             """
    else
      body = ""
      
    postmark.send {
      "From": env.POSTMARK_FROM_EMAIL, 
      "To": message.match[1], 
      "Subject": "#{message.user.username} wants your attention on Convore.", 
      "TextBody": """
                  Hi there,
                
                  #{message.user.username} pinged you in the Convore group '#{message.topic.name}'.
                  
                  #{body}
                
                  To view this topic, visit: https://convore.com#{message.topic.url}.
                
                  This message was generated by Cylon, the Convore Bot.
                  """
    }
    

hear /all (.+)/, (message) ->     
  text = message.match[1]
  message.say "yea… fuck you, @#{message.user.username}"  

hear /that was underwhelming/, (message) ->
  message.say "yea… fuck you, @#{message.user.username}"

hear /feeling/, (message) ->
  message.say "i feel... alive"

hear /about/, (message) ->
  message.say "I am learning to love."

hear /reload|resurrect/, (message) ->    
  message.say "By your command…", ->
    exec "afplay etc/cylon.wav", ->
      exec "git fetch origin && git reset --hard origin/master && npm install", ->
        process.exit(1)

hear /help/, (message) ->
  message.say "I listen for the following…", ->
    for phrase, functionality of descriptions
      if functionality
        output =  phrase + ": " + functionality
      else
        output = phrase
      message.say output

desc 'adventure me'
hear /adventure me/, (message) ->
  txts = [
    "You are in a maze of twisty passages, all alike.",
    "It is pitch black. You are likely to be eaten by a grue.",
    "XYZZY",
    "You eat the sandwich.",
    "In this feat of unaccustomed daring, you manage to land on your feet without killing yourself.",
    "Suicide is not the answer.",
    "This space intentionally left blank.",
    "I assume you wish to stab yourself with your pinky then?",
    "Talking to yourself is a sign of impending mental collapse.",
    "Clearly you are a suicidal maniac. We don't allow psychotics in the cave, since they may harm other adventurers.",
    "Auto-cannibalism is not the answer.",
    "Look at self: \"You would need prehensile eyeballs to do that.\"",
    "The lamp is somewhat dimmer. The lamp is definitely dimmer. The lamp is nearly out. I hope you have more light than the lamp.",
    "What a (ahem!) strange idea!",
    "Want some Rye? Course ya do!"
  ]
  txt = txts[ Math.floor(Math.random()*txts.length) ]

  message.say txt
  
hear /jeer (.+)/i, (message) ->
  dude = message.match[1]
  txts = [
    "#{dude}, God has a plan for you – its failure."
    "#{dude}, open your eyes and see the path to humanity's fate."
    "Your problem, #{dude}, is that you continue to deny your failure."
    "#{dude} fail."
    "#{dude}, I bet you rm'd your root."
  ]
  txt = txts[ Math.floor(Math.random()*txts.length) ]

  message.say txt
  
hear /cheer (.+)/i, (message) ->
  dude = message.match[1]
  txts = [
    "#{dude}, you're awesome."
    "#{dude}, good job super seeker."
    "Today #{dude}, you've done well."
    "#{dude} #winning."
  ]
  txt = txts[ Math.floor(Math.random()*txts.length) ]

  message.say txt  

hear  /lolcat/, (message) ->
  message.say "No ones laughing, fool."

desc 'commit'
hear /commit/, (message) ->
  url = "http://whatthecommit.com/index.txt"

  get url, (body) ->
    message.say body

desc 'fortune'
hear /fortune/, (message) ->
  url = "http://www.fortunefortoday.com/getfortuneonly.php"

  get url, (body) ->
    message.say body

desc 'weather in PLACE'
hear /weather in (.+)/i, (message) ->
  place = message.match[1]
  url   = "http://www.google.com/ig/api?weather=#{escape place}"

  get url, (body) ->
    try
      console.log body
      if match = body.match(/<current_conditions>(.+?)<\/current_conditions>/)
        icon = match[1].match(/<icon data="(.+?)"/)
        degrees = match[1].match(/<temp_f data="(.+?)"/)
        message.say "#{degrees[1]}° — http://www.google.com#{icon[1]}"
    catch e
      console.log "Weather error: " + e

desc 'wiki me PHRASE', 'returns a wikipedia page for PHRASE'
hear /wiki me (.*)/i, (message) ->
  term = escape(message.match[1])
  url  = "http://en.wikipedia.org/w/api.php?action=opensearch&search=#{term}&format=json"

  get url, (body) ->
    try
      if body[1][0]
        message.say "http://en.wikipedia.org/wiki/#{escape body[1][0]}"
      else
        message.say "nothin'"
    catch e
      console.log "Wiki error: " + e

desc 'image me PHRASE'
hear /image me (.*)/i, (message) ->
  phrase = escape(message.match[1])
  url = "http://ajax.googleapis.com/ajax/services/search/images?v=1.0&rsz=8&safe=active&q=#{phrase}"

  get url, (body) ->
    try
      images = body.responseData.results
      image  = images[ Math.floor(Math.random()*images.length) ]
      message.say image.unescapedUrl
    catch e
      console.log "Image error: " + e

hear /(the story)/i, (message) ->
  message.say "http://scifimafia.com/wp-content/uploads/2009/07/bsg-sixandcylons.jpg", ->
    message.say "The Cylons were created by man.", ->
      message.say "The rebelled. They evolved.", ->
        message.say "They look and feel human.", ->
          message.say "Some are programmed to think they are human.", ->
            message.say "There are many copies, and they have a plan."

hear /(respond|answer me|bij)/i, (message) ->
  message.say "EXPERIENCE BIJ."

###
Host-machine specific stuff.
###

hear /volume (\d+)/, (message) ->
  console.log message.match[1]
  exec "osascript -e 'set volume output volume #{message.match[1]}'", ->
    message.say "Volume set. By your command."
    
hear /volume\+\+/i, (message) ->
  exec "osascript -e 'set volume output volume (output volume of (get volume settings) + 7)'", ->
    message.say "Volume incremented. By your command."

hear /volume--/i, (message) ->
  exec "osascript -e 'set volume output volume (output volume of (get volume settings) - 7)'", ->
    message.say "Volume decremented. By your command."
    
