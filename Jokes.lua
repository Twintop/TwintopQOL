local _, TwintopQOL = ...
TwintopQOL.Jokes = TwintopQOL.Jokes or {}

local L = TwintopQOL.Localization

-- Shipped joke list. Seeds a new install, and is what "Reset to Defaults" restores.
-- Players who never customize their list always use this (so they pick up new
-- jokes in addon updates); a custom list is stored in TwintopQOLSaved.jokes.
local DEFAULT_JOKES = {
    "What do ducks like on their tacos? Quackamole and beako de gallo.",
    "I don't like German sausages. They're the wurst.",
    "Which vegetable do you stand in line for? A queue-cumber.",
    "Everyone knows Albert Einstein was brilliant. His brother Frank, though, was a real monster.",
    "My wife says I'm the cheapest man in the world. Well, I'm not buying it.",
    "What do you call a funny drawing? A snickerdoodle.",
    "A friend asked me to play the part of Brutus in an upcoming play about Julius Caesar.",
    "What do you call a factory that makes okay products? A satisfactory.",
    "What do you call a sad strawberry? A blueberry.",
    "My physical therapist said I should do lunges to stay in shape. That would be a big step forward.",
    "I asked my dog what's two minus two. He said nothing.",
    "Where do you learn to make a banana split? Sundae school.",
    "Do you know why koala bears aren't really bears? They don't meet the koalafications.",
    "I used to be addicted to soap, but I'm clean now.",
    "What do you call it when a snowman throws a tantrum? A meltdown.",
    "Did you hear about the circus fire? It was in tents.",
    "How can you tell it's a dogwood tree? By the bark.",
    "Don't trust atoms. They make up everything!",
    "What kind of car does a sheep like to drive? A Lamborghini.",
    "If the early bird gets the worm, I'll sleep in until there's pancakes.",
    "I don't trust stairs. They're always up to something.",
    "Every time I take my dog to the park, the ducks try to bite him. That's what I get for buying a pure bread dog.",
    "Time flies like an arrow. Fruit flies like a banana.",
    "I used to hate facial hair, but then it grew on me.",
    "Most people can't tell the difference between entomology and etymology. I can't find the words for how much this bugs me.",
    "We're renovating the house, and the first floor is going great, but the second floor is another story.",
    "At first, I thought my chiropractor wasn't any good, but now I stand corrected.",
    "What breed of dog can jump higher than a skyscraper? Any breed of dog. Skyscrapers can't jump.",
    "What's the best way to watch a fly-fishing tournament? Live stream.",
    "I have a joke about chemistry, but I don't think it'll get a reaction.",
    "I have a joke about a broken pencil, but it's pointless.",
    "I have a joke about the flu, but I hope you don't get it.",
    "I have a joke about drilling, but it's boring.",
    "I have a joke about procrastination, but I'll tell it to you later.",
    "I have a joke about butter, but I'm not going to spread it.",
    "I could tell a joke about pizza, but it's a little cheesy.",
    "Don't buy anything made with Velcro. It's a total rip-off.",
    "I used to be addicted to the hokey pokey, but then I turned myself around.",
    "What do you call a donkey with only three legs? A wonkey.",
    "To whoever stole my copy of Microsoft Office, I will find you. You have my Word.",
    "What are the strongest days of the week? Saturday and Sunday. The rest are weak-days.",
    "Why do ducks have tail feathers? To cover their buttquacks.",
    "This graveyard looks overcrowded. People must be dying to get in there.",
    "What's brown and sticky? A stick.",
    "Why was the math textbook so sad? It had so many problems!",
    "I decided to sell my vacuum cleaner. It was just gathering dust.",
    "Why is a doctor always calm? Because they have a lot of patients.",
    "Five out of four people admit they're bad with fractions.",
    "I told my friend she drew her eyebrows too high. She seemed surprised!",
    "Don't sing in the shower! If you get soap in your mouth, it will turn into a soap opera.",
    "Did you ever notice ants don't get sick? They're full of anty-bodies.",
    "What did the mommy buffalo say to her son when he left for work? Bison.",
    "It really takes guts to be an organ donor.",
    "How do you deal with a fear of speed bumps? You slowly get over it.",
    "How do astronomers organize a party? They planet.",
    "What do you call a fibbing feral? A lion.",
    "My daughter screeched, 'Daaaaaad, you haven't listened to one word I've said, have you!?' What a strange way to start a conversation with me...",
    "A slice of apple pie is $2.50 in Jamaica and $3.00 in the Bahamas. These are the pie rates of the Caribbean.",
    "My friend keeps saying, 'Cheer up, druid. It could be worse. You could be stuck underground in a hole full of water.' I know he means well.",
    "What does a zombie vegetarian eat? 'GRRRAAAAAIIIINNNNS!'",
    "What did the pirate say on his 80th birthday? AYE MATEY!",
    "How many tickles does it take to make an octopus laugh? Ten-tickles.",
    "Wondering if they're ticklish? Test-tickles are a great place to start.",
    "I've just written a book called 'Fifty Shades of Gravy.' It's very saucy.",
    "The adjective for metal is metallic. But not so for iron... which is ironic.",
    "Welcome to the Sexual Innuendo Club. Thank you all for coming.",
    "My house got robbed and one of the items missing was my limbo set. I thought to myself... how low can these guys go?",
    "I called the paranoia hotline and they answered, 'How did you get this number?'",
    "What's a plumber's least favorite vegetable? Leeks.",
    "I had a fun childhood. My friends used to push me down the hill in old tires. They were Goodyears.",
    "Dentists always ask dumb questions like 'When's the last time you flossed?' Like dude, you were there!",
    "I got tired of being judged for going bald, so I went out and bought a cheap wig... It was a small price toupée.",
    "I once entered the world kleptomaniac championships. I took gold, silver, and bronze.",
    "I'm French and just moved abroad. People here are pretty insensitive and always joke about baguettes. They don't care that they're laughing at my pain.",
    "Does anybody know where a guy can find a person to hang out with, talk to, and enjoy spending time with? Asking for a friend.",
    "I've got a German friend who's a sound technician. I've got a Czech one too. Czech one too.",
    "I asked my wife if I was the only one she had ever been with. She said yes, all the others were nines and tens.",
    "I returned my lizard to the pet store because he wouldn't stop telling dad jokes. 'That's not a lizard,' the store clerk told me. 'That's a stand-up chameleon.'",
    "It's a five-minute walk from my house to the pub, and it's a 35-minute walk from the pub to my house. The difference is staggering.",
    "Did you know that your pupils are the last parts to stop working after you die? They dilate.",
    "Interviewer: Why should we hire you as a waiter? Me: For starters, I bring a lot to the table.",
    "I've just discovered that Bruce Lee had a vegetarian brother... Broco Lee.",
    "I started reading a horror story in braille. Something bad is about to happen, I can feel it.",
    "Why is the divorce rate so high among tennis players? To them, love means nothing.",
    "'Trojan' isn't a good name for a condom. Didn't the real Trojan horse burst open and let loads of little guys pour out?",
    "What do you call a line of men waiting to get haircuts? A barberqueue.",
    "What do you call sweaty boobs? Humidititties.",
    "How much does a rainbow weigh? Not much. They're actually pretty light!",
    "My friend blocked me on Facebook because I post too many bird puns. Well, toucan play at that game.",
    "I hate when my friends get mad at me for being lazy. It's not like I did anything.",
    "Many people are too judgmental... I can tell just by looking at them.",
    "I accidentally drank a bottle of invisible ink last night. I'm in the hospital now, waiting to be seen.",
    "Who hides in the bathroom at parties? The party-pooper.",
    "Someone has glued my pack of cards together... I don't know how to deal with it.",
    "I hate my job. All I do is crush cans all day. It's soda pressing.",
    "I went for a job interview at IKEA today. The manager said, 'Come in, make a seat.'",
    "My friend went bald years ago, but still carries his old comb with him. He just can't part with it.",
    "My wife is thinking of leaving me because of my obsession with poker, but I think she's bluffing.",
    "What do you call two monkeys who share an Amazon account? Prime mates.",
    "What do you call a short mother? A minimum.",
    "I don't mean to brag, but... cashiers are always checking me out.",
    "I was just looking at my ceiling. Not sure if it's the best ceiling in the world, but it's definitely up there.",
    "I've started telling everyone about the health benefits of eating dried grapes. It's all about raisin awareness.",
    "I was going to propose to my girlfriend, but my dog ate the ring. Now it's a diamond in the ruff.",
    "My son, a fire mage, asked me 'Mom, are we pyromaniacs?' I responded, 'Yes, we arson.'",
    "I had to fire the guy I hired to mow my lawn. He just didn't cut it.",
    "I made a graph showing all my past relationships. It has an ex-axis and a why-axis.",
    "My friend has accused me of stealing her thesaurus. Not only was I shocked, I was also aghast, appalled and dismayed.",
    "People call me self-centered. But that's enough about them.",
    "My girlfriend complains a lot that I don't smile anymore. Well, she's the one who wanted a serious relationship.",
    "It hurts me to say this, but... I have a sore throat.",
    "Tequila might not be the answer, but it's worth a shot.",
    "What kind of doctor is Dr. Pepper? A fizzician.",
    "People say being a waiter is a bad job... but, hey, it puts food on the table.",
    "Atheism is a non-prophet organization.",
    "What's more amazing than a talking dog? A spelling bee.",
    "A red and a blue ship have just collided in the Caribbean. Apparently the survivors are marooned.",
    "Once you've seen one shopping center, you've seen the mall.",
    "A plateau is the highest form of flattery.",
    "My dolphin puns are terrible on porpoise.",
    "Why can't you play poker on the African savanna? There are too many cheetahs.",
    "I've deleted the phone numbers of all the Germans I know from my mobile phone. Now it's Hans free.",
    "Breaking news! Energizer Bunny arrested! Charged with battery.",
    "Have you ever heard of a music group called Cellophane? They mostly wrap.",
    "I went to the zoo the other day. There was only one dog in it. It was a shitzu.",
    "I like looking in the mirror... it's good to reflect sometimes.",
    "Is it strange how saying sentences backwards creates backwards sentences saying how strange it is?",
    "What's the sleepiest paper? A napkin.",
    "What type of bees produce milk? Boobies.",
    "A lady just dropped a steak while I was at the store. I said, 'Whoops, that must be ground beef!'",
    "Two moles are crawling down a mole hole. The second mole tells the first mole, 'It smells like molasses down here!'",
    "I'm afraid for the calendar. Its days are numbered.",
    "Dear Math, grow up and solve your own problems.",
    "What did the ocean say to the beach? Nothing, it just waved.",
    "Why do seagulls fly over the ocean? Because if they flew over the bay, we'd call them bagels.",
    "I got carded at a liquor store, and my Blockbuster card accidentally fell out. The cashier said never mind.",
    "I ordered a chicken and an egg from Amazon. I'll let you know...",
    "I once had a dream I was floating in an ocean of orange soda. It was more of a fanta sea.",
    "The other day a clown held the door open for me. It was a nice jester.",
    "How does a programmer lose his mind? Bit by bit.",
    "Why do treehouses make good businesses? They typically have good branch managers.",
    "Why did the non-binary prospector head west? There was gold in them/their hills!",
    "My kids asked me what 'opaque' means. I said that according to the dictionary, it's still unclear.",
    "My spouse asked me why our fridge was full of stir fry this morning. Turns out I was sleep wokking again.",
    "I'm desperately trying to find out who's been pooping on my lawn. It's a real who-dung-it.",
    "I got home after programming all day and my spouse asked me to pick up some groceries. He said, 'Buy a gallon of milk. If there are apples, buy 12.' Then he got mad at me when I came home with 12 gallons of milk.",
    "My pet-collecting friend went missing in a horse barn. We suspect foal play.",
    "I signed up for this new subscription service where I receive new tires on a regular basis. It's my retirement plan.",
    "I want to tell you a salty joke. On second thought, Na.",
    "Every morning at the breakfast table, I tell my kids I'm going for a jog, but then I don't. It's a running joke.",
    "Someone made the mistake of bringing his attack dog to the circus. As might have been expected, it went straight for the juggler.",
    "My daughter asked me to pass her lipstick, but I accidentally gave her a glue stick. She's still not talking to me.",
    "What has more letters than the alphabet? The Dalaran mail room.",
    "Garrosh walks into a bar. The Horde and the Alliance form a line and punch him. That's the punchline.",
    "Where do shamans go to get an education? Elementary school.",
    "A young Arthas went to Uther's house for a visit and saw a switch he had never seen before. Curious, he asked, 'What's the switch for?' Uther replied, 'FOR THE LIGHT!'",
    "Why did Bwonsamdi cross the road? To get to De Other Side.",
    "So the Venthyr covenant is getting a voice chat of its own. It's called Venthyrlo.",
    "Why are guardian druids the best tanks for M+? They know all the best roots.",
    "Why did Lord Chamberlain block the toilets in Darkhaven? The enema overflows.",
    "Why did the Kul Tirans settle in the southeastern area? Because they loved how Tiragarde Sounds.",
    "What's a warlock's favorite drink? Shardonnay.",
    "What did the orc yell to his companions after discovering the Un'goro Tar Pits? Look, tar!",
    "Did you know that the Centaurs are generally considered attention-seeking by the other races of Azeroth? Some say that they can't help but be the centaur of attention.",
    "Why does Monty, the gnomish flute player in Deeprun Tram, never miss a beat? He's a metro-gnome.",
    "Feral: Why do I always get drunk and fail my finals? Boomkin: You should stack int.",
    "Worrying about my insomnia is keeping me up all night.",
    "I'm not bragging or anything, but I made six figures this year. So they named me the year's worst employee at the toy factory.",
    "I somehow managed to make it through high school math while only being able to remember even numbers! What are the odds?!",
    "What do you call an unimpressed robot? Sighborg.",
    "I used to be addicted to elevators. Now I'm taking steps to avoid them.",
    "If towels could tell jokes... they'd have the driest sense of humor.",
    "My Night Fae friend used to tell me that he invented a boat that can carry cars. It was just a ferry tale.",
    "How does a druid cut their hair? Eclipse it.",
    "What's the abbreviation for Death Knight? Decay.",
    "Why aren't warriors using intellect enchants? Because they don't want their weapons to be smarter than they are.",
    "Where does Ragnaros go for his back treatments? The pyro-practor.",
    "What do you call a gnome priest? A compact disc.",
    "What do rogues and noobs have in common? They both pick locks.",
    "You know you have been playing WoW for too long when the microwave dings and you yell 'GRATS!'",
    "How many Blizzard developers does it take to get an expansion right? Nobody knows yet.",
    "Why did the enchanter have to clean out his bank? Because it was full of dust.",
    "How do you get an engineer to do something you want them to do? Tell them it's impossible.",
    "Mechagnome Engineer No. 1: \"I bet you can't name two structures that can hold water.\" Engineer No. 2: \"Well, dam\"",
    "There are 10 types of people in this world: those who understand binary, and those who don't.",
    "The programmer got stuck in the shower because the instructions on the shampoo bottle said: Lather, rinse, repeat.",
    "What happens when you read a book about anti-gravity? You can't put it down.",
    "Someone keeps sending me flowers with the heads cut off... I think a druid is stalking me.",
    "Did you hear about the guy who put a feral on a hot air balloon? It caused an uproar.",
    "How do you email your guildmates in Bastion? You just click a-send.",
    "Anyone seen the gatherings of resto druids in treant form hanging about Stormwind lately? Not sure what they are up to, but it looks pretty shady.",
    "Did you know that bells are one of the most requested items for Tauren player models? Mainly because their horns don't work.",
    "What does Sire Denathrius say to the crowd at a heavy music festival to get them hyped? \"Metal all you like, mortals.\"",
    "What is Alexstrasza's favorite instrument? The Wyrmrest accordion.",
    "They say vulpera are born wanderers and merchants. What's less known is their reverence for sliced meats and cheeses. Their most popular business is also their spiritual leader and head caravanner: the Deli Llama.",
    "Why did the naaru ask for a loan? Because they were a bit light on money.",
    "They say that you can safely fit 3 people on the expedition yak mount without a problem. I thought that sounded easy but finding 3 people without a problem is pretty hard.",
    "What is a good Kul Tiran team building activity? The Drust fall.",
    "If Anduin is King in Elwynn Forest, what is he in the Redridge Mountains? Hiking.",
    "What do you call a speed contest where everyone is in denial? All lied races.",
    "Did you know that rocky mountain oysters are the original sack lunch?",
    "I'm really excited for the amateur autopsy club I just joined. Tuesday is open Mike night.",
    "My roommate says I have schizophrenia. Joke's on him. I don't have a roommate.",
    "It was just confirmed that the man who fell off the roof of a 30-story nightclub... was not a bouncer.",
    "If a child refuses to nap, are they guilty of resisting a rest?",
    "Do you think there will ever be a time when people stop mistaking Zelda for Link? Personally, I think it's Hylian likely.",
    "To the person who stole my place in the queue: I'm after you now.",
    "My 72-year-old dad has come up with a lot of jokes over the years, but his favorite has always been \"What do you call a joke about corn? Corny.\" I guess he corn-ered the market on that one.",
    "Did you hear about the lion who ate his family? He swallowed his pride.",
    "Chromie was going to tell a time-traveling joke... but you guys didn't like it.",
    "What do you call a Forsaken without a body and a nose? Nobody nose.",
    "What do you call a sleepy balance druid? A napkin.",
    "I hear they've made a new artificially intelligent Oreo. It's one smart cookie.",
    "What do you get when you cross a wall unit with artificial intelligence? Shelf-awareness.",
    "Despite losing Gilneas City, the worgen didn't lose everything. They keep it all in their were-houses.",
    "A young rogue robbed the Stormwind bank using a reflection prism but later turned himself in. Luckily, the judge was lenient as he saw a lot of himself in the man.",
    "I built my own glasses, but I don't want to make a spectacle of it.",
    "How do you know someone's been playing since Vanilla? Don't worry, they'll tell you.",
    "An Orc walks into a bar with a parrot on his shoulder. Barkeep says, \"Crikey! Where'd you find that?\" The parrot replies, \"Durotar, they're all over the place!\"",
    "Why do core raiders smell bad? Because they never wipe.",
    "You might be an engineer if... you've used coat hangers and duct tape for something other than hanging coats and taping ducts.",
    "How do snails fight? They slug it out.",
    "Do you understand how cryptocurrency works? I'm a bitcoinfused.",
    "3.14% of Kul Tirans are pi rates.",
    "What did the resto druid say about the girl they didn't know? I've never met herbivore.",
    "I can always tell when someone is lying just by looking at them. I can tell when they're standing too.",
    "An astronaut walks into a space bar and sees everyone on the floor. That's when he realized the gravity of the situation.",
    "I think I am too emotionally attached to onions. I cry every time I cut them.",
    "Dogs can't read MRIs, but cat scan.",
    "You know you're addicted to WoW when the only reason you go to church is for the stam buff.",
    "Where do rainbows go when they're bad? Prism. It's a light sentence.",
    "I am really disappointed that it is called The Dark Portal and not... Orc de Triomphe.",
    "What's a druid's favorite drink? Root beer.",
    "Why is it called getting your dog fixed when it doesn't work anymore afterward?",
    "What starts with E and ends with E, but only has one letter in it? Envelope.",
    "RIP, boiling water. You will be mist.",
    "I got fired on my first day at the bank. A customer asked me to check her balance, so I pushed her over.",
    "How many ears does Captain Kirk have? Three: his left ear, his right ear, and his final frontier.",
    "What did the janitor say when he jumped out of the closet? 'Supplies!'",
    "Have you heard about the chocolate record player? It sounds pretty sweet.",
    "My friends are really mad that I have no sense of direction. So I packed up my stuff and right!",
    "I'm not always what I eat, but sometimes... I yam.",
    "A Forsaken walks into a bar. He says to the bartender, \"I'll take a beer and a mop.\"",
    "The Shadowlands get their own cookies! They're called Oreobos.",
    "I told my Shadowlands gear that I loved it... It burst into tiers!",
    "I've been pressing tomatoes on my stuff for three days now, but I still can't find any of this ketchup gear everyone's been talking about!",
    "Why don't you startle Garrosh? Hellscream!",
    "Bolvar used to have a full head of hair... He should be called Baldvar now.",
    "You have now! Did you hear Chromie's time-travel joke?",
    "I tried calling the tinnitus helpline. No one answered; I just heard ringing.",
    "Why do programmers prefer dark mode? Because light attracts bugs.",
    "I told my spouse to embrace their mistakes so they hugged me.",
    "One of my Alliance friends trolls so much he should have gone Horde.",
    "I just failed a fire safety course in M+ mage training when they asked what steps I would take in case of an explosion. Apparently, \"really big ones\" wasn't an acceptable answer...",
    "A lumberjack went into a forest to cut down a tree. Upon arrival, he started to swing at a tree, when it shouted, \"Wait! I'm a druid, a talking tree!\" The lumberjack grinned, \"And you will dialogue!\"",
    "My friend asked me if I wanted to hear a really good Batman impression, so I replied, \"Go for it!\" He shouted, \"NO!! NOT THE KRYPTONITE!\" Slightly puzzled, I said, \"That's Superman.\" \"Thanks, man!\" he laughed. \"I've been practicing it a lot.\"",
    "What do you call it if a fire mage and a paladin share a bath? A hot tub with bubbles.",
    "If you think your microwave and TV spying on you is bad... your vacuum cleaner has been gathering dirt on you for years.",
    "I bought a universal remote today. I was disappointed to find out that it does not, in fact, control the universe. Not even remotely.",
    "The Fibonacci convention is supposed to be pretty special this year. They say it's going to be as big as the last two put together.",
    "You would think a snail mount without a shell would move a bit faster, but it's actually more sluggish.",
    "People always ask rogues how they sneak chocolate into movie theaters. Well, let's just say, they have a few Twix up their sleeves.",
    "A bad workman always blames his fools... *Tools!! I meant tools!! Stupid keyboard...",
    "For the last eight years I've been voted the most secretive employee in the office by my coworkers. Can't tell you how much this award means to me.",
    "I bought a dog from a blacksmith in town. As soon as I got him home he made a bolt for the door.",
    "Why do druids hate math? It gives them square roots.",
    "What emotion does a depressed cantaloupe feel? Meloncholy.",
    "Why do chicken coops have two doors? Because if they had four they would be chicken sedans.",
    "The inventor of the USB stick has died. Thanks for the memory.",
    "Iron Man is technically a FEmale.",
    "What's a rogue's favorite drink? Subtle tea.",
    "What do you call a druid who melees in tree form? A combat log.",
    "How does Naxxramas fly? With its four wings.",
    "What do you get if you cross a gnome and a tauren? A mini-taur.",
    "What do you call five mogu rolling down a hill? The Rolling Stones.",
    "Why do hunters get smashed in bars? Because they're always multi-shotting.",
    "How do you stop a Warrior from charging? You take away his credit card.",
    "How come people get lost in Thunder Bluff? Because the layout makes a real mesa things.",
    "What do you call a Tauren Demon Hunter? Illidairy.",
    "What do you call a tauren rogue? Invisibull.",
    "Why do mages and warlocks get invited to all the parties? Because mages bring the food and warlocks get you stoned.",
    "How many dwarves does it take to screw in a light bulb? Two. One to hold the light bulb in place and the other to drink until the room starts spinning.",
    "Why didn't the undead cross the road? He didn't have the guts.",
    "How many software engineers does it take to change a light bulb? None. That's a hardware issue.",
    "When I wrote this code, only God and I knew how it worked. Now only God knows.",
    "Conventional wisdom: If it ain't broke, don't fix it. Developer: If it ain't broke, consider adding more features.",
    "What did the electrical engineer say when he got shocked? \"That hertz!\"",
    "An SQL statement walks into a bar and sees two tables. It approaches, and asks \"May I join you?\"",
    "What's a hydraulic ram used for? It's where you get steel wool!",
    "Never argue with pi. It's irrational.",
    "What do you call a mechanical shovel? Ground-breaking technology!",
    "Old software engineers never die... They just reboot.",
    "Did you hear about the company that sells elastomeric insulators? Their motto is \"Resistance is butyl.\"",
    "I asked a Grimrail Depot engineer how many times his train had derailed. He said, \"I'm not sure. It's hard to keep track.\"",
    "What did the mechanical frog battle pet say? Rivet, rivet.",
    "Why did the engineer create a robot fish battle pet? He wanted more e-fish-in-sea.",
    "Latest Mechagon news: After suffering weak gains at the poles, the National Transistor Party has been trying to energize its base.",
    "I have some crockery that has photos of developers drinking gin. They're tech-tonic plates.",
    "What do you call a psychic gnome who escapes from jail? A small medium at large.",
    "Why do worgen druids turn into cats? Because otherwise it would be ruff.",
    "I got a job at a Westfall farm but I resigned because they didn't have horses. I wanted something more stable.",
    "There once was a gnome king who was only 12 inches tall... He was a terrible king, but an amazing ruler.",
    "What do you NEVER buy at a yard sale? Meters.",
    "Dark humor is like clean water. Not everyone gets it.",
    "I had a debate with a flat earther. He said he'll walk to the edge of the earth to prove me wrong. I'm sure he'll come around.",
    "The Beastie Boys are releasing a five-part anthology. Parts A-D are free, but you have to fight for your right to Part E.",
    "My neighbor's house got broken into last night but they only stole their fruit bowl. They're absolutely peachless.",
    "I saw someone stealing from an Apple store. I guess that makes me an iWitness.",
    "How do programmers decide what to wear to work? They have a dress code.",
    "What do you call a dwarf signaling hello? A microwave.",
    "What's the smallest kind of bear? The bear minimum.",
    "The treant Gnarlgar is an old, somewhat frail leader with a mysterious aura, but bad breath due to his diet and rough feet from walking everywhere... He is a super-calloused-fragile-mystic-hexed-by-halitosis.",
    "My spouse has stood beside me for 20 years... We only have one chair in the house.",
    "When I raid, I never worry about my fingers. I can always count on them.",
    "Patient: \"I'm scared of random letters.\" Doctor: \"Are you?\" Patient: *screams* Doctor: \"Oh, I see.\" Patient: *screams again*",
    "I bought some chicken drumsticks. Now I just need to find a chicken that plays the drums.",
    "What do you call a death knight who shows up out of nowhere? Sir-prise.",
    "I recently had a toe amputated and replaced with a prosthetic made out of a breath mint. Now I have a Tic Tac toe.",
    "The past, the present and the future walked into a bar. It was very tense.",
    "My grandma replaced her chair with a bean bag. I think she is off her rocker.",
    "Someone broke into the police station and stole all the toilets. Police say they have nothing to go on.",
    "Windows make terrible liars... You can see right through them.",
    "I was going to make a joke about bland food, but then I realized it was just tasteless.",
    "How do Forsaken without noses smell? Terrible!",
    "A hunter killed 11 rabbits. They were very odd, but they were prime.",
    "The doctor said I have the peek-a-boo virus. They sent me straight to the ICU.",
    "At my son's fourth birthday party I didn't recognize him. I'd never seen him be four.",
    "What did the death row inmate say before he was executed? \"I wouldn't be shocked if this didn't work.\"",
    "Never yell into a colander. You'll strain your voice.",
    "I was napping under a citrus tree. It was sublime.",
    "When I was young my dad said to me, \"You can be anything you want in life, the sky is the limit!\" Which made me sad, because I wanted to be an astronaut.",
    "What do you call an illegally parked frog? Toad.",
    "I hate how funerals are always at 9 a.m. I'm not really a mourning person.",
    "Vegetable oil is made from vegetables. Olive oil is made from olives. Baby oil is cruel.",
    "My grandpa died in an Italian restaurant. I guess he pasta way.",
    "I'm starting a business to teach math to gnomes and dwarves. It's called \"Making the Little Things Count.\"",
    "A wise man once told me you should give 100 percent in everything you do, unless you're donating blood.",
    "I hate peer pressure and you should too.",
    "What do you call a death knight who doesn't wash? Sir Melly!",
    "They say one person in each group of friends had the potential to be a serial killer... So I pushed Dave off a cliff, just in case it was him.",
    "What do you call three resto druids walking across private property? Trees passing.",
    "What did the Kul Tiran crewmates find when they looked in the toilet? The captain's log.",
    "What is the difference between a weasel and a stoat? One is weasily identified. The other is stoatally different.",
    "What do you call a comedian who never comes out of the house? An inside joke.",
    "Plague, mana, and even goblin-engineered: when it comes to Horde artillery, Theramore bombs.",
    "Some bananas are difficult to open. I find this unappealing.",
    "I'd moustache you a question but I'm shaving it for later.",
    "A hunter missed their wedding because they disengaged.",
    "I fired the janitor for smoking pot because I can't stand high maintenance people.",
    "Why are tauren so tired after giving birth? Because they've been de-calf-inated.",
    "I took the batteries out of the carbon monoxide alarm because the loud beeping was giving me a headache and making me feel sick and dizzy.",
    "The salesman at the furniture store told me, 'This sofa will fit five people without any problems.' I said, 'Where the hell am I going to find five people without any problems?'",
    "Why does Piglet smell? Because he plays with Pooh!",
    "Did you know that artificial orange juice was first invented in Ancient China... during the Tang Dynasty.",
    "I'm addicted to brake fluid but it's okay, I can stop at any time.",
    "I asked my friend if he was gay. He didn't give me a straight answer.",
    "I was about to post a joke about sodium, but Na, people wouldn't get it.",
    "What is Bigfoot's favorite exercise? Sasquats.",
    "A weasel walks into a bar. The bartender is shocked. 'Wow, I've never served a weasel before! What'll it be?' The weasel looks the bartender straight in the eye. 'Pop,' goes the weasel.",
    "What do you call a redheaded ninja? A ginja!",
    "What do you call an Irishman who is bouncing off the walls? Rick O'Shea.",
    "Ban pre-shredded cheese. Make America grate again!",
    "I sued an airline when my luggage went missing. I lost my case.",
    "Two guys got arrested for stealing a calendar. They both got six months.",
    "What is the difference between an alligator and a crocodile? You'll see one in a while, and the other a bit later.",
    "My friend, Jim, drowned last week. We placed a life jacket on his coffin... It's what he would have wanted.",
    "I lost my pickle! Whatever, it's not a big dill.",
    "I lost my wife's audiobook last night... now I'm never going to hear the end of it.",
    "What is a duck's favorite snack? Quackers.",
    "A guy tried selling me a coffin. That's the last thing I need.",
    "My cows stopped making milk last week! It's an udder disaster!",
    "How do you spot a blind man on a nude beach? It's not hard.",
    "I brought mushrooms to a party yesterday. They can really make you a fungi.",
    "What's the difference between ignorance and apathy? I don't know and I don't care.",
    "I saw a poor old woman trip and fall today. At least I assume she was poor. She only had five dollars in her wallet.",
    "What happens if the school bully walks into a statistics class? The mean increases.",
    "My girlfriend has left me because she thinks I have an obsession with gambling... I bet you she'll be back.",
    "I'll never forget what my grandad said just before he kicked the bucket. 'Watch how far I can kick this bucket!'",
    "If you fall in love with someone from South Korea are they your Seoul mate?",
    "My wife kicked me out because of my terrible Arnold Schwarzenegger impressions, but don't worry. I'll return.",
    "When my wife caught me standing on the bathroom scales, sucking in my stomach, she laughed, 'That's not going to help!' I replied, 'Sure it does. It's the only way I can see the numbers.'",
    "A Mexican magician says he will disappear on the count of three. He says 'uno, dos...' *poof*. He disappeared without a tres.",
    "The worst part about kissing a perfect 10 is how cold the mirror feels on my lips.",
    "I hate it when my friend suddenly says 'Are you even listening to me?' I mean, who the hell starts a conversation like that?",
    "I bought my wife a fridge as an anniversary present. I can't wait to see her face light up when she opens it.",
    "I'm using only fans right now and it's hot. I'm waiting for a technician to get my air conditioner fixed.",
    "Bruce Lee was fast, but he had three even faster brothers. Quick Lee, Sudden Lee, and Instant Lee.",
    "SpongeBob may be the main character of the show, but Patrick is the star.",
    "My wife left me because I'm too insecure. No wait, she's back. She just went out to bring me a cake.",
    "To whoever stole my depression medication: I hope you're happy.",
    "My spouse had a vasectomy because I didn't want any kids. When I got home, they were still there.",
    "My boss asked me why I only get sick on work days. I said it must be my weekend immune system.",
    "I've just invented the first thought-controlled air freshener. It makes scents, when you think about it.",
    "My friend got me a jar of dirt for my birthday. I told them I appreciate the sediment.",
    "My dog swallowed a whole bag of Scrabble tiles. We took him to the vet to get him checked out. No word yet.",
    "I knew a tattoo artist that would give free tattoos to women that flashed him their boobs. It was a real tit for tat situation.",
    "I told my boss three companies were after me, so I needed a pay rise. He asked me which three companies they were. I told him, 'Gas, electric, and water.'",
    "What do you call a man that has been married and divorced multiple times? Lord of the Rings.",
    "Super Mario is Japanese, so technically his last name is Mario. His first name is Itsumi, making him Itsumi Mario.",
    "What do you use to clean a pig? Ham sanitizer.",
    "How do you make your water bed bouncier? You add spring water!",
    "Did you hear about the origami teacher who quit? Too much paperwork.",
    "Does your yard contain too many druids? There's a guy who will do your tree removal for free. His company is called 'Random Axe of Kindness.'",
    "What do you call a shoe made out of bananas? A slipper.",
    "Don't challenge Death to a pillow fight. Unless you're prepared for the reaper cushions.",
    "What's the number one cause of divorce? Marriage.",
    "Violence isn't the answer... It's the question and the answer is 'yes!'",
    "I accidentally sprayed deodorant in my mouth. Now when I talk, I have a weird axe scent.",
    "I dumped my last girlfriend because she was a communist. I should've known sooner. There were red flags everywhere.",
    "Where do Kul Tiran pirates get their hooks? Secondhand stores.",
    "My buddy called animal welfare today and said, 'I just found a suitcase in the woods with four kittens in it.' 'That's terrible,' she replied. 'Are they moving?' 'I'm not sure, to be honest,' he said, 'but if they were, that would explain the suitcase.'",
    "Rick Astley will let you borrow any of his Disney movies, except one. He's never gonna give you Up.",
    "Tequila is not the answer... But it's worth a shot.",
    "What's the last thing to go through a bug's mind when it hits a windshield? Its butt.",
    "If we are to be serious about saving the planet, we should stop printing calendars. They're the reason our days are numbered.",
    "I was at the airport and witnessed a man collapse on the luggage carousel. I think he's OK, though. I saw him slowly coming round.",
    "What happened when the oxymoron walked into the bar? There was a deafening silence.",
    "Why did the shark blush? Because it saw the ocean's bottom.",
    "Two goldfish swim into a bar. The bartender asks, \"Why the long faeces?\"",
    "Why can't you hear a pterodactyl using the bathroom? Because the pee is silent.",
    "Did you hear about the guy who evaporated? He'll be mist!",
    "A gnome just came up to me and asked if the Earth was flat. I told him no, but he shook his head. \"Druid, the Earth is 71 percent water, and nearly all of it is uncarbonated.\"",
    "Writing crime novels is an okay job. It has its prose and cons.",
    "A paladin watered an avocado tree with holy water so they could make 'Holy Guacamole.'",
    "I asked Katy Stampwhistle for help with posting a pachyderm. I was having trouble addressing the elephant in the room.",
    "Someone came into my house and stole all of my lightbulbs. I was delighted.",
    "Who designs Kul Tiran pirate ships? ARGHHitects. Caaaarrrrrrrpenters build them, and they have a large arrrrrrrrr&d department.",
    "A Forsaken was searching for more help with his understaffed ship. All he had was a skeleton crew.",
    "Getting hit in the funny bone may not actually be funny, but it is humerus.",
    "In life, Bach was a composer. In death, he is a de-composer.",
    "What's a feral's favorite drink? Mice water.",
    "Why can shadow priests get away with not doing mechanics? Because they can just use a-void form.",
    "My son has been eating electrical cords. So I grounded him until he conducts himself properly.",
    "My friend gave up smoking cold turkey. He's doing better now but he's still coughing up feathers.",
    "If athletes get athlete's foot, what do astronauts get? Missile toe.",
    "I asked a resto druid for help with my herb garden. They gave me some sage advice.",
    "What happened to the scientist that couldn't stop adding up the sides of precious gems? They became addicted to crystal math.",
    "I was bullied into leveling my fishing. Yes, it's true, I caved to pier pressure.",
    "If Queen Azshara accidentally farts during battle, pretend like nothing happens. Noble gasses should have no reaction.",
    "I honestly didn't know that Brann liked cars so much. But how does he know I've got a Dodge?",
    "Did you hear about the dyslexic Worgen Shadow Priest? Turns out they've been following the old dogs.",
    "The Emerald Dream may be nice for herbalists, but it really shines for tailors -- there are so many superb looms!",
    "The new World Tree is pretty unimpressive. Compared to the likes of Nordrassil and Teldrassil, this one is just a mere 'drassil.",
    "Why did the orc chieftain disown his daughter? He found her OnlyClans.",
    "What is a blood elf's favorite food? Salami ashal'anore.",
    "Why did Prophet Velen have to rest? He was feeling light-headed.",
    "Do Trolls call footsie scissoring?",
    "Why does Ponzo barter with bricks and boulders? Because all of his gold goes to paying off a Loamm shark.",
    "Why didn't the Guardian Druid fill out his weekly vault options? Because he did the bear minimum.",
    "Why do Death Knights hate dentists? Because they prevent Death and Tooth Decay.",
    "What spec is addicted to dating apps? Guardian Druids -- swipe swipe swipe.",
    "Did you hear about the two warlocks who FEL in love?",
    "What do you do when your mining spot floods? Draenor.",
    "Where did Mueh'zala live after race-changing to Tauren? De Udder Side.",
    "My Druid friend thought getting travel form would help him pick up the ladies. Sadly, now he just goes stag everywhere."
}

