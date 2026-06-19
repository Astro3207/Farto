import iotm.ash;
import postadventure.ash;

void mood(string function){
    if (get_property("script") == "6-kiss"){
        foreach ef in $effects[Troubled Waters, Pride of the Puffin, Ur-Kel's Aria of Annoyance, Drescher's Annoying Noise]
            if (have_effect(ef) > 0)
                cli_execute("uneffect " + ef);
        if (current_mcd() > 0)
            cli_execute("mcd 0");
        int targetInit = max($monster[hot skeleton].base_initiative + 1, $monster[hot werewolf].base_initiative + 1, $monster[hot ghost].base_initiative + 1);
        if (targetInit > 448)
            abort("init too high");
        if (numeric_modifier("initiative") < targetInit)
            cli_execute("gain " + targetInit + " initiative");
        if (have_effect($effect[chilled to the bone]) > 0 && have_effect($effect[Touched by a Ghost]) > 0 && my_maxhp() < 1000 && get_property("subscript") == "village")
            use($item[hot Dreadsylvanian cocoa]);
        if (get_property("_monkeyPawWishesUsed").to_int() > 0 || !bullseyeReady()){
            if (numeric_modifier("item drop") < 500)
                cli_execute("gain 500 item drop 100 maxmeatspent");
            if (get_property("subscript") == "castle" && item_amount($item[shadow brick]) == 0)
                cli_execute("acquire shadow brick");
            if (get_property("subscript") == "forest"){
                if (have_effect($effect[null afternoon]) == 0)
                    use($item[null-day exploit]);
                if (have_effect($effect[chilled to the bone]) > 0)
                    use($item[hot dreadsylvanian cocoa]);
                if (my_maxhp() < 700)
                    cli_execute("gain 700 hp 100 maxmeatspent");
            }
        }
    } else if (get_property("script") == "farto"){
        foreach ef in $effects[Yes\, Can Haz, ode to booze]
            if (have_effect(ef) > 0)
                cli_execute("uneffect " + ef);
        foreach ef in $effects[Only Dogs Love a Drunken Sailor,How to Scam Tourists,Best Pals,Sweat equity, Flapper Dancin',Legendary Pasta Eyeball,
            ballad of richie thingfinder,material witness,
            pride of the puffin, Singer's Faithful Ocelot,Drescher's Annoying Noise, Leash of Linguini, empathy,Thoughtful Empathy,
            Disco Leer,Polka of Plenty,Tubes of Universal Meat,Lubricating Sauce,Strength of the Tortoise]{
            if (ef == $effect[material witness] && get_property("_jukebox") == "false"){
                visit_url("showclan.php?whichclan=2046992052&action=joinclan&confirm=on");
            } else if (ef == $effect[material witness] && get_property("_jukebox") == "true"){
                continue;
            } else if (to_int(get_property("_heartstonePalsUsed")) == 5 && ef == $effect[best pals]){
                continue;
            } else if (ef == $effect[ballad of richie thingfinder] && get_property("_thingfinderCasts") == 10){
                continue;
            } else if (ef == $effect[sweat equity] && to_int(get_property("_bczSweatEquityCasts")) >= 11){
                continue;
            }
            if (have_effect(ef) == 0)
                cli_execute(ef.default);
            if (have_effect(ef) == 0)
                abort(ef + " did not increase");
        }
        //mana burning: disco leer, leash of linguini, pride of the puffin, drescher's annoying noise, empathy and thoughtful empathy,Singer's Faithful Ocelot,Fat Leon's Phat Loot Lyric,Ur-Kel's Aria of Annoyance,Polka of Plenty,Lubricating Sauce,Strength of the Tortoise,Tubes of Universal Meat
    }
    switch (get_property("maxOverride")){
        case "-combat":
            if (have_effect($effect[Apriling Band Patrol Beat]) == 0 && total_turns_played() >= get_property("nextAprilBandTurn").to_int())
                    cli_execute("aprilband effect nc");
            if (numeric_modifier("combat rate") > -35)
                cli_execute("gain -35 combat rate 100 maxmeatspent");
            break;
        case "combat":
            if (numeric_modifier("combat rate") < 35)
                cli_execute("gain 35 combat rate 800 maxmeatspent");
            if (have_effect($effect[Apriling Band Battle Cadence]) == 0 && total_turns_played() >= get_property("nextAprilBandTurn").to_int())
                cli_execute("aprilband effect c");
            break;
        case "spooky res":
            if (numeric_modifier("spooky res") < 10)
                cli_execute("gain spooky res 100 maxmeatspent");
            break;
    }
    switch (function){
        case "-combat":
            if (numeric_modifier("combat rate") > -35)
                cli_execute("gain -35 combat rate 100 maxmeatspent");
            if (have_effect($effect[Apriling Band Patrol Beat]) == 0 && total_turns_played() >= get_property("nextAprilBandTurn").to_int())
                cli_execute("aprilband effect nc");
            break;
        case "combat":
            if (numeric_modifier("combat rate") < 35)
                cli_execute("gain 35 combat rate 100 maxmeatspent");
            if (have_effect($effect[Apriling Band Battle Cadence]) == 0 && total_turns_played() >= get_property("nextAprilBandTurn").to_int())
                cli_execute("aprilband effect c");
            break;
        case "item drop":
            if (numeric_modifier("item drop") < 666)
                cli_execute("gain 666 item drop 100 maxmeatspent");
            break;
        case "spooky res":
            if (numeric_modifier("spooky res") < 10)
                cli_execute("gain spooky res 100 maxmeatspent");
            break;
    }
}

