import iotm.ash;
import postadventure.ash;

void mood(string function){
    if (get_property("script") == "6-kiss"){
        foreach ef in $effects[Troubled Waters, Pride of the Puffin, Ur-Kel's Aria of Annoyance, Drescher's Annoying Noise, ode to booze, Let's Go Shopping!]
            if (have_effect(ef) > 0)
                cli_execute("uneffect " + ef);
        if (current_mcd() > 0)
            cli_execute("mcd 0");
        int targetInit = max($monster[hot skeleton].base_initiative + 1, $monster[hot werewolf].base_initiative + 1, $monster[hot ghost].base_initiative + 1);
        if (numeric_modifier("initiative") < targetInit)
            cli_execute("gain " + targetInit + " initiative");
        if (have_effect($effect[chilled to the bone]) > 0 && have_effect($effect[Touched by a Ghost]) > 0 && my_maxhp() < 1000 && get_property("subscript") == "village")
            use($item[hot Dreadsylvanian cocoa]);
        if (get_property("_monkeyPawWishesUsed").to_int() > 0 || !bullseyeReady()){
            if (numeric_modifier("item drop") < 500)
                cli_execute("gain 500 item drop 100 maxmeatspent");
            if (get_property("subscript") == "castle" && item_amount($item[shadow brick]) == 0)
                retrieve_item($item[shadow brick]);
            if (get_property("subscript") == "forest"){
                if (have_effect($effect[null afternoon]) == 0)
                    use($item[null-day exploit]);
                if (have_effect($effect[chilled to the bone]) > 0)
                    use($item[hot dreadsylvanian cocoa]);
                if (my_maxhp() < 700)
                    cli_execute("gain 700 hp 100 maxmeatspent");
            }
        }
    } else if (get_property("script") == "slime"){
        foreach ef in $effects[Let's Go Shopping!]
            if (have_effect(ef) > 0)
                cli_execute("uneffect " + ef);
    } else if (get_property("script") == "farto"){
        foreach ef in $effects[Yes\, Can Haz, ode to booze]
            if (have_effect(ef) > 0)
                cli_execute("uneffect " + ef);
        foreach ef in $effects[Only Dogs Love a Drunken Sailor,Best Pals,Sweat equity, Flapper Dancin',Legendary Pasta Eyeball,material witness,
            Singer's Faithful Ocelot, Leash of Linguini, empathy,Thoughtful Empathy,Blood Bond,Bet Your Autumn Dollar,
            Disco Leer,Polka of Plenty,Tubes of Universal Meat,Lubricating Sauce,Strength of the Tortoise, party soundtrack]{
            if (ef == $effect[material witness] && get_property("_jukebox") == "false"){
                visit_url("showclan.php?whichclan=2046992052&action=joinclan&confirm=on");
            } else if (ef == $effect[material witness] && get_property("_jukebox") == "true"){
                continue;
            } else if (to_int(get_property("_heartstonePalsUsed")) >= (4 + dayType()) && ef == $effect[best pals]){
                continue;
            } else if (ef == $effect[The Ballad of Richie Thingfinder] && get_property("_thingfinderCasts") == 10){
                continue;
            } else if (ef == $effect[party soundtrack] && (dayType() == 0 || get_property("_cinchUsed").to_int() > 85)){
                continue;
            } else if (ef == $effect[sweat equity] && ((my_basestat($stat[submoxie]) - 118881) < BCZcost("SweatEquityCasts"))){
                continue;
            } else if (ef == $effect[Legendary Pasta Eyeball] && my_class() == $class[pastamancer]){
                continue;
            }
            if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)))
                continue;
            if (dayType() == 0 && effectDuration(ef) > (my_adventures() + pvp_attacks_left()))
                continue;
            if (dayType() == 1 && effectDuration(ef) > my_adventures() && have_equipped($item[drunkula's wineglass]))  
                continue;
            if (have_effect(ef) == 0)
                cli_execute(ef.default);
            if (have_effect(ef) == 0)
                abort(ef + " did not increase");
        }
        cli_execute("gain meat drop 3 eff");
        if (my_location().environment == "underwater")
            cli_execute("gain better diver 3 eff");
    }
    if (function == "")
        function = get_property("maxOverride");
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
    }}

boolean useChestMimic(){
    return true;
}

float boozeValue(string q1, string q2){
    string pref = "_cupBoozeValue" + q1 + q2;
    if (get_property(pref) != "") return get_property(pref).to_float();
    boolean [item] pool;
    foreach it in $items[]{
        if (item_type(it) != "booze" || !it.tradeable || !it.discardable) continue;
        string q = it.quality.to_lower_case();   // mafia reports "EPIC" in caps, the rest lowercase
        if (q == q1 || q == q2) pool[it] = true;
    }
    float avg = average_value(pool, 100000);
    set_property(pref, avg);
    return avg;
}

// Tiers follow garbo: 0-1 drops EPIC/awesome, 2-3 awesome/good, 4-5 good/decent,
// then decent/crappy. First drop of the day needs 6 charges, later ones 10.
float cupValue(){
    int drops = get_property("_cupOf13sDrops").to_int();
    int charges = drops == 0 ? 6 : 10;
    if (drops <= 1) return boozeValue("epic", "awesome") / charges;
    if (drops <= 3) return boozeValue("awesome", "good") / charges;
    if (drops <= 5) return boozeValue("good", "decent") / charges;
    return boozeValue("decent", "crappy") / charges;
}

record lgrRealm {
    string access;      // realm-access pref stem: <access>Always / _<access>Today
    string capPref;     // daily LGR drops of this currency so far
    int cap;            // LGR stops dropping it at this count
    item currency;
};

lgrRealm [string] lgrRealms = {
    "sleaze":  new lgrRealm("sleazeAirport", "_luckyGoldRingBeachBuck", 25, $item[Beach Buck]),
    "spooky":  new lgrRealm("spookyAirport", "_luckyGoldRingCoinspiracy", 25, $item[Coinspiracy]),
    "stench":  new lgrRealm("stenchAirport", "_luckyGoldRingFunFunds", 15, $item[FunFunds&trade;]),
    "cold":    new lgrRealm("coldAirport", "_luckyGoldRingWalmart", 15, $item[Wal-Mart gift certificate]),
    "hot":     new lgrRealm("hotAirport", "_luckyGoldRingVolcoino", 2, $item[Volcoino]),
    "fantasy": new lgrRealm("fr", "_luckyGoldRingRubee", 10, $item[Rubee&trade;]),
    "cyber":   new lgrRealm("cr", "_luckyGoldRingBit", 10, $item[0])   // the item named "0"
};

float currencyValue(item currency){
    if (currency.tradeable) return item_value(currency);
    string pref = "_lgrCurrencyValue" + currency.to_int();
    if (get_property(pref) != "") return get_property(pref).to_float();
    float best;
    foreach cm in $coinmasters[]{
        if (cm.item != currency) continue;
        foreach it in $items[]{
            if (!it.tradeable || !sells_item(cm, it)) continue;
            int cost = sell_price(cm, it);
            if (cost > 0) best = max(best, item_value(it) / cost);
        }
    }
    set_property(pref, best);
    return best;
}

float LGRValue(){
    float [int] drops;
    drops[count(drops)] = 100;
    put_closet(item_amount($item[sand dollar]),$item[sand dollar]);
    put_closet(item_amount($item[hobo nickel]),$item[hobo nickel]);
    foreach realm, r in lgrRealms {
        boolean open = get_property(r.access + "Always").to_boolean()
            || get_property("_" + r.access + "Today").to_boolean();
        if (!open || get_property(r.capPref).to_int() >= r.cap) continue;
        float value = currencyValue(r.currency);
        if (value > 0) drops[count(drops)] = value;
    }
    float total;
    foreach i, v in drops
        total += v;
    return total / count(drops) / 10;
}

// Mirrors garbo's Mr. Cheeng's spectacles bonus: a drop every ~4 turns, picked
// evenly from tradeable potions. Scans every item, so cached daily.
float CheengValue(){
    if (get_property("_cheengValue") != "") return get_property("_cheengValue").to_float();
    boolean [item] pool;
    foreach it in $items[]{
        if (it.tradeable && it.discardable && item_type(it) == "potion") pool[it] = true;
    }
    float value = average_value(pool, 100000) * 0.25;
    set_property("_cheengValue", value);
    return value;
}

float snowglobeValue(){
    if (get_property("_snowglobeValue") != "") return get_property("_snowglobeValue").to_float();
    boolean [item] pool;
    foreach it in $items[]{
        if (!it.tradeable || !it.discardable) continue;
        if (it.inebriety > 0 || it.fullness > 0 || item_type(it) == "potion") pool[it] = true;
    }
    float value = average_value(pool, 100000) * 0.13;
    set_property("_snowglobeValue", value);
    return value;
}

// Mirrors garbo's Portable Laughing Stock "horizon" value, which garbo uses
// outside meat-target fights: ~2% of turns drop a fruit, 10% of those a classic
// fruit and the rest a basic one. Only ~22 items, so no cache needed.
float laughingValue(){
    float basic = average_value($items[orange, grapefruit, grapes, lemon, lime, papaya,
        cranberries, strawberry, cherry, kumquat, tangerine, raspberry, kiwi, blackberry,
        banana, cactus fruit, plum, pear, peach]);
    float classic = average_value($items[classic banana, antique watermelon, quince]);
    return 0.02 * (0.1 * classic + 0.9 * basic);
}

float pointerRingValue(){
    float meat;
    int n;
    foreach i, m in get_monsters(my_location()){
        if (m.max_meat == 0) continue;
        meat += meat_drop(m);
        n++;
    }
    if (n == 0) return 0;
    meat /= n;
    return meat >= 500 ? 700 : meat >= 100 ? 500 : 300;
}

// Ordnance magnet: 25% of fights drop one of these combat items, picked evenly.
// Only ~100 saved-price lookups, so no cache needed.
boolean [item] ordnanceDrops = $items[ancient spice, Battlie Light Saver, beer bomb, big boom,
    big red button, black plastic oyster egg, bottle of alcohol, bottled swamp gas, boulder,
    brass gear, bus pass, can of Ghuol-B-Gone&trade;, can of sterno, carton of rotten eggs,
    chunk of hot iron, cigarette lighter, Cloaca grenade, cocktail napkin,
    communications windchimes, drone self-destruct chip, droopy doll eye, droppable microphone,
    Duskwalker syringe, Dyspepsi grenade, El Vibrato punchcard (216 holes),
    El Vibrato punchcard (142 holes), exploding gum, exploding hacky-sack, ferret bait,
    fetid feather, fire of unknown origin, firebomb, flaming feather, flaregun,
    flirtatious feather, floorboard cruft, frightful feather, frigid ninja stars, frozen feather,
    Gnomitronic Hyperspatial Demodulizer, grouchy restless spirit, groupie lipstick,
    half-rotten brain, handful of napalm, hemp net, illegal firecracker, imitation crab meat,
    imp air, jagged scrap metal, janitor sponge, jigsaw blade, lavender plastic oyster egg,
    leftovers of indeterminate origin, little piece of steel, live nautical mine,
    mariachi G-string, mauve plastic oyster egg, Mer-kin killscroll, Mer-kin sawdust,
    molotov cocktail cocktail, molten scrap metal, nastygeist, NG, nugget of sodium,
    onion shurikens, ovoid leather thing, PADL Phone, patchouli oil bomb, pencil stub,
    photoprotoneutron torpedo, pixel cross, plot hole, puce plastic oyster egg, red button,
    rocky raccoon, rusty bonesaw, sake bomb, sausage bomb,
    scroll of ancient forbidden unspeakable evil, shuriken salad, skate skates, slime stack,
    spangly unitard, spooky lasso, spooky music box mechanism, star throwing star,
    stick of dynamite, stink-penny, stone frisbee, superamplified boom box, tequila grenade,
    throwing candy, throwing fork, throwing spoon, underwater slingshot, water pipe bomb,
    Way More Tears&trade; pepper spray, wood screw];

float ordnanceValue(){
    return average_value(ordnanceDrops, 100000) * 0.25;
}

// Dread zones need other pants, so Pantsgiving is never weighed there.
boolean [location] hotZones = $locations[The Dark Elbow of the Woods, The Dark Heart of the Woods,
    The Dark Neck of the Woods, Pandamonium Slums, Infernal Rackets Backstage];

float pantsgivingValue(){
    int fights = get_property("_pantsgivingCount").to_int();
    if (fights >= 500 && get_property("_pantsgivingFullness").to_int() >= 3) return 0;
    int [int] thresholds = {5, 50, 500};
    int target = 5000;
    foreach i, threshold in thresholds
        if (fights < threshold){ target = threshold; break; }
    return valueOfOrgan("stomach").to_float() / (target - fights);
}

string bonusGear(){
    float voa = get_property("valueOfAdventure").to_float();
    float [item] bonus;

    // 4% of turns refund an adventure.
    bonus[$item[mafia thumb ring]] = (1 / 0.96 - 1) * voa;

    // Flap chance is 1/(2 + flaps used) for the first 5 free flaps.
    int flaps = get_property("_batWingsFreeFights").to_int();
    if (flaps < 5)
        bonus[$item[bat wings]] = voa / (2 + flaps);

    // Average best-choice value (~4,112) spread over the encounter interval.
    int [int] cleaverIntervals = {1, 6, 10, 12, 15, 20};
    int encounters = get_property("_juneCleaverEncounters").to_int();
    int interval = encounters < count(cleaverIntervals) ? cleaverIntervals[encounters] : 30;
    bonus[$item[June cleaver]] = (voa*5 + mall_price($item[savings bond]) + 2500)/9/ interval;

    bonus[$item[KoL Con 13 snowglobe]] = snowglobeValue();
    bonus[$item[Cup of 13s]] = cupValue();
    
    if (dayType() == 1){
        float goblinValue = 150 + adjusted_meat_drop($monster[sausage goblin]);
        bonus[$item[Kramco Sausage-o-Matic&trade;]] = sausage_goblin_chance() * goblinValue;
    }

    bonus[$item[Pantsgiving]] = pantsgivingValue();

    bonus[$item[mafia pointer finger ring]] = pointerRingValue();
    bonus[$item[lucky gold ring]] = LGRValue();
    bonus[$item[Mr. Cheeng's spectacles]] = CheengValue();
    bonus[$item[can of mixed everything]] = snowglobeValue() / 2;
    bonus[$item[Portable Laughing Stock]] = laughingValue();
    bonus[$item[ordnance magnet]] = ordnanceValue();

    buffer out;
    foreach it, value in bonus {
        if (available_amount(it) == 0 || value <= 0) continue;
        // Quoted as garbo does: otherwise the maximizer reads numbers in a name
        // (KoL Con 13 snowglobe, Cup of 13s) as weights.
        out.append(", " + to_string(value, "%.2f") + " \"bonus " + it + "\"");
    }
    return out.to_string();
}

void preAdv(){
    if (get_property("script") == "FreeKill" && my_fullness() == fullness_limit() && get_property("_pantsgivingFullness").to_int() < 2)
        stashgrab($item[pantsgiving]);
    // ── Familiar selection ────────────────────────────────────────────────────
        if (my_familiar() != $familiar[stooper]){
            string famOvr = get_property("famOverride");
            string maxOvr = get_property("maxOverride");
            if (famOvr != "")
                use_familiar(famOvr.to_familiar());
    //        else if (have_effect($effect[Citizen of a Zone]) == 0 && get_property("screechCombats").to_int() > 0)
       //         use_familiar($familiar[patriotic eagle]);
            else if (item_amount($item[1950 Vampire Vintner wine]) == 0 && dayType() == 0)
                use_familiar($familiar[vampire vintner]);
            else if ($familiar[chest mimic].experience < 100){
                use_familiar($familiar[chest mimic]);
                if (have_effect($effect[heart of white]) == 0)
                    use($item[white candy heart]);
            } else if (numeric_modifier("familiar weight") > 49 || dayType() == 0){
                if (have_familiar($familiar[robortender]))
                    use_familiar($familiar[robortender]);
                else
                    altFam($familiar[robortender]);
            } else if ($familiar[cooler yeti].experience < 400 && get_property("_coolerYetiAdventures") == "false" && (dayType() == 0 || inebriety_limit() - 4 > my_inebriety())){
                use_familiar($familiar[cooler yeti]);
                if (have_effect($effect[heart of white]) == 0)
                    use($item[white candy heart]);
            } else if (get_property("_knuckleboneDrops").to_int() < 100 && item_amount($item[knucklebone]) < 10000 && isFartScauce() && my_location().environment != "underwater")
                use_familiar($familiar[skeleton of crimbo past]);
            else if (get_property("_swordOfSWordsKills").to_int() < 12 || have_effect($effect[everything looks red]) == 0 || have_effect($effect[everything looks yellow]) == 0)
                use_familiar($familiar[sword of s words]);
            else if (maxOvr == "item drop" || get_property("_mapToACandyRichBlockDrops").to_int() < 1)
                use_familiar($familiar[jill-of-all-trades]);
            else if (maxOvr == "-combat")
                use_familiar($familiar[peace turkey]);
            else if (maxOvr == "+combat")
                use_familiar($familiar[Jumpsuited Hound Dog]);
            else if (have_familiar($familiar[robortender]))
                use_familiar($familiar[robortender]);
            else
                use_familiar($familiar[comma chameleon]);
        }

    // ── Familiar equip helper ─────────────────────────────────────────────────
        string famEquip(){
            if (get_property("famEquipOverride") != "") return get_property("famEquipOverride");
            if (have_effect($effect[driving waterproofly]) == 0 && my_location().environment == "underwater" && my_familiar() != $familiar[comma chameleon]) return ", equip little bitty bathysphere";
            if (my_familiar() == $familiar[skeleton of crimbo past]) return ", equip small peppermint-flavored sugar walking crook";
            if (my_familiar() == $familiar[cooler yeti] || my_familiar() == $familiar[chest mimic]) return ", equip toy cupid bow";
            if (my_familiar() == $familiar[mini kiwi]) return ", equip aviator goggles";
            if (my_familiar() == $familiar[Hobo in Sheep's Clothing]) return ", equip half-height cigar";
            if (my_familiar() == $familiar[stocking mimic]) return ", equip bag of many confections";
            if (my_familiar() == $familiar[comma chameleon] || my_familiar() == $familiar[robortender]) return "";
            if (my_familiar() == $familiar[none] || my_familiar() == $familiar[purse rat] || get_property("maxOverride") == "-combat" || get_property("maxOverride") == "combat") return "";
            return ", equip Li'l Businessman Kit";
        }
        if ((my_familiar() == $familiar[robortender] || (my_familiar() == $familiar[Comma Chameleon]) && (chameleon() == $familiar[none] || chameleon() == $familiar[robortender])) && get_property("script") == "farto"){
            if (my_familiar() == $familiar[Comma Chameleon] && chameleon() == $familiar[none]){
                retrieve_item(item_amount(familiar_equipment($familiar[robortender]))+1,familiar_equipment($familiar[robortender]));
                visit_url("inv_equip.php?which=2&action=equip&whichitem=" + familiar_equipment($familiar[robortender]).to_int());
                set_property("commaFamiliar","Robortender");
            }
            if (!contains_text(get_property("_roboDrinks"), "drive-by shooting")){
                retrieve_item($item[drive-by shooting]);
                visit_url("inventory.php?action=robooze&which=1&whichitem=9396");
            }
            if (!contains_text(get_property("_roboDrinks"), "Bloody Nora")){
                retrieve_item($item[Bloody Nora]);
                visit_url("inventory.php?action=robooze&which=1&whichitem=9388");
            }
            if (!contains_text(get_property("_roboDrinks"), "Newark")){
                retrieve_item($item[Newark]);
                visit_url("inventory.php?action=robooze&which=1&whichitem=9391");
            }
            if (!contains_text(get_property("_roboDrinks"), "single entendre")){
                retrieve_item($item[single entendre]);
                visit_url("inventory.php?action=robooze&which=1&whichitem=9384");
            }
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
    if (get_property("unconditionalOverride") != ""){
        append(maximize, get_property("unconditionalOverride"));
    } else {
        append(maximize, maxOvr != "" ? maxOvr : "item drop");
    }
    if (get_property("script") == "slime"){
        // freeSomething == "this fight already has a guaranteed free outcome, so
        // don't burn a free-kill charge on it". It starts true at exactly 5 turns
        // of coating (the chamoisole gall-bladder squeeze) and is set true once we
        // commit a free-kill weapon below.
        boolean freeSomething = have_effect($effect[Coated in Slime]) == 5;
        if (clubEmReady){
            append(maximize, ", equip legendary seal-clubbing club");
        } else if (get_property(get_clan_id() + "Tickled") == "tickled"){
            // Carry the shovel to squeeze a gall bladder (see slime.ash state machine).
            retrieve_item($item[rusty grave robbing shovel]);
            append(maximize, ", equip rusty grave robbing shovel");
        } else if (jokesterReady && !freeSomething){ append(maximize, ", equip The Jokester's gun"); freeSomething = true; }
        else if (get_property("_clubEmTimeUsed").to_int() < 5 && !freeSomething){ append(maximize, ", equip legendary seal-clubbing club"); freeSomething = true; }
        // Shirt: honour slime.ash's shirtOverride, skip entirely on the purse rat
        // (ML build), else a free-kill shirt, else the chamoisole.
        if (get_property("shirtOverride") != "")
            append(maximize, get_property("shirtOverride"));
        else if (my_familiar() == $familiar[purse rat])
            print("skipping shirt");
        else if (yellowReady && !freeSomething)  append(maximize, ", equip jurassic parka");
        else if (!freeSomething)                 append(maximize, ", equip chamoisole");

        if ((my_basestat($stat[submoxie]) - 62500) > BCZcost("SweatBulletsCasts") && !freeSomething)
            append(maximize, ", equip blood cubic zirconia");
        else if (dartReady && !freeSomething)    append(maximize, ", equip everfull dart holster");
        if (avalancheReady)                      append(maximize, ", equip mchugelarge left ski");
        if (batReady && !freeSomething)          append(maximize, ", equip bat wings");
        append(maximize, famEquip());
    } else if (get_property("script") == "FreeKill"){
        int highStat = max(my_buffedstat($stat[muscle]),my_buffedstat($stat[mysticality]),my_buffedstat($stat[moxie]));
        // Hat
        if (get_property("hatOverride") != "")
            append(maximize, get_property("hatOverride"));
        // Mainhand
        if (get_property("mainOverride") != "")
            append(maximize, get_property("mainOverride"));
        else if (get_property("weaponOverride") != "")
            append(maximize, get_property("weaponOverride"));
        // Offhand
        if (have_equipped($item[Drunkula's wineglass]))
            append(maximize, ", equip Drunkula's wineglass");
        else if (get_property("offOverride") != "")
            append(maximize, get_property("offOverride"));
        // Back
        if (get_property("backOverride") != "")
            append(maximize, get_property("backOverride"));
        else if (have_item($item[protonic accelerator pack]) && get_property("questPAGhost") == "unstarted")
            append(maximize, ", equip protonic accelerator pack");
        // Shirt
        if (have_equipped($item[devilbone corset]))
            append(maximize, ", equip devilbone corset");
        else if (get_property("shirtOverride") != "")
            append(maximize, get_property("shirtOverride"));
        // Pants
        if (have_equipped($item[devilbone greaves]))
            append(maximize, ", equip devilbone greaves");
        else if (get_property("pantsOverride") != "")
            append(maximize, get_property("pantsOverride"));
        else if (my_fullness() == fullness_limit() && get_property("_pantsgivingFullness").to_int() < 2 && get_property("_pantsgivingCount").to_int() >= 50)
            append(maximize, ", equip pantsgiving");
        // Acc1
        if (have_equipped($item[angelbone dice]))
            append(maximize, ", equip angelbone dice");
        else if (get_property("acc1Override") != "")
            append(maximize, get_property("acc1Override"));
        // Acc2
        if (have_equipped($item[angelbone chopsticks]))
            append(maximize, ", equip angelbone chopsticks");
        else if (get_property("acc2Override") != "")
            append(maximize, get_property("acc2Override"));
        // Acc3
        if (have_equipped($item[devilbone rosary]))
            append(maximize, ", equip devilbone rosary");
        else if (get_property("acc3Override") != "")
            append(maximize, get_property("acc3Override"));
        // Fam equip
        if (get_property("famEquipOverride") != "")
            append(maximize, get_property("famEquipOverride"));
    } else {
        if (get_property("unconditionalOverride") == ""){
            // Hat
            if (get_property("hatOverride") != "")
                append(maximize, get_property("hatOverride"));
            else if (my_familiar() == $familiar[cooler yeti] || my_familiar() == $familiar[chest mimic])
                append(maximize, ", equip giant yellow hat");
            // Mainhand
            if (have_equipped($item[angelbone totem]) || my_spleen_use() > 15)
                append(maximize, ", equip angelbone totem");
            else if (clubEmReady)
                append(maximize, ", equip legendary seal-clubbing club");
            else if (get_property("mainOverride") != "")
                append(maximize, get_property("mainOverride"));
            else if (get_property("weaponOverride") != "")
                append(maximize, get_property("weaponOverride"));
            else if (dayType() == 0 && my_class() == $class[seal clubber])
                append(maximize, ", equip monodent");
            else if (jokesterReady && get_property("script") != "coat" && get_property("script") != "stick" && get_property("script") != "farto")
                append(maximize, ", equip The Jokester's gun");
            else if (my_basestat($stat[muscle]) >= 200 && get_property("script") == "6-kiss")
                append(maximize, ", equip dreadful glove");
            // Offhand
            if (have_equipped($item[Drunkula's wineglass]))
                append(maximize, ", equip Drunkula's wineglass");
            else if (get_property("offOverride") != "")
                append(maximize, get_property("offOverride"));
            else if (get_property("shrunkenHeadZombieMonster") == "" && get_property("script") != "6-kiss" && item_amount($item[shrunken head]) > 0 && my_adventures() > 50)
                append(maximize, ", equip shrunken head");
            else if (clubEmExact && have_effect($effect[everything looks purple]) == 0)
                append(maximize, ", equip roman candelabra");
            else if (get_property("maxOverride") == "combat" || get_property("maxOverride") == "-combat")
                append(maximize, "");
            else if (get_property("script") != "farto")
                append(maximize, ", equip carnivorous potted plant");
            // Back
            if (get_property("backOverride") != "")
                append(maximize, get_property("backOverride"));
            // Shirt
            if (have_equipped($item[devilbone corset]))
                append(maximize, ", equip devilbone corset");
            else if (get_property("shirtOverride") != "")
                append(maximize, get_property("shirtOverride"));
            else if (yellowReady && (my_adventures() > 100 || dayType() == 1))
                append(maximize, ", equip parka (dilophosaur)");
            else if (spikeReady)
                append(maximize, ", equip parka (spikolodon)");
            else if (my_basestat($stat[mysticality]) >= 200 && get_property("script") == "6-kiss")
                append(maximize, ", equip dreadful sweater");
            // Pants
            if (have_equipped($item[devilbone greaves]))
                append(maximize, ", equip devilbone greaves");
            else if (get_property("pantsOverride") != "")
                append(maximize, get_property("pantsOverride"));
            else if (get_property("_pantsgivingCount").to_int() < 4 && available_amount($item[pantsgiving]) > 0
                    && !(hotZones contains my_location()))
                append(maximize, ", equip pantsgiving");
            else if ((get_property("sweat").to_int() < 90 && dayType() == 0) || (get_property("_sweatOutSomeBoozeUsed").to_int() < 3 && dayType() == 1)){
                append(maximize, ", equip designer sweatpants");
            }
            // Acc1
            if (have_equipped($item[angelbone dice]))
                append(maximize, ", equip angelbone dice");
            else if (get_property("acc1Override") != "")
                append(maximize, get_property("acc1Override"));
            else if (dartReady && (my_adventures() > 40 || dayType() == 1))
                append(maximize, ", equip everfull dart holster");
            else if (greenReady && (my_adventures() > 30 || dayType() == 1))
                append(maximize, ", equip spring shoes");
            else if (bcz)
                append(maximize, ", equip blood cubic zirconia");
            else if (vote)
                append(maximize, ", equip &quot;I Voted!&quot; sticker");
            // Acc2
            if (have_equipped($item[angelbone chopsticks]))
                append(maximize, ", equip angelbone chopsticks");
            else if (get_property("acc2Override") != "")
                append(maximize, get_property("acc2Override"));
            else if (have_equipped($item[angelbone dice]))
                append(maximize, ", equip mafia thumb ring");
            else if (avalancheReady)
                append(maximize, ", equip McHugeLarge left ski");
            else if (MobiusNCReady())
                append(maximize, ", equip mobius ring");
            // Acc3
            if (have_equipped($item[devilbone rosary]))
                append(maximize, ", equip devilbone rosary");
            else if (get_property("acc3Override") != "")
                append(maximize, get_property("acc3Override"));
            else if (get_property("subscript") == "village")
                append(maximize, ", equip Mesmereyes");
            else if (get_property("script") == "6-kiss")
                append(maximize, ", equip Dreadsylvania Auditor's badge");
            // Fam equip
            append(maximize, famEquip());
            // Bonuses
            if (get_property("bonusOverride") != "")
                append(maximize, get_property("bonusOverride"));
            else
                append(maximize, bonusGear());
        }
    }

    if (!maximize(maximize.to_string(), false))
        abort();
    // Sheriff override — only in non-slime non-angelbone-totem context
 //   if (get_property("script") != "slime" && sheriff && !have_equipped($item[angelbone totem]) && get_property("script") != "coat" && get_property("script") != "stick" && get_property("script") != "FreeKill" && get_property("script") != "farto")
   //     cli_execute("equip sheriff pistol; equip acc2 sheriff moustache; equip acc3 sheriff badge");

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
    if (get_property("script") == "FreeKill"){
        float mpTar = min(1, 500 / to_float(my_maxmp()));
        float hpTar = min(1, 1000 / to_float(my_maxhp()));
        string hpAutoRecovery = to_float(round(hpTar * 0.75 * 10000))/10000;
        string hpAutoRecoveryTarget = to_float(round(hpTar * 10000))/10000;
        string mpAutoRecovery = to_float(round(mpTar * 0.5 * 10000))/10000;
        string mpAutoRecoveryTarget = to_float(round(mpTar * 10000))/10000;
        set_property("hpAutoRecovery",       hpAutoRecovery);
        set_property("hpAutoRecoveryTarget", hpAutoRecoveryTarget);
        set_property("mpAutoRecovery",       mpAutoRecovery);
        set_property("mpAutoRecoveryTarget", mpAutoRecoveryTarget);
        if (equipped_item($slot[codpiece5]) != $item[Tuesday's ruby])
            codpiece("peridot of peril,blood cubic zirconia,baseball diamond,tuesday's ruby,tuesday's ruby");
        if (get_property("_seadentWaveUsed") == "false"){
            if (dayType() == 0 && contains_text(get_property("lastEncounter"),"gingerbread")){
                use_skill($skill[Sea *dent: Summon a Wave]);
            } else if (dayType() == 1 && contains_text(get_property("lastEncounter"),"shadow")){
                use_skill($skill[Sea *dent: Summon a Wave]);
                if (get_property("_seadentWaveZone") == "Shadow Rift")
                    set_property("_seadentWaveZone",my_location());
            }
        }
    if (my_familiar() == $familiar[comma chameleon] && chameleon() != $familiar[stocking mimic] && get_property("script") == "FreeKill" && get_property("subscript") != "NonSMFK" && get_property("subscript") != "stompingBoots"){
        if (item_amount($item[bag of many confections]) == 0){
            cli_execute("refresh all");
            retrieve_item(1,$item[bag of many confections]);
        }
        visit_url("inv_equip.php?pwd="+my_hash()+"&which=2&action=equip&whichitem=4329");
    }

        //monster level
        foreach ef in $effects[Ur-Kel's Aria of Annoyance,Pride of the Puffin,Bloodbathed,Misplaced Rage,Manbait,Sweetbreads Flamb&eacute;,Red Lettered,Spangled Star,Tortious,Litterbug,Not Sharing,Para-lyzed Jaw,Contemptible Emanations,Lapdog,Ashen Burps,The Cupcake of Wrath,Gelded,Mysteriously Handsome]{
            if (mall_price(effect_to_item(ef)) > mall_price($item[pocket wish]))
                continue;
            if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)))
                continue;
            if (numeric_modifier("Monster level") >= 150)
                break;
            if (have_effect(ef) == 0)
                cli_execute(ef.default);
        }

        //initiative
        if (jump_chance($monster[killer clownfish]) - numeric_modifier("Initiative Penalty") < 100){
            foreach ef in $effects[Bow-Legged Swagger,Natural 1,Patent Alacrity,Silent Hunting,Clear Ears\, Can't Lose,Poppy Performance,Hiding in Plain Sight,Digitalis\, Dig It,Ass Over Teakettle,Song of Slowness,Synthetic Buzz,Seal Clubbing Frenzy,Springy Fusilli]{
                if (mall_price(effect_to_item(ef)) > mall_price($item[pocket wish]))
                    continue;
                if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)))
                    continue;
                if (jump_chance($monster[flaming monstera]) >= 100)
                    break;
                if (have_effect(ef) == 0)
                    cli_execute(ef.default);
            }
        }

        foreach ef in $effects[Tranquilized Mind,Cunctatitis, Mathematically Precise]{
            if (have_effect(ef) > 0)
                cli_execute("uneffect " + ef);
        }
    }
    if (item_amount($item[dry noodles]) < 2)
        retrieve_item(2,$item[dry noodles]);
    if (item_amount($item[lit leaf lasso]) < 2)
        buy(2,$item[lit leaf lasso]);
    if (item_amount($item[logic grenade]) < 2)
        retrieve_item(2,$item[logic grenade]);
    if (item_amount($item[glitched malware]) < 1)
        retrieve_item(1,$item[glitched malware]);
    if (get_property("subscript") == "weakling" || get_property("subscript") == "looseFK"){
        if (closet_amount($item[shard of double-ice]) > 0)
            take_closet($item[shard of double-ice]);
        else 
            retrieve_item($item[shard of double-ice]);
    } else if (my_familiar() != $familiar[vampire vintner]){
        put_closet(item_amount($item[shard of double-ice]),$item[shard of double-ice]);
    }
    if (item_amount($item[4-D camera]) == 0)
        retrieve_item($item[4-D camera]);
    if (item_amount($item[pulled green taffy]) == 0)
        retrieve_item($item[pulled green taffy]);
    if (item_amount($item[pulled red taffy]) < 100 && mall_price($item[pulled red taffy]) < (redTaffyValue() - 100))
        buy($item[pulled red taffy], 2000, redTaffyValue() - 100);
    if (item_amount($item[stuffed yam stinkbomb]) == 0)
        retrieve_item($item[stuffed yam stinkbomb]);
    if (item_amount($item[new age healing crystal]) < 100)
        retrieve_item(110,$item[new age healing crystal]);
    if (item_amount($item[Arr\, M80]) < 60)
        retrieve_item(70,$item[Arr\, M80]);

    if (get_property("maxOverride") == "-mus,-mys,-mox"){
        set_property("maxOverride","");
    }
}

void main(){
    string boof = get_property("betweenBattleScript");
    try {
        if (get_property("noncombatForcerActive") == "true" && get_property("inSpendAdv") != "true")
            postAdv();
        preAdv();
        if (item_amount($item[dry noodles]) == 0)
            retrieve_item($item[dry noodles]);
        if (item_amount($item[4-D camera]) == 0)
            retrieve_item($item[4-D camera]);
        cli_execute("checkpoint clear");
        mood("");
    } finally {
        set_property("betweenBattleScript",boof);
    }
}