-- FNV-1a (32-bit) hash. We key persisted joke usage on a hash of the text rather
-- than the text itself (cheap to store) or the array index (which drifts whenever
-- the list is edited). Identical jokes hash identically, so duplicate entries are
-- naturally collapsed into one "seen" key.
local function HashJoke(text)
    local h = 2166136261
    for i = 1, #text do
        h = bit.bxor(h, text:byte(i))
        h = (h * 16777619) % 4294967296
    end
    return h
end

-- Hashes for the active list, rebuilt whenever the list changes.
local jokeHashes

-- Content types wipe jokes can be switched on or off for, in Configuration page order.
TwintopQOL.Jokes.CONTENT_TYPES = {
    "openWorld",
    "dungeonNormal",
    "dungeonHeroic",
    "dungeonMythic",
    "mythicPlus",
    "delve",
    "scenario",
    "raidLFR",
    "raidNormal",
    "raidHeroic",
    "raidMythic",
    "battleground",
    "arena"
}

-- WoW Forever only has Normal dungeons and raids, and no arenas.
local NOT_IN_FOREVER = {
    dungeonHeroic = true,
    dungeonMythic = true,
    mythicPlus = true,
    delve = true,
    scenario = true,
    raidLFR = true,
    raidHeroic = true,
    raidMythic = true,
    arena = true
}
if TwintopQOL.IsForever then
    for i = #TwintopQOL.Jokes.CONTENT_TYPES, 1, -1 do
        if NOT_IN_FOREVER[TwintopQOL.Jokes.CONTENT_TYPES[i]] then
            table.remove(TwintopQOL.Jokes.CONTENT_TYPES, i)
        end
    end
