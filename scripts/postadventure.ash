import iotm.ash;

void pearl(){
    record pearl {
    location loc;
    modifier ele_res;
	string donePref;
    };
    pearl[string] pearls = {
        "anemone":  new pearl($location[Anemone Mine],              $modifier[spooky resistance],   "_unblemishedPearlAnemoneMine"),
        "bar":	    new pearl($location[The Dive Bar],              $modifier[sleaze resistance],   "_unblemishedPearlDiveBar"),
        "reef":	    new pearl($location[Madness Reef],              $modifier[stench resistance],   "_unblemishedPearlMadnessReef"),
        "trench":	new pearl($location[The Marinara Trench],       $modifier[hot resistance],      "_unblemishedPearlMarinaraTrench"),
        "deepests":	new pearl($location[The Briniest Deepests],     $modifier[cold resistance],     "_unblemishedPearlTheBriniestDeepests"),
    };
    foreach str in $strings[anemone,bar,reef,trench,deepests]{
        if (to_int(get_property(pearls[str].donePref + "Progress")) < 100 && get_property(pearls[str].donePref) != "true"){
            set_property("maxOverride",pearls[str].ele_res);
            set_property("pantsOverride",", equip really nice");
            set_property("famEquipOverride",", equip little bitty bathy");
            adv1(pearls[str].loc);
            if (numeric_modifier( pearls[str].ele_res ) < 18){
                abort();
            }
        }
    }
}

void cookbookbat(){
    if (get_property("_cookbookbatQuestMonster") != ""){
        set_property("famOverride","cookbookbat");
        location CBBLoc = to_location(get_property("_cookbookbatQuestLastLocation"));
        monster CBBMon = to_monster(get_property("_cookbookbatQuestMonster"));
        if (have_effect($effect[everything looks green]) == 0 && have_effect($effect[Everything looks Beige]) == 0){
            set_property("acc1Override","equip spring shoes");
            equip($slot[acc2],$item[spring shoes]);
            set_property("battleAction", "skill spring away");
            visit_url("adventure.php?snarfblat=" + to_int(CBBLoc));
            if (get_property("lastEncounter") == get_property("_cookbookbatQuestMonster")){
                set_property("battleAction", "skill saucegeyser");  
                run_combat();
            } else {
                run_choice(-1);
                set_property("battleAction", "skill saucegeyser");
                visit_url("inventory.php?action=parachute");
                visit_url("choice.php?option=1&whichchoice=1543&monid=" + to_int(CBBMon));
                run_combat();
                set_property("battleAction", "custom combat script");
            }
        } else if (get_property("_juneCleaverFightsLeft") == 0 && have_effect($effect[Everything looks Beige]) == 0){
            set_property("mainOverride","equip june cleaver");
            adv1(CBBLoc);
            visit_url("inventory.php?action=parachute");
            visit_url("choice.php?option=1&whichchoice=1543&monid=" + to_int(CBBMon));
            run_combat();
            set_property("battleAction", "custom combat script");
        } else if (!contains_text(get_property("_perilLocations"), to_string(to_int(CBBLoc))) && CBBLoc!= $location[the primordial soup]){
            set_property("acc1Override",", equip peridot of peril");
            set_property("choiceAdventure1557","1&bandersnatch=" + to_int(CBBMon));
            adv1(CBBLoc,0,"");
        }
    }
    set_property("battleAction", "custom combat script");
    set_property("mainOverride","");
    set_property("famOverride","");
    set_property("acc1Override","");
}

void cyberzone() {
    while (to_int(get_property("_cyberFreeFights")) < 10) {
        maximize("item drop", false);

        if (!contains_text(get_property("banishedPhyla"), "construct")) {
            adv1($location[cyberzone 1], 0, "");
            continue;
        }

        // Scout zones we haven't identified yet
        if (get_property("_cyberZone1Hacker") == "") {
            adv1($location[cyberzone 1], 0, "");
            set_property("_cyberZone1Hacker", last_monster());
            continue;
        }
        if (get_property("_cyberZone2Hacker") == ""
            && get_property("_cyberZone1Hacker") != "greyhat hacker") {
            adv1($location[cyberzone 2], 0, "");
            set_property("_cyberZone2Hacker", last_monster());
            continue;
        }
        if (get_property("_cyberZone3Hacker") == ""
            && get_property("_cyberZone1Hacker") != "greyhat hacker"
            && get_property("_cyberZone2Hacker") != "greyhat hacker") {
            adv1($location[cyberzone 3], 0, "");
            set_property("_cyberZone3Hacker", last_monster());
            continue;
        }

        // Adventure in whichever zone has the target hacker
        location [monster] hackerZone = {
            to_monster(get_property("_cyberZone1Hacker")): $location[cyberzone 1],
            to_monster(get_property("_cyberZone2Hacker")): $location[cyberzone 2],
            to_monster(get_property("_cyberZone3Hacker")): $location[cyberzone 3]
        };
        foreach mon in $monsters[greyhat hacker,bluehat hacker,greenhat hacker,redhat hacker,purplehat hacker] {
            if (hackerZone contains mon) {
                if (contains_text(get_property("banishedMonsters"), mon + ":Sea *dent")){
                    set_property("mainOverride",", equip monodent");
                    set_property("battleAction","skill sea *dent: throw a lightning bolt");
                    adv1($location[The spooky forest]);
                    return;
                } else {
                    set_property("mainOverride","");
                    set_property("battleAction","custom combat script");
                }
                adv1(hackerZone[mon], 0, "");
                break;
            }
        }
    }
}

void BoFaWish(){
    if (my_class() == $class[accordion thief]){
            int [string] wish_map = {
                "280":	1160,
                "242":	981,
                "441":	1751,
                "389":	375,
                "243":	977
            };
        foreach loc in wish_map{
            if ((!contains_text(get_property("_perilLocations"),loc) || get_property("rwbLocation") == to_location(to_int(loc))) && can_adventure(to_location(to_int(loc)))){
                if (have_effect($effect[Everything Looks Red, White and Blue]) == 0 && to_int(get_property("_bookOfFactsWishes")) < 2){
                    set_property("famOverride","patriotic eagle");
                    set_property("BoFaWishRWB","true");
                }
                set_property("acc1Override",", equip peridot of peril");
                set_property("choiceAdventureScript","");
                set_property("choiceAdventure1557","1&bandersnatch=" + wish_map[loc]);
                try{
                    adv1(to_location(to_int(loc)));
                } finally {
                    set_property("famOverride","");
                    set_property("acc1Override","");
                    set_property("choiceAdventureScript","generalChocie.ash");
                    set_property("BoFaWishRWB","false");
                }
                return;
            }
        }
    } else {
        abort();
    }
}

void shadowRealm(){
    set_property("maxOverride","item drop");
    if (to_int(get_property("_bczRefractedGazeCasts")) < 9)
        set_property("acc2Override",", equip blood cubic zirconia");
    if (to_int(get_property("_batWingsSwoopUsed")) < 11)
        set_property("backOverride",", equip bat wings");
    if (get_property("questRufus") == "unstarted")
        use($item[closed-circuit pay phone]);
    if(get_property("_seadentWaveZone") == "Shadow Rift")
        set_property("mainOverride",", equip monodent");
    cli_execute("preadventure.ash");
    adv1($location[Shadow Rift (The Misspelled Cemetary)]);
    if (get_property("questRufus") == "step1") {
        use($item[closed-circuit pay phone]);
        adv1($location[Shadow Rift (The Misspelled Cemetary)]);
    }
    set_property("maxOverride","");
    set_property("mainOverride","");
}