void preAdv(){
    // ── Familiar selection ────────────────────────────────────────────────────
    if (my_familiar() != $familiar[stooper]){
        string famOvr = get_property("famOverride");
        string maxOvr = get_property("maxOverride");
        if (famOvr != "")
            use_familiar(famOvr.to_familiar());
        else if (get_property("_knuckleboneDrops").to_int() < 100)
            use_familiar($familiar[skeleton of crimbo past]);
        else if (have_effect($effect[Citizen of a Zone]) == 0 && get_property("screechCombats").to_int() > 0)
            use_familiar($familiar[patriotic eagle]);
        else if ($familiar[chest mimic].experience < 550 && !get_property("_garboCompleted").contains_text("ascend")){
            use_familiar($familiar[chest mimic]);
            if (have_effect($effect[heart of white]) == 0)
                use($item[white candy heart]);
        } else if (($familiar[cooler yeti].experience < 400 && get_property("_coolerYetiAdventures") == "false") || ($familiar[cooler yeti].experience < 800 && !get_property("_garboCompleted").contains_text("ascend"))){
            use_familiar($familiar[cooler yeti]);
            if (have_effect($effect[heart of white]) == 0)
                use($item[white candy heart]);
        } else if (maxOvr == "item drop" || get_property("_mapToACandyRichBlockDrops").to_int() < 1)
            use_familiar($familiar[jill-of-all-trades]);
        else if (maxOvr == "-combat")
            use_familiar($familiar[peace turkey]);
        else if (maxOvr == "+combat")
            use_familiar($familiar[Jumpsuited Hound Dog]);
        else if (get_property("script") == "slime")
            use_familiar($familiar[purse rat]);
        else
            use_familiar($familiar[cookbookbat]);
    }

    // ── Familiar equip helper ─────────────────────────────────────────────────
    string famEquip(){
        if (get_property("famEquipOverride") != "") return get_property("famEquipOverride");
        if (my_familiar() == $familiar[skeleton of crimbo past]) return ", equip small peppermint-flavored sugar walking crook";
        if (my_familiar() == $familiar[cooler yeti] || my_familiar() == $familiar[chest mimic]) return ", equip toy cupid bow";
        if (my_familiar() == $familiar[mini kiwi]) return ", equip aviator goggles";
        if (my_familiar() == $familiar[Hobo in Sheep's Clothing]) return ", equip half-height cigar";
        if (my_familiar() == $familiar[none] || my_familiar() == $familiar[purse rat] || get_property("maxOverride") == "-combat" || get_property("maxOverride") == "combat") return "";
        return ", equip Li'l Businessman Kit";
    }

    string maxOvr = get_property("maxOverride");
    boolean clubEmReady = get_property("clubEmNextWeekMonster") != "" && total_turns_played() >= get_property("clubEmNextWeekMonsterTurn").to_int() + 8;
    boolean clubEmExact = total_turns_played() == get_property("clubEmNextWeekMonsterTurn").to_int() + 8;
    boolean jokesterReady = get_property("_firedJokestersGun") == "false";
    boolean avalancheReady = get_property("_mcHugeLargeAvalancheUses").to_int() < 3;
    boolean spikeReady = get_property("_spikolodonSpikeUses").to_int() < 5;
    boolean batReady = get_property("_batWingsFreeFights").to_int() < 5;
    boolean dartReady = have_effect($effect[everything looks red]) == 0;
    boolean greenReady = have_effect($effect[everything looks green]) == 0;
    boolean yellowReady = have_effect($effect[everything looks yellow]) == 0;
    boolean bcz = (my_basestat($stat[submoxie]) - 118881) > BCZcost("SweatBulletsCasts");
    boolean vote = item_amount($item[&quot;I Voted!&quot; sticker]) > 0 && total_turns_played()%11 == 1 && get_property("_voteFreeFights").to_int() < 3;
    boolean sheriff = get_property("_assertYourAuthorityCast").to_int() < 3 && item_amount($item[Sheriff pistol]) >= 1 && !clubEmReady;

    buffer maximize;
    append(maximize, maxOvr != "" ? maxOvr : "item drop");

    if (get_property("script") == "slime"){
        boolean freeSomething = have_effect($effect[Coated in Slime]) == 5;
        if (my_familiar() == $familiar[purse rat])
            freeSomething = true;
        if (clubEmReady)
            append(maximize, ", equip legendary seal-clubbing club");
        else if (jokesterReady && !freeSomething){ append(maximize, ", equip The Jokester's gun"); freeSomething = true; }
        else if (get_property("_clubEmTimeUsed").to_int() < 5 && !freeSomething){ append(maximize, ", equip legendary seal-clubbing club"); freeSomething = true; }
        
        if (get_property("shirtOverride") != "")
            append(maximize, get_property("shirtOverride"));
        else if (my_familiar() == $familiar[purse rat])
            print("skipping shirt");
        else if (yellowReady && !freeSomething)       append(maximize, ", equip jurassic parka");
        else if (!freeSomething)                 append(maximize, ", equip chamoisole");
        
        if ((my_basestat($stat[submoxie]) - 40000) > BCZcost("SweatBulletsCasts") && !freeSomething)
            append(maximize, ", equip blood cubic zirconia");
        else if (dartReady && !freeSomething)    append(maximize, ", equip everfull dart holster");
        if (avalancheReady)                      append(maximize, ", equip mchugelarge left ski");
        if (batReady && !freeSomething)          append(maximize, ", equip bat wings");
        append(maximize, famEquip());
    } else {
        // Hat
        if (get_property("hatOverride") != "")
            append(maximize, get_property("hatOverride"));
        else if (my_familiar() == $familiar[cooler yeti] || my_familiar() == $familiar[chest mimic])
            append(maximize, ", equip giant yellow hat");
        // Mainhand
        if (have_equipped($item[angelbone totem]))
            append(maximize, ", equip angelbone totem");
        else if (clubEmReady)
            append(maximize, ", equip legendary seal-clubbing club");
        else if (get_property("mainOverride") != "")
            append(maximize, get_property("mainOverride"));
        else if (jokesterReady && get_property("script") != "coat" && get_property("script") != "stick" && get_property("script") != "farto")
            append(maximize, ", equip The Jokester's gun");
        else if (my_basestat($stat[muscle]) >= 200 && get_property("script") == "6-kiss")
            append(maximize, ", equip dreadful glove");
        else
            append(maximize, ", equip june cleaver");
        // Offhand
        if (have_equipped($item[Drunkula's wineglass]))
            append(maximize, ", equip Drunkula's wineglass");
        else if (get_property("offOverride") != "")
            append(maximize, get_property("offOverride"));
        else if (get_property("shrunkenHeadZombieMonster") == "" && get_property("script") != "6-kiss" && item_amount($item[shrunken head]) > 0)
            append(maximize, ", equip shrunken head");
        else if (clubEmExact && have_effect($effect[everything looks purple]) == 0)
            append(maximize, ", equip roman candelabra");
        else if (get_property("maxOverride") == "combat" || get_property("maxOverride") == "-combat")
            append(maximize, "");
        else if (get_property("subscript") == "garbo")
            append(maximize, ", equip kol con");
        else
            append(maximize, ", equip carnivorous potted plant");
        // Back
        if (get_property("backOverride") != "")
            append(maximize, get_property("backOverride"));
        else if (batReady)
            append(maximize, ", equip bat wings");
        // Shirt
        if (have_equipped($item[devilbone corset]))
            append(maximize, ", equip devilbone corset");
        else if (get_property("shirtOverride") != "")
            append(maximize, get_property("shirtOverride"));
        else if (yellowReady || spikeReady)
            append(maximize, ", equip jurassic parka");
        else if (my_basestat($stat[mysticality]) >= 200 && get_property("script") == "6-kiss")
            append(maximize, ", equip dreadful sweater");
        // Pants
        if (have_equipped($item[devilbone greaves]))
            append(maximize, ", equip devilbone greaves");
        else if (get_property("pantsOverride") != "")
            append(maximize, get_property("pantsOverride"));
        else if (get_property("sweat").to_int() < 75)
            append(maximize, ", equip designer sweatpants");
        // Acc1
        if (have_equipped($item[angelbone dice]))
            append(maximize, ", equip angelbone dice");
        else if (get_property("acc1Override") != "")
            append(maximize, get_property("acc1Override"));
        else if (dartReady)
            append(maximize, ", equip everfull dart holster");
        else if (greenReady)
            append(maximize, ", equip spring shoes");
        else if (bcz)
            append(maximize, ", equip blood cubic zirconia");
        else if (vote)
            append(maximize, ", equip &quot;I Voted!&quot; sticker");
        else
            append(maximize, ", equip mafia thumb ring");
        // Acc2
        if (have_equipped($item[angelbone chopsticks]))
            append(maximize, ", equip angelbone chopsticks");
        else if (get_property("acc2Override") != "")
            append(maximize, get_property("acc2Override"));
        else if (have_equipped($item[angelbone dice]))
            append(maximize, ", equip mafia thumb ring");
        else if (avalancheReady)
            append(maximize, ", equip McHugeLarge left ski");
        else
            append(maximize, ", equip lucky gold ring");
        // Acc3
        if (have_equipped($item[devilbone rosary]))
            append(maximize, ", equip devilbone rosary");
        else if (get_property("acc3Override") != "")
            append(maximize, get_property("acc3Override"));
        else if (get_property("subscript") == "village")
            append(maximize, ", equip Mesmereyes");
        else if (get_property("_timeCopsFoughtToday").to_int() < 11)
            append(maximize, ", equip mobius ring");
        else if (get_property("script") == "6-kiss")
            append(maximize, ", equip Dreadsylvania Auditor's badge");
        else
            append(maximize, ", equip ordnance magnet");
        // Fam equip
        append(maximize, famEquip());
    }

    if (!maximize(maximize.to_string(), false))
        abort();

    // Sheriff override — only in non-slime non-angelbone-totem context
    if (get_property("script") != "slime" && sheriff && !have_equipped($item[angelbone totem]) && get_property("script") != "coat" && get_property("script") != "stick")
        cli_execute("equip sheriff pistol; equip acc2 sheriff moustache; equip acc3 sheriff badge");

    // Parka mode
    if (yellowReady)
        cli_execute("parka dilophosaur");
    else if (spikeReady && have_equipped($item[jurassic parka]))
        cli_execute("parka spikolodon");

    // Free kill flag
    set_property("freeKillReady",
        (have_equipped($item[The Jokester's gun])
        || (have_equipped($item[jurassic parka]) && yellowReady)
        || (have_equipped($item[everfull dart holster]) && dartReady)
        || (have_equipped($item[spring shoes]) && greenReady)
        || have_equipped($item[blood cubic zirconia])
        || have_equipped($item[sheriff pistol])) ? "true" : "false");

    if ($strings[village, castle] contains get_property("subscript"))
        cli_execute("retrocape vampire kill");

    if (get_property("script") == "slime"){
        if (have_effect($effect[Coated in Slime]) == 5)
            while (my_hp() < my_maxhp())
                cli_execute("recover hp");
    }
}

void main(){
    string boof = get_property("betweenBattleScript");
    set_property("betweenBattleScript","");
    try {
        if (get_property("noncombatForcerActive") == "true")
            postAdv();
        if (item_amount($item[4-d camera]) == 0)
            cli_execute("shop take 4-d camera");
        preAdv();
        cli_execute("checkpoint clear");
        mood("");
    } finally {
        set_property("betweenBattleScript",boof);
    }
}