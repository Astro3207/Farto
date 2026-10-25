import iotm.ash;
import postadventure.ash;

// ─── SHARED HELPERS ──────────────────────────────────────────────────────────

// Auto-recovery levels scaled so HP recovers toward 1000 and MP toward 500,
// whatever the current max.
void setAutoRecovery(){
    float mpTar = min(1, 500 / to_float(my_maxmp()));
    float hpTar = min(1, 1000 / to_float(my_maxhp()));
    set_property("hpAutoRecovery",       to_float(round(hpTar * 0.75 * 10000))/10000);
    set_property("hpAutoRecoveryTarget", to_float(round(hpTar * 10000))/10000);
    set_property("mpAutoRecovery",       to_float(round(mpTar * 0.5 * 10000))/10000);
    set_property("mpAutoRecoveryTarget", to_float(round(mpTar * 10000))/10000);
}

// ─── BONUS GEAR VALUES (bonusGear) ───────────────────────────────────────────

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

// Average base meat of the meat-dropping monsters at the current location.
float locationBaseMeat(){
    float meat;
    int n;
    foreach i, m in get_monsters(my_location()){
        if (m.max_meat == 0) continue;
        meat += meat_drop(m);
        n++;
    }
    return n == 0 ? 0 : meat / n;
}

float pointerRingValue(){
    float meat = locationBaseMeat();
    if (meat == 0) return 0;
    return meat >= 500 ? 700 : meat >= 100 ? 500 : 300;
}

// Pantogram pants: the pants' own meat plus whatever their familiar weight adds
// to the current familiar's meat drop, as a share of this location's base meat.
// Both are read off the pants, since the pantogram roll can change.
// One numeric modifier out of _pantogramModifier ("Meat Drop: +60, Familiar
// Weight: +10, ..."); 0 when the pants don't have it.
int pantogramModifier(string name){
    matcher m = create_matcher(name + ": \\+?(-?\\d+)", get_property("_pantogramModifier"));
    return m.find() ? m.group(1).to_int() : 0;
}

float pantogramValue(){
    int weight = familiar_weight(my_familiar()) + weight_adjustment();
    int extra = pantogramModifier("Familiar Weight");
    if (have_equipped($item[pantogram pants])) weight -= extra;
    float famMeat = numeric_modifier(my_familiar(), "meat drop", weight + extra, equipped_item($slot[familiar]))
        - numeric_modifier(my_familiar(), "meat drop", weight, equipped_item($slot[familiar]));
    return (pantogramModifier("Meat Drop") + famMeat) / 100 * locationBaseMeat();
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

float pantsgivingValue(){
    int fights = get_property("_pantsgivingCount").to_int();
    if (fights >= 500 && get_property("_pantsgivingFullness").to_int() >= 3) return 0;
    int [int] thresholds = {5, 50, 500};
    int target = 5000;
    foreach i, threshold in thresholds
        if (fights < threshold){ target = threshold; break; }
    float pantsValue = valueOfOrgan("stomach").to_float() / (target - fights);
    return round(pantsValue/10) * 10;
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
        goblinValue = round((sausage_goblin_chance() * goblinValue)/10) * 10;
        bonus[$item[Kramco Sausage-o-Matic&trade;]] = goblinValue;
    }

    bonus[$item[Pantsgiving]] = pantsgivingValue();
    bonus[$item[pantogram pants]] = pantogramValue();

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

// ─── MAXIMIZER SLOT HELPERS ──────────────────────────────────────────────────

string famEquip(){
    if (get_property("famEquipOverride") != "") return get_property("famEquipOverride");
    cli_execute("unequip familiar equipment");
    if (contains_text(get_property("maxOverride"),"sea")
        && !my_familiar().underwater
        && have_effect($effect[Wet Willied]) == 0
        && have_effect($effect[Driving Waterproofly]) == 0
        && !(boolean_modifier("Underwater Familiar")))
        return available_amount($item[das boot]) > 0 ? ", equip das boot" : ", equip little bitty bathysphere";
    if (my_familiar() == $familiar[skeleton of crimbo past]) return ", equip small peppermint-flavored sugar walking crook";
    if (my_familiar() == $familiar[cooler yeti] || my_familiar() == $familiar[chest mimic]) return ", equip toy cupid bow";
    if (my_familiar() == $familiar[mini kiwi]) return ", equip aviator goggles";
    if (my_familiar() == $familiar[Hobo in Sheep's Clothing]) return ", equip half-height cigar";
    if (my_familiar() == $familiar[stocking mimic]) return ", equip bag of many confections";
    if (my_familiar() == $familiar[comma chameleon] || my_familiar() == $familiar[robortender]) return "";
    if (my_familiar() == $familiar[none] || my_familiar() == $familiar[purse rat] || get_property("maxOverride") == "-combat" || get_property("maxOverride") == "combat") return "";
    return ", equip Li'l Businessman Kit";
}

// ", equip <bone>" while that end-of-day bone item is already on, so the
// maximizer keeps it; otherwise the slot's override (possibly "").
string boneOr(item bone, string override){
    return have_equipped(bone) ? ", equip " + bone : override;
}

// Dread zones need other pants, so Pantsgiving is never weighed there.
boolean [location] hotZones = $locations[The Dark Elbow of the Woods, The Dark Heart of the Woods,
    The Dark Neck of the Woods, Pandamonium Slums, Infernal Rackets Backstage];

// ─── PRE-ADVENTURE ───────────────────────────────────────────────────────────

// True when ef can be had: its source item costs no more than a pocket wish, and
// any skill behind it is known.
boolean buffAvailable(effect ef){
    if (mall_price(effect_to_item(ef)) > mall_price($item[pocket wish]))
        return false;
    return to_skill(ef) == $skill[none] || have_skill(to_skill(ef));
}

// Combat consumables preAdv() keeps on hand: under low, retrieve up to target.
record stockLevel {
    int low;
    int target;
};

stockLevel [item] combatStock = {
    $item[dry noodles]:             new stockLevel(2, 2),
    $item[logic grenade]:           new stockLevel(2, 2),
    $item[glitched malware]:        new stockLevel(1, 1),
    $item[4-D camera]:              new stockLevel(1, 1),
    $item[pulled green taffy]:      new stockLevel(1, 1),
    $item[pulled indigo taffy]:     new stockLevel(1, 1),
    $item[stuffed yam stinkbomb]:   new stockLevel(1, 1),
    $item[new age healing crystal]: new stockLevel(100, 110),
    $item[Arr\, M80]:               new stockLevel(60, 70)
};

void preAdv(){
    if (get_property("script") == "FreeKill")
        dropEldritchAttunement();
    if (my_mp() > 1000)
        manaburn(700);
    if (get_property("script") == "FreeKill" && my_fullness() == fullness_limit() && get_property("_pantsgivingFullness").to_int() < 2 && available_amount($item[pantsgiving]) == 0)
        stashgrab($item[pantsgiving]);
    // ── Familiar selection ────────────────────────────────────────────────────
    if (my_familiar() != $familiar[stooper]){
        string famOvr = get_property("famOverride");
        string maxOvr = get_property("maxOverride");
        if (famOvr != "")
            use_familiar(famOvr.to_familiar());
        else if (item_amount($item[1950 Vampire Vintner wine]) == 0 && dayType() == 0)
            use_familiar($familiar[vampire vintner]);
        else if ($familiar[chest mimic].experience < 100){
            use_familiar($familiar[chest mimic]);
            if (have_effect($effect[heart of white]) == 0)
                use($item[white candy heart]);
        } else if (numeric_modifier("familiar weight") > 49 || dayType() == 0){
            if (have_familiar($familiar[robortender]))
                use_familiar($familiar[robortender]);
            else if (get_property("commaFamiliar") == "" || (my_familiar() == $familiar[comma chameleon] && chameleon() == $familiar[none]))
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

    if ((my_familiar() == $familiar[robortender] || (my_familiar() == $familiar[Comma Chameleon]) && (chameleon() == $familiar[none] || chameleon() == $familiar[robortender])) && get_property("script") == "farto"){
        if (my_familiar() == $familiar[Comma Chameleon] && chameleon() == $familiar[none]){
            retrieve_item(item_amount(familiar_equipment($familiar[robortender]))+1,familiar_equipment($familiar[robortender]));
            visit_url("inv_equip.php?which=2&action=equip&whichitem=" + familiar_equipment($familiar[robortender]).to_int());
            set_property("commaFamiliar","Robortender");
        }
        // The robooze form takes the drink's own item id.
        foreach drink in $items[drive-by shooting, Bloody Nora, Newark, single entendre]{
            if (contains_text(get_property("_roboDrinks"), drink.to_string()))
                continue;
            retrieve_item(drink);
            visit_url("inventory.php?action=robooze&which=1&whichitem=" + drink.to_int());
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
        append(maximize, get_property("shirtOverride"));
        // Pants
        string pants = get_property("pantsOverride");
        if (pants != "")
            append(maximize, pants);
        else if (my_fullness() == fullness_limit() && get_property("_pantsgivingFullness").to_int() < 2 && get_property("_pantsgivingCount").to_int() >= 50)
            append(maximize, ", equip pantsgiving");
        // Accessories
        append(maximize, get_property("acc1Override"));
        append(maximize, get_property("acc2Override"));
    //    if (get_property("acc2Override") != "")
      //      append(maximize, get_property("acc2Override"));
        //else if (MobiusNCReady())
          //  append(maximize, ", equip mobius ring");
        append(maximize, get_property("acc3Override"));
        // Fam equip
        append(maximize, famEquip());
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
            else if (clubEmExact && have_effect($effect[everything looks purple]) == 0)
                append(maximize, ", equip roman candelabra");
            else if ((get_property("cursedMagnifyingGlassCount").to_int() < 13 && get_property("_voidFreeFights").to_int() < 5 && dayType() == 1) || (get_property("cursedMagnifyingGlassCount").to_int() < 4 && dayType() == 0))
                append(maximize, ", equip cursed magnifying glass");
            else if (maxOvr != "combat" && maxOvr != "-combat" && get_property("script") != "farto")
                append(maximize, ", equip carnivorous potted plant");
            // Back
            if (get_property("backOverride") != "")
                append(maximize, get_property("backOverride"));
            // Shirt
            string shirt = boneOr($item[devilbone corset], get_property("shirtOverride"));
            if (shirt != "")
                append(maximize, shirt);
            else if (yellowReady && (my_adventures() > 100 || dayType() == 1))
                append(maximize, ", equip parka (dilophosaur)");
            else if (spikeReady)
                append(maximize, ", equip parka (spikolodon)");
            else if (my_basestat($stat[mysticality]) >= 200 && get_property("script") == "6-kiss")
                append(maximize, ", equip dreadful sweater");
            // Pants
            string pants = boneOr($item[devilbone greaves], get_property("pantsOverride"));
            if (pants != "")
                append(maximize, pants);
            else if (get_property("_pantsgivingCount").to_int() < 4 && available_amount($item[pantsgiving]) > 0
                    && !(hotZones contains my_location()))
                append(maximize, ", equip pantsgiving");
            else if ((get_property("sweat").to_int() < 90 && dayType() == 0) || (get_property("_sweatOutSomeBoozeUsed").to_int() < 3 && dayType() == 1)){
                append(maximize, ", equip designer sweatpants");
            }
            // Acc1
            string acc1 = boneOr($item[angelbone dice], get_property("acc1Override"));
            if (acc1 != "")
                append(maximize, acc1);
            else if (dartReady && (my_adventures() > 40 || dayType() == 1))
                append(maximize, ", equip everfull dart holster");
            else if (greenReady && (my_adventures() > 30 || dayType() == 1))
                append(maximize, ", equip spring shoes");
            else if (bcz)
                append(maximize, ", equip blood cubic zirconia");
            else if (vote)
                append(maximize, ", equip &quot;I Voted!&quot; sticker");
            // Acc2
            string acc2 = boneOr($item[angelbone chopsticks], get_property("acc1Override"));
            if (acc2 != "")
                append(maximize, acc2);
            else if (have_equipped($item[angelbone dice]))
                append(maximize, ", equip mafia thumb ring");
            else if (avalancheReady)
                append(maximize, ", equip McHugeLarge left ski");
            else if (MobiusNCReady())
                append(maximize, ", equip mobius ring");
            // Acc3
            string acc3 = boneOr($item[devilbone rosary], get_property("acc3Override"));
            if (acc3 != "")
                append(maximize, acc3);
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

    string context = my_location() + ";" + get_property("_seadentWaveZone");
    if (get_property("savedMaximizer") == maximize.to_string() && get_property("savedMaximizerContext") == context){
        outfit("farming");
        if (get_property("savedFamEquip").to_item() != $item[none])
            equip(get_property("savedFamEquip").to_item());
    } else {
        if (!maximize(maximize.to_string(), false))
            if (!maximize(maximize.to_string(), false))
                abort();
        set_property("savedMaximizer",maximize.to_string());
        set_property("savedMaximizerContext",context);
        cli_execute("outfit save farming");
        set_property("savedFamEquip",equipped_item($slot[familiar]));
    }
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
        setAutoRecovery();
        if (equipped_item($slot[codpiece5]) != $item[Tuesday's ruby])
            codpiece("heartstone,blood cubic zirconia,baseball diamond,tuesday's ruby,tuesday's ruby");
        if (my_familiar() == $familiar[comma chameleon] && chameleon() != $familiar[stocking mimic] && get_property("subscript") != "NonSMFK" && get_property("subscript") != "stompingBoots"){
            if (item_amount($item[bag of many confections]) == 0){
                cli_execute("refresh all");
                retrieve_item(1,$item[bag of many confections]);
            }
            visit_url("inv_equip.php?pwd="+my_hash()+"&which=2&action=equip&whichitem=4329");
        }

        //monster level
        foreach ef in mlEffects{
            if (!buffAvailable(ef))
                continue;
            if (numeric_modifier("Monster level") >= 150)
                break;
            if (have_effect(ef) == 0)
                cli_execute(ef.default);
        }

        //initiative
        if (jump_chance($monster[killer clownfish]) - numeric_modifier("Initiative Penalty") < 100){
            foreach ef in $effects[Bow-Legged Swagger,Natural 1,Patent Alacrity,Silent Hunting,Clear Ears\, Can't Lose,Poppy Performance,Hiding in Plain Sight,Digitalis\, Dig It,Ass Over Teakettle,Song of Slowness,Synthetic Buzz,Seal Clubbing Frenzy,Springy Fusilli]{
                if (!buffAvailable(ef))
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
    if (get_property("script") == "bladdering"){
        retrieve_item(2,$item[ink bladder]);
    }

    if (contains_text(get_property("shrunkenHeadZombieAbilities"),"Meat Drop") && have_effect($effect[Juiced]) == 0 && my_buffedstat($stat[moxie]) < $monster[giant squid].base_attack && numeric_modifier("familiar weight") < 200){
        use($item[mer-kin cooljuice]);
    }
    // Combat consumables: when under min, retrieve up to target.
    foreach it, stock in combatStock{
        if (item_amount(it) < stock.low)
            retrieve_item(stock.target, it);
    }
    // Bought rather than retrieved so mafia doesn't burn leaves crafting them.
    if (item_amount($item[lit leaf lasso]) < 2)
        buy(2,$item[lit leaf lasso]);
    if (item_amount($item[pulled red taffy]) < 100 && mall_price($item[pulled red taffy]) < (redTaffyValue() - 100))
        buy($item[pulled red taffy], 2000, redTaffyValue() - 100);
    if (get_property("subscript") == "weakling" || get_property("subscript") == "looseFK"){
        if (closet_amount($item[shard of double-ice]) > 0)
            take_closet($item[shard of double-ice]);
        else
            retrieve_item($item[shard of double-ice]);
    } else if (my_familiar() != $familiar[vampire vintner]){
        put_closet(item_amount($item[shard of double-ice]),$item[shard of double-ice]);
    }
    // Keep LGR currencies out of inventory.
    put_closet(item_amount($item[sand dollar]),$item[sand dollar]);
    put_closet(item_amount($item[hobo nickel]),$item[hobo nickel]);

    if (contains_text(get_property("maxOverride"),"combat") && !contains_text(get_property("maxOverride"),"-combat")){
        if (have_effect($effect[Carlweather's Cantata of Confrontation]) == 0 && dayType() == 1)
            use_skill($skill[Carlweather's Cantata of Confrontation]);
        if (numeric_modifier("combat rate") < 15)
            cli_execute("equip little bitty bath");
        if (numeric_modifier("combat rate") < 15)
            abort("combat rate too low, see what you can do to buff");
    }
    if (get_property("script") == "FreeKill")
        set_property("freeMeat",my_meat());
}

// ─── MOOD ────────────────────────────────────────────────────────────────────

// Meat a buff earns over the turns it will run: its Meat Drop and Item Drop %
// times the per-1% weights setDropWeighting() wrote into maxOverride, capped
// at the adventures left today. Returns -1 when maxOverride carries no weights.
float buffValue(effect ef){
    float meatWeight = -1;
    float itemWeight = 0;
    matcher m = create_matcher("([0-9.]+) Meat Drop", get_property("maxOverride"));
    if (m.find())
        meatWeight = m.group(1).to_float();
    m = create_matcher("([0-9.]+) Item Drop", get_property("maxOverride"));
    if (m.find())
        itemWeight = m.group(1).to_float();
    if (meatWeight < 0)
        return -1;
    float perTurn = numeric_modifier(ef, "Meat Drop") * meatWeight + numeric_modifier(ef, "Item Drop") * itemWeight;
    return perTurn * min(effectDuration(ef), my_adventures());
}

// True when ef's source item is already on hand, isn't an item, or costs less
// in the mall than the buff earns. Without drop weights, keeps buying as before.
boolean buffWorthBuying(effect ef){
    item it = effect_to_item(ef);
    if (it == $item[none] || item_amount(it) > 0)
        return true;
    float value = buffValue(ef);
    int price = mall_price(it);
    if (value < 0 || price <= value)
        return true;
    print("Skipping " + ef + ": " + it + " costs " + price + ", buff worth ~" + round(value), "orange");
    return false;
}

// Farto mood buffs that aren't worth (or can't be) cast right now.
boolean skipMoodBuff(effect ef){
    switch (ef){
        case $effect[material witness]:        return get_property("_jukebox") == "true";
        case $effect[best pals]:               return to_int(get_property("_heartstonePalsUsed")) >= (4 + dayType());
        case $effect[party soundtrack]:        return dayType() == 0 || get_property("_cinchUsed").to_int() > 85;
        case $effect[sweat equity]:            return (my_basestat($stat[submoxie]) - 118881) < BCZcost("SweatEquityCasts");
        case $effect[Legendary Pasta Eyeball]: return my_class() == $class[pastamancer];
        case $effect[Incredibly Well Lit]:     return get_property("_aug7Cast").to_boolean() || get_property("_augSkillsCast").to_int() == 5;
    }
    return false;
}

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
        if (have_effect($effect[Let's Go Shopping!]) > 0)
            cli_execute("uneffect Let's Go Shopping!");
    } else if (get_property("script") == "farto"){
        foreach ef in $effects[Yes\, Can Haz, ode to booze]
            if (have_effect(ef) > 0)
                cli_execute("uneffect " + ef);
        foreach ef in $effects[Only Dogs Love a Drunken Sailor,Best Pals,Sweat equity, Flapper Dancin',Legendary Pasta Eyeball,material witness,
            Singer's Faithful Ocelot, Leash of Linguini, empathy,Thoughtful Empathy,Blood Bond,Bet Your Autumn Dollar,Incredibly Well Lit,Fat Leon's Phat Loot Lyric,
            Disco Leer,Polka of Plenty,Tubes of Universal Meat,Lubricating Sauce,Strength of the Tortoise, party soundtrack]{
            if (skipMoodBuff(ef))
                continue;
            // The jukebox lives in another clan; hop there for the first play.
            if (ef == $effect[material witness])
                visit_url("showclan.php?whichclan=2046992052&action=joinclan&confirm=on");
            if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)))
                continue;
            if (dayType() == 0 && effectDuration(ef) > (my_adventures() + pvp_attacks_left()))
                continue;
            if (dayType() == 1 && effectDuration(ef) > my_adventures() && have_equipped($item[devilbone corset]))
                continue;
            if (have_effect(ef) == 0 && !buffWorthBuying(ef))
                continue;
            if (have_effect(ef) == 0)
                cli_execute(ef.default);
            if (have_effect(ef) == 0)
                abort(ef + " did not increase");
        }
        cli_execute("gain meat drop 3 eff");
        if (my_location().environment == "underwater")
            cli_execute("gain better diver 3 eff");
        setAutoRecovery();
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
            if (numeric_modifier("item drop") < 666 && get_property("script") != "farto")
                cli_execute("gain 666 item drop 100 maxmeatspent");
            break;
        case "spooky res":
            if (numeric_modifier("spooky res") < 10)
                cli_execute("gain spooky res 100 maxmeatspent");
            break;
    }}

// ─── ENTRY ───────────────────────────────────────────────────────────────────

void main(){
    string boof = get_property("betweenBattleScript");
    try {
        if (get_property("noncombatForcerActive") == "true" && get_property("inSpendAdv") != "true")
            postAdv();
        preAdv();
        cli_execute("checkpoint clear");
        if (have_effect($effect[Runneth On Empty]) == 0)
            ptrackOnce("midFarm");
        mood("");
    } finally {
        set_property("betweenBattleScript",boof);
    }
}
