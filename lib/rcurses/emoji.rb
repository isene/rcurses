module Rcurses
  module EmojiPicker
    extend Rcurses::Input

    CATEGORIES = {
      "Smileys" => [
        ["😀","grin"],["😃","smiley"],["😄","smile"],["😁","beaming"],["😆","laughing"],
        ["😅","sweat smile"],["🤣","rofl"],["😂","joy"],["🙂","slight smile"],["😉","wink"],
        ["😊","blush"],["😇","innocent"],["🥰","love face"],["😍","heart eyes"],["🤩","starstruck"],
        ["😘","kiss"],["😗","kissing"],["😚","kiss closed"],["😙","kiss smile"],["🥲","happy tear"],
        ["😋","yum"],["😛","tongue"],["😜","tongue wink"],["🤪","zany"],["😝","tongue closed"],
        ["🤑","money"],["🤗","hug"],["🤭","hand mouth"],["🤫","shush"],["🤔","thinking"],
        ["🫡","salute"],["🤐","zipper"],["🤨","raised brow"],["😐","neutral"],["😑","expressionless"],
        ["😶","no mouth"],["🫥","dotted face"],["😏","smirk"],["😒","unamused"],["🙄","roll eyes"],
        ["😬","grimace"],["😮‍💨","exhale"],["🤥","liar"],["😌","relieved"],["😔","pensive"],
        ["😪","sleepy"],["🤤","drool"],["😴","sleep"],["😷","mask"],["🤒","sick"],
        ["🤕","bandage"],["🤢","nausea"],["🤮","vomit"],["🥵","hot"],["🥶","cold"],
        ["🥴","woozy"],["😵","dizzy"],["🤯","exploding"],["🤠","cowboy"],["🥳","party"],
        ["🥸","disguise"],["😎","cool"],["🤓","nerd"],["🧐","monocle"],["😕","confused"],
        ["🫤","diagonal mouth"],["😟","worried"],["🙁","frown"],["😮","open mouth"],["😯","hushed"],
        ["😲","astonished"],["😳","flushed"],["🥺","pleading"],["🥹","holding tears"],["😦","frowning"],
        ["😧","anguished"],["😨","fearful"],["😰","anxious"],["😥","sad relief"],["😢","cry"],
        ["😭","sob"],["😱","scream"],["😖","confounded"],["😣","persevere"],["😞","disappointed"],
        ["😓","downcast"],["😩","weary"],["😫","tired"],["🥱","yawn"],["😤","triumph"],
        ["😡","rage"],["😠","angry"],["🤬","swearing"],["😈","devil smile"],["👿","devil"],
        ["💀","skull"],["☠️","crossbones"],["💩","poop"],["🤡","clown"],["👹","ogre"],
        ["👻","ghost"],["👽","alien"],["🤖","robot"],["💋","kiss mark"],["❤️","heart"],
        ["🧡","orange heart"],["💛","yellow heart"],["💚","green heart"],["💙","blue heart"],
        ["💜","purple heart"],["🖤","black heart"],["🤍","white heart"],["🤎","brown heart"],
        ["💔","broken heart"],["❤️‍🔥","fire heart"],["💕","two hearts"],["💞","revolving hearts"],
        ["💓","heartbeat"],["💗","growing heart"],["💖","sparkling heart"],["💘","cupid"],
        ["💝","ribbon heart"],["💟","heart decoration"],["🫶","heart hands"]
      ],
      "People" => [
        ["👋","wave"],["🤚","raised back"],["🖐️","splayed hand"],["✋","raised hand"],
        ["🖖","vulcan"],["🫱","right hand"],["🫲","left hand"],["🫳","palm down"],["🫴","palm up"],
        ["👌","ok"],["🤌","pinched"],["🤏","pinch"],["✌️","peace"],["🤞","crossed fingers"],
        ["🫰","index thumb"],["🤟","love you"],["🤘","rock"],["🤙","call me"],
        ["👈","left point"],["👉","right point"],["👆","up point"],["🖕","middle finger"],
        ["👇","down point"],["☝️","index up"],["🫵","point at viewer"],["👍","thumbsup"],
        ["👎","thumbsdown"],["✊","fist"],["👊","punch"],["🤛","left fist"],["🤜","right fist"],
        ["👏","clap"],["🙌","raised hands"],["🫶","heart hands"],["👐","open hands"],
        ["🤲","palms up"],["🤝","handshake"],["🙏","pray"],["✍️","writing"],["💪","muscle"],
        ["🦾","mechanical arm"],["🧠","brain"],["👀","eyes"],["👁️","eye"],["👅","tongue"],
        ["👄","lips"],["🫦","biting lip"],["👶","baby"],["🧒","child"],["👦","boy"],
        ["👧","girl"],["🧑","person"],["👱","blond"],["👨","man"],["🧔","beard"],
        ["👩","woman"],["🧓","older person"],["👴","old man"],["👵","old woman"]
      ],
      "Animals" => [
        ["🐶","dog"],["🐱","cat"],["🐭","mouse"],["🐹","hamster"],["🐰","rabbit"],
        ["🦊","fox"],["🐻","bear"],["🐼","panda"],["🐻‍❄️","polar bear"],["🐨","koala"],
        ["🐯","tiger"],["🦁","lion"],["🐮","cow"],["🐷","pig"],["🐸","frog"],
        ["🐵","monkey"],["🐔","chicken"],["🐧","penguin"],["🐦","bird"],["🐤","chick"],
        ["🦆","duck"],["🦅","eagle"],["🦉","owl"],["🦇","bat"],["🐺","wolf"],
        ["🐗","boar"],["🐴","horse"],["🦄","unicorn"],["🐝","bee"],["🐛","bug"],
        ["🦋","butterfly"],["🐌","snail"],["🐞","ladybug"],["🐜","ant"],["🪲","beetle"],
        ["🐢","turtle"],["🐍","snake"],["🦎","lizard"],["🦂","scorpion"],["🐙","octopus"],
        ["🦑","squid"],["🐠","fish"],["🐟","tropical fish"],["🐡","blowfish"],["🐬","dolphin"],
        ["🐳","whale"],["🐋","humpback"],["🦈","shark"],["🐊","crocodile"],["🐅","tiger2"],
        ["🐆","leopard"],["🦓","zebra"],["🦍","gorilla"],["🦧","orangutan"],["🐘","elephant"],
        ["🦛","hippo"],["🦏","rhino"],["🐪","camel"],["🐫","two hump camel"],["🦒","giraffe"],
        ["🦘","kangaroo"],["🦬","bison"],["🐃","water buffalo"],["🐂","ox"],["🐄","dairy cow"]
      ],
      "Food" => [
        ["🍎","apple"],["🍐","pear"],["🍊","orange"],["🍋","lemon"],["🍌","banana"],
        ["🍉","watermelon"],["🍇","grapes"],["🍓","strawberry"],["🫐","blueberry"],["🍈","melon"],
        ["🍒","cherry"],["🍑","peach"],["🥭","mango"],["🍍","pineapple"],["🥥","coconut"],
        ["🥝","kiwi"],["🍅","tomato"],["🥑","avocado"],["🌽","corn"],["🌶️","pepper"],
        ["🥒","cucumber"],["🥕","carrot"],["🧄","garlic"],["🧅","onion"],["🥔","potato"],
        ["🍞","bread"],["🥐","croissant"],["🥖","baguette"],["🧀","cheese"],["🥚","egg"],
        ["🍳","cooking"],["🥞","pancakes"],["🧇","waffle"],["🥓","bacon"],["🍔","burger"],
        ["🍟","fries"],["🍕","pizza"],["🌭","hotdog"],["🥪","sandwich"],["🌮","taco"],
        ["🌯","burrito"],["🫔","tamale"],["🥗","salad"],["🍝","spaghetti"],["🍜","ramen"],
        ["🍲","stew"],["🍛","curry"],["🍣","sushi"],["🍱","bento"],["🥟","dumpling"],
        ["🍩","donut"],["🍪","cookie"],["🎂","cake"],["🍰","shortcake"],["🧁","cupcake"],
        ["🍫","chocolate"],["🍬","candy"],["🍭","lollipop"],["🍮","custard"],["🍯","honey"],
        ["☕","coffee"],["🍵","tea"],["🧃","juice box"],["🍺","beer"],["🍻","cheers"],
        ["🥂","champagne"],["🍷","wine"],["🍸","cocktail"],["🍹","tropical drink"],["🧊","ice"]
      ],
      "Travel" => [
        ["🏠","house"],["🏡","garden house"],["🏢","office"],["🏥","hospital"],["🏦","bank"],
        ["🏨","hotel"],["🏪","store"],["🏫","school"],["🏬","department store"],["🏛️","classical"],
        ["⛪","church"],["🕌","mosque"],["🕍","synagogue"],["⛩️","shinto"],["🕋","kaaba"],
        ["⛲","fountain"],["🏕️","camping"],["🏖️","beach"],["🏜️","desert"],["🏝️","island"],
        ["🏔️","mountain"],["⛰️","mountain2"],["🌋","volcano"],["🗻","fuji"],["🗼","tokyo tower"],
        ["🗽","statue liberty"],["✈️","airplane"],["🛩️","small plane"],["🚀","rocket"],
        ["🛸","ufo"],["🚁","helicopter"],["🚂","train"],["🚗","car"],["🚕","taxi"],
        ["🚌","bus"],["🚲","bike"],["🛵","scooter"],["🚤","speedboat"],["⛵","sailboat"],
        ["🚢","ship"],["⚓","anchor"],["🗺️","world map"],["🧭","compass"],["🌍","earth"],
        ["🌎","earth americas"],["🌏","earth asia"],["🌙","moon"],["⭐","star"],["🌟","glowing star"],
        ["☀️","sun"],["🌤️","partly sunny"],["⛅","cloudy"],["🌧️","rain"],["⛈️","storm"],
        ["🌈","rainbow"],["☔","umbrella rain"],["❄️","snowflake"],["⛄","snowman"],["🔥","fire"],
        ["💧","drop"],["🌊","wave"]
      ],
      "Objects" => [
        ["⌚","watch"],["📱","phone"],["💻","laptop"],["⌨️","keyboard"],["🖥️","desktop"],
        ["🖨️","printer"],["🖱️","mouse"],["💾","floppy"],["💿","cd"],["📷","camera"],
        ["🎥","movie camera"],["📺","tv"],["📻","radio"],["🔔","bell"],["🔕","no bell"],
        ["📢","megaphone"],["📣","horn"],["⏰","alarm"],["⏳","hourglass"],["🔋","battery"],
        ["🔌","plug"],["💡","bulb"],["🔦","flashlight"],["🕯️","candle"],["🗑️","trash"],
        ["🔑","key"],["🗝️","old key"],["🔒","lock"],["🔓","unlock"],["🔨","hammer"],
        ["🪓","axe"],["⛏️","pick"],["🔧","wrench"],["🔩","nut bolt"],["⚙️","gear"],
        ["📎","paperclip"],["✂️","scissors"],["📌","pin"],["📍","round pin"],["🖊️","pen"],
        ["✏️","pencil"],["📝","memo"],["📁","folder"],["📂","open folder"],["📅","calendar"],
        ["📊","chart"],["📈","chart up"],["📉","chart down"],["🗂️","card index"],
        ["💰","money bag"],["💵","dollar"],["💴","yen"],["💶","euro"],["💷","pound"],
        ["💎","gem"],["⚖️","scales"],["🧰","toolbox"],["🧲","magnet"],["🔗","link"],
        ["📦","package"],["📫","mailbox"],["📬","mailbox flag"],["📧","email"],["📩","envelope arrow"],
        ["🎁","gift"],["🎀","ribbon"],["🏷️","label"],["🔖","bookmark"]
      ],
      "Symbols" => [
        ["✅","check"],["❌","cross"],["❓","question"],["❗","exclamation"],["‼️","double excl"],
        ["⭕","circle"],["🚫","prohibited"],["🔴","red circle"],["🟠","orange circle"],
        ["🟡","yellow circle"],["🟢","green circle"],["🔵","blue circle"],["🟣","purple circle"],
        ["⚫","black circle"],["⚪","white circle"],["🟥","red square"],["🟧","orange square"],
        ["🟨","yellow square"],["🟩","green square"],["🟦","blue square"],["🟪","purple square"],
        ["⬛","black square"],["⬜","white square"],["🔶","orange diamond"],["🔷","blue diamond"],
        ["🔺","red triangle"],["🔻","red triangle down"],["💠","diamond dot"],["🔘","radio button"],
        ["✨","sparkles"],["⚡","zap"],["💥","boom"],["🎵","music"],["🎶","notes"],
        ["➡️","right arrow"],["⬅️","left arrow"],["⬆️","up arrow"],["⬇️","down arrow"],
        ["↗️","upper right"],["↘️","lower right"],["↙️","lower left"],["↖️","upper left"],
        ["🔀","shuffle"],["🔁","repeat"],["🔂","repeat one"],["▶️","play"],["⏸️","pause"],
        ["⏹️","stop"],["⏺️","record"],["⏭️","next track"],["⏮️","prev track"],
        ["🔊","loud"],["🔇","mute"],["🔔","bell2"],["📌","pushpin"],
        ["♻️","recycle"],["🏁","checkered flag"],["🚩","flag"],["🏳️","white flag"],
        ["🏴","black flag"],["⚠️","warning"],["🛑","stop sign"],["⛔","no entry"],
        ["♾️","infinity"],["💯","hundred"],["🆗","ok button"],["🆕","new"],["🆓","free"],
        ["ℹ️","info"],["🔤","abc"],["🔢","numbers"],["#️⃣","hash"],["*️⃣","asterisk"],
        ["0️⃣","zero"],["1️⃣","one"],["2️⃣","two"],["3️⃣","three"],["©️","copyright"],
        ["®️","registered"],["™️","trademark"]
      ],
      "Flags" => [
        ["🇳🇴","norway"],["🇸🇪","sweden"],["🇩🇰","denmark"],["🇫🇮","finland"],["🇮🇸","iceland"],
        ["🇬🇧","uk"],["🇺🇸","usa"],["🇨🇦","canada"],["🇦🇺","australia"],["🇳🇿","new zealand"],
        ["🇩🇪","germany"],["🇫🇷","france"],["🇪🇸","spain"],["🇮🇹","italy"],["🇵🇹","portugal"],
        ["🇳🇱","netherlands"],["🇧🇪","belgium"],["🇨🇭","switzerland"],["🇦🇹","austria"],
        ["🇵🇱","poland"],["🇨🇿","czech"],["🇬🇷","greece"],["🇹🇷","turkey"],["🇷🇺","russia"],
        ["🇺🇦","ukraine"],["🇯🇵","japan"],["🇰🇷","south korea"],["🇨🇳","china"],["🇮🇳","india"],
        ["🇧🇷","brazil"],["🇲🇽","mexico"],["🇦🇷","argentina"],["🇿🇦","south africa"],
        ["🇪🇬","egypt"],["🇮🇱","israel"],["🇸🇦","saudi"],["🇦🇪","uae"],["🇹🇭","thailand"],
        ["🇻🇳","vietnam"],["🇮🇩","indonesia"],["🇵🇭","philippines"],["🇲🇾","malaysia"],
        ["🇸🇬","singapore"],["🇭🇰","hong kong"],["🇹🇼","taiwan"],["🏳️‍🌈","rainbow flag"],
        ["🏴‍☠️","pirate flag"],["🎌","crossed flags"],["🏁","checkered"]
      ]
    }.freeze

    CELL_W = 4  # Each emoji cell = 4 terminal columns (space + emoji + space)

    # Main entry point: opens picker overlay, returns emoji string or nil
    def self.pick(parent_pane)
      max_h, max_w = IO.console ? IO.console.winsize : [24, 80]

      cols = 11
      ow = cols * CELL_W + 4
      oh = [max_h - 4, 22].min
      return nil if oh < 8

      ox = (max_w - ow) / 2 + 1
      oy = (max_h - oh) / 2 + 1

      overlay = Rcurses::Popup.new(x: ox, y: oy, w: ow, h: oh, fg: 255, bg: 236)
      overlay.scroll = false

      categories = CATEGORIES.keys
      cat_idx = 0
      sel_idx = 0
      search = ""

      fmt = "255,236"

      begin
        loop do
          # Determine items for current category or search
          if search.empty?
            items = CATEGORIES[categories[cat_idx]]
          else
            items = CATEGORIES.values.flatten(1).select { |_e, k|
              k.include?(search.downcase)
            }
          end

          total = items.size
          sel_idx = sel_idx.clamp(0, [total - 1, 0].max)

          # === Build pane text (header + blank grid area + footer) ===
          lines = []

          # Header: category tabs (wrapped to fit)
          header_lines = 0
          if search.empty?
            tab_rows = [[]]
            row_w = 0
            categories.each_with_index do |c, i|
              tab = " #{c} "
              tw = tab.length
              if row_w + tw > ow && !tab_rows.last.empty?
                tab_rows << []
                row_w = 0
              end
              tab_rows.last << (i == cat_idx ? tab.b.r : tab)
              row_w += tw
            end
            tab_rows.each { |tr| lines << tr.join("") }
            header_lines = tab_rows.size
          else
            lines << " Search: #{search}".b
            header_lines = 1
          end
          lines << ""
          header_lines += 1  # blank separator

          # Blank lines for grid area (pane fills bg color)
          grid_rows = (total + cols - 1) / cols
          grid_rows.times { lines << "" }

          # Pad remaining space
          while lines.size < oh - 3
            lines << ""
          end

          # Footer
          lines << ""
          if total > 0 && items[sel_idx]
            lines << " :#{items[sel_idx][1]}:".fg(245)
          else
            lines << ""
          end

          overlay.text = lines.join("\n")
          overlay.ix = 0
          overlay.full_refresh
          overlay.border_refresh

          # === Render emoji grid at explicit cursor positions ===
          # This bypasses display_width entirely for grid alignment
          flat_i = 0
          items.each_slice(cols) do |row|
            grid_row = flat_i / cols
            abs_row = oy + header_lines + grid_row
            row.each_with_index do |(emoji, _keyword), col_i|
              abs_col = ox + col_i * CELL_W
              STDOUT.print "\e[#{abs_row};#{abs_col}H"
              if flat_i == sel_idx
                STDOUT.print " #{emoji} ".c("236,255")  # Inverted colors
              else
                STDOUT.print " #{emoji} ".c(fmt)
              end
              flat_i += 1
            end
          end
          STDOUT.flush

          # Input
          chr = getchr(flush: false)
          case chr
          when 'ESC'
            return nil
          when 'ENTER'
            return (total > 0 && items[sel_idx]) ? items[sel_idx][0] : nil
          when 'RIGHT'
            sel_idx = [sel_idx + 1, total - 1].min if total > 0
          when 'LEFT'
            sel_idx = [sel_idx - 1, 0].max
          when 'UP'
            sel_idx = [sel_idx - cols, 0].max
          when 'DOWN'
            sel_idx = [sel_idx + cols, total - 1].min if total > 0
          when 'TAB'
            if search.empty?
              cat_idx = (cat_idx + 1) % categories.size
              sel_idx = 0
            end
          when 'S-TAB'
            if search.empty?
              cat_idx = (cat_idx - 1) % categories.size
              sel_idx = 0
            end
          when 'BACK'
            if search.length > 0
              search = search[0..-2]
              sel_idx = 0
            end
          when /^.$/
            search << chr
            sel_idx = 0
          end
        end
      ensure
        overlay.cleanup if overlay.respond_to?(:cleanup)
      end
    end
  end
end
