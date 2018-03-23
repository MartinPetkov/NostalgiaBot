# Description:
#   Remember past employees that you miss.
#
# Commands:
#   nostalgiabot Remind (me|<person>) of <person> - Digs up a memorable quote from the past, and remind the person.
#   nostalgiabot Quote <person> - Digs up a memorable quote from the past.
#   nostalgiabot Random quote - Dig up random memory from random person
#   nostalgiabot Remember that <person> said "<quote>" - Stores a new quote, to forever remain in the planes of Nostalgia.
#   nostalgiabot Who do you remember? - See the memories the NostalgiaBot holds on to.
#   nostalgiabot Converse <person1>, <person2> [, <person3>...] - Start a nonsensical convo
#   nostalgiabot Alias <name> as <alias1> [<alias2> ...] - Add nicknames to the memorees
#   nostalgiabot Start Guess Who - Start a game of Guess Who!
#   nostalgiabot Show Guess Who - Show the current quote to guess
#   nostalgiabot Guess <person> - Guess who said the current quote. Ends when guessed correctly.
#   nostalgiabot End Guess Who - End the game of Guess Who!.
#   nostalgiabot Give up - End the game of Guess Who! and get the answer.
#   nostalgiabot Hacker me - Get a 100% real quote from a professional hacker.
#   nostalgiabot Commit message me - Generate your next commit message
#   nostalgiabot Remember past - Gather memories from the past
#   nostalgiabot stats - See how memorable everyone is
#   nostalgiabot ? - Ring the nostalgiaphone
#
# Author:
#   MartinPetkov

fs = require 'fs'
request = require 'request'
rg = require 'random-greetings'
schedule = require 'node-schedule'

adminsFile = 'admins.json'
loadFile = (fileName) ->
    return JSON.parse((fs.readFileSync fileName, 'utf8').toString().trim())

admins = loadFile(adminsFile)

toTitleCase = (str) ->
    str.replace /\w\S*/g, (txt) ->
        txt[0].toUpperCase() + txt[1..txt.length - 1].toLowerCase()

isUndefined = (myvar) ->
    return typeof myvar == 'undefined'

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

randomQuoteRespond = (res, nostalgiaName, targetName) ->
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

    response = if isUndefined(targetName) then '' else "@#{targetName} Do you remember this?\n\n"
    response += "\"#{randomQuote}\" - #{displayName}"

    res.send response

remindRespond = (res) ->
    targetName = res.match[1].toLowerCase().trim()
    nostalgiaName = res.match[2].toLowerCase().trim()

    if targetName.toLowerCase() == 'me'
        targetName = res.message.user.name

    randomQuoteRespond(res, nostalgiaName, targetName)

quoteRespond = (res) ->
    nostalgiaName = res.match[1].toLowerCase().trim()

    randomQuoteRespond(res, nostalgiaName)

randomNameAndQuoteRespond = (res) ->
    nostalgiaName = res.random Object.keys(memories)

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
        # Remove @s at the front
        if name[0] == '@'
            name = name.substr(1)

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

    # Filter out @all's
    newQuote = newQuote.replace(/@all/g, "[at]all")

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


quoteOfTheDaySend = (robot) ->
    return () ->
        qotd = 'Here is your Quote Of The Day™!\n\n'
        names = Object.keys(memories)
        randomName = names[Math.round(Math.random() * (names.length - 1))]
        quotes = memories[randomName]
        randomQuote = quotes[Math.round(Math.random() * (quotes.length - 1))]
        qotd += "\"#{randomQuote}\" - #{randomName}"
        robot.send room: process.env.GENERAL_ROOM_ID, qotd

qotdScheduleRespond = (res) ->
    res.send """
    #{process.env.QOTD_SCHEDULE.replace(/\ /g, '\t')}
    ┬\t┬\t┬\t┬\t┬\t┬
    |\t│\t│\t│\t│\t|
    │\t│\t│\t│\t│\t└ day of week (0 - 7) (0 or 7 is Sun)
    │\t│\t│\t│\t└─── month (1 - 12)
    │\t│\t│\t└────── day of month (1 - 31)
    │\t│\t└───────── hour (0 - 23)
    │\t└──────────── minute (0 - 59)
    └─────────────── second (0 - 59, OPTIONAL)
    """

module.exports = (robot) ->
    robot.respond /Remember +(?:that )?(.+) +said +"([^"]+)"/i, rememberPerson
    robot.respond /Remember +(?:that )?(.+) +said +“([^“”]+)”/i, rememberPerson

    # Admin functions
    robot.respond /Forget (\S+)$/i, forgetPersonRespond
    robot.respond /Forget that (.+) +said +"([^"]+)"$/i, forgetMemoryRespond
    robot.respond /Reattribute "([^"]+)" from (.+) to (.+)/i, reattributeRespond

    robot.respond /Remind @?(.+) of (.+)/i, remindRespond
    robot.respond /Quote (.+)/i, quoteRespond
    robot.respond /Random quote/i, randomNameAndQuoteRespond

    robot.respond /Converse (\S+)( *, *.+)+/i, convoRespond
    robot.respond /Alias (\S+) as ( *.+)+/i, aliasRespond

    robot.respond /Hacker me/i, hackerRespond
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
    robot.hear /.*(guten tag|hallo|hola|Góðan daginn|good morning|morning|sup|hey|hello|howdy|greetings|yo|hiya|welcome|bonjour|buenas dias|buenas noches|good day|what's up|what's happening|how goes it|howdy do|shalom),? +@?nostalgiabot!?.*/i, greetingRespond

    # Schedule a quote of the day
    schedule.scheduleJob process.env.QOTD_SCHEDULE, quoteOfTheDaySend(robot)
    robot.respond /qotd/i, qotdScheduleRespond
