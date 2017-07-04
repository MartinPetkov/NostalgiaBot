# Description:
#   Remember past employees that you miss.
#
# Commands:
#   nostalgiabot (Remind me of|Quote) <person> - Digs up a memorable quote from the past.
#   nostalgiabot Random quote - Dig up random memory from random person
#   nostalgiabot Remember that <person> said "<quote>" - Stores a new quote, to forever remain in the planes of Nostalgia.
#   nostalgiabot Who do you remember? - See the memories the NostalgiaBot holds on to.
#   nostalgiabot Start convo with <person1>, <person2> [, <person3>...] - Start a nonsensical convo
#   nostalgiabot Alias <name> as <alias1> [<alias2> ...] - Add nicknames to the memorees
#   nostalgiabot Start Guess Who - Start a game of Guess Who!
#   nostalgiabot Show Guess Who - Show the current quote to guess
#   nostalgiabot Guess <person> - Guess who said the current quote. Ends when guessed correctly.
#   nostalgiabot End Guess Who - End the game of Guess Who!.
#   nostalgiabot Give up - End the game of Guess Who! and get the answer.
#   nostalgiabot Hacker me - Get a 100% real quote from a professional hacker.
#   nostalgiabot BS me - Get a technobable quote that sounds almost real.
#   nostalgiabot Commit message me - Generate your next commit message
#   nostalgiabot Remember past - Gather memories from the past
#   nostalgiabot stats - See how memorable everyone is
#   nostalgiabot ? - Ring the nostalgiaphone
#
# Author:
#   MartinPetkov

fs = require 'fs'
request = require 'request'
rg = require('random-greetings')

adminsFile = 'admins.json'
loadFile = (fileName) ->
    return JSON.parse((fs.readFileSync fileName, 'utf8').toString().trim())

admins = loadFile(adminsFile)

toTitleCase = (str) ->
    str.replace /\w\S*/g, (txt) ->
        txt[0].toUpperCase() + txt[1..txt.length - 1].toLowerCase()

memoryDir = "./memories"

weekday = new Array(7);
weekday[0]=  "Sunday";
weekday[1] = "Monday";
weekday[2] = "Tuesday";
weekday[3] = "Wednesday";
weekday[4] = "Thursday";
weekday[5] = "Friday";
weekday[6] = "Saturday";

memories = {}

rememberPast = () ->
    memories = {}
    quoteFiles = fs.readdirSync memoryDir
    for quoteFile in quoteFiles
        do (quoteFile) ->
            name = "#{quoteFile}".toString().toLowerCase().trim()
            quotes = (fs.readFileSync "#{memoryDir}/#{quoteFile}", 'utf8').toString().split("\n").filter(Boolean)
            memories[name] = quotes

rememberPast()

randomQuoteRespond = (res, nostalgiaName) ->
    displayName = toTitleCase(nostalgiaName)
    if ! (nostalgiaName of memories)
        res.send "I don't remember #{displayName}"
        return

    randomQuote = (res.random memories[nostalgiaName])

    if ! randomQuote
        res.send "No memories to remember"
        return

    if (randomQuote.indexOf('$current_day') > 0)
        d = new Date()
        randomQuote = randomQuote.replace('$current_day', weekday[d.getDay()])

    res.send "\"#{randomQuote}\" - #{displayName}"

msgRespond = (res) ->
    nostalgiaName = res.match[1].toLowerCase().trim()

    randomQuoteRespond(res, nostalgiaName)

randomNameAndQuoteRespond = (res) ->
    names = (name for name of memories)
    nostalgiaName = res.random names

    randomQuoteRespond(res, nostalgiaName)


shuffleNames = (names) ->
    i = names.length
    while --i
        j = Math.floor(Math.random() * (i+1))
        [names[i], names[j]] = [names[j], names[i]] # use pattern matching to swap

    return names

