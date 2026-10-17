// StockingMimic.ash -- FKPrep + bulkFK and their helper trees, being lifted out of farto.ash.

import iotm.ash;
import preadventure.ash;

string highStat = "";
string lowStat = "";
int [string] chibiStats;

record choicePair {
    int first;
    int second;
};

// Progress tracker -- prints "SM: phase: XXX" (mirrors UnderTheSea's step()) so an
// abort partway through a run is easy to place.
void step(string msg){
    print("SM: " + msg, "blue");
}

// ─── helpers used by FKPrep (verbatim from farto.ash) ────────────────────────

void monkeyPaw(string buffType){
    if (buffType == "meat"){
        foreach ef in $effects[Braaaaaains, Frosty, Let's Go Shopping!, covetous robbery, Low on the Hog, Leisurely Amblin']{
            if (to_int(get_property("_monkeyPawWishesUsed")) == 5)
                return;
            if (have_effect(ef) == 0)
                cli_execute("monkeypaw effect " + ef);
        }
    } else if (buffType == "familiar weight"){
        foreach ef in $effects[covetous robbery, Sweet Incentive, Down With Chow,Chow Downed, squirming like a toad, heavy petting, cute vision, meat puppet, Braaaaaains, frosty,sinuses for miles]{
            if (to_int(get_property("_monkeyPawWishesUsed")) == 5)
                return;
            if (have_effect(ef) == 0){
                cli_execute("monkeypaw effect " + ef);
            }
        }
    }
}
void chibiBuddy(){
    highStat = "";
    lowStat = "";

    foreach cstat in chibiStats {
        if (highStat == "" || chibiStats[cstat] > chibiStats[highStat])
            highStat = cstat;

        if (lowStat == "" || chibiStats[cstat] < chibiStats[lowStat])
            lowStat = cstat;
    }

    choicePair [string] raiseLow = {
        "chibiAlignment":     new choicePair(4,1),
        "chibiFitness":       new choicePair(1,1),
        "chibiIntelligence":  new choicePair(2,1),
        "chibiSocialization": new choicePair(3,1)
    };

    if (chibiStats[highStat] <= 5) {
   #     set_property("chibiChoice1", raiseLow[lowStat].first);
    #    set_property("chibiChoice2", raiseLow[lowStat].second);
        return;
    }

    choicePair [string] lowerHigh = {
        "chibiAlignment":     new choicePair(3,2),
        "chibiFitness":       new choicePair(4,2),
        "chibiIntelligence":  new choicePair(1,2),
        "chibiSocialization": new choicePair(2,2)
    };

    if (chibiStats[lowStat] >= 5) {
   #     set_property("chibiChoice1", lowerHigh[highStat].first);
   #     set_property("chibiChoice2", lowerHigh[highStat].second);
        return;
    }

    // -------------------------------
    // Transfer from highest to lowest
    // -------------------------------

    choicePair [string] transfer = {
        "chibiAlignment|chibiFitness": new choicePair(2,4),
        "chibiAlignment|chibiIntelligence": new choicePair(3,5),
        "chibiAlignment|chibiSocialization": new choicePair(1,5),

        "chibiFitness|chibiAlignment": new choicePair(3,4),
        "chibiFitness|chibiIntelligence": new choicePair(4,3),
        "chibiFitness|chibiSocialization": new choicePair(2,3),

        "chibiIntelligence|chibiAlignment": new choicePair(1,4),
        "chibiIntelligence|chibiFitness": new choicePair(3,3),
        "chibiIntelligence|chibiSocialization": new choicePair(4,5),

        "chibiSocialization|chibiAlignment": new choicePair(2,5),
        "chibiSocialization|chibiFitness": new choicePair(4,4),
        "chibiSocialization|chibiIntelligence": new choicePair(1,3)
    };

    string key = highStat + "|" + lowStat;

    if (transfer contains key) {
        set_property("chibiChoice1", transfer[key].first);
        set_property("chibiChoice2", transfer[key].second);
    }
}
void chibiHandling(){
    chibiStats["chibiAlignment"] = to_int(get_property("chibiAlignment"));
    chibiStats["chibiFitness"] = to_int(get_property("chibiFitness"));
    chibiStats["chibiIntelligence"] = to_int(get_property("chibiIntelligence"));
    chibiStats["chibiSocialization"] = to_int(get_property("chibiSocialization"));
    boolean balanced = true;
    foreach cstat in chibiStats
        balanced &= chibiStats[cstat] >= 4 && chibiStats[cstat] <= 6;

    // seed highStat / lowStat so the loop condition below is valid on the first check
    highStat = "";
    lowStat = "";
    foreach cstat in chibiStats {
        if (highStat == "" || chibiStats[cstat] > chibiStats[highStat])
            highStat = cstat;
        if (lowStat == "" || chibiStats[cstat] < chibiStats[lowStat])
            lowStat = cstat;
    }

    // infinite loop protection: hard cap on iterations, plus bail if chibiBuddy() picks no
    // move or a use() leaves the stats unchanged
    int chibiTries = 0;
    string lastStats = "";
    while (!balanced && chibiStats[highStat] > 5 && chibiStats[lowStat] < 5){
        chibiStats["chibiAlignment"] = to_int(get_property("chibiAlignment"));
        chibiStats["chibiFitness"] = to_int(get_property("chibiFitness"));
        chibiStats["chibiIntelligence"] = to_int(get_property("chibiIntelligence"));
        chibiStats["chibiSocialization"] = to_int(get_property("chibiSocialization"));
        balanced = true;
        foreach cstat in chibiStats
            balanced &= chibiStats[cstat] >= 4 && chibiStats[cstat] <= 6;

        if (balanced)
            break;

        string curStats = chibiStats["chibiAlignment"] + "," + chibiStats["chibiFitness"] + ","
            + chibiStats["chibiIntelligence"] + "," + chibiStats["chibiSocialization"];
        if (curStats == lastStats){
            print("chibiHandling: stats stuck at " + curStats + ", bailing", "red");
            break;
        }
        lastStats = curStats;
        chibiTries += 1;
        if (chibiTries > 10){
            print("chibiHandling: hit 10 iterations without balancing, bailing", "red");
            break;
        }

        chibiBuddy();
        if (get_property("chibiChoice1") == "0" || get_property("chibiChoice1") == ""){
            print("chibiHandling: chibiBuddy() found no move for " + curStats + ", bailing", "red");
            break;
        }
        use($item[ChibiBuddy&trade; (on)]);
        set_property("chibiChoice1","0");
        set_property("chibiChoice2","0");
    }
}
void prepBuffs(){
    foreach ef in $effects[benetton's medley of diversity, inigo's incantation of inspiration]{
        if (have_effect(ef) > 0)
            cli_execute("uneffect " + ef);
    }

    //fam weight
    foreach ef in $effects[Robot Friends,Healthy Green Glow,Chorale of Companionship,Human-Fish Hybrid,Whole Latte Love,Shortly Stacked,Thoughtful Empathy,Leash of Linguini,blood bond,Empathy,Black Tongue,Man's Worst Enemy,Billiards Belligerence,You Can Really Taste the Dormouse,Kindly Resolve,Human-Machine Hybrid,Shrimpin' Ain't Easy,Over-Familiar With Dactyls,Loyal Tea,Warm Shoulders,One Foot Heavier,Work For Hours a Week,A Girl Named Sue,Panna Consideration,Loyal as a Rock,Candied Devil,Wildsun Boon,Only Dogs Love a Drunken Sailor,Best Pals,Heart of Green,Bestial Sympathy,Herder\, Bitter\, Fester\, Stranger,Party Soundtrack,Shortly Wired,Greased-Up Familiar,Crocodile Tear,Spiced Out,offhand remarkable,Greased-Up Familiar,Crocodile Tear,Familial Ties,Busker Do,Swimming Head]{
        if (mall_price(effect_to_item(ef)) > mall_price($item[pocket wish]) && ef.attributes != "nohookah")
            continue;
        if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)))
            continue;
        if (have_effect(ef) == 0)
            cli_execute(ef.default);
    }
    if (have_effect($effect[Happy Salamander]) == 0){
        visit_url("showclan.php?whichclan=2047010939&action=joinclan&confirm=on");
        visit_url("clan_rumpus.php?action=click&spot=4&furni=1");
        visit_url("showclan.php?whichclan=" + get_property("homeClanID").to_int() + "&action=joinclan&confirm=on");
    }
    while (have_effect($effect[blue swayed]) < 50)
        use($item[pulled blue taffy]);
    while (have_effect($effect[Cold Hearted]) < 20)
        use($item[love song of icy revenge]);
    while (have_effect($effect[She Ate Too Much Candy]) < 25){
        use($item[Prunets]);
    }
    //meat drop
    foreach ef in $effects[Incredibly Well Lit,Loded,Meet the Meat,Tubes of Universal Meat,Holiday Bliss,So You Can Work More...,Legendary Pasta Eyeball,Polka of Plenty]{
        if (mall_price(effect_to_item(ef)) > mall_price($item[pocket wish]))
            continue;
        if (ef == $effect[Incredibly Well Lit] && dayType() == 0)
            continue;
        if (ef == $effect[Meet the Meat] && get_property("_clanFortuneBuffUsed") == "true")
            continue;
        if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)))
            continue;
        if (have_effect(ef) == 0)
            cli_execute(ef.default);
    }
    cli_execute("gain meat drop 7 eff 12 turns");
    //item drop
    foreach ef in $effects[Steely-Eyed Squint,Spookyravin',Unbarking Dogs,One Very Clear Eye,Materiel Intel,Spitting Rhymes,Joyful Resolve,Lubricating Sauce]{
        if (mall_price(effect_to_item(ef)) > mall_price($item[pocket wish]))
            continue;
        if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)) && ef != $effect[Steely-Eyed Squint])
            continue;
        if (have_effect(ef) == 0)
            cli_execute(ef.default);
    }
    //crit rate
    foreach ef in $effects[Berry Critical,Mark of Candy Cain,Invisible (20 Minutes Ago),Mariachi Moisture]{
        if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)))
            continue;
        if (have_effect(ef) == 0)
            cli_execute(ef.default);
    }
    foreach ef in $effects[Bow-Legged Swagger,null afternoon]{
        if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)) && to_skill(ef) != $skill[Bow-Legged Swagger])
            continue;
        if (have_effect(ef) == 0)
            cli_execute(ef.default);
    }
    use ($item[fishy pipe]);
    //mus needs to be done later, shieldbutt may be able to do it
#    foreach ef in $effects[Puissant Pressure,Incredibly Hulking,Juiced Out,Gr8ness]{
#        if (have_effect(ef) == 0)
#            cli_execute(ef.default);
#    }
}


// cap - current for a preference that's either a plain daily counter or a "true"/"false"
// one-shot flag (to_int() chokes on the latter, so those are special-cased to 0/cap).
int prefFreeKillsLeft(string pref, int cap){
    string val = get_property(pref);
    if (val == "true")
        return 0;
    if (val == "false")
        return cap;
    return max(0, cap - to_int(val));
}