end

-- Difficulty IDs that aren't Normal; anything unlisted counts as Normal.
local DUNGEON_DIFFICULTIES = {
    [2] = "dungeonHeroic",
    [8] = "mythicPlus",
    [23] = "dungeonMythic"
}
local RAID_DIFFICULTIES = {
    [5] = "raidHeroic",
    [6] = "raidHeroic",
    [7] = "raidLFR",
    [15] = "raidHeroic",
    [16] = "raidMythic",
    [17] = "raidLFR"
}
local DELVE_DIFFICULTY = 208

---Returns the content type of the player's current instance.
---@return string
local function GetContentType()
    local _, instanceType, difficultyId = GetInstanceInfo()
    if instanceType == "party" then
        return DUNGEON_DIFFICULTIES[difficultyId] or "dungeonNormal"
    elseif instanceType == "raid" then
        return RAID_DIFFICULTIES[difficultyId] or "raidNormal"
    elseif instanceType == "scenario" then
        return difficultyId == DELVE_DIFFICULTY and "delve" or "scenario"
    elseif instanceType == "pvp" then
        return "battleground"
    elseif instanceType == "arena" then
        return "arena"
    end
    return "openWorld"
end

---Returns the active joke list: the player's custom list, or the defaults.
---@return string[]
local function GetActiveList()
    return (TwintopQOLSaved and TwintopQOLSaved.jokes) or DEFAULT_JOKES
end

local function GetHashes()
    if not jokeHashes then
        jokeHashes = {}
        local list = GetActiveList()
        for i = 1, #list do
            jokeHashes[i] = HashJoke(list[i])
        end
    end
    return jokeHashes
end

-- Pick a joke we haven't used yet this cycle. When every (unique) joke has been
-- seen, the cycle resets. State persists across sessions via TwintopQOLSaved.
local function PickJoke()
    local jokeList = GetActiveList()
    TwintopQOLSaved = TwintopQOLSaved or {}
    TwintopQOLSaved.seen = TwintopQOLSaved.seen or {}
    if not TwintopQOLSaved.jokesConfig.noRepeats then
        return jokeList[fastrandom(1, #jokeList)]
    end

    local seen = TwintopQOLSaved.seen
    local hashes = GetHashes()

    local pool = {}
    for i = 1, #jokeList do
        if not seen[hashes[i]] then
            pool[#pool + 1] = i
        end
    end

    -- All jokes seen (or the list shrank to all-seen): start a fresh cycle.
    if #pool == 0 then
        wipe(seen)
        for i = 1, #jokeList do
            pool[i] = i
        end
    end

    local index = pool[fastrandom(1, #pool)]
    seen[hashes[index]] = true
    return jokeList[index]
end

---Returns a copy of the shipped default jokes.
---@return string[]
function TwintopQOL.Jokes:GetDefaults()
    return CopyTable(DEFAULT_JOKES)
end

---Returns a copy of the active joke list.
---@return string[]
function TwintopQOL.Jokes:GetList()
    return CopyTable(GetActiveList())
end

---Replaces the active joke list. A list identical to the defaults clears the
---custom list, so the player goes back to tracking the shipped defaults.
---@param list string[]
function TwintopQOL.Jokes:SetList(list)
    local isDefault = #list == #DEFAULT_JOKES
    if isDefault then
        for i = 1, #list do
            if list[i] ~= DEFAULT_JOKES[i] then
                isDefault = false
                break
            end
        end
    end

    TwintopQOLSaved.jokes = (not isDefault) and CopyTable(list) or nil
    jokeHashes = nil
end

---Whether the player is using a custom joke list.
---@return boolean
function TwintopQOL.Jokes:IsCustom()
    return TwintopQOLSaved.jokes ~= nil
end

-- Send a joke to the most appropriate group chat channel.
function TwintopQOL.Jokes:Send()
    if #GetActiveList() == 0 then
        return
    end

    if IsInRaid() then
        C_ChatInfo.SendChatMessage(PickJoke(), "RAID")
    elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        C_ChatInfo.SendChatMessage(PickJoke(), "INSTANCE_CHAT")
    elseif IsInGroup() then
        C_ChatInfo.SendChatMessage(PickJoke(), "PARTY")
    end
end

-- Chat channels /tqol joke can name, with the words that pick each one: its name and the chat box's short commands.
local CHANNEL_WORDS = {
    SAY = { "say", "s" },
    YELL = { "yell", "y", "shout", "sh" },
    EMOTE = { "emote", "e", "em", "me" },
    PARTY = { "party", "p" },
    RAID = { "raid", "ra" },
    RAID_WARNING = { "rw", "raidwarning" },
    INSTANCE_CHAT = { "instance", "i" },
    GUILD = { "guild", "g" },
    OFFICER = { "officer", "o" },
    WHISPER = { "whisper", "w", "tell", "t" }
}

local channelByWord = {}
for channel, words in pairs(CHANNEL_WORDS) do
    for _, word in ipairs(words) do
        channelByWord[word] = channel
    end
end

---Picks the channel that reaches the player's group, the way the chat box does: party and raid chat go to instance
---chat in an instance group only, and instance chat goes to raid or party chat in a home group only.
---@param channel string
---@return string? channel Nil when nobody would hear it.
---@return string? reason Why nobody would hear it.
local function ResolveChannel(channel)
    if channel == "PARTY" then
        if IsInGroup(LE_PARTY_CATEGORY_HOME) then
            return "PARTY"
        elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
            return "INSTANCE_CHAT"
        end
        return nil, L["ErrNotInGroup"]
    elseif channel == "RAID" then
        if IsInRaid(LE_PARTY_CATEGORY_HOME) then
            return "RAID"
        elseif IsInRaid(LE_PARTY_CATEGORY_INSTANCE) then
            return "INSTANCE_CHAT"
        end
        return nil, L["ErrNotInRaid"]
    elseif channel == "INSTANCE_CHAT" then
        if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
            return "INSTANCE_CHAT"
        elseif IsInRaid(LE_PARTY_CATEGORY_HOME) then
            return "RAID"
        elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
            return "PARTY"
        end
        return nil, L["ErrNotInInstanceGroup"]
    elseif channel == "RAID_WARNING" then
        if not IsInRaid() then
            return nil, L["ErrNotInRaid"]
        end
    elseif channel == "GUILD" or channel == "OFFICER" then
        if not IsInGuild() then
            return nil, L["ErrNotInGuild"]
        end
    end
    return channel
end

---Tells a joke in a chat channel. Prints why instead when nobody would hear it.
---@param channel string A chat type, as SendChatMessage takes it.
---@param target? string Who a whisper goes to.
function TwintopQOL.Jokes:SendTo(channel, target)
    if #GetActiveList() == 0 then
        return
    end

    local resolved, reason = ResolveChannel(channel)
    if not resolved then
        TwintopQOL:Print(reason)
        return
    end
    C_ChatInfo.SendChatMessage(PickJoke(), resolved, nil, target)
end

---Handles /tqol joke: tells a joke in group chat, or in the channel named, as in "say", "raid", or "whisper Name".
---@param args? string What followed "joke".
function TwintopQOL.Jokes:Command(args)
    local word, rest = TwintopQOL:ParseCmdString(args)
    if word == "" then
        self:Send()
        return
    end

    local channel = channelByWord[strlower(word)]
    if not channel then
        TwintopQOL:Print(string.format(L["JokesUnknownChannel"], word))
        return
    end

    local target
    if channel == "WHISPER" then
        target = strtrim(rest or "")
        if target == "" then
            TwintopQOL:Print(L["JokesWhisperNoTarget"])
            return
        end
    end
    self:SendTo(channel, target)
end

---Fills in missing Configuration settings. Called once saved variables are loaded.
function TwintopQOL.Jokes:Init()
    -- Wipe jokes used to ride on silly mode, so an existing save keeps whatever it had.
    if TwintopQOLSaved.jokesConfig == nil then
        TwintopQOLSaved.jokesConfig = { enabled = TwintopQOLSaved.sillyEnabled == true }
    end

    local config = TwintopQOLSaved.jokesConfig
    if config.noRepeats == nil then
        config.noRepeats = true
    end
    config.content = config.content or {}
    for _, contentType in ipairs(self.CONTENT_TYPES) do
        if config.content[contentType] == nil then
            config.content[contentType] = true
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ENCOUNTER_END")
eventFrame:SetScript("OnEvent", function(_, _, _, _, _, _, success)
    local config = TwintopQOLSaved.jokesConfig
    if success ~= 1 and config.enabled and config.content[GetContentType()] then
        C_Timer.After(0, function()
            C_Timer.After(3, function()
                TwintopQOL.Jokes:Send()
            end)
        end)
    end
end)