convoRespond = (res) ->
    allNames = (res.match[1].toLowerCase().trim() + " " + res.match[2].toLowerCase().trim()).split(",")
    fixedNames = []
    for name in allNames
        name = name.toLowerCase().trim()
        fixedNames.push name
    allNames = fixedNames

    # Generate quotes
    convoMap = {}
    for name in allNames
        if !(name of memories)
            res.send "I don't recognize #{name}"
            return

        firstQuote = (res.random memories[name])
        secondQuote = (res.random memories[name])
        if memories[name].length > 1
            while secondQuote == firstQuote
                secondQuote = (res.random memories[name])

        personQuotes = []
        personQuotes.push "#{name}: " + firstQuote
        personQuotes.push "#{name}: " + secondQuote
        convoMap[name] = personQuotes

    allNames = Object.keys(convoMap)

    # Assemble quotes
    convo = ""
    lastName = ""
    i = 2
    while i--
        allNames = shuffleNames(allNames)
        while allNames[0] == lastName && allNames.length > 1
            allNames = shuffleNames(allNames)
        lastName = allNames[allNames.length-1]

        for name in allNames
            convo += convoMap[name][i] + "\n"

    res.send convo

aliasRespond = (res) ->
    regularName = res.match[1].toLowerCase().trim()
    aliases = res.match[2].toLowerCase().trim().split(" ")

    if !(regularName of memories)
        res.send "Could not find #{regularName} in vast memory bank"
        return

    for alias in aliases
        if alias of memories
            res.send "Alias \"#{alias}\" already exists as a separate memory"
        else
            process.chdir(memoryDir)
            fs.symlinkSync(regularName, alias)
            res.send "Aliased #{regularName} as #{alias}!"
            process.chdir('..')

    rememberPast()

hackerRespond = (res) ->
    hackerUrl = "https://hacker.actor/quote"
    request.get {uri:"#{hackerUrl}", json: true}, (err, r, data) ->
        if err
            res.send "The Hackers are too busy stealing your data to provide a quote"
        else
            res.send "\"#{data.quote}\" - l33t h4xx0r"

commitMessageRespond = (res) ->
    commitMessageUrl = "http://www.whatthecommit.com/index.txt"
    request.get {uri:"#{commitMessageUrl}", json: true}, (err, r, data) ->
        if err
            res.send "Too busy coding to generate a message"
        else
            res.send "#{data}"

bsRespond = (res) ->
    # From http://www.atrixnet.com/bs-generator.html
    res.send "\"" + toTitleCase generateBS() + "\" - Lead Synergist"

yoloRespond = (res) ->
    res.send "alias yolo='git commit -am \"DEAL WITH IT\" && git push -f origin master'"

rememberPastRespond = (res) ->
    rememberPast()
    res.send "All memories have been gathered!"

statsRespond = (res) ->
    stats = "Memories made:\n"
    for person in Object.keys(memories)
        stats = stats + "#{person}: " + memories[person].length + "\n"

    res.send stats

saveQuotes = (nostalgiaName) ->
    quotePath = "#{memoryDir}/#{nostalgiaName}"
    quotes = memories[nostalgiaName]

    # Write entire list of quotes to quotePath
    fs.writeFileSync(quotePath, '')
    for q in quotes
        do (q) ->
            fs.appendFileSync(quotePath, "#{q}\n")

rememberPerson = (res) ->
    nostalgiaName = res.match[1].toLowerCase().trim()
    newQuote = res.match[2]

    # Make sure the messages don't contain non-alphabetical characters
    if /.*[^a-zA-Z_0-9 @].*/.test(nostalgiaName)
        res.send "I can't remember names with fancy symbols and characters"
    else
        if !(nostalgiaName of memories)
            memories[nostalgiaName] = []

        # Add new quote if it does not exist
        quotes = memories[nostalgiaName]
        if (quotes.indexOf(newQuote) < 0)
            quotes.push(newQuote)
        memories[nostalgiaName] = quotes

        saveQuotes(nostalgiaName)

        res.send "Memory stored!"

        rememberPast()


# Admin functions
forgetPersonRespond = (res) ->
    senderName = res.message.user.name
    if ! (senderName in admins)
        res.send "You must be an admin to perform this function"
        return

    nostalgiaName = res.match[1].toLowerCase().trim()

    if ! (nostalgiaName of memories)
        res.send "I don't remember #{nostalgiaName}"
        return

    # Delete the file with memories
    quotePath = "#{memoryDir}/#{nostalgiaName}"
    fs.unlinkSync(quotePath)
    rememberPast()

    res.send "#{nostalgiaName} forgotten forever :'("

forgetMemoryRespond = (res) ->
    senderName = res.message.user.name
    if ! (senderName in admins)
        res.send "You must be an admin to perform this function"
        return

    nostalgiaName = res.match[1].toLowerCase().trim()
    if ! (nostalgiaName of memories)
        res.send "I don't remember #{nostalgiaName}"
        return

    quoteToForget = res.match[2]
    if ! (quoteToForget in memories[nostalgiaName])
        res.send "I don't remember #{nostalgiaName} saying \"#{quoteToForget}\""
        return

    memories[nostalgiaName].splice(memories[nostalgiaName].indexOf(quoteToForget), 1)
    saveQuotes(nostalgiaName)

    rememberPast()

    res.send "Forgot that #{nostalgiaName} said \"#{quoteToForget}\""

reattributeRespond = (res) ->
    senderName = res.message.user.name
    if ! (senderName in admins)
        res.send "You must be an admin to perform this function"
        return

    quote = res.match[1]
    oldName = res.match[2].toLowerCase().trim()
    if ! (oldName of memories)
        res.send "I don't remember #{oldName}"
        return

    if ! (quote in memories[oldName])
        res.send "I don't remember #{oldName} saying \"#{quote}\""
        return

    newName = res.match[3].toLowerCase().trim()
    if ! (newName of memories)
        res.send "I don't remember #{newName}"
        return

    # Actually move the quote over
    memories[oldName].splice(memories[oldName].indexOf(quote), 1)
    if (memories[newName].indexOf(quote) < 0)
        memories[newName].push(quote)
    saveQuotes(oldName)
    saveQuotes(newName)

    rememberPast()

    res.send "Quote \"#{quote}\" reattributed from #{oldName} to #{newName}"


guessWhoPlaying = false
guessWhoTarget = ''
guessWhoQuote = ''
startGuessWhoRespond = (res) ->
    guessWhoPlaying = true
    res.send "Guess Who game started!"

    guessWhoTarget = res.random Object.keys(memories)
    guessWhoQuote = res.random memories[guessWhoTarget]
    res.send "Who said \"#{guessWhoQuote}\"?"

showGuessWhoQuoteRespond = (res) ->
    if guessWhoPlaying
        res.send "Who said \"#{guessWhoQuote}\"?"
    else
        res.send "You are not playing Guess Who right now"

guessRespond = (res) ->
    senderName = res.message.user.name
    guess = res.match[1].toLowerCase().trim()
    if guessWhoPlaying
        if guess == guessWhoTarget
            res.send "Correct! #{toTitleCase senderName} correctly guessed that #{toTitleCase guessWhoTarget} said \"#{guessWhoQuote}\""
            endGuessWhoRespond res
        else
            res.send "Wrong! Try again"
    else
        res.send "You are not playing Guess Who right now"

endGuessWhoRespond = (res) ->
    guessWhoPlaying = false
    guessWhoTarget = ''
    guessWhoQuote = ''
    res.send "Guess Who game over"

giveUpRespond = (res) ->
    res.send "You gave up! #{toTitleCase guessWhoTarget} said \"#{guessWhoQuote}\""
    endGuessWhoRespond(res)


bobRossOnVacation = false
returnFromVacation = () ->
    bobRossOnVacation = false

bobRossRespond = (res) ->
    if !(bobRossOnVacation)
        res.send "There are no bugs, just happy little accidents!"
        res.send "http://s.newsweek.com/sites/www.newsweek.com/files/2014/09/29/1003bobrosstoc.jpg"

        bobRossOnVacation = true
        setTimeout(returnFromVacation, 3600000) # 1h

whoDoYouRememberRespond = (res) ->
    res.send Object.keys(memories)

nostalgiaphoneRespond = (res) ->
    res.send 'You rang?'

greetingRespond = (res) ->
    res.send "#{rg.greet()} @#{res.message.user.name}!"

module.exports = (robot) ->
    robot.respond /Remember +(?:that )?(.+) +said +"([^"]+)"/i, rememberPerson

    # Admin functions
    robot.respond /Forget (\S+)$/i, forgetPersonRespond
    robot.respond /Forget that (.+) +said +"([^"]+)"$/i, forgetMemoryRespond
    robot.respond /Reattribute "([^"]+)" from (.+) to (.+)/i, reattributeRespond

    robot.respond /Remind me of (.*)/i, msgRespond
    robot.respond /Quote (.*)/i, msgRespond
    robot.respond /Random quote/i, randomNameAndQuoteRespond

    robot.respond /Start convo with (\S+)( *, *.+)+/i, convoRespond
    robot.respond /Alias (\S+) as ( *.+)+/i, aliasRespond

    robot.respond /Hacker me/i, hackerRespond
    robot.respond /BS me/i, bsRespond
    robot.respond /Commit message me/i, commitMessageRespond
    robot.respond /YOLO/i, yoloRespond

    robot.respond /Who do you remember\??/i, whoDoYouRememberRespond

    robot.respond /Remember Past/i, rememberPastRespond
    robot.respond /stats/i, statsRespond

    robot.respond /( +\?)/i, nostalgiaphoneRespond

    robot.respond /start guess who/i, startGuessWhoRespond
    robot.respond /show guess who/i, showGuessWhoQuoteRespond
    robot.respond /guess (.*)/i, guessRespond
    robot.respond /end guess who/i, endGuessWhoRespond
    robot.respond /give up/i, giveUpRespond

    robot.hear /.*that's a bug.*/i, bobRossRespond
    robot.hear /.*(((good)? +morning)|greetings),? +@?nostalgiabot!?.*/i, greetingRespond