// Daily cap for every free kill source that's a simple "preference counts up to a cap"
// deal (looseFK()/weakMonsters() sources included). Keyed by the preference itself.
int [string] freeKillCap = {
    "_backUpUses": 11,
    "_cyberFreeFights": 10,
    "_sealsSummoned": 10,
    "_bczSweatBulletsCasts": 13,
    "_gingerbreadMobHitUsed": 1,
    "_shatteringPunchUsed": 3,
    "_firedJokestersGun": 1,
    "_assertYourAuthorityCast": 3,
    "_clubEmTimeUsed": 5,
    "_interestingCoinHeads": 1,
    "_aprilBandTomUses": 3,
    "_glitchMonsterFights": 1,
    "_shadowBricksUsed": 13,
    "_gingerbreadCityTurns": 30,
    "_leafMonstersFought": 5,
    "_tiedUpFlamingLeafletFought": 1,
    "_brickoFights": 10,
    "_speakeasyFreeFights": 3,
    "_cargoPocketEmptied": 1,
    "_lynyrdSnareUses": 3,
    "_archSpadeDigs": 11,
    "_photocopyUsed": 1,
    "_molehillMountainUsed": 1
};
// Possession/class gate for the entries above that need one -- anything missing here is
// treated as always available (matches how weakMonstersLeft() doesn't gate those either).
boolean [string] freeKillGate = {
    "_backUpUses": have_item($item[backup camera]),
    "_cyberFreeFights": have_item($item[server room key]),
    "_sealsSummoned": my_class() == $class[seal clubber],
    "_bczSweatBulletsCasts": have_skill($skill[BCZ: Sweat Bullets]),
    "_gingerbreadMobHitUsed": have_skill($skill[Gingerbread Mob Hit]),
    "_shatteringPunchUsed": have_skill($skill[Shattering Punch]),
    "_firedJokestersGun": have_item($item[The Jokester's gun]),
    "_assertYourAuthorityCast": have_skill($skill[Assert Your Authority]),
    "_clubEmTimeUsed": have_item($item[legendary seal-clubbing club]),
    "_interestingCoinHeads": have_item($item[interesting coin]),
    "_aprilBandTomUses": have_item($item[Apriling band quad tom]),
    "_glitchMonsterFights": have_item($item[\[glitch season reward name\]])
};

// Preliminary estimate of remaining free kills for the given leg ("leg1", "leg2", or "both"),
// read straight off the daily-cap preferences bulkFK/FKPrep already track. Cobb's Knob Treasury
// adventures (embezzler/bander runaways), Black Crayon Flower (chained relativity/Pocket
// Professor), and The Deep Machine Tunnels (machine elf) are real fights, not free kills, so
// they're deliberately left out of the tally.
int freeKillCount(string leg){
    int n;
    switch (leg) {
        case "both":
            if (dayType() == 1)
                break;
            foreach pref, cap in freeKillCap {
                if (freeKillGate contains pref && !freeKillGate[pref])
                    continue;
                n += cap;
            }
            if (have_skill($skill[just the facts]))
                n += 15; // habitat recall + be gregarious, full-day guess
            if (have_item($item[combat lover's locket]))
                n += 3;
            n += have_effect($effect[shadow affinity]) + 15;
            n += 27; // gregarious
            if (have_item($item[Everfull Dart Holster]))
                n += 1;
            if (have_item($item[jurassic parka]))
                n += 1;
            n += 5;  // trick-or-treat kid
            if (can_adventure($location[A Mob of Zeppelin Protesters]))
                n += 5; // red zeppelin (glark cable)
            n += 2;  // tied-up flaming monstera / leaviathan (mall-price gated)
            n += 2;  // august cat day skills
            n += 1;  // paranormal ghost (rough -- can recur through the day)
            n += 1;  // eldritch tentacles
            if (have_item($item[envyfish egg]))
                n += 1;
            if (have_item($item[shaking 4-D camera]))
                n += 1;
            n += item_amount($item[mimic egg]); // dayType() == 1 only
        case "currentLeg":
            foreach pref, cap in freeKillCap {
                if (freeKillGate contains pref && !freeKillGate[pref])
                    continue;
                n += prefFreeKillsLeft(pref, cap);
            }
            if (have_skill($skill[just the facts]))
                n += ((3 - to_int(get_property("_monsterHabitatsRecalled"))) * 5) + to_int(get_property("_monsterHabitatsFightsLeft"));
            n += to_int(get_property("beGregariousFightsLeft"));
            if (have_item($item[combat lover's locket]))
                n += max(0, 3 - get_property("_locketMonstersFought").split_string(",").count());
            if (dayType() == 1)
                n += have_effect($effect[shadow affinity]);
            if (have_item($item[Everfull Dart Holster]) && have_effect($effect[everything looks red]) == 0)
                n += 1;
            if (have_item($item[jurassic parka]) && have_effect($effect[everything looks yellow]) == 0)
                n += 1;
            if (contains_text(get_property("_trickOrTreatBlock"), "D"))
                n += 1;
            if (can_adventure($location[A Mob of Zeppelin Protesters]))
                n += max(0, 5 - to_int(get_property("_glarkCableUses")));
            if (get_property("_tiedUpFlamingMonsteraFought") == "false" && mall_price($item[tied-up flaming monstera]) < 15000)
                n += 1;
            if (get_property("_tiedUpLeaviathanFought") == "false" && mall_price($item[tied-up leaviathan]) < 15000)
                n += 1;
            if (get_property("_aug8Cast") == "false")
                n += max(0, 4 - to_int(get_property("_augSkillsCast")));
            if (get_property("questPAGhost") == "started"
                || (get_property("questPAGhost") == "unstarted"
                    && total_turns_played() >= to_int(get_property("nextParanormalActivity"))
                    && item_amount($item[almost-dead walkie-talkie]) > 0))
                n += 1;
            if (get_property("_eldritchTentacleFought") == "false" && to_int(get_property("eldritchTentaclesFought")) < 11)
                n += 1;
            if (item_amount($item[envyfish egg]) > 0)
                n += 1;
            if (item_amount($item[shaking 4-D camera]) > 0)
                n += 1;
            if (dayType() == 1)
                n += item_amount($item[mimic egg]);
    }
    return n;
}

// ─── FREE-KILL PREP ──────────────────────────────────────────────────────────

void doSpleen(){
    foreach spl in $items[medicinal gruel, psilocyber mushroom, gleaming oyster egg,
        Party-in-a-Can&trade;, body spradium, Crimbeau de toilette]{
        if (have_effect(itemEffectNotes(spl).ef) > 0)
            continue;
        if (spl == $item[body spradium] && item_amount($item[body spradium]) == 0)
            continue;
        //700 is the estimated fam weight
        if (((numeric_modifier(itemEffectNotes(spl).ef,"Familiar Weight") * 27 * freeKillCount("both"))-mall_price(spl)) < ((700*27*4/2) - mall_price($item[Extrovermectin&trade;])/2))
            continue;
        chew(spl);
    }
}

item cheapestPasta(){
    int [item] pasta_prices;
    foreach it in $items[Frutti di Scatoletta,Pesto alla Marziano,Arrattabbattabiata,Orzo di Riso,Pasta Grimavera,Linguini Ubriacapa,Gnocci Domani,Formica e Pepe,Tubetto Gelatto]{
        pasta_prices[it] = mall_price(it);
    }
    item cheap_pasta;
    int lowest_value = 999999999;
    foreach it, value in pasta_prices {
        if (value < lowest_value) {
            lowest_value = value;
            cheap_pasta = it;
        }
    }
    return cheap_pasta;
}

int valueOfFamPot(item it) {
    int n;
    if (it == $item[Black and White Apron Meal Kit]){
        n = (10*27*freeKillCount("currentLeg") + (12 * get_property("valueOfAdventure").to_int()))/3 - mall_price(it);
    } else {
        n = (numeric_modifier(itemEffectNotes(it).ef,"familiar weight")*27*freeKillCount("currentLeg") + (averageAdventures(it) * get_property("valueOfAdventure").to_int()))/organSpace(it) - mall_price(it);
    }
    return n;
}

// Effect extenders on day 1 of ascensions, some nohookah food on day 2
void dieting(){
	if (dayType() == 0){
		// Strip every effect that might get in the way of effect extenders
        if (have_item($item[Bowl of Infinite Jelly]))
            put_closet($item[Bowl of Infinite Jelly]);
        if (have_effect($effect[Marked by the Don]) > 0 && have_skill($skill[disco nap]))
            use_skill($skill[disco nap]);
		foreach ef in my_effects(){
			if ($effects[Shadow Affinity, On the Trail, Lucky!, Apriling Band Battle Cadence,
				Everything Looks Red, Everything Looks Yellow, Everything Looks Green,
				Apriling Band Patrol Beat] contains ef)
				continue;
			cli_execute("uneffect " + ef);
		}
		if (have_effect($effect[Shadow Affinity]) == 0)
			if (!user_confirm("dieting: Shadow Affinity fell off before the rollover-day binge. Continue?"))
                abort();
        if (have_item($item[law of averages]))
            use($item[law of averages]);
        if (have_item($item[Mayo Minder&trade;]) && get_property("mayoMinderSetting") != "Mayodiol")
            use($item[Mayo Minder&trade;]);
        if (closet_amount($item[Bowl of Infinite Jelly]) > 0 && my_fullness() == fullness_limit()-1)
            take_closet($item[Bowl of Infinite Jelly]);
        while (my_fullness() < fullness_limit()){
            if (get_property("legendaryNoodlesStomach") == 0 && fullness_limit()-my_fullness() > 1){
                eat (cheapestPasta());
            } else {
                eat ($item[thyme jelly donut]);
            }
            if (have_effect($effect[jelly-coated insides]) > 0)
                abort("uneffect jelly-coated insides");
            if (get_property("spiceMelangeUsed") == "false" && my_fullness() > 3 && my_inebriety() > 3)
                use ($item[spice melange]);
            if (have_skill($skill[Sweat Out Some Booze]) && get_property("sweat").to_int() >= 25)
                use_skill($skill[Sweat Out Some Booze]);
        }
        if (get_property("_mimeArmyShotglassUsed") == "false")
            drink($item[Temps Tempranillo]);
        drink(inebriety_limit() - my_inebriety(), $item[Temps Tempranillo]);
        if (my_fullness() == fullness_limit() && get_property("_pantsgivingFullness").to_int() < 1){
            if (item_amount($item[pantsgiving]) == 0)
                stashgrab($item[pantsgiving]);
            if (item_amount($item[pantsgiving]) > 0){
                equip($item[pantsgiving]);
                use_familiar($familiar[patriotic eagle]);
                retrieve_item($item[dish of clarified butter]);
                visit_url("inv_use.php?which=3&whichitem=9908");
                run_combat();
                run_choice(-1);
                if (my_fullness() < fullness_limit())
                    eat(1,$item[thyme jelly donut]);
            }
        }
        if (get_property("spiceMelangeUsed") == "false")
            use ($item[spice melange]);
		eat(fullness_limit() - my_fullness(), $item[thyme jelly donut]);
		drink(inebriety_limit() - my_inebriety(), $item[Temps Tempranillo]);

	} else {
		foreach fo in $effects[In the Depths, Sugar-Frosted Pet Guts, ratabunga\, dude!, Beefy Heart]{
			if (my_fullness() >= fullness_limit())
				break;
			if (have_effect(fo) > 0)
				continue;
			if (effect_to_item(fo) == $item[Black and White Apron Meal Kit]){
                if (valueOfFamPot($item[Black and White Apron Meal Kit]) < valueOfOrgan("liver"))
                    continue;
                if (my_class() == $class[accordion thief])
                    continue;
                retrieve_item($item[Black and White Apron Meal Kit]);
                if (my_class() == $class[seal clubber]){
                    retrieve_item($item[cranberries]);
                    visit_url("inv_use.php?which=3&whichitem=11472");
                    visit_url("choice.php?whichchoice=1518&option=1&meal=0&ingredients0%5B%5D=672");
                } else if (my_class() == $class[pastamancer]){
                    retrieve_item($item[philosopher's scone]);
                    visit_url("inv_use.php?which=3&whichitem=11472");
                    visit_url("choice.php?whichchoice=1518&option=1&meal=1&ingredients1%5B%5D=4956");
                }else
                    abort();
			} else if (valueOfFamPot(effect_to_item(fo)) > valueOfOrgan("stomach")){
				eat(effect_to_item(fo));
			}
		}
	}
}

// Spend the day's three Mayam Calendar resonance rings. Guarded on _mayamSymbolsUsed being empty, so a second call is a no-op.
void useMayamRings(){
	if (get_property("_mayamSymbolsUsed") != "" || !have_item($item[Mayam Calendar]))
		return;
	use_familiar($familiar[chest mimic]);
	cli_execute("mayam rings vessel yam cheese explosion;"
		+ " mayam rings fur lightning eyepatch yam;"
		+ " mayam rings eye meat yam clock");
}

float optimalCandy(){
    float perCandyPrice = 100.0;
    float perPound = 27.0 * freeKillCount("both");
    int pounds = floor(perPound / (2.0 * perCandyPrice)) - 5;
    return pounds * pounds;
}

item candyPick(){
    foreach it in $items[]{
        if (it == $item[bag of many confections])
            continue;
        if (it.candy == true && mall_price(it) < 200 && item_amount(it) > 0){
            return it;
        }
    }
    foreach it in $items[]{
        if (it.candy == true && mall_price(it) <= 100){
            buy(it,(optimalCandy() - get_property("mimicCandiesFed").to_int()),100);
            return it;
        }
    }
    abort("Lmao you ran out of cheap candy");
    return $item[none];
}

void feedCandy(){
    while (get_property("mimicCandiesFed").to_int() < optimalCandy() || get_property("lastStockingMimicReset").to_int() != my_ascensions( )){
        int numFed = min(item_amount(candyPick()),max((optimalCandy() - get_property("mimicCandiesFed").to_int()),1));
        if (contains_text(visit_url("familiarbinger.php?action=binge&pwd=" + my_hash() + "&qty="+numFed+"&whichitem=" + candyPick().to_int()).to_string(),"quickly consumes")){
            if (get_property("lastStockingMimicReset").to_int() != my_ascensions( )){
                set_property("lastStockingMimicReset",my_ascensions( ));
                set_property("mimicCandiesFed",numFed);
            } else {
                set_property("mimicCandiesFed",get_property("mimicCandiesFed").to_int() + numFed);
            }
        } else {
            cli_execute("refresh all");
        }
    }
}

void FKPrep(){
	step("phase: FKPrep start");
	starter();
	// Combat runs off the player's saved combat macro (id in the combatMacroID
	// pref) as the native KoL auto-attack -- round 0 only works when the macro is
	// set natively, not embedded in a mafia CCS. starter() just cleared the
	// auto-attack, so re-arm it here.
    if (dayType() == 0 && have_effect($effect[shadow affinity]) == 0){
        int peevp = pvp_attacks_left();
        if (peevp > 0 && count(current_pvp_stances( )) > 0) {
            cli_execute("PVP_MAB; unequip pants");
        }
    }
    if (get_auto_attack() == 0)
        aa("facsimile");
	if (get_property("_shadowAffinityToday") == "false")
		use($item[closed-circuit pay phone]);
    if (item_amount($item[black garden rose]) > 0)
        use($item[black garden rose]);
	step("phase: FKPrep dieting");
	if (my_inebriety() < inebriety_limit()){
		dieting();
	}
    if (isFartScauce()){
        retrieve_item(25, $item[bag of many confections]);
        retrieve_item(25, $item[stomp box]);
    }
	set_property("script", "FreeKill");
    retrieve_item($item[burning paper crane]);
    step("phase: 9 special buffs");
    foreach ef in $effects[Robot Friends,Healthy Green Glow,Shortly Stacked,Shortly Wired,steely-eyed squint,Human-Fish Hybrid,Black Tongue,Human-Machine Hybrid,Warm Shoulders]{
        if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)))
            continue;
        if (buffCount() == 5 && !get_property("_bagOTricksUsed").to_boolean()
            && available_amount($item[Bag o' Tricks]) > 0)
            use(1, $item[Bag o' Tricks]);
        if (buffCount() >= 10)
            break;
        if (have_effect(ef) == 0)
            cli_execute(ef.default);
    }
    if (can_adventure($location[The SMOOCH Army HQ])){
        cli_execute("maximize disco style");
        visit_url("place.php?whichplace=airport_hot&action=airport4_zone1");
        run_choice(-1);
    }
    step("phase: FKPrep buffs");
	useMayamRings();
    step("phase: FKPrep hidden temple");
    whitelist("Bonus Adventures from Hell");
	if (my_ascensions() != get_property("lastTempleAdventures").to_int()
		&& get_property("questM16Temple") == "finished"){
        set_property("betweenBattleScript","");
		use($item[stone wool]);
		set_property("choiceAdventure582", "1");
		set_property("choiceAdventure579", "3");
		adv1($location[The Hidden Temple]);
        set_property("betweenBattleScript","preadventure.ash");
		useMayamRings();
	}
    doSpleen();
    if (my_spleen_use() == 4 || my_spleen_use() == 6)
        cli_execute("synthesize greed");
    if (get_property("beGregariousCharges").to_int() == 0)
        chew (1,$item[Extrovermectin&trade;]);
    if (item_amount($item[Bastille Battalion control rig]) > 0)
        cli_execute("bastille muscle gesture");
    if ($ints[7452,7454,7455,7456,7458,7462,7463,7464,7465,7466,7468,7471,7472,7474,7475,7476,7477,7478,7479,7480,7481,7482] contains augToday().to_int())
        castAugToday();
    if (have_effect($effect[Hammertime]) == 0)
        use($item[too legit potion]);
    effect[int] beretBuffs;
    if (dayType() == 0){
        beretBuffs[0] = $effect[joy];
        beretBuffs[1] = $effect[Whole Latte Love];
        beretBuffs[2] = $effect[Bureaucratized];
        beretBuffs[3] = $effect[Christmessy];
        beretBuffs[4] = $effect[\[1701\]Hip to the Jive];
    } else if (dayType() == 1){
        beretBuffs[0] = $effect[Optimist Primal];
        beretBuffs[1] = $effect[Beastly Flavor];
        beretBuffs[2] = $effect[Toothy Grin];
        beretBuffs[3] = $effect[Phairly Pheromonal];
        beretBuffs[4] = $effect[Souper Vengeful];
    }
    while (get_property("_beretBuskingUses").to_int() < 5){
        if (beretBuffs[get_property("_beretBuskingUses").to_int()] == $effect[\[1701\]Hip to the Jive])
            beretBusking("meat drop","Candied Teeth,Cool Catlike,Takin' It Greasy,Pharmaceutically Cool,Earthen Fist,Delayed Gratification,Work For Hours a Week,Stinking Cloud,Uncaged Power,Infernal Thirst");
        else
            beretBusking("15 familiar weight,meat drop",beretBuffs[get_property("_beretBuskingUses").to_int()].to_string());
    }
	prepBuffs();
	monkeypaw("familiar weight");

	step("phase: FKPrep ChibiBuddy");
	// ChibiBuddy: wake it, chat once, then hand off to farto's chibiHandling.
	if (get_property("_chibiChanged") == "false"){
		if (item_amount($item[ChibiBuddy&trade; (off)]) > 0)
			use($item[ChibiBuddy&trade; (off)]);
		cli_execute("chibi chat");
		chibiHandling();
	}

	step("phase: FKPrep daily items");
	if (get_property("_glennGoldenDiceUsed") == "false" && have_item($item[Glenn's golden dice]))
		use($item[Glenn's golden dice]);
	while (get_property("_poolGames").to_int() < 3)
		cli_execute("pool 1");
	if (get_property("friarsBlessingReceived") == "false")
		cli_execute("friars blessing 2");
	if (get_property("_portableSteamUnitUsed") == "false")
		cli_execute("use portable steam unit");
	if (get_property("_madTeaParty") == "false")
		cli_execute("hatter filthy knitted dread sack");

	foreach ef in $effects[Flapper Dancin', Polka Face, Polka of Plenty,
		The Ballad of Richie Thingfinder, Earning Interest, Bet Your Autumn Dollar,
		Sweat Equity, Legendary Pasta Eyeball, Heart of Pink, Tingling Feeling,
		Disco Leer,Serendipity]{
		if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)))
			continue;
        if (ef == $effect[Serendipity] && get_property("_augSkillsCast").to_int() >= 3)
            continue;
		if (have_effect(ef) == 0)
			cli_execute(ef.default);
	}

	if (have_effect($effect[Do I Know You From Somewhere?]) == 0){
		if (item_amount($item[driftwood beach comb]) == 0)
			use($item[piece of driftwood]);
		cli_execute("beach head 10");
		cli_execute("combo 10");
	}
    foreach ef in $effects[familiar.enq, All Is Forgiven, loyal tea,Schroedinger's Anticipation]{
        if (have_effect(ef) > 0)
            continue;
        if (numeric_modifier(ef,"familiar weight") * 27 * freeKillCount("both") > mall_price($item[pocket wish])){
            cli_execute("genie effect " + ef);
        }
    }
    altFam($familiar[stocking mimic]);
    feedCandy();
	step("phase: FKPrep stash pops");
	// Stash-borrowed one-a-day item pops.
	foreach it in $items[defective Game Grid token, BittyCar MeatCar, Platinum Yendorian Express Card]{
		stashgrab(it);
		if (have_item(it))
			use(it);
		stashreturn(it);
	}

    if (get_property("questPAGhost") == "unstarted" && !have_item($item[protonic accelerator pack])
        && total_turns_played() >= get_property("nextParanormalActivity").to_int()){
        use($item[almost-dead walkie-talkie]);
    }
	step("phase: FKPrep codpiece");
	codpiece("none");
    retrieve_item(2, $item[tuesday's ruby]);
	codpiece("heartstone,blood cubic zirconia,baseball diamond,tuesday's ruby,tuesday's ruby");
}

// ─── bulkFK and helpers (verbatim from farto.ash, not yet refactored) ────────

// Standard free-kill farming stance used all over weakMonsters()/bulkFK()'s
// one-off monster kills: comma chameleon out, maximize for familiar weight
// with the eternity codpiece equipped (so its own familiar-weight bonus
// doesn't get maximized away). extraMax, if given, is appended to
// maxOverride as-is (e.g. ",-weapon" in seals()).

void mimicPrep(string extraMax){
    altFam($familiar[stocking mimic]);
    set_property("maxOverride","familiar weight, equip eternity codpiece" + extraMax);
    if (get_auto_attack() == 0)
        aa("facsimile");
}
void mimicPrep(){
    mimicPrep("");
}

void shorts(){
    mimicPrep();
    if (get_property("_cargoPocketEmptied") == "true")
        return;
    boolean[int] emptied;

    foreach i, s in split_string(get_property("cargoPocketsEmptied"), ",")
        emptied[to_int(s)] = true;
    set_property("offOverride",", equip cursed magnifying glass");
    foreach id in $ints[646,191,306,250,30,490,612,317,448,267,47,143,425,402,589,579,136,299,220,428,235,265,363,452,383,666,443,568] {
        if (!emptied[id]) {
            main@preadventure( );
            cli_execute("cargo pick " + id);
            break;
        }
    }
    set_property("offOverride","");
    main@postadventure( );
}
void augustCat(){
    if (get_property("_aug8Cast") == false && to_int(get_property("_augSkillsCast")) < 4) {
        main@preadventure( );
        use_skill($skill[Aug. 8th: Cat Day!]);
        main@postadventure( );
    }
}

void augustGolem(){
    if (get_property("_aug22Cast") == false && to_int(get_property("_augSkillsCast")) < 5) {
        main@preadventure( );
        use_skill($skill[Aug. 22nd: Tooth Fairy Day!]);
        main@postadventure( );
        set_property("_aug22Cast","true");
    }
}

void cyberzone() {
    while (to_int(get_property("_cyberFreeFights")) < 10) {
        location [monster] hackerZone = {
            to_monster(get_property("_cyberZone1Hacker")): $location[cyberzone 1],
            to_monster(get_property("_cyberZone2Hacker")): $location[cyberzone 2],
            to_monster(get_property("_cyberZone3Hacker")): $location[cyberzone 3]
        };
        if (!contains_text(get_property("banishedPhyla"), "construct")) {
            set_property("hpAutoRecoveryTarget","0.25");
            cli_execute("recover hp");
            foreach mon in $monsters[greyhat hacker,greenhat hacker,redhat hacker,purplehat hacker,bluehat hacker] {
                if (hackerZone contains mon && hackerZone[mon] != $location[cyberzone 1]) {
                    adv1(hackerZone[mon], 0, "");
                    break;
                }
            }
            continue;
        }
        // Adventure in whichever zone has the target hacker
        foreach mon in $monsters[greyhat hacker,greenhat hacker,redhat hacker,purplehat hacker] {
            if (hackerZone contains mon) {
                if (contains_text(get_property("banishedMonsters"), mon + ":Sea *dent") && get_property("_cyberFreeFights").to_int() < 10){
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
    }}
void shadowBoss(){
    if (get_property("rufusQuestTarget") == "shadow scythe" || get_property("rufusQuestTarget") == "shadow spire"){
        if (have_skill($skill[blood bubble])) {
            if (have_effect($effect[blood bubble]) == 0)
                use_skill($skill[blood bubble]);
            set_property("maxOverride","familiar weight, equip petrified wood wizard's pouch, equip wicker slicker");
        } else
            set_property("maxOverride","familiar weight, equip petrified wood wizard's pouch, equip Drunkula's ring of haze, equip wicker slicker");
    }else if (get_property("rufusQuestTarget") == "shadow orrery"){
        if (have_effect($effect[bendin' hell]) == 0){
            foreach ef in $effects[Belch the Rainbow&trade;,Song of Sauce]{
                if (have_effect(ef) == 0)
                    cli_execute(ef.default);
            }
        }
        set_property("maxOverride","familiar weight");
        set_property("shirtOverride",", equip ultracolor");
    }
}
void shadowRealmFK(){
    altFam($familiar[stocking mimic]);
    if (get_auto_attack() == 0)
        aa("facsimile");
    if (!contains_text(get_property("maxOverride"),"familiar"))
        set_property("maxOverride","familiar weight, equip eternity codpiece");
    if (get_property("questRufus") == "step1") {
        use($item[closed-circuit pay phone]);
        adv1($location[Shadow Rift (The Misspelled Cemetary)]);
    }
    if (get_property("_shadowAffinityToday") == false && get_property("questRufus") != "unstarted"){
        if (get_property("rufusQuestType") == "entity")
            shadowBoss();
        else if (have_effect($effect[shadow affinity]) < get_property("encountersUntilSRChoice").to_int() && get_property("rufusQuestType") == "artifact"){
            NCforce(false);
            if (get_property("noncombatForcerActive") == "false")
                cli_execute("alliedradio misc sniper");
        } else if (have_effect($effect[shadow affinity]) < get_property("encountersUntilSRChoice").to_int()){
            abort("script out non entity case");
        }
    }
    if ($monster[shadow slab].elemental_resistance > 85){
        if (have_item($item[petrified wood wizard's pouch]))
            set_property("acc3Override",",equip petrified wood wizard's pouch");
    }
    if (to_int(get_property("_batWingsSwoopUsed")) < 11 && dayType() == 0)
        set_property("backOverride",", equip bat wings");
    if (get_property("questRufus") == "unstarted")
        use($item[closed-circuit pay phone]);
    if (get_property("questRufus") == "started" && get_property("rufusQuestType") == "items"){
        retrieve_item(3,to_item(get_property("rufusQuestTarget")));
    } else if (have_effect($effect[shadow affinity]) > 0){
        if (have_effect($effect[fishy]) < 840)
            set_property("mainOverride",", equip monodent");
        else
            set_property("mainOverride","");
        adv1($location[Shadow Rift (The Misspelled Cemetary)]);
    } else {
        NCforce(false);
        if (get_property("rufusQuestType") == "entity"){
            if (to_int(get_property("_spikolodonSpikeUses")) < 5 && have_effect($effect[everything looks yellow]) == 0){
                set_property("shirtOverride",", equip jurassic parka (spikolodon)");
            } else {
                set_property("shirtOverride","");
            }
            if (to_int(get_property("_mcHugeLargeAvalancheUses")) < 3)
                set_property("offOverride",", equip mchugelarge left ski");
            else
                set_property("offOverride","");
            if (get_property("noncombatForcerActive") == "true" || get_property("encountersUntilSRChoice").to_int() == 0){
                set_auto_attack(0);
                shadowBoss();
            } else {
                if (have_effect($effect[fishy]) < 840)
                    set_property("mainOverride",", equip monodent");
                else
                    set_property("mainOverride","");
            }
        }
        adv1($location[Shadow Rift (The Misspelled Cemetary)]);
    }
    if (get_property("questRufus") == "step1") {
        use($item[closed-circuit pay phone]);
        adv1($location[Shadow Rift (The Misspelled Cemetary)]);
    }
    if (get_property("_shadowAffinityToday") == false)
        use($item[closed-circuit pay phone]);
    set_property("shirtOverride","");
    set_property("acc3Override","");
    set_property("backOverride","");}
void sandworm(){
    mimicPrep();
    if (available_amount($item[Apriling band quad tom]) == 0)
        cli_execute("breakfast.ash");
    if (get_property("_aprilBandTomUses").to_int() < 3){
        while (to_int(get_property("_aprilBandTomUses")) < 3 && available_amount($item[Apriling band quad tom]) > 0){
            main@preadventure( );
            cli_execute("aprilband play quad tom");
            run_combat();
            main@postadventure( );
        }
    }
}
void archaeologist(){
    if (to_int(get_property("_archSpadeDigs")) < 11 && can_adventure($location[A Mob of Zeppelin Protesters])){
        if (my_location() == $location[none])
            set_location($location[the red zeppelin]);
        if (my_location() != $location[the red zeppelin]){
            if (get_property("zeppelinProgress").to_int() >= 6){
                set_property("mainOverride",", equip legendary seal-clubbing club");
                set_property("backOverride",", equip retrocape (heck kill)");
            } else {
                set_property("mainOverride","");
            }
            set_property("acc1Override",",bonus mafia pointer");
            if (to_int(get_property("_glarkCableUses")) < 5) {
                retrieve_item(5,$item[glark cable]);
                adv1($location[the red zeppelin]);
            } else
                abort("Ran out of glarks to charge spade");
            set_property("acc1Override","");
        }
        main@preadventure( );
        use($item[Archaeologist's Spade]);
        main@postadventure( );
    }
}
void MobiusMaybe(){
    if (get_property("_timeCopsFoughtToday").to_int() < 10)
        set_property("acc2Override",", equip mobius ring");
}
// Time Lord Badge of Honor and Time Bandit Badge of Courage are mutually
// exclusive -- an account owns one or the other. Returns whichever this
// player has, defaulting to the Time Lord badge.
item timeBadge(){
    if (available_amount($item[Time Bandit Badge of Courage]) > 0)
        return $item[Time Bandit Badge of Courage];
    return $item[Time Lord Badge of Honor];
}
// Shrug the effect giving the most of your highest buffed stat. Returns false
// when there was nothing to shrug or the shrug failed.
boolean uneffectBuff(){
    float [stat] adjBase_Stat = {
        $stat[muscle]:30,
        $stat[mysticality]:50,
        $stat[moxie]:30
    };
    stat st = $stat[muscle];
    foreach sta in $stats[mysticality, moxie]{
        if (my_buffedstat(sta) > my_buffedstat(st))
            st = sta;
    }
    effect toRemove;
    int statBuff;
    foreach ef in my_effects( ){
        if ((numeric_modifier(ef, to_string(st) + " Percent")/100)*adjBase_Stat[st] > statBuff){
            statBuff = (numeric_modifier(ef, to_string(st) + " Percent")/100)*adjBase_Stat[st];
            toRemove = ef;
        }
    }
    foreach ef in my_effects( ){
        if (ef == $effect[wine-befouled])
            continue;
        if (numeric_modifier(ef, to_string(st)) > statBuff){
            statBuff = numeric_modifier(ef, to_string(st));
            toRemove = ef;
        }
    }
    // Nothing left to shed (stats are all from gear, or the only buff is
    // wine-befouled), or the uneffect didn't take -- tell the caller to stop.
    if (toRemove == $effect[none])
        return false;
    if (!cli_execute("uneffect " + toRemove))
        return false;
    return have_effect(toRemove) == 0;
}
boolean looseFK(){
    set_property("maxOverride","familiar weight, equip eternity codpiece");
    if (have_effect($effect[everything looks red]) == 0){
        set_property("maxOverride","familiar weight, equip everfull dart holster");
        print ("FK is bullseye");
        return true;
    }
    if ((my_basestat($stat[submoxie]) - 62500) > BCZcost("SweatBulletsCasts") && get_property("_bczSweatBulletsCasts").to_int() < 13){
        set_property("maxOverride","familiar weight, equip eternity codpiece");
        print ("FK is sweat");
        return true;
    }
    if (get_property("_bczSweatBulletsCasts").to_int() < 9){
        abort("Script has been skipping over sweat bullets for some reason");
    }
    if (get_property("_gingerbreadMobHitUsed") == "false"){
        print ("FK is gingerbread");
        return true;
    }
    if (get_property("_shatteringPunchUsed").to_int() < 3){
        print ("FK is shattering");
        return true;
    }
    if (have_effect($effect[everything looks yellow]) == 0){
        set_property("maxOverride","familiar weight, equip eternity codpiece, equip jurassic parka (dilophosaur)");
        print ("FK is jurassic acid");
        return true;
    }
    if (get_property("_firedJokestersGun") == false){
        print ("FK is jokester's gun");
        set_property("maxOverride","familiar weight, equip eternity codpiece, equip jokester's gun");
        return true;
    }
    if (get_property("_clubEmTimeUsed").to_int() < 5){
        print ("FK is club em back in time");
        set_property("maxOverride","familiar weight, equip eternity codpiece, equip legendary seal-clubbing");
        return true;
    }
    if (get_property("_shadowBricksUsed").to_int() < 13){
        print ("FK is shadow brick");
        set_property("maxOverride","familiar weight, equip eternity codpiece");
        int n = 13 - get_property("_shadowBricksUsed").to_int();
        retrieve_item(n,$item[shadow brick]);
        return true;
    }
    if (item_amount($item[interesting coin]) > 0 && get_property("_interestingCoinHeads") == "false"){
        print("fk is interesting coin");
        set_property("maxOverride","familiar weight, equip eternity codpiece");
        return true;
    }
    if (get_property("_assertYourAuthorityCast").to_int() < 3){
        print ("FK is assert");
        set_property("maxOverride","familiar weight, equip sheriff pistol, equip sheriff moustache, equip sheriff badge");
        return true;
    }
    return false;
}

void resCheck(string str){
    if (numeric_modifier(pearls[str].ele_res) < 18)
        cli_execute("gain 18 " + pearls[str].ele_res);
    if (numeric_modifier(pearls[str].ele_res) < 18)
        abort(pearls[str].ele_res + " is below 18");
}

void underwaterBaseball(){
    mimicPrep();
    resCheck("bar");
    if (get_property("_curveballFightsLeft").to_int() == 0 && looseFK()){
        set_property("subscript","looseFK");
        set_property("acc1Override",", equip mafia pointer");
        adv1($location[The Dive Bar]);
        baseballD();
    } else if (get_property("_curveballFightsLeft").to_int() > 0){
        set_property("backOverride",", equip retrocape (heck kill)");
        adv1($location[The Dive Bar]);
    }
    set_property("acc1Override","");
    set_property("backOverride","");
}

boolean pearloP1Done(){
    foreach str in $strings[anemone,trench,bar]{
        if (get_property(pearls[str].donePref) == "false")
            return false;
    }
    return true;
}

void pearloP1(){
    if (get_property("_fishyPipeUsed") == "false")
        use ($item[fishy pipe]);
    if (have_effect($effect[Wet Willied]) == 0)
        use($item[willyweed]);
    if (have_effect($effect[driving waterproofly]) == 0)
        set_property("pantsOverride",", equip really nice swim");
    banishFish();
    if (get_auto_attack() == 0)
        aa("facsimile");
    equip($slot[acc2],$item[mafia pointer finger ring ]);
    set_property("acc2Override",", bonus mafia pointer finger");
    if (numeric_modifier("Critical Hit Percent") < 100)
        abort("can't guarantee critical hit");
    if ((baseballPlayers() >= 8 && get_property("_baseballInnings").to_int() < 3) || get_property("_curveballFightsLeft").to_int() > 0) {
        underwaterBaseball();
    } else if (looseFK()){
        set_property("acc3Override",", equip " + timeBadge());
        set_property("subscript","looseFK");
        foreach str in $strings[trench,bar]{
            if (get_property(pearls[str].donePref) == "false" || str == "bar"){
                resCheck(str);
                altFam($familiar[stocking mimic]);
                adv1(pearls[str].loc);
                break;
            }
        }
    }
    set_property("pantsOverride","");
    set_property("acc2Override","");
}
void pearloP2(){
    if (get_property("_fishyPipeUsed") == "false")
        use ($item[fishy pipe]);
    if (have_effect($effect[Wet Willied]) == 0){
        use($item[willyweed]);
    }
    banishFish();
    foreach str in $strings[deepests,reef]{
        if (have_effect($effect[driving waterproofly]) == 0)
            set_property("pantsOverride", ", equip really nice swim");
        altFam($familiar[stocking mimic]);
        if (get_property(pearls[str].donePref) == "false" || str == "reef"){
            resCheck(str);
            adv1(pearls[str].loc);
            break;
        }
    }
    set_property("pantsOverride","");
}
void pearloP3(){
    if (get_property("_fishyPipeUsed") == "false")
        use ($item[fishy pipe]);
    if (have_effect($effect[Wet Willied]) == 0){
        use($item[willyweed]);
    }
    banishFish();
    foreach str in $strings[bar,anemone,trench]{
        if (get_property(pearls[str].donePref) == "false" || str == "trench" || (str == "bar" && get_property("acc3Override") != ", equip backup camera")){
            resCheck(str);
            adv1(pearls[str].loc);
            break;
        }
    }
}
void gingerbread(){
    if (my_name().to_lower_case() == "the great white hunter"){
        set_property("_gingerbreadCityTurns","30");
        return;
    }
    if (get_property("gingerbreadCityAvailable") == false){
        if (get_property("_gingerbreadCityToday") == false)
            use($item[counterfeit city]);
    }
    retrieve_item(29,$item[gingerbread cigarette]);
    if (get_property("_gingerbreadCityTurns").to_int() < 30){
        mimicPrep();
        adv1($location[Gingerbread Upscale Retail District]);
    }
    if (contains_text(LastAdvTxt(),"almost midnight") || get_property("_gingerbreadCityTurns").to_int() == 19)
        adv1($location[Gingerbread Civic Center]);
}

void habitatRecall(){
    while (to_int(get_property("_monsterHabitatsRecalled")) < 3 || to_int(get_property("_monsterHabitatsFightsLeft")) > 0 || get_property("beGregariousFightsLeft").to_int() > 0){
        banishFish();
        if (copyTarget == $monster[sausage goblin] && to_int(get_property("_monsterHabitatsFightsLeft")) == 0 && to_int(get_property("_monsterHabitatsRecalled")) < 3){
            mimicPrep();
            set_property("offOverride",", equip kramco");
            set_property("acc1Override",",bonus mafia pointer");
            if (get_property("_fishyPipeUsed") == "false")
                use ($item[fishy pipe]);
            if (have_effect($effect[Wet Willied]) == 0)
                use($item[willyweed]);
            if (have_effect($effect[driving waterproofly]) == 0)
                set_property("pantsOverride", ", equip really nice swim");
            adv1($location[The Briniest Deepests]);
            set_property("offOverride","");
            set_property("acc1Override","");
            set_property("pantsOverride", "");
        } else if (to_int(get_property("_monsterHabitatsFightsLeft")) == 0 && to_int(get_property("_monsterHabitatsRecalled")) < 3){
            mimicPrep();
            main@preadventure();
            cli_execute("reminisce " + copyTarget);
            main@postadventure();
        }
        while (to_int(get_property("_monsterHabitatsFightsLeft")) > 0 || get_property("beGregariousFightsLeft").to_int() > 0){
            mimicPrep();
            if (get_auto_attack() == 0)
                aa("facsimile");
            if (get_property("beGregariousFightsLeft").to_int() == 1 && get_property("beGregariousCharges").to_int() == gregsToSave() && to_int(get_property("_monsterHabitatsRecalled")) == 3 && dayType() == 1){
                if (mall_price($item[flask of embalming fluid]) < 1000)
                    altFam($familiar[reanimated reanimator]);
            }
            pearloP2();
        }
        set_property("offOverride","");
        set_property("acc2Override","");
    }
}
void backup(){
    if (to_int(get_property("_mimicEggsObtained")) < 11 && $familiar[chest mimic].experience > 100 && to_monster(get_property("lastCopyableMonster")) == copyTarget){
        set_property("famOverride","chest mimic");
        set_property("maxOverride","familiar weight, equip eternity codpiece");
        if (have_effect($effect[driving waterproofly]) == 0)
            set_property("pantsOverride",", equip really nice swim");
        set_property("acc3Override",", equip backup camera");
        pearloP3();
    }
    while (to_int(get_property("_backUpUses")) < 11){
        if (to_monster(get_property("lastCopyableMonster")) != copyTarget2){
            if (get_property("_photocopyUsed") == false){
                whitelist("Temporary");
            set_property("acc2Override",", equip spring shoes");
            visit_url("clan_viplounge.php?action=faxmachine&whichfloor=2");
            visit_url("clan_viplounge.php?preaction=receivefax&whichfloor=2");
            if (item_amount($item[photocopied monster]) > 0){
                mimicPrep();
                main@preadventure( );
                use($item[photocopied monster]);
                }
            } else {
                abort("trying to backup to not " + copyTarget2);
            }
            set_property("acc2Override","");
        }
        mimicPrep();
        if (get_property("beGregariousFightsLeft").to_int() > 0){
            if (have_skill($skill[Meteor Lore]) && get_property("_macrometeoriteUses").to_int() < 10){
                set_auto_attack(7290);
                set_property("acc3Override","");
            } else if (available_amount($item[Powerful Glove]) > 0 && get_property("_powerfulGloveBatteryPowerUsed").to_int() <= 90){
                set_auto_attack(7326);
                set_property("acc3Override",", equip Powerful Glove");
            }else{
                aa("facsimile");
                set_property("acc3Override",", equip backup camera");
            }
        } else {
            aa("facsimile");
            set_property("acc3Override",", equip backup camera");
            if (is_banished(copyTarget2))
                set_property("acc2Override",", equip spring shoes");
            if (have_effect($effect[everything looks purple]) == 0)
                set_property("offOverride",", equip roman candel");
        }
        pearloP3();
        set_property("offOverride","");
        set_property("acc2Override","");
    }
    set_property("acc3Override","");
}
void mimicEgg(){
    while (item_amount($item[mimic egg]) > 0 && dayType() == 1 && contains_text(get_property("mimicEggMonsters"),copyTarget.to_int().to_string())){
        mimicPrep();
        main@preadventure( );
        cli_execute("c2t_megg fight " + copyTarget);
        run_combat();
        cli_execute("postadventure");
    }
}
void faxing(){
    if (get_property("_photocopyUsed") == false){
        cli_execute("/whitelist fart sauce annex");
        visit_url("clan_viplounge.php?action=faxmachine&whichfloor=2");
        visit_url("clan_viplounge.php?preaction=receivefax&whichfloor=2");
        if (item_amount($item[photocopied monster]) > 0){
            mimicPrep();
            main@preadventure( );
            use($item[photocopied monster]);
        }
    }
}
void reminisce() {
    while ((get_property("_locketMonstersFought").split_string(",").count() < 3 && dayType() == 0) || (get_property("_locketMonstersFought").split_string(",").count() < 2 && dayType() == 1)){
        foreach mon in $monsters[Frozen Bag of Tortellini,Sausage goblin,black crayon golem, black crayon spiraling shape]{
            if (get_property("_locketMonstersFought").contains_text(mon.to_int()))
                continue;
            mimicPrep();
            main@preadventure( );
            cli_execute("reminisce " + mon);
            main@postadventure();
            if (locketAvailable() == 0)
                break;
        }
    }
}
void seals(){
    while (get_property("_sealsSummoned").to_int() < 10 && my_class() == $class[seal clubber]){
        int n = get_property("_sealsSummoned").to_int();
        retrieve_item((10-n),$item[seal-blubber candle]);
        mimicPrep(",-weapon");
        set_property("mainOverride"," ");
        cli_execute("equip gnawed-up dog bone");
        main@preadventure( );
        use($item[figurine of a wretched-looking seal]);
    }
    set_property("mainOverride","");
}

// += 1 for every active effect that deals automatic per-round damage (mafia's
// "Damage Aura" / "Sporadic Damage Aura" modifiers -- Cowrruption, Boxing Day
// Glow, Spiky Hair, Simmering, Frostbeard, and so on). fightPicker() adds this
// to the double-ice estimate so chip damage doesn't kill a weak monster before
// the free kill lands.
int passiveDamage(){
	int n = 2;
	foreach ef in my_effects(){
		if (numeric_modifier(ef, "Damage Aura") != 0
			|| numeric_modifier(ef, "Sporadic Damage Aura") != 0
            || numeric_modifier(ef, "Thorns") != 0)
			n += 1;
	}
	return n;
}

float MLDamageReduction()
	return max(0.50,(1-(numeric_modifier($modifier[monster level])*0.004)));

// -- HP-headroom math for fightPicker() ----------------------------------------
// The double-ice build chips every monster each round (coldform proc plus the
// passive-damage auras counted by passiveDamage()). If that chip damage kills a
// weakling before the free kill lands, the free kill is wasted -- so fightPicker()
// only hands back a monster whose HP clears the relevant target below, buffing
// Monster Level to pad the monster's HP when it doesn't.

int estimatedIceDamage(){
    int highStat = max(my_buffedstat($stat[muscle]),
                       my_buffedstat($stat[mysticality]),
                       my_buffedstat($stat[moxie]));
    return to_int(highStat * MLDamageReduction());
}
// lowHPTarget: chip damage across a fast (~9-round) free kill.
// highHPTarget: chip damage across a slow (~29-round) one.
int lowHPTarget()
    return (9 * passiveDamage()) + estimatedIceDamage();
int highHPTarget()
    return (23 * passiveDamage()) + estimatedIceDamage();


// m.base_hp already includes current ML, so test it directly against
// lowHPTarget() after each buff rather than tracking an ML target.
boolean buffML(monster m){
    foreach ef in $effects[Ur-Kel's Aria of Annoyance,Pride of the Puffin,Bloodbathed,Misplaced Rage,Manbait,Sweetbreads Flamb&eacute;,Red Lettered,Spangled Star,Tortious,Litterbug,Not Sharing,Para-lyzed Jaw,Contemptible Emanations,Lapdog,Ashen Burps,The Cupcake of Wrath,Gelded,Mysteriously Handsome]{
        if (m.base_hp > lowHPTarget())
            break;
        if (mall_price(effect_to_item(ef)) > mall_price($item[pocket wish]))
            continue;
        if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef)))
            continue;
        if (have_effect(ef) == 0)
            cli_execute(ef.default);
    }
    if (m.base_hp <= lowHPTarget() && mcd_max() > current_mcd())
        change_mcd(mcd_max());
    return m.base_hp > lowHPTarget();
}
boolean safeToFK(monster m){
    print(m + " HP will be " + m.base_hp);
    print("Icicle damage is " + estimatedIceDamage());
    print ("Monster HP must be above " + lowHPTarget());
    print ("Monster HP must be below " + highHPTarget());
    if (m == $monster[none]){
        set_property("offOverride","");
        return false;
    }
    if (m.base_hp > highHPTarget()){
        set_property("offOverride",", equip april shower thoughts shield");
        return false;
    }
    set_property("offOverride","");
    if (m.base_hp > lowHPTarget())
        return true;
    if (buffML(m))
        return true;
    while (m.base_hp <= lowHPTarget())
        if (!uneffectBuff())
            break;
    if (m.base_hp <= lowHPTarget())
        return false;
    else
        return true;
}

// The single protonic ghost that haunts each almost-dead walkie-talkie zone, so
// the ghost fight can be run through safeToFK() like the rest. Ordered as on the
// Protonic accelerator pack wiki page; $monster[none] for an unrecognised zone.
monster ghostFor(location loc){
    monster [location] ghost = {
        $location[The Spooky Forest]:         $monster[The Headless Horseman],
        $location[The Haunted Kitchen]:       $monster[The Icewoman],
        $location[Cobb's Knob Treasury]:      $monster[The ghost of Ebenoozer Screege],
        $location[The Haunted Conservatory]:  $monster[The ghost of Lord Montague Spookyraven],
        $location[The Old Landfill]:          to_monster("the ghost of Vanillica \"Trashblossom\" Gorton"),
        $location[The Smut Orc Logging Camp]: $monster[The ghost of Richard Cockingham],
        $location[The Haunted Gallery]:       $monster[The ghost of Waldo the Carpathian],
        $location[The Haunted Wine Cellar]:   $monster[The ghost of Jim Unfortunato],
        $location[The Overgrown Lot]:         $monster[the ghost of Oily McBindle],
        $location[The Skeleton Store]:        $monster[boneless blobghost],
        $location[Madness Bakery]:            $monster[the ghost of Monsieur Baguelle],
        $location[Inside the Palindome]:      to_monster("Emily Koops, a spooky lime"),
        $location[The Icy Peak]:              $monster[the ghost of Sam McGee]
    };
    if (ghost contains loc)
        return ghost[loc];
    return $monster[none];
}

// Make sure a walkie-talkie ghost report is live (forcing one with the item if
// the pack's own timer is up but nothing's pending yet) and return its zone.
// $location[none] if we can't get a report. Guarded on questPAGhost so the item
// is only ever burned once per report.
location walkieGhost(){
    if (get_property("questPAGhost") == "unstarted" && !have_item($item[protonic accelerator pack])){
        retrieve_item($item[almost-dead walkie-talkie]);
        use($item[almost-dead walkie-talkie]);
    }
    if (get_property("ghostLocation") != "")
        return to_location(get_property("ghostLocation"));
    return $location[none];
}

// The ordered weaklings, flaming leaflets -> tied-up leaviathan (leaviathan
// deliberately last). Returns the first still-outstanding fight, or "done".
// checkHP applies safeToFK() -- available AND chip-safe (buffML'ing when it can),
// skipping any that can't be made safe. checkHP == false is the "delay is used
// up" pass: availability only, HP be damned, just finish the free kills. The
// item-summon fights look their representative monster up by name -- fix the
// strings if a lookup misses.
string pickWeakling(boolean checkHP){
    if (!checkHP)
        set_property("offOverride","");
    if (to_int(get_property("_aprilBandTomUses")) < 3
        && available_amount($item[Apriling band quad tom]) > 0
        && (!checkHP || safeToFK($monster[giant sandworm])))
        return "sandworm";
    if (to_int(get_property("_lynyrdSnareUses")) < 3
        && (!checkHP || safeToFK(to_monster("Lynyrd"))))
        return "lynyrd";
    if ((to_int(get_property("_glarkCableUses")) < 5 || to_int(get_property("_archSpadeDigs")) < 11)
        && can_adventure($location[A Mob of Zeppelin Protesters])
        && (!checkHP || safeToFK(to_monster("red snapper"))))
        return "zeppelin";
    if (contains_text(get_property("_trickOrTreatBlock"), "D")
        && (!checkHP || safeToFK(to_monster("vandal kid"))))
        return "trickortreat";
    if (get_property("_cargoPocketEmptied") != "true"
        && (!checkHP || safeToFK($monster[1335 HaXx0r])))
        return "shorts";
    if (to_int(get_property("_speakeasyFreeFights")) < 3
        && (!checkHP || safeToFK(to_monster("traveling hobo"))))
        return "speakeasy";
    if (to_int(get_property("_brickoFights")) < 10
        && (!checkHP || safeToFK($monster[BRICKO ooze])))
        return "BRICKO";
    if (get_property("_aug8Cast") == "false"
        && get_property("_augSkillsCast").to_int() < 4
        && (!checkHP || safeToFK($monster[Skeletal cat])))
        return "augustCat";
    if ((get_property("questPAGhost") == "started" || (get_property("questPAGhost") == "unstarted"
        && total_turns_played() >= to_int(get_property("nextParanormalActivity")) && get_property("ghostLocation") != ""))
        && (!checkHP || safeToFK(ghostFor(walkieGhost()))))
        return "ghost";
    if ((to_int(get_property("_leafMonstersFought")) < 5
            || get_property("_tiedUpFlamingLeafletFought") == "false")
        && (!checkHP || safeToFK($monster[flaming leaflet])))
        return "leaflet";
    return "done";
}

// Three-tier pick:
//  1. the ordered weaklings, full criteria (available + chip-safe, buffML if needed)
//  2. nothing safe -> burn delay turns on gingerbread, then pearl P1, and hope the
//     passive-damage / ML picture shifts before we come back around
//  3. delay used up -> take the ordered weaklings again with the HP criteria off,
//     just finishing whatever free kills are still outstanding
string fightPicker(){
    string pick = pickWeakling(true);
    if (pick != "done")
        return pick;

    if (to_int(get_property("_gingerbreadCityTurns")) < 30)
        return "gingerbread";

    return pickWeakling(false);
}

// Put the standard mimic free-kill combat gear on NOW -- run the same maximize
// preadventure.ash does before a fight -- so my_buffedstat() / ML read what the
// fight will actually use. Without this, fightPicker() decides on pre-maximize
// stats and safeToFK()'s HP math is wrong the moment preadventure swaps gear.
// (This settles the surface stance only; underwater picks still shift once you
// dive, and the per-pick overrides -- shield, weapon, hat -- are applied later.)
void settleStance(){
    set_property("offOverride","");
    mimicPrep();
    main@preadventure( );
}

void weakMonsters(){
    step("phase: weakMonsters start");
    set_property("acc3Override",", equip " + timeBadge());
    set_property("subscript","weakling");
    retrieve_item($item[shard of double-ice]);
    if (have_effect($effect[coldform]) == 0)
        use($item[phial of coldness]);
    equip($slot[acc3],timeBadge());
    // fightPicker() returns one key per call, in strict priority order; run that
    // fight, then re-ask. It also sets offOverride and buffs ML as needed.
    // settleStance() before every fightPicker() so the pick is made with the real
    // combat gear on, not whatever the last dispatch left equipped.
    settleStance();
    string pick = fightPicker();
    while (pick != "done"){
        // pearloP1() leaves subscript on "looseFK" -- re-assert it each pass.
        set_property("subscript","weakling");

        if (pick == "gingerbread"){
            step("phase: weakMonsters gingerbread");
            gingerbread();
        } else if (pick == "pearloP1"){
            step("phase: weakMonsters pearl P1");
            pearloP1();
        } else if (pick == "leaflet"){
            step("phase: weakMonsters flaming leaflets");
            mimicPrep();
            main@preadventure( );
            if (get_property("_tiedUpFlamingLeafletFought") == "false"){
                use($item[tied-up flaming leaflet]);
            } else {
                visit_url("campground.php?preaction=leaves");
                visit_url("choice.php?"+my_hash()+"&whichchoice=1510&option=1&leaves=11");
                run_combat();
            }
            main@postadventure( );
        } else if (pick == "augustCat"){
            step("phase: weakMonsters August Cat Day (skeletal cat)");
            mimicPrep();
            augustCat();
        } else if (pick == "BRICKO"){
            step("phase: weakMonsters BRICKO ooze");
            mimicPrep();
            main@preadventure( );
            use($item[bricko ooze]);
            main@postadventure( );
        } else if (pick == "speakeasy"){
            step("phase: weakMonsters traveling hobo");
            mimicPrep();
            adv1($location[An Unusually Quiet Barroom Brawl]);
        } else if (pick == "shorts"){
            step("phase: weakMonsters cargo shorts (haxx0r)");
            shorts();
        } else if (pick == "lynyrd"){
            step("phase: weakMonsters lynyrd snare");
            mimicPrep();
            main@preadventure( );
            use($item[lynyrd snare]);
            main@postadventure( );
        } else if (pick == "trickortreat"){
            step("phase: weakMonsters trick-or-treat kid");
            mimicPrep();
            set_property("hatOverride",", equip beholed bedsheet");
            main@preadventure( );
            candy("fight");
            main@postadventure( );
            set_property("hatOverride","");
        } else if (pick == "zeppelin"){
            step("phase: weakMonsters red zeppelin / archaeologist");
            if (to_int(get_property("_archSpadeDigs")) < 11) {
                set_property("archSkeleton","true");
                mimicPrep();
                archaeologist();
                set_property("archSkeleton","false");
            } else if (to_int(get_property("_glarkCableUses")) < 5 && can_adventure($location[A Mob of Zeppelin Protesters])){
                if (get_property("questL11Ron") == "step4")
                    set_property("mainOverride",", equip legendary seal-clubbing club");
                else
                    set_property("mainOverride","");
                mimicPrep();
                retrieve_item(5,$item[glark cable]);
                adv1($location[the red zeppelin]);
                set_property("acc2Override","");
            }
            set_property("mainOverride","");
        } else if (pick == "sandworm"){
            step("phase: weakMonsters giant sandworm (quad tom)");
            sandworm();
            // Out of quad toms -- stop other _aprilBandTomUses < 3 guards retrying.
            if (available_amount($item[Apriling band quad tom]) == 0)
                set_property("_aprilBandTomUses","3");
        } else if (pick == "ghost"){
            step("phase: weakMonsters paranormal ghost (walkie-talkie)");
            mimicPrep();
            location ghostLoc = walkieGhost();
            if (ghostLoc != $location[none])
                adv1(ghostLoc);
        }

        settleStance();
        pick = fightPicker();
    }
    step("phase: special leaf monsters");
    cli_execute("buy 4 lit leaf lasso");
    if (get_property("_tiedUpFlamingMonsteraFought") == "false"){
        mimicPrep();
        main@preadventure( );
        use($item[tied-up flaming monstera]);
        main@postadventure( );
    }
    if (get_property("_tiedUpLeaviathanFought") == "false"){
        mimicPrep();
        main@preadventure( );
        use($item[tied-up leaviathan]);
        main@postadventure( );
    }

    set_property("acc2Override","");
    set_property("acc3Override","");
    set_property("mainOverride","");
    set_property("offOverride","");
    set_property("hatOverride","");
    set_property("subscript","");
}

void LBMWPrep(boolean lantern){
    if (lantern == true){
        set_property("backOverride",", equip retrocape (heck kill)");
    }
    if (get_auto_attack() == 0)
        aa("facsimile");
    set_property("acc3Override",", equip " + timeBadge());
    retrieve_item($item[shard of double-ice]);
    mimicPrep();
}

// -- Black Rose Garden (choice 1637) -------------------------------------------
// Every thing in the garden is a choice.php form: option 1 plus rgpoi/rgx/rgy/rgf.
// Walking around is client-side only, so posting a point's form interacts
// with it from anywhere. rgpoi indexes are renumbered after each action, so
// re-parse the current page before every interaction.

record rosePoi {
    int i;
    int x;
    int y;
    int f;
    string label;      // button text minus " at position x,y"
    boolean disabled;  // e.g. "blocked by monster at 7,15"
};

string [int] roseLoot     = {0: "wine", 1: "bowl", 2: "incense"};
string [int] roseMonsters = {0: "flamingo", 1: "golem", 2: "ghost", 3: "angel", 4: "gnome"};

boolean inRoseGarden(string page){
    return contains_text(page, "name=whichchoice value=\"1637\"");
}

rosePoi [int] rosePois(string page){
    rosePoi [int] out;
    matcher m = create_matcher("class=rgpoi data-x=\"(\\d+)\" data-y=\"(\\d+)\" data-i=\"(\\d+)\">"
        + ".*?name=\"rgf\" value=\"(-?\\d+)\"><input type=submit class=\"button( disabled)?\""
        + " value=\"(.+?) at position", page);
    while (m.find())
        out[count(out)] = new rosePoi(m.group(3).to_int(), m.group(1).to_int(),
            m.group(2).to_int(), m.group(4).to_int(), m.group(6), m.group(5) != "");
    return out;
}

// First enabled point whose label starts with verb and names one of keys.
rosePoi roseFind(rosePoi [int] pois, string verb, string [int] keys){
    foreach _, p in pois{
        if (p.disabled || !p.label.starts_with(verb)) continue;
        foreach k, key in keys
            if (contains_text(p.label.to_lower_case(), key))
                return p;
    }
    return new rosePoi(-1);
}

string roseInteract(rosePoi p){
    print("Rose garden: " + p.label + " at " + p.x + "," + p.y, "blue");
    return run_choice(1, "rgpoi=" + p.i + "&rgx=" + p.x + "&rgy=" + p.y + "&rgf=" + p.f);
}

// Loot every wine / bowl / incense first, then fight every listed monster, then
// leave. Fights get the usual mimic prep and pre/post-adventure hooks, which
// means re-entering the garden afterwards, because the maximize can't run
// from inside the choice. Loot that a monster was blocking unlocks once it dies.
void roseGarden(){
    string garden = "campground.php?action=rosegarden";
    string page = visit_url(garden);
    int loopCount = 0;
    while (inRoseGarden(page)){
        if (loopCount++ > 40)
            abort("roseGarden: looped over 40 times -- an interaction probably isn't changing the garden");
        rosePoi [int] pois = rosePois(page);

        rosePoi loot = roseFind(pois, "Take", roseLoot);
        if (loot.i >= 0){
            page = roseInteract(loot);
            continue;
        }

        rosePoi mob = roseFind(pois, "Fight", roseMonsters);
        if (mob.i < 0) break;
        run_choice(2);   // step out so the maximizer can change gear
        mimicPrep();
        main@preadventure();
        page = visit_url(garden);
        mob = roseFind(rosePois(page), "Fight", roseMonsters);
        if (mob.i < 0) continue;
        roseInteract(mob);
        if (current_round() > 0)
            run_combat();
        main@postadventure();
        page = visit_url(garden);
    }
    if (inRoseGarden(page))
        run_choice(2);
}

void locationBasedWeakMonsters(){
    step("phase: weakMonsters start");
    set_property("subscript","weakling");
    if (have_effect($effect[coldform]) == 0)
        use($item[phial of coldness]);
    equip($slot[acc3],timeBadge());
    step("phase: weakMonsters gingerbread");
    while (to_int(get_property("_gingerbreadCityTurns")) < 30){
        LBMWPrep (false);
        gingerbread();
    }
    step("phase: weakMonsters pearl P1");
    while (looseFK()){
        LBMWPrep (false);
        pearloP1();
    }
    set_property("subscript","weakling");
    while (to_int(get_property("_speakeasyFreeFights")) < 3){
        step("phase: weakMonsters traveling hobo");
        LBMWPrep (true);
        adv1($location[An Unusually Quiet Barroom Brawl]);
    }
    if (get_property("questPAGhost") == "started" && get_property("ghostLocation") != ""){
        step("phase: weakMonsters paranormal ghost (walkie-talkie)");
        LBMWPrep (true);
        while (get_property("ghostLocation").to_location() != $location[none])
            adv1(get_property("ghostLocation").to_location());
    }
    while (to_int(get_property("_glarkCableUses")) < 5 && can_adventure($location[A Mob of Zeppelin Protesters])){
        if (get_property("questL11Ron") == "step4")
            set_property("mainOverride",", equip legendary seal-clubbing club");
        else
            set_property("mainOverride","");
        LBMWPrep (true);
        if (to_int(get_property("_glarkCableUses")) == 4){
            set_property("mainOverride",", equip angelbone totem");
            equip($slot[off-hand],$item[angelbone totem]);
            equip($slot[off-hand],$item[shrunken head]);
            set_property("offOverride",", equip shrunken head");
            equip($slot[weapon],$item[angelbone totem]);
        }
        retrieve_item(5,$item[glark cable]);
        adv1($location[the red zeppelin]);
        set_property("mainOverride","");
        set_property("acc2Override","");
        set_property("offOverride","");
        set_property("backOverride","");
    }
}

void nonlocationBasedWeakMonsters(){
    step("phase: weakMonsters red zeppelin / archaeologist");
    while (to_int(get_property("_archSpadeDigs")) < 11){
        set_property("archSkeleton","true");
        LBMWPrep (true);
        archaeologist();
        set_property("archSkeleton","false");
    }
    if (get_property("_aug8Cast") == "false" && to_int(get_property("_augSkillsCast")) < 4){
        step("phase: weakMonsters August Cat Day (skeletal cat)");
        LBMWPrep (true);
        augustCat();
    }
    if (to_int(get_property("_brickoFights")) < 10){
        step("phase: weakMonsters BRICKO ooze");
        LBMWPrep (true);
        main@preadventure( );
        use($item[bricko ooze]);
        main@postadventure( );
    }
    if (get_property("_cargoPocketEmptied") != "true"){
        step("phase: weakMonsters cargo shorts (haxx0r)");
        shorts();
    }
    step("phase: weakMonsters lynyrd snare");
    while (to_int(get_property("_lynyrdSnareUses")) < 3){
        LBMWPrep (true);
        main@preadventure( );
        use($item[lynyrd snare]);
        main@postadventure( );
    }
    while (contains_text(get_property("_trickOrTreatBlock"), "D")){
        step("phase: weakMonsters trick-or-treat kid");
        LBMWPrep (true);
        set_property("hatOverride",", equip beholed bedsheet");
        main@preadventure( );
        candy("fight");
        main@postadventure( );
        set_property("hatOverride","");
    }
    while (to_int(get_property("_aprilBandTomUses")) < 3
        && available_amount($item[Apriling band quad tom]) > 0){
        step("phase: weakMonsters giant sandworm (quad tom)");
        sandworm();
    }
    if (my_fullness() < fullness_limit() && my_class() != $class[seal clubber]){
        equip($item[devilbone corset]);
        equip($slot[acc3],$item[angelbone chopsticks]);
        eat($item[eldritch mushroom pizza]);
        cli_execute("unequip devilbone corset; unequip angelbone chopsticks");
    }
    while (to_int(get_property("_leafMonstersFought")) < 5
            || get_property("_tiedUpFlamingLeafletFought") == "false"){
        step("phase: weakMonsters flaming leaflets");
        LBMWPrep (true);
        main@preadventure( );
        if (get_property("_tiedUpFlamingLeafletFought") == "false"){
            use($item[tied-up flaming leaflet]);
        } else {
            visit_url("campground.php?preaction=leaves");
            visit_url("choice.php?"+my_hash()+"&whichchoice=1510&option=1&leaves=11");
            run_combat();
        }
        main@postadventure( );
    }
    step("phase: special leaf monsters");
    cli_execute("buy 4 lit leaf lasso");
    if (get_property("_tiedUpFlamingMonsteraFought") == "false"){
        mimicPrep();
        main@preadventure( );
        use($item[tied-up flaming monstera]);
        main@postadventure( );
    }
    if (get_property("_tiedUpLeaviathanFought") == "false"){
        mimicPrep();
        main@preadventure( );
        use($item[tied-up leaviathan]);
        main@postadventure( );
    }

    set_property("acc2Override","");
    set_property("acc3Override","");
    set_property("mainOverride","");
    set_property("offOverride","");
    set_property("hatOverride","");
    set_property("subscript","");
}

// True while weakMonsters() still has something to do -- gates the call in
// bulkFK(). Mirrors fightPicker()'s availability checks (minus the HP math).
boolean weakMonstersLeft(){
    if (to_int(get_property("_gingerbreadCityTurns")) < 30) return true;
    if (to_int(get_property("_leafMonstersFought")) < 5) return true;
    if (get_property("_tiedUpFlamingLeafletFought") == "false") return true;
    if (to_int(get_property("_brickoFights")) < 10) return true;
    if (to_int(get_property("_speakeasyFreeFights")) < 3) return true;
    if (get_property("_cargoPocketEmptied") != "true") return true;
    if (to_int(get_property("_lynyrdSnareUses")) < 3) return true;
    if (contains_text(get_property("_trickOrTreatBlock"), "D")) return true;
    if ((to_int(get_property("_glarkCableUses")) < 5 || to_int(get_property("_archSpadeDigs")) < 11)
        && can_adventure($location[A Mob of Zeppelin Protesters])) return true;
    if (to_int(get_property("_aprilBandTomUses")) < 3
        && available_amount($item[Apriling band quad tom]) > 0) return true;
    if (get_property("_tiedUpFlamingMonsteraFought") == "false"
        && mall_price($item[tied-up flaming monstera]) < 15000) return true;
    if (get_property("_tiedUpLeaviathanFought") == "false"
        && mall_price($item[tied-up leaviathan ]) < 15000) return true;
    if (get_property("_aug8Cast") == "false"
        && to_int(get_property("_augSkillsCast")) < 4) return true;
    if (get_property("questPAGhost") == "started"
        || (get_property("questPAGhost") == "unstarted"
            && total_turns_played() >= to_int(get_property("nextParanormalActivity"))
            && item_amount($item[almost-dead walkie-talkie]) > 0)) return true;
    return false;
}

boolean EmbezBetter(){
    int n = mall_price($item[11-leaf clover])/700;
    if (n < (numeric_modifier($modifier[meat drop])/100 + 1))
        return true;
    return false;
}

void embezzler(){
    while ((get_property("_aprilBandSaxophoneUses").to_int() < 3 || EmbezBetter()) && dayType() == 1){
        altFam($familiar[robortender]);
        if (get_property("_roboDrinks") != "drive-by shooting"){
            retrieve_item($item[drive-by shooting]);
            visit_url("inventory.php?action=robooze&which=1&whichitem=9396");
        }
        set_property("script","embezzler");
        if (get_property("_batWingsFreeFights").to_int() < 5){
            set_property("unconditionalOverride","meat drop, equip mafia pointer finger, equip bat wings");
        } else {
            set_property("unconditionalOverride","meat drop, equip mafia pointer finger");
        }
        if (have_effect($effect[Lucky!]) == 0){
            getLucky();
        }
        adv1($location[Cobb's knob treasury]);
    }
}

void restOfHiddenCity(){
    if (!can_adventure($location[An Overgrown Shrine (Southeast)]) || (get_property("zigguratLianas") > 0 && to_int(get_property("_drunkPygmyBanishes")) >= 11))
        return;
    set_property("maxOverride","familiar experience");
    while (to_int(get_property("_drunkPygmyBanishes")) < 11){
        if (!contains_text(get_property("banishedMonsters"),"pygmy bowler") && contains_text(get_property("banishedMonsters"),"pygmy orderlies"))
            set_property("famOverride","patriotic eagle");
        else if (contains_text(get_property("banishedMonsters"),"pygmy orderlies") && dayType() == 1 && get_property("screechCombats").to_int() > 0)
            set_property("famOverride","patriotic eagle");
        else
            set_property("famOverride","chest mimic");
        drunkPygmy();
    }
    while (get_property("zigguratLianas") == 0 && dayType() == 1){
        set_property("famOverride","chest mimic");
        lianas();
    }
    if (have_effect($effect[Everything looks Beige]) == 0 && have_item($item[crepe paper parachute cape])){
        adv1($location[An Overgrown Shrine (Southeast)]);
        cli_execute("equip weapon antique machete");
        visit_url("inventory.php?action=parachute");
        visit_url("choice.php?option=1&whichchoice=1543&monid=1426");
    }
    aa("facsimile");
}

void miscellaneousFams(){
    step("phase: miscellaneous fams");
    if (get_property("_machineTunnelsAdv").to_int() < 5 && mall_price($item[self-dribbling basketball]) + mall_price($item[Deep Machine Tunnels snowglobe]) <= 10000){
        if (have_effect($effect[Inside The Snowglobe]) == 0)
            use($item[Deep Machine Tunnels snowglobe]);
        while (get_property("_machineTunnelsAdv").to_int() < 5){
            altFam($familiar[machine elf]);
            set_property("subscript","NonSMFK");
            set_property("maxOverride","item drop");
            adv1($location[The Deep Machine Tunnels]);
        }
        set_property("subscript","");
        set_property("maxOverride","familiar weight");
    }
    if (get_property("_pocketProfessorLectures").to_int() == 0 && get_property("_locketMonstersFought").split_string(",").count() < 3 && !contains_text(get_property("_locketMonstersFought"),"1199") && dayType() == 0){
        string profTarget;
        if (dayType() == 0)
            profTarget = "witchess bishop";
        else if (dayType() == 1)
            profTarget = "Pumpkin spice wraith";
        set_property("maxOverride","familiar weight");
        set_property("pantsOverride",", equip tearaway Pants");
        set_property("offOverride", ", equip kol con snowglobe");
        set_property("acc1Override", ", equip Mr. Cheeng's spectacles");
        set_property("acc2Override", ", equip Lucky gold ring");
        set_property("acc3Override", ", equip Portable Laughing Stock");
        set_property("subscript","NonSMFK");
        altFam($familiar[Pocket Professor]);
        main@preadventure();
        cli_execute("reminisce " + profTarget);
        while (get_property("_chainedRelativityMonster") == profTarget)
            run_combat();
        set_property("pantsOverride","");
        set_property("offOverride", "");
        set_property("acc1Override", "");
        set_property("acc2Override", "");
        set_property("acc3Override", "");
        set_property("offOverride", "");
        set_property("subscript","");
    }
    if (get_property("_banderRunaways").to_int() < 30){
        set_auto_attack(0);
        if (have_effect($effect[Apriling Band Battle Cadence]) == 0 && total_turns_played() >= get_property("nextAprilBandTurn").to_int())
            cli_execute("aprilband effect c");
        while (get_property("_banderRunaways").to_int() < floor((my_familiar().familiar_weight() + weight_adjustment( ))/5)){
            if ($location[Cobb's Knob Treasury].combat_percent < 100)
                cli_execute("gain 15 combat");
            set_property("subscript","stompingBoots");
            set_property("maxOverride","familiar weight");
            if (get_property("_banderRunaways").to_int() < ((my_familiar().familiar_weight() + weight_adjustment( ))/5 - 6)){
                set_property("offOverride",", equip rake");
                set_property("mainOverride",", equip june cleaver");
                set_property("acc1Override",", equip spring shoes");
            } else {
                set_property("offOverride","");
                set_property("mainOverride","");
                set_property("acc1Override","");
            }
            altFam($familiar[Pair of Stomping Boots]);
            if (get_property("_pantsgivingCount").to_int() < 50){
                if (item_amount($item[pantsgiving]) == 0)
                    stashgrab($item[pantsgiving]);
                if (item_amount($item[pantsgiving]) > 0)
                    set_property("pantsOverride",", equip pantsgiving");
            } else if (get_property("sweat").to_int() < 90)
                set_property("pantsOverride",", equip designer sweatpants");
            else
                set_property("pantsOverride","");
            adv1($location[Cobb's Knob Treasury]);
        }
        set_property("subscript","");
        if (get_auto_attack() == 0)
            aa("facsimile");
        set_property("pantsOverride","");
        set_property("offOverride","");
        set_property("mainOverride","");
        set_property("acc1Override","");
    }
}

// Locations already scanned with the Peridot today. _perilLocations is a
// comma-separated list of location ids; an empty property splits into one
// blank entry, so skip anything that isn't a real id. Keyed by location so
// callers can test membership with `contains`.
boolean [location] periledLocations() {
    boolean [location] periled;
    foreach i, id in split_string(get_property("_perilLocations"), ","){
        if (id.to_int() == 0)
            continue;
        periled[id.to_int().to_location()] = true;
    }
    return periled;
}

void peridotFishing(){
    string perilLocations;
    whitelist("Temporary");
    repeat {
        perilLocations = get_property("_perilLocations");
        foreach loc in $locations[The Spooky Forest,The Unquiet Garves,The Bat Hole Entrance,
              Guano Junction,The Batrat and Ratbat Burrow,
              The Beanbat Chamber,Outskirts of Camp Logging Camp,Camp Logging Camp,
              South of the Border,Cobb's Knob Laboratory,
              The Penultimate Fantasy Airship,The Sleazy Back Alley,
              The Haunted Pantry,The Outskirts of Cobb's Knob,
              The Haiku Dungeon,The Briny Deeps,The Brinier Deepers,The Briniest Deepests,
              An Octopus's Garden,The Wreck of the Edgar Fitzsimmons,
              Madness Reef,The Marinara Trench,
              Anemone Mine,The Dive Bar,The Mer-Kin Outpost,The Coral Corral,Mer-kin Elementary School,
              Mer-kin Library,The Red Queen's Garden,
              The Enormous Greater-Than Sign,Noob Cave,
              The Laugh Floor,Infernal Rackets Backstage,
              Cobb's Knob Barracks,Cobb's Knob Kitchens,
              Cobb's Knob Harem,Cobb's Knob Treasury,
              The Defiled Cranny,The Defiled Niche,
              The Defiled Nook,The Goatlet,
              The Hidden Temple,The Smut Orc Logging Camp,
              The Caliginous Abyss,Dreadsylvanian Woods,
              Dreadsylvanian Village,Dreadsylvanian Castle,
              The Hidden Bowling Alley,The Hidden Park,
              The Degrassi Knoll Restroom,The Degrassi Knoll Bakery,
              The Degrassi Knoll Gym,The Degrassi Knoll Garage,
              The Old Landfill,The Arid\, Extra-Dry Desert,
              The Red Zeppelin,The Thinknerd Warehouse,
              The Haunted Kitchen,The Haunted Conservatory,
              The Black Forest,The Skeleton Store,
              Madness Bakery,The Overgrown Lot,The Deep Machine Tunnels,
              An Unusually Quiet Barroom Brawl,The Fungus Plains,
              Hero's Field,Vanya's Castle,Megalo-City,Pandamonium Slums]{
            set_property("subscript","peridot");
            if (periledLocations()[loc] == false && can_adventure(loc) == true && loc.wanderers == true){
                print (turns_until_forced_noncombat(loc) + " at " + loc);
                if (loc == $location[Pandamonium Slums] && available_amount($item[Hey Deze map]) == 0)
                    continue;
                if (loc == $location[The Deep Machine Tunnels] && have_effect($effect[Inside The Snowglobe]) == 0)
                    continue;
                if (loc == $location[The Degrassi Knoll Garage] && get_property("questM01Untinker") == "started")
                    continue;
                if (turns_until_forced_noncombat(loc) == 0) 
                    continue;
                mimicPrep();
                set_property("offOverride",", equip Kramco Sausage-o-Matic");
                set_property("acc2Override",",bonus mafia pointer");
                if (loc == $location[The Unquiet Garves]){
                    put_closet(item_amount($item[grave robbing shovel]),$item[grave robbing shovel]);
                    put_closet(item_amount($item[rusty grave robbing shovel]),$item[rusty grave robbing shovel]);
                }
                if (get_property("_timeCopsFoughtToday").to_int() < 10)
                    set_property("acc1Override",", equip mobius");
                if (loc.zone == "The Mer-Kin Deepcity"){
                    set_property("hatOverride",", equip mer-kin scholar mask");
                    set_property("pantsOverride",", equip Mer-kin scholar tailpiece");
                    cli_execute("closet put * mer-kin hallpass");
                }else if (loc.environment == "underwater"){
                    set_property("pantsOverride",", equip really nice swim");
                    if (loc == $location[the caliginous abyss])
                        set_property("acc1Override",", equip black glass");
                }else if (loc.zone == "The 8-Bit Realm") {
                    set_property("acc2Override",", equip continuum");
                }

                adv1(loc);
                set_property("acc2Override","");
                set_property("hatOverride","");
                set_property("pantsOverride","");
            }
        }
    } until (perilLocations == get_property("_perilLocations"));
    whitelist("homeclan");
    set_property("acc1Override","");
    set_property("offOverride","");
    set_property("subscript","");
}

void bulkFKD2(){
    step("phase: bulkFK start");
    set_property("inSpendAdv","true");
    set_property("script","FreeKill");
    // Arm the player's combat macro as the native auto-attack so a standalone
    // bulkFK() run (FKPrep skipped because the express card is already used) still fights.
    starter();
    if (get_auto_attack() == 0)
        aa("facsimile");
    if (weakMonstersLeft())
        weakMonsters();
    step("phase: August Golem");
    augustGolem();
    step("phase: bulkFK spleen (Extrovermectin)");
    if (my_spleen_use() < spleen_limit()){
        int toChew = floor((spleen_limit()-my_spleen_use())/2);
        chew (toChew,$item[Extrovermectin&trade;]);
        int mojo = 3-get_property("currentMojoFilters").to_int();
        use(mojo,$item[mojo filter]);
        toChew = floor((spleen_limit()-my_spleen_use())/2);
        chew (toChew,$item[Extrovermectin&trade;]);
    }
    if (dayType() == 1 && get_property("_backUpUses").to_int() < 11 && !contains_text(get_property("banishedPhyla"),"fish"))
        banishFish();
    step ("phase: use up hidden city");
    restOfHiddenCity();
    step ("phase: rose garden");
    roseGarden();
    step("phase: bulkFK habitat recall");
    habitatRecall();
    step("phase: bulkFK backup camera");
    backup();
    step("phase: bulkFK cyberzone");
    while (get_property("_cyberFreeFights").to_int() < 10){
        constructBanish();
        mimicPrep();
        cyberzone();
    }
    step("phase: bulkFK shadow rift");
    if (get_property("_shadowAffinityToday") == "false")
        shadowRealmFK();
    while (have_effect($effect[shadow affinity]) > 0){
        cli_execute("uneffect coldform");
        shadowRealmFK();
    }
    step("phase: bulkFK loose FK");
    while (looseFK()){
        set_property("subscript","looseFK");
        if (baseballPlayers() == 9 && get_property("_curveballFightsLeft").to_int() == 0 && get_property("_baseballInnings").to_int() < 3)
            baseballD();
        shadowRealmFK();
    }
    set_property("subscript","");
    step("phase: bulkFK NC force");
    NCforce(false);
    while (get_property("noncombatForcerActive") == true || get_property("encountersUntilSRChoice").to_int() == 0){
        shadowRealmFK();
        NCforce(false);
    }
    miscellaneousFams();
    step("phase: bulkFK reminisce");
    reminisce();
    step("phase: bulkFK glitch monster");
    if (get_property("_glitchMonsterFights") == 0 && have_item($item[\[glitch season reward name\]])){
        mimicPrep();
        main@preadventure( );
        eat($item[[glitch season reward name]]);
    }
    set_property("hatOverride","");
    step("phase: bulkFK god lobster");
    while (get_property("_godLobsterFights").to_int() < 3){
        use($item[dish of clarified butter]);
    }
    if (get_property("_molehillMountainUsed") == false)
        use($item[molehill mountain]);
    step("phase: bulkFK mimic egg");
    mimicEgg();
    step("phase: bulkFK faxing");
    faxing();
    if (item_amount($item[shaking 4-D camera]) > 0){
        mimicPrep();
        main@preadventure( );
        use($item[shaking 4-D camera]);
    }
    if (item_amount($item[envyfish egg]) > 0){
        mimicPrep();
        main@preadventure( );
        use($item[envyfish egg]);
    }
    if (my_class() == $class[seal clubber]){
        step("phase: bulkFK seals");
        seals();
    }
    if (get_property("eldritchTentaclesFought").to_int() < 11 && get_property("_eldritchTentacleFought") == "false"){
        main@preadventure();
        visit_url("place.php?whichplace=forestvillage&action=fv_scientist");
        run_choice(1);
        main@postadventure();
    }
    step("phase: peridot fishing");
    peridotFishing();
    stashreturn($item[pantsgiving]);
    if (!contains_text(get_property("thoth19_event_list"),"postFKD2"))
        cli_execute("ptrack add postFKD2");
    codpiece("none");
    embezzler();
}
void locationBasedAdventuring(){
    miscellaneousFams();
    step ("phase: use up hidden city");
    restOfHiddenCity();
    step ("phase: rose garden");
    roseGarden();
    if (dayType() == 0 && mall_price($item[Homeowner's loam]) < 30000){
        abort("Script in using loams for black rose garden");
    }
    step("phase: bulkFK habitat recall");
    habitatRecall();
    step("phase: bulkFK backup camera");
    backup();
    step("phase: bulkFK cyberzone");
    while (get_property("_cyberFreeFights").to_int() < 10){
        mimicPrep();
        cyberzone();
    }
    if (my_spleen_use() < 15){
        step("phase: peridot fishing");
        peridotFishing();
    }
    locationBasedWeakMonsters();
}
void bulkFKD1(){
    set_property("inSpendAdv","true");
    set_property("script","FreeKill");
    equip($slot[acc3],timeBadge());
    buffML($monster[Flaming leaflet]);
    locationBasedAdventuring();
    if (my_spleen_use() < 10){
        use_familiar($familiar[stooper]);
        equip($item[devilbone greaves]);
        equip($slot[acc1],$item[angelbone dice]);
        equip($slot[acc2],$item[devilbone rosary]);
        doSpleen();
        if (my_inebriety() <= inebriety_limit()){
            if (my_inebriety() == inebriety_limit()-3)
                drink($item[friendly turkey]);
            if (get_property("vintnerWineEffect") == "Wine-Befouled") {
                drink($item[1950 Vampire Vintner wine]);
                cli_execute("acquire 3 tombstone-shaped Crimboween cookie");
                visit_url("inventory.php?action=cupof13s");
                visit_url("choice.php?option=1&whichchoice=1601&"+my_hash()+"&whichitem1=2200&whichitem2=2200&whichitem3=2200");
            } else if (my_inebriety() == inebriety_limit()-2){
                item CupItem = mall_price($item[cuppa Improprie tea]) < mall_price($item[demonic cow's blood])*2 ? $item[cuppa Improprie tea]:$item[demonic cow's blood];
                int CupNum = CupItem.to_int();
                retrieve_item(3,CupItem);
                visit_url("inventory.php?action=cupof13s");
                visit_url("choice.php?option=1&whichchoice=1601&"+my_hash()+"&whichitem1="+CupNum+"&whichitem2="+CupNum+"&whichitem3="+CupNum);
                cli_execute("acquire 3 tombstone-shaped Crimboween cookie");
                visit_url("inventory.php?action=cupof13s");
                visit_url("choice.php?option=1&whichchoice=1601&"+my_hash()+"&whichitem1=2200&whichitem2=2200&whichitem3=2200");
            }
            if (my_inebriety() == inebriety_limit())
                drink($item[vintage smart drink]);
        }
        if (my_spleen_use() < spleen_limit()){
            int toChew = floor((spleen_limit()-my_spleen_use())/2);
            chew (toChew,$item[Extrovermectin&trade;]);
            int mojo = 3-get_property("currentMojoFilters").to_int();
            use(mojo,$item[mojo filter]);
            toChew = floor((spleen_limit()-my_spleen_use())/2);
            chew (toChew,$item[Extrovermectin&trade;]);
        }
        use_familiar($familiar[comma chameleon]);
        cli_execute("maximize familiar weight");
    }
    nonlocationBasedWeakMonsters();
    step("phase: August Golem");
    augustGolem();
    step("phase: bulkFK reminisce");
    reminisce();
    step("phase: bulkFK glitch monster");
    if (get_property("_glitchMonsterFights") == 0 && have_item($item[\[glitch season reward name\]])){
        mimicPrep();
        main@preadventure( );
        eat($item[[glitch season reward name]]);
    }
    set_property("hatOverride","");
    step("phase: bulkFK god lobster");
    while (get_property("_godLobsterFights").to_int() < 3){
        use($item[dish of clarified butter]);
    }
    if (get_property("_molehillMountainUsed") == false)
        use($item[molehill mountain]);
    step("phase: bulkFK mimic egg");
    mimicEgg();
    step("phase: bulkFK faxing");
    faxing();
    if (item_amount($item[shaking 4-D camera]) > 0){
        mimicPrep();
        main@preadventure( );
        use($item[shaking 4-D camera]);
    }
    if (item_amount($item[envyfish egg]) > 0){
        mimicPrep();
        main@preadventure( );
        use($item[envyfish egg]);
    }
    if (my_class() == $class[seal clubber]){
        if (dayType() == 0 && fullness_limit() - my_fullness() >= 1){
            equip($item[devilbone corset]);
            equip($slot[acc3],$item[angelbone chopsticks]);
            if (fullness_limit() - my_fullness() >= 3)
                eat($item[eldritch mushroom pizza]);
            cli_execute("unequip devilbone corset; unequip angelbone chopsticks");
            cli_execute("ash import dinner;heavyWeightBooze()");
            cli_execute("unequip devilbone rosary;unequip angelbone dice;unequip devilbone greaves;unequip angelbone totem; familiar comma chameleon");
        }
        step("phase: bulkFK seals");
        seals();
    }
    if (get_property("eldritchTentaclesFought").to_int() < 11 && get_property("_eldritchTentacleFought") == "false"){
        main@preadventure();
        visit_url("place.php?whichplace=forestvillage&action=fv_scientist");
        run_choice(1);
        main@postadventure();
    }
    stashreturn($item[pantsgiving]);
    if (!contains_text(get_property("thoth19_event_list"),"postFKD1"))
        cli_execute("ptrack add postFKD1");
    codpiece("none");
}

// ─── ENTRY ───────────────────────────────────────────────────────────────────

// Full free-kill run: FKPrep (skipped once the Yendorian express card is spent)
// then bulkFK. Individual phases are still reachable as `call StockingMimic.ash
// FKPrep` / `bulkFK`. Wrapped in try/finally so finisher() restores the account's
// mafia hooks / CCS / auto-recovery even if a phase aborts partway.
void main(){
    try {
        starter();
        if (get_property("expressCardUsed") == "false"){
            if (get_property("_gitUpdated") == false)
                cli_execute("breakfast.ash");
            if (get_property("prusias_profitTracking_date") != today_to_string( ))
                cli_execute("ptrack add preprepD2");
            else if (!contains_text(get_property("thoth19_event_list"),"preprepD1") && dayType() == 0)
                cli_execute("ptrack add preprepD1");
            set_property("inSpendAdv","true");
            set_property("script","FreeKill");
            FKPrep();
            if (!contains_text(get_property("thoth19_event_list"),"postprepD2")){
                stashreturn($item[pantsgiving]);
                cli_execute("ptrack add postprepD2");
            }else if (!contains_text(get_property("thoth19_event_list"),"postprepD1") && dayType() == 0)
                cli_execute("ptrack add postprepD1");
        }
        if (dayType() == 0)
            bulkFKD1();
        if (dayType() == 1)
            bulkFKD2();
    } finally {
        finisher();
    }
}