void postAdv(){
    if (get_property("_lastCombatLost") == "true" && get_property("noncombatForcerActive") != "true" && LastAdvTxt().contains_text("Round 1") && my_location() != $location[the outer compound]){
        cli_execute("cast tongue;cast cannel");
        abort("It appears you lost the last combat, look into that");
    }
    if (have_effect($effect[beaten up]) > 0 )
        cli_execute("cast tongue of the walrus");
    if (get_property("lastAdventure") == "Poisoned Spleen")
        abort("Spleen Poisoned");
    foreach ef in $effects[juiced,majorly poisoned]{
        if (have_effect(ef) > 0)
            cli_execute("uneffect " + ef);
    }
    if (my_location() == $location[mer-kin elementary school] && to_monster(get_property("lastEncounter")) == $monster[none] && $ints[396, 397, 398, 399, 400, 401] contains last_choice()){
        buffer elementaryQueue = to_buffer(get_property("elementaryQueue"));
        append(elementaryQueue, ", " + last_choice());
        delete(elementaryQueue,0,5);
        set_property("elementaryQueue",to_string(elementaryQueue));
    }
    if (get_property("script") == "unblemisedPearl"){
        if (my_buffedstat($stat[moxie]) < 405)
            cli_execute("gain 405 moxie");
        if (have_effect($effect[fishy]) == 0)
            abort("Out of fishy");
    }
    if (my_adventures() < 100 && get_property("_lawOfAveragesUsed") == "0")
        use($item[law of averages]);
    if (get_property("autumnatonQuestLocation") == "" && item_amount($item[autumn-aton]) > 0)
        cli_execute("autumnaton send shadow rift");
    if (have_effect($effect[resined]) == 0)
        use($item[distilled resin]);
    if (get_property("trainsetPosition").to_int() >= get_property("lastTrainsetConfiguration").to_int() + 42 && get_workshed() == $item[model train set]){
        visit_url("campground.php?action=workshed");
        trainset();
    }
    if (get_property("_universeCalculated").to_int() < (get_property("ascensionsToday") == "1" ? 3 : get_property("skillLevel144").to_int()) && uniAdv <= my_adventures())
        if (universe() == my_adventures()){
            visit_url("runskillz.php?action=Skillz&whichskill=144&targetplayer=0&quantity=1");
            visit_url("choice.php?whichchoice=1103&option=1&num="+uniInt);
        }
#    if (get_property("_mimicEggsObtained").to_int() < 0 && $familiar[chest mimic].experience >= 550){
#        cli_execute("unequip cursed monkey's paw");
#        put_closet(1,$item[cursed monkey's paw]);
#        if (have_effect($effect[chilled to the bone]) > 0)
#            use($item[hot dreadsylvanian cocoa]);
#        try {
#            cli_execute("garbo nobarf");
#        } finally {
#            take_closet($item[cursed monkey's paw]);
#        }
#    }
    if (get_property("sweat").to_int() > 75 && my_adventures() > 100 && have_equipped($item[designer sweatpants])){
        if (get_property("_sweatOutSomeBoozeUsed").to_int() < 3)
            use_skill($skill[sweat out some booze]);
        else
            use_skill($skill[Make Sweat-Ade]);
    }
    if (get_property("leprecondoInstalled") != "19,9,13,18" && to_int(get_property("_leprecondoRearrangements")) < 3){
        leprecondo("19,9,13,18");
    }
    if ((my_adventures() <= 102 && have_equipped($item[drunkula's wineglass]) && !get_property("_garboCompleted").contains_text("ascend")) || (my_adventures() <= 10 && my_location() == $location[A Maze of Sewer Tunnels]))
        abort("Done for the day");
    if (my_adventures() == 0){
        if (have_equipped($item[drunkula's wineglass]))
            abort("Done for the day");
        if ($strings[solobop, 6-kiss, coat, stick] contains get_property("script")){
            if (!have_equipped($item[angelbone chopsticks])){
                equip($slot[acc3],$item[angelbone chopsticks]);
                cli_execute("refresh all; CONSUME ALL");
                return;
            } else if (!have_equipped($item[devilbone greaves])){
                equip($item[devilbone greaves]);
                cli_execute("refresh all; CONSUME ALL");
                return;
            } else if (!have_equipped($item[devilbone corset])){
                equip($item[devilbone corset]);
                cli_execute("refresh all; CONSUME ALL");
                return;
            } else if (contains_text(get_property("_garboCompleted"),"ascend")){
            } else if (my_familiar() != $familiar[stooper]){
                use_familiar($familiar[stooper]);
                cli_execute("refresh all; CONSUME ALL");
                return;
            } else if (!have_equipped($item[devilbone rosary]) && get_property("subscript") != "forest"){
                equip($slot[acc1],$item[devilbone rosary]);
                cli_execute("refresh all; CONSUME ALL");
                return;
            } else if (!have_equipped($item[angelbone totem]) && get_property("subscript") != "village" && get_property("subscript") != "castle"){
                equip($item[angelbone totem]);
                cli_execute("refresh all; CONSUME ALL");
                return;
            } else if (!have_equipped($item[angelbone dice])){
                equip($slot[acc1],$item[angelbone dice]);
                cli_execute("refresh all; CONSUME ALL");
                return;
            } else if (my_inebriety() == inebriety_limit()) {
                cli_execute("CONSUME NIGHTCAP");
                cli_execute("equip drunkula's wineglass; unequip devilbone rosary; unequip angelbone dice; familiar cookbookbat");
                return;
            }
        }
    }
}
void spendAdv(){
    set_property("betweenBattleScript","preadventure.ash");
    if (get_property("_cyberFreeFights").to_int() < 10 && have_effect($effect[everything looks green]) == 0){
        while (get_property("screechCombats") == "0" && !contains_text(get_property("banishedPhyla"),"construct")){
            set_property("famOverride","patriotic eagle");
            set_property("maxOverride","ml");
            set_property("acc2Override",", equip peridot of peril");
            set_property("acc3Override",",equip spring shoes");
            adv1($location[Madness Bakery],0,"");
        }
        set_property("famOverride","");
        set_property("maxOverride","");
        set_property("acc2Override","");
        set_property("acc3Override","");
        while (get_property("banishedPhyla").contains_text("construct") && get_property("_cyberFreeFights").to_int() < 10){
            cyberzone();
        }
    }
    if (get_property("noncombatForcerActive") == "true" && get_property("script") != "solobop"){
        if (have_effect($effect[Coated in Slime]) <= 6 && have_effect($effect[Coated in Slime]) > 0)
            camo();
        if (have_effect($effect[chilled to the bone]) > 0)
            use($item[hot Dreadsylvanian cocoa]);
        while (get_property("_aprilBandTubaUses").to_int() < 3 && item_amount($item[Apriling band tuba]) > 0)
            cli_execute("aprilband play tuba");
        if (get_property("_claraBellUsed") == "false")
            use($item[clara's bell]);
        while (get_property("timesRested").to_int() < total_free_rests()){
            cli_execute("unequip hat; equip apriling band helmet;camp rest free");
            if (get_property("_cinchUsed").to_int() <= 40){
                equip($slot[acc3],$item[cincho de mayo]);
                use_skill($skill[Cincho: Fiesta Exit]);
            }
        }
        if ((get_property("questL06Friar") == "started" || get_property("questL06Friar") == "step1") && get_property("ascensionsToday") == "1" && get_property("seaAftercore") == "true"){
            if (get_property("questL06Friar") == "started")
                visit_url("friars.php?action=friars");
            while (get_property("noncombatForcerActive") == "true" && item_amount($item[dodecagram]) == 0)
                adv1($location[the dark neck of the woods],0,"");
            while (get_property("noncombatForcerActive") == "true" && item_amount($item[box of birthday candles]) == 0)
                adv1($location[the dark heart of the woods],0,"");
            while (get_property("noncombatForcerActive") == "true" && item_amount($item[eldritch butterknife]) == 0)
                adv1($location[the dark elbow of the woods],0,"");
        } else if (get_property("questM16Temple") != "finished" && get_property("seaAftercore") == "true"){
            while (get_property("questM16Temple") != "finished" && get_property("noncombatForcerActive") == "true"){
                if (item_amount($item[tree-holed coin]) == 0 && item_amount($item[Spooky Temple map]) == 0){
                    set_property("choiceAdventure502","2");
                    set_property("choiceAdventure505","2");
                    adv1($location[the spooky forest]);
                } else if (item_amount($item[Spooky Temple map]) == 0){
                    set_property("choiceAdventure502","3");
                    set_property("choiceAdventure506","3");
                    set_property("choiceAdventure507","1");
                    adv1($location[the spooky forest]);
                } else if (item_amount($item[spooky sapling]) == 0){
                    set_property("choiceAdventure502","1");
                    set_property("choiceAdventure503","3");
                    set_property("choiceAdventure504","3");
                    adv1($location[the spooky forest]);
                }
                if (item_amount($item[Spooky-Gro fertilizer]) == 0)
                    cli_execute("acquire Spooky-Gro fertilizer");
                if (item_amount($item[Spooky Temple map]) > 0 && item_amount($item[spooky sapling]) > 0){
                    use($item[Spooky Temple map]);
                    if (get_property("_mayamSymbolsUsed") == "")
                        cli_execute("mayam rings vessel yam cheese explosion; mayam rings fur bottle wall clock; mayam rings eye meat yam yam");
                    if (have_effect($effect[stone-faced]) == 0)
                        use($item[stone wool]);
                    set_property("choiceAdventure582","1");
                    set_property("choiceAdventure579","3");
                    adv1($location[the hidden temple]);
                }
            }
        } else if (get_property("script") != "stick" && get_property("script") != "coat"){
            if (get_property("_shadowAffinityToday") == "false" || have_effect($effect[shadow affinity]) > 0){
                if (get_property("questRufus")== "unstarted"){
                    use($item[closed-circuit pay phone]);
                }
                while (have_effect($effect[shadow affinity]) > 0){
                    shadowRealm();
                }
            }
            if (have_effect($effect[null afternoon]) == 0)
                use($item[null-day exploit]);
            set_property("choiceAdventure1497","1");
            while (get_property("noncombatForcerActive") == "true"){
                set_property("acc2Override",", equip petrified wood wizard's pouch");
                use($item[closed-circuit pay phone]);
                if (get_property("_mcHugeLargeAvalancheUses").to_int() < 3)
                    set_property("acc3Override",", equip McHugeLarge left ski");
                if (get_property("_spikolodonSpikeUses").to_int() < 5){
                    set_property("shirtOverride",", equip parka spikolodon");
                }
                if (get_property("rufusQuestTarget") == "shadow scythe")
                    use_skill($skill[Cannelloni Cocoon]);
                if (get_property("rufusQuestTarget") == "shadow orrery")
                    set_property("maxOverride","elemental dmg");
                adv1($location[Shadow Rift (The Nearby Plains)],0,"");
                use($item[closed-circuit pay phone]);
                if (item_amount($item[Rufus's shadow lodestone]) > 0)
                    adv1($location[Shadow Rift (The Nearby Plains)],0,"");
            }
            set_property("shirtOverride","");
            set_property("acc2Override","");
            set_property("acc3Override","");
            set_property("maxOverride","");
        }
    }
    if (delay() && get_property("seaAftercore") == "true" && $location[the spooky forest].turns_spent < 5 && get_property("questM16Temple") != "finished"){
        if (have_effect($effect[Coated in Slime]) <= 6)
            camo();
        set_property("betweenBattleScript","");
        if (get_property("clubEmNextWeekMonster") != "" && total_turns_played() >= get_property("clubEmNextWeekMonsterTurn").to_int() + 8)
            equip($item[legendary seal-clubbing club]);
        else if (item_amount($item[&quot;I Voted!&quot; sticker]) > 0 && total_turns_played()%11 == 1 && get_property("_voteFreeFights").to_int() < 3)
            equip($slot[acc3],$item[&quot;I Voted!&quot; sticker]);
        else if (have_effect($effect[everything looks green]) == 0)
            equip($slot[acc3],$item[spring shoes]);
        adv1($location[the spooky forest],0,"");
    }
    if (get_property("_spikolodonSpikeUses").to_int() == 5 && get_property("questM10Azazel") != "finished" && (delay() || my_adventures() < 250) && get_property("seaAftercore") == "true" && get_property("ascensionsToday") == "1"){
        if (have_effect($effect[Coated in Slime]) <= 6 && have_effect($effect[Coated in Slime]) > 0)
            camo();
        set_property("betweenBattleScript","");
        set_property("afterAdventureScript","");
        while (item_amount($item[dodecagram]) == 0 && get_property("questL06Friar") == "step1"){
            cli_execute("acquire 1 handheld allied radio; alliedradio misc sniper");
            adv1($location[the dark neck of the woods],0,"");
        }
        while (item_amount($item[box of birthday candles]) == 0 && get_property("questL06Friar") == "step1"){
            cli_execute("acquire 1 handheld allied radio; alliedradio misc sniper");
            adv1($location[the dark heart of the woods],0,"");
        }
        while (item_amount($item[eldritch butterknife]) == 0 && get_property("questL06Friar") == "step1"){
            cli_execute("acquire 1 handheld allied radio; alliedradio misc sniper");
            adv1($location[the dark elbow of the woods],0,"");
        }
        if (get_property("questL06Friar") == "step2")
            visit_url("friars.php?action=ritual");
        int backstage1 = item_amount($item[gin-soaked blotter paper]) + item_amount($item[beer-scented teddy bear]) + item_amount($item[giant marshmallow]);
        int backstage2 = item_amount($item[booze-soaked cherry]) + item_amount($item[comfy pillow]) + item_amount($item[sponge cake]);
        if (delay() && item_amount($item[observational glasses]) == 0){
            maximize("combat",false);
            if (get_property("clubEmNextWeekMonster") != "" && total_turns_played() >= get_property("clubEmNextWeekMonsterTurn").to_int() + 8)
                equip($item[legendary seal-clubbing club]);
            else if (item_amount($item[&quot;I Voted!&quot; sticker]) > 0 && total_turns_played()%11 == 1 && get_property("_voteFreeFights").to_int() < 3)
                equip($slot[acc3],$item[&quot;I Voted!&quot; sticker]);
            else if (have_effect($effect[everything looks green]) == 0)
                equip($slot[acc3],$item[spring shoes]);
            adv1($location[The Laugh Floor],0,"");
        } else if (my_adventures() < 250){
            if (have_effect($effect[Coated in Slime]) > 0)
                camo();
            while (item_amount($item[observational glasses]) == 0){
                maximize("combat",false);
                if (numeric_modifier("combat rate") < 35)
                    cli_execute("gain 35 combat rate 100 spendperturn");
                if (have_effect($effect[Apriling Band Battle Cadence]) == 0 && total_turns_played() >= get_property("nextAprilBandTurn").to_int())
                    cli_execute("aprilband effect c");
                adv1($location[The Laugh Floor],0,"");
            }
            while ((backstage1 < 2 || backstage2 < 2) && item_amount($item[Azazel's unicorn]) == 0){
                adv1($location[Infernal Rackets Backstage],0,"");
                backstage1 = item_amount($item[gin-soaked blotter paper]) + item_amount($item[beer-scented teddy bear]) + item_amount($item[giant marshmallow]);
                backstage2 = item_amount($item[booze-soaked cherry]) + item_amount($item[comfy pillow]) + item_amount($item[sponge cake]);
            }
        }
        if (backstage1 > 1 && backstage2 > 1 && item_amount($item[observational glasses]) > 0){
            cli_execute("equip acc3 observational glasses; acquire 5 bus pass; acquire 5 imp air");
            visit_url("pandamonium.php?action=moan");
            visit_url("pandamonium.php?action=moan");
            visit_url("pandamonium.php?action=mourn");
            visit_url("pandamonium.php?action=mourn&preaction=observe");
            visit_url("pandamonium.php?action=sven");
            if (item_amount($item[giant marshmallow]) > 0){
                visit_url("pandamonium.php?action=sven&preaction=help");
                visit_url("pandamonium.php?action=sven&bandmember=Bognort&togive=4673&preaction=try");
            } else {
                visit_url("pandamonium.php?action=sven&preaction=help");
                visit_url("pandamonium.php?action=sven&bandmember=Bognort&togive=4675&preaction=try");
            }
            if (item_amount($item[beer-scented teddy bear]) > 0){
                visit_url("pandamonium.php?action=sven");
                visit_url("pandamonium.php?action=sven&bandmember=Stinkface&togive=4670&preaction=try");
            } else {
                visit_url("pandamonium.php?action=sven");
                visit_url("pandamonium.php?action=sven&bandmember=Stinkface&togive=4675&preaction=try");
            }
            if (item_amount($item[booze-soaked cherry]) > 0){
                visit_url("pandamonium.php?action=sven");
                visit_url("pandamonium.php?action=sven&bandmember=Flargwurm&togive=4671&preaction=try");
            } else {
                visit_url("pandamonium.php?action=sven");
                visit_url("pandamonium.php?action=sven&bandmember=Flargwurm&togive=4674&preaction=try");
            }
            if (item_amount($item[comfy pillow]) > 0){
                visit_url("pandamonium.php?action=sven");
                visit_url("pandamonium.php?action=sven&bandmember=Jim&togive=4672&preaction=try");
            } else {
                visit_url("pandamonium.php?action=sven");
                visit_url("pandamonium.php?action=sven&bandmember=Jim&togive=4674&preaction=try");
            }
            visit_url("pandamonium.php?action=temp");
            cli_execute("drink steel margarita");
        }
    }
    if (my_adventures() < 50 && !get_property("banishedMonsters").contains_text("sewer gator") && get_property("_garboCompleted").contains_text("ascend") && have_effect($effect[everything looks green]) == 0 && my_inebriety() <= inebriety_limit() && get_property("script") == ""){
        string clanID = get_clan_id();
        if (have_effect($effect[coated in slime]) > 0)
            camo();
        visit_url("showclan.php?whichclan=2047010572&action=joinclan&confirm=on");
        equip($item[monodent of the sea]);
        equip($item[roman candelabra]);
        equip($slot[acc3],$item[spring shoes]);
        equip($slot[acc2],$item[peridot of peril]);
        set_property("betweenBattleScript","");
        set_property("choiceAdventure1557","1&bandersnatch=681");
        adv1($location[A Maze of Sewer Tunnels],0,"");
        visit_url("inventory.php?action=parachute");
        visit_url("choice.php?option=1&whichchoice=1543&monid=679");
        run_combat();
        visit_url("showclan.php?whichclan="+clanID+"&action=joinclan&confirm=on");
    }
    if (free_Kill()){
        if (have_effect($effect[everything looks yellow]) == 0){
            cli_execute("parka dilophosaur");
            set_property("shirtOverride",", equip jurassic parka");
            shadowRealm();
        } else if (have_effect($effect[everything looks red]) == 0){
            set_property("acc1Override",", equip everfull dart holster");
            shadowRealm();
        }
        set_property("maxOverride","");
        set_property("backOverride","");
        set_property("shirtOverride","");
        set_property("acc1Override","");
    }
    if (get_property("encountersUntilSRChoice") == 0){
        shadowRealm();
    }
    if (have_effect($effect[everything looks beige]) == 0 && (free_run() || get_property("_juneCleaverFightsLeft") == 0)){
        cookbookbat();
    }
    location CBBLoc = to_location(get_property("_cookbookbatQuestLastLocation"));
    if (!contains_text(get_property("_perilLocations"), to_string(to_int(CBBLoc))) && CBBLoc!= $location[the primordial soup] 
        && get_property("_cookbookbatQuestIngredient") == "Yeast of Boris"
        && have_effect($effect[everything looks beige]) > 30){
        cookbookbat();
    }
    if (my_adventures() < 25 && to_int(get_property("_bookOfFactsWishes")) < 3) 
        BoFaWish();
    if (free_run()){
        if (have_effect($effect[everything looks green]) == 0 && ((have_effect($effect[everything looks beige]) <= to_int(get_property("_juneCleaverFightsLeft"))) || have_effect($effect[everything looks beige]) >= 30)){
            set_property("acc1Override",", equip spring shoes");
            shadowRealm();
        }
        set_property("acc1Override","");
    }
}

void main(){
    set_property("afterAdventureScript","");
    string boof = get_property("betweenBattleScript");
//    set_property("betweenBattleScript","");
    set_property("hpAutoRecovery",0.75);
    set_property("hpAutoRecoveryTarget",0.95);
    set_property("mpAutoRecovery",0.45);
    set_property("mpAutoRecoveryTarget",0.6);
    try {
        postAdv();
        if (my_adventures() != 0 && get_property("script") != "unblemisedPearl")
            spendAdv();
    } finally {
        set_property("betweenBattleScript",boof);
        set_property("afterAdventureScript","postadventure.ash");
    }
}