`// All code below from http://www.atrixnet.com/bs-generator.html, I take no credit for it
function randomarray(a) {
  var i;
  for (i=a.length;i--;) {
    var j = Math.floor((i+1)*Math.random());
    var temp = a[i];
    a[i] = a[j];
    a[j] = temp;
  }
return a;
}

function generateBS() {
    var adverbs = new Array (
        'appropriately', 'assertively', 'authoritatively', 'collaboratively', 'compellingly', 'competently', 'completely',
        'continually', 'conveniently', 'credibly', 'distinctively', 'dramatically', 'dynamically', 'efficiently',
        'energistically', 'enthusiastically', 'globally', 'holisticly', 'interactively', 'intrinsically', 'monotonectally',
        'objectively', 'phosfluorescently', 'proactively', 'professionally', 'progressively', 'quickly', 'rapidiously',
        'seamlessly', 'synergistically', 'uniquely', 'fungibly'
    );

    var verbs = new Array (
        'actualize', 'administrate', 'aggregate', 'architect', 'benchmark', 'brand', 'build', 'communicate', 'conceptualize',
        'coordinate', 'create', 'cultivate', 'customize', 'deliver', 'deploy', 'develop', 'disintermediate', 'disseminate',
        'drive', 'embrace', 'e-enable', 'empower', 'enable', 'engage', 'engineer', 'enhance', 'envisioneer', 'evisculate',
        'evolve', 'expedite', 'exploit', 'extend', 'fabricate', 'facilitate', 'fashion', 'formulate', 'foster', 'generate',
        'grow', 'harness', 'impact', 'implement', 'incentivize', 'incubate', 'initiate', 'innovate', 'integrate', 'iterate',
        'leverage existing', 'leverage other\'s', 'maintain', 'matrix', 'maximize', 'mesh', 'monetize', 'morph', 'myocardinate',
        'negotiate', 'network', 'optimize', 'orchestrate', 'parallel task', 'plagiarize', 'pontificate', 'predominate',
        'procrastinate', 'productivate', 'productize', 'promote', 'provide access to', 'pursue', 'recaptiualize',
        'reconceptualize', 'redefine', 're-engineer', 'reintermediate', 'reinvent', 'repurpose', 'restore', 'revolutionize',
        'scale', 'seize', 'simplify', 'strategize', 'streamline', 'supply', 'syndicate', 'synergize', 'synthesize', 'target',
        'transform', 'transition', 'underwhelm', 'unleash', 'utilize', 'visualize', 'whiteboard', 'cloudify', 'right-shore'
    );

    var adjectives = new Array (
        '24/7', '24/365', 'accurate', 'adaptive', 'alternative', 'an expanded array of', 'B2B', 'B2C', 'backend',
        'backward-compatible', 'best-of-breed', 'bleeding-edge', 'bricks-and-clicks', 'business', 'clicks-and-mortar',
        'client-based', 'client-centered', 'client-centric', 'client-focused', 'collaborative', 'compelling',  'competitive',
        'cooperative', 'corporate', 'cost effective', 'covalent', 'cross functional', 'cross-media', 'cross-platform',
        'cross-unit', 'customer directed', 'customized', 'cutting-edge', 'distinctive', 'distributed', 'diverse', 'dynamic',
        'e-business', 'economically sound', 'effective', 'efficient', 'emerging', 'empowered', 'enabled', 'end-to-end',
        'enterprise', 'enterprise-wide', 'equity invested', 'error-free', 'ethical', 'excellent', 'exceptional', 'extensible',
        'extensive', 'flexible', 'focused', 'frictionless', 'front-end', 'fully researched', 'fully tested', 'functional',
        'functionalized', 'future-proof', 'global', 'go forward', 'goal-oriented', 'granular', 'high standards in',
        'high-payoff', 'high-quality', 'highly efficient', 'holistic', 'impactful', 'inexpensive', 'innovative',
        'installed base', 'integrated', 'interactive', 'interdependent', 'intermandated', 'interoperable', 'intuitive',
        'just in time', 'leading-edge', 'leveraged', 'long-term high-impact', 'low-risk high-yield', 'magnetic',
        'maintainable', 'market positioning', 'market-driven', 'mission-critical', 'multidisciplinary', 'multifunctional',
        'multimedia based', 'next-generation', 'one-to-one', 'open-source', 'optimal', 'orthogonal', 'out-of-the-box',
        'pandemic', 'parallel', 'performance based', 'plug-and-play', 'premier', 'premium', 'principle-centered', 'proactive',
        'process-centric', 'professional', 'progressive', 'prospective', 'quality', 'real-time', 'reliable', 'resource-sucking',
        'resource-maximizing', 'resource-leveling', 'revolutionary', 'robust', 'scalable', 'seamless', 'stand-alone',
        'standardized', 'standards compliant', 'state of the art', 'sticky', 'strategic', 'superior', 'sustainable',
        'synergistic', 'tactical', 'team building', 'team driven', 'technically sound', 'timely', 'top-line', 'transparent',
        'turnkey', 'ubiquitous', 'unique', 'user-centric', 'user friendly', 'value-added', 'vertical', 'viral', 'virtual',
        'visionary', 'web-enabled', 'wireless', 'world-class', 'worldwide', 'fungible', 'cloud-ready', 'elastic', 'hyper-scale',
        'on-demand', 'cloud-based', 'cloud-centric', 'cloudified'
    );

    var nouns = new Array (
        'action items', 'alignments', 'applications', 'architectures', 'bandwidth', 'benefits',
        'best practices', 'catalysts for change', 'channels', 'collaboration and idea-sharing', 'communities', 'content',
        'convergence', 'core competencies', 'customer service', 'data', 'deliverables', 'e-business', 'e-commerce', 'e-markets',
        'e-tailers', 'e-services', 'experiences', 'expertise', 'functionalities', 'growth strategies', 'human capital',
        'ideas', 'imperatives', 'infomediaries', 'information', 'infrastructures', 'initiatives', 'innovation',
        'intellectual capital', 'interfaces', 'internal or "organic" sources', 'leadership', 'leadership skills',
        'manufactured products', 'markets', 'materials', 'meta-services', 'methodologies', 'methods of empowerment', 'metrics',
        'mindshare', 'models', 'networks', 'niches', 'niche markets', 'opportunities', '"outside the box" thinking', 'outsourcing',
        'paradigms', 'partnerships', 'platforms', 'portals', 'potentialities', 'process improvements', 'processes', 'products',
        'quality vectors', 'relationships', 'resources', 'results', 'ROI', 'scenarios', 'schemas', 'services', 'solutions',
        'sources', 'strategic theme areas', 'supply chains', 'synergy', 'systems', 'technologies', 'technology',
        'testing procedures', 'total linkage', 'users', 'value', 'vortals', 'web-readiness', 'web services', 'fungibility',
        'clouds', 'nosql', 'storage', 'virtualization'
    );

    adjectives = randomarray(adjectives);
    nouns = randomarray(nouns);
    adverbs = randomarray(adverbs);
    verbs = randomarray(verbs);

    var x;

    var statement = adverbs[adverbs.length-1];
    adverbs.length -= 1;
    statement = statement + " " + verbs[verbs.length-1];
    verbs.length -= 1;
    statement = statement + " " + adjectives[adjectives.length-1];
    adjectives.length -= 1;
    statement = statement + " " + nouns[nouns.length-1];
    nouns.length -= 1;

    return statement;
}`
