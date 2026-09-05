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
        foreach ef in $effects[covetous robbery, joy, Chow Downed, heavy petting, squirming like a toad,Braaaaaains, Low on the Hog, Leisurely Amblin', frosty,sinuses for miles]{
            if (to_int(get_property("_monkeyPawWishesUsed")) == 5)
                return;
            if (have_effect(ef) == 0)
                cli_execute("monkeypaw effect " + ef);
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
        chibiBuddy();
        use($item[ChibiBuddy&trade; (on)]);
        set_property("chibiChoice1","0");
        set_property("chibiChoice2","0");
    }
}
void prepBuffs(){
    foreach ef in $effects[benetton's medley of diversity, inigo's incantation of inspiration,Familial Ties,Busker Do,Swimming Head]{
        if (have_effect(ef) > 0)
            cli_execute("uneffect " + ef);
    }

    //fam weight
    foreach ef in $effects[Robot Friends,Healthy Green Glow,Chorale of Companionship,Human-Fish Hybrid,Whole Latte Love,Shortly Stacked,Thoughtful Empathy,Leash of Linguini,Empathy,Black Tongue,Man's Worst Enemy,Billiards Belligerence,You Can Really Taste the Dormouse,Kindly Resolve,Human-Machine Hybrid,Shrimpin' Ain't Easy,Over-Familiar With Dactyls,Loyal Tea,Warm Shoulders,One Foot Heavier,Work For Hours a Week,A Girl Named Sue,Panna Consideration,Loyal as a Rock,Candied Devil,Wildsun Boon,Only Dogs Love a Drunken Sailor,Best Pals,Heart of Green,Bestial Sympathy,Herder\, Bitter\, Fester\, Stranger,Party Soundtrack,Shortly Wired,Greased-Up Familiar,Crocodile Tear]{
        if (have_effect(ef) == 0)
            cli_execute(ef.default);
    }
    while (have_effect($effect[blue swayed]) < 50){
        use($item[pulled blue taffy]);
    }
    while (have_effect($effect[She Ate Too Much Candy]) < 25){
        use($item[Prunets]);
    }

    //Monster level. Needs reconsidering to work with weakMonsters()
    foreach ef in $effects[Ur-Kel's Aria of Annoyance,Pride of the Puffin,Bloodbathed,Misplaced Rage,Manbait,Sweetbreads Flamb&eacute;,Red Lettered,Spangled Star,Tortious,Litterbug,Not Sharing,Para-lyzed Jaw,Contemptible Emanations,Lapdog,Ashen Burps,The Cupcake of Wrath,Gelded,Mysteriously Handsome]{
        if (have_effect(ef) == 0)
            cli_execute(ef.default);
    }
    //meat drop
    foreach ef in $effects[Loded,Incredibly Well Lit,Tubes of Universal Meat,Holiday Bliss,So You Can Work More...,Legendary Pasta Eyeball,Polka of Plenty]{
        if (have_effect(ef) == 0)
            cli_execute(ef.default);
    }
    //item drop
    foreach ef in $effects[Steely-Eyed Squint,Spookyravin',Unbarking Dogs,Cold Hearted,One Very Clear Eye,Materiel Intel,Spitting Rhymes,Joyful Resolve,Lubricating Sauce]{
        if (have_effect(ef) == 0)
            cli_execute(ef.default);
    }
    //initiative
    foreach ef in $effects[Bow-Legged Swagger,Natural 1,Patent Alacrity,Silent Hunting,Clear Ears\, Can't Lose,Poppy Performance,Hiding in Plain Sight,Digitalis\, Dig It,Ass Over Teakettle,Song of Slowness,Synthetic Buzz,Seal Clubbing Frenzy,Springy Fusilli]{
        if (have_effect(ef) == 0)
            cli_execute(ef.default);
    }
    //mus needs to be done later, shieldbutt may be able to do it
#    foreach ef in $effects[Puissant Pressure,Incredibly Hulking,Juiced Out,Gr8ness]{
#        if (have_effect(ef) == 0)
#            cli_execute(ef.default);
#    }
}

// ─── FREE-KILL PREP ──────────────────────────────────────────────────────────

void doSpleen(){
    foreach spl in $items[medicinal gruel, psilocyber mushroom, gleaming oyster egg,
        Party-in-a-Can&trade;, body spradium, Crimbeau de toilette]{
        if (spleen_limit() == my_spleen_use())
            return;
        if (spl == $item[body spradium] && item_amount($item[body spradium]) == 0)
            continue;
        if (mall_price(spl) > 10000)
            continue;
        chew(spl);
    }
}

// Effect extenders on day 1 of ascensions, some nohookah food on day 2
void dieting(){
	if (get_property("ascensionsToday") == "1"){
		// Strip every effect that might get in the way of effect extenders
		foreach ef in my_effects(){
			if ($effects[Shadow Affinity, On the Trail, Lucky!, Apriling Band Battle Cadence,
				Everything Looks Red, Everything Looks Yellow, Everything Looks Green,
				Apriling Band Patrol Beat] contains ef)
				continue;
			cli_execute("uneffect " + ef);
		}
		if (have_effect($effect[Shadow Affinity]) == 0)
			abort("dieting: Shadow Affinity fell off before the rollover-day binge");
		if (get_property("ascensionsToday") == "1")
			use($item[law of averages]);
		eat(fullness_limit() - my_fullness(), $item[thyme jelly donut]);
		drink(inebriety_limit() - my_inebriety(), $item[Temps Tempranillo]);
        if (my_fullness() == fullness_limit() && get_property("_pantsgivingFullness").to_int() < 1){
            stashgrab($item[pantsgiving]);
            equip($item[pantsgiving]);
            use_familiar($familiar[patriotic eagle]);
            retrieve_item($item[dish of clarified butter]);
            visit_url("inv_use.php?which=3&whichitem=9908");
            run_combat();
            run_choice(-1);
            if (my_fullness() < fullness_limit())
                eat(1,$item[thyme jelly donut]);
        }
        if (get_property("spiceMelangeUsed") == "false" || get_property("_aug16Cast") == "false"){
            if (get_property("spiceMelangeUsed") == "false")
                use ($item[spice melange]);
            if (get_property("_aug16Cast") == "false")
                use_skill($skill[Aug. 16th: Roller Coaster Day!]);
        }
		eat(fullness_limit() - my_fullness(), $item[thyme jelly donut]);
		drink(inebriety_limit() - my_inebriety(), $item[Temps Tempranillo]);

	//	doSpleen();
	} else {
		foreach dr in $items[Feliz Navidad]{
			if (my_inebriety() >= inebriety_limit())
				break;
			if (mall_price(dr) < 10000)
				drink(dr);
		}
		foreach fo in $effects[In the Depths, Sugar-Frosted Pet Guts, Beefy Heart]{
			if (my_fullness() >= fullness_limit())
				break;
			if (have_effect(fo) > 0)
				continue;
			if (effect_to_item(fo) == $item[Black and White Apron Meal Kit] && my_class() == $class[seal clubber]){
				retrieve_item($item[cranberries]);
				visit_url("inv_use.php?which=3&whichitem=11472");
				visit_url("choice.php?whichchoice=1518&option=1&meal=0&ingredients0%5B%5D=672");
			} else if (effect_to_item(fo).mall_price() < 30000){
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

void FKPrep(){
	step("phase: FKPrep start");
	starter();
	// Combat runs off the player's saved combat macro (id in the combatMacroID
	// pref) as the native KoL auto-attack -- round 0 only works when the macro is
	// set natively, not embedded in a mafia CCS. starter() just cleared the
	// auto-attack, so re-arm it here.
    if (get_property("ascensionsToday") == 1){
        int peevp = pvp_attacks_left();
        if (peevp > 0 && count(current_pvp_stances( )) > 0) {
            cli_execute("PVP_MAB; unequip pants");
        }
    }
    aa("facsimile");
	if (get_property("_shadowAffinityToday") == "false")
		use($item[closed-circuit pay phone]);

	step("phase: FKPrep dieting");
	if (my_inebriety() < inebriety_limit()){
		dieting();
	}

	retrieve_item(25, $item[bag of many confections]);
	set_property("script", "FreeKill");

	step("phase: FKPrep buffs");
	useMayamRings();
	beretBusking("familiar weight");
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
	if (get_property("_glennGoldenDiceUsed") == "false")
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
		Disco Leer]{
		if (have_effect(ef) == 0)
			cli_execute(ef.default);
	}

	if (have_effect($effect[Yeg's Glory]) == 0 && my_daycount() > 1)
		use($item[fancy chess set]);

	if (have_effect($effect[Do I Know You From Somewhere?]) == 0){
		if (item_amount($item[driftwood beach comb]) == 0)
			use($item[piece of driftwood]);
		cli_execute("beach head 10");
		cli_execute("combo 10");
	}

	step("phase: FKPrep stash pops");
	// Stash-borrowed one-a-day item pops.
	foreach it in $items[defective Game Grid token, BittyCar MeatCar, Platinum Yendorian Express Card]{
		stashgrab(it);
		if (have_item(it))
			use(it);
		stashreturn(it);
	}

	step("phase: FKPrep hidden temple");
	if (get_property("ascensionsToday").to_int() == 0
		&& my_ascensions() != get_property("lastTempleAdventures").to_int()
		&& get_property("questM16Temple") == "finished"){
		use($item[stone wool]);
		set_property("choiceAdventure582", "1");
		set_property("choiceAdventure579", "3");
		adv1($location[The Hidden Temple]);
		useMayamRings();
	}

	step("phase: FKPrep codpiece");
	codpiece("none");
	codpiece("peridot of peril,blood cubic zirconia,baseball diamond,tuesday's ruby,tuesday's ruby");
}

// ─── bulkFK and helpers (verbatim from farto.ash, not yet refactored) ────────

// Standard free-kill farming stance used all over weakMonsters()/bulkFK()'s
// one-off monster kills: comma chameleon out, maximize for familiar weight
// with the eternity codpiece equipped (so its own familiar-weight bonus
// doesn't get maximized away). extraMax, if given, is appended to
// maxOverride as-is (e.g. ",-weapon" in seals()).
void mimicPrep(string extraMax){
    if (have_familiar($familiar[stocking mimic]))
        set_property("famOverride","stocking mimic");
    else
        set_property("famOverride","comma chameleon");
    set_property("maxOverride","familiar weight, equip eternity codpiece" + extraMax);
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

    foreach id in $ints[646,191,306,250,30,490,612,317,448,267,47,143,425,402,589,579,136,299,220,428,235,265,363,452,383,666,443,568] {
        if (!emptied[id]) {
            main@preadventure( );
            cli_execute("cargo pick " + id);
            return;
        }
    }
    main@postadventure( );
}
void august(){
    if (to_int(get_property("_augSkillsCast")) >= 4)
        return;

    foreach id in $ints[22,8] {
        if (get_property("_aug" + id + "Cast") == false && to_int(get_property("_augSkillsCast")) < 4) {
            main@preadventure( );
            cli_execute("cast Aug. " + id);
            main@postadventure( );
        }
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
            foreach mon in $monsters[greyhat hacker,greenhat hacker,redhat hacker,purplehat hacker] {
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
    if (get_property("rufusQuestTarget") == "shadow scythe")
        abort("Shadow scythe, kill manually");
    else if (get_property("rufusQuestTarget") == "shadow orrery"){
        set_property("maxOverride","familiar weight");
        set_property("shirtOverride",", equip ultracolor");
    } else if (get_property("rufusQuestTarget") == "shadow spire"){
        set_property("hpAutoRecovery",0.36);
        set_property("hpAutoRecoveryTarget",0.36);
        cli_execute("recover hp");
        set_property("maxOverride","familiar weight, equip petrified wood wizard's pouch");
    }
}
void shadowRealmFK(){
    set_property("famOverride","comma chameleon");
    if (!contains_text(get_property("maxOverride"),"familiar"))
        set_property("maxOverride","familiar weight, equip eternity codpiece");
    if (get_property("questRufus") == "step1") {
        use($item[closed-circuit pay phone]);
        adv1($location[Shadow Rift (The Misspelled Cemetary)]);
    }
    if (get_property("_shadowAffinityToday") == false && get_property("questRufus") != "unstarted"){
        if (get_property("rufusQuestType") == "entity")
            shadowBoss();
        else if (have_effect($effect[shadow affinity]) < get_property("encountersUntilSRChoice").to_int()){
            abort("script out non entity case");
        }
    }
    if ($monster[shadow slab].elemental_resistance > 85){
        set_property("acc3Override",",equip petrified wood wizard's pouch");
    } else {
        set_property("acc3Override",",equip petrified wood wizard's pouch");
    }
    if (to_int(get_property("_batWingsSwoopUsed")) < 11 && get_property("ascensionsToday") == "1")
        set_property("backOverride",", equip bat wings");
    if (get_property("questRufus") == "unstarted")
        use($item[closed-circuit pay phone]);
    if (get_property("questRufus") == "started" && get_property("rufusQuestType") == "items"){
        retrieve_item(3,to_item(get_property("rufusQuestTarget")));
    } else if (have_effect($effect[shadow affinity]) > 0){
        adv1($location[Shadow Rift (The Misspelled Cemetary)]);
    } else {
        NCforce();
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
                shadowBoss();
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
    set_property("backOverride","");}
void sandworm(){
    mimicPrep();
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
        if (my_location() != $location[the red zeppelin]){
            if (get_property("zeppelinProgress").to_int() >= 6)
                set_property("mainOverride",", equip legendary seal-clubbing club");
            else
                set_property("mainOverride","");
            if (to_int(get_property("_glarkCableUses")) < 5) {
                retrieve_item(5,$item[glark cable]);
                adv1($location[the red zeppelin]);
            } else
                abort();
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
void uneffectBuff(){
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
        if (numeric_modifier(ef, to_string(st)) > statBuff){
            statBuff = numeric_modifier(ef, to_string(st));
            toRemove = ef;
        }
    }
    cli_execute("uneffect " + toRemove);
}
boolean looseFK(){
    set_property("maxOverride","familiar weight, equip eternity codpiece");
    if ((my_basestat($stat[submoxie]) - 118881) > BCZcost("SweatBulletsCasts")){
        set_property("maxOverride","familiar weight, equip eternity codpiece");
        print ("FK is sweat");
        return true;
    }
    if (get_property("_gingerbreadMobHitUsed") == "false"){
        print ("FK is gingerbread");
        return true;
    }
    if (get_property("_shatteringPunchUsed").to_int() < 3){
        print ("FK is shattering");
        return true;
    }
    if (have_effect($effect[everything looks red]) == 0){
        set_property("maxOverride","familiar weight, equip eternity codpiece, equip everfull dart holster");
        print ("FK is bullseye");
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
    if (get_property("_assertYourAuthorityCast").to_int() < 3){
        print ("FK is assert");
        set_property("maxOverride","familiar weight, equip sheriff pistol, equip sheriff moustache, equip sheriff badge");
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
    return false;
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
    if (have_effect($effect[Wet Willied]) == 0){
        use($item[willyweed]);
    }
    banishFish();
    while (looseFK()){
        set_property("famOverride","comma chameleon");
        set_property("pantsOverride",", equip really nice swim");
        set_property("acc3Override",", equip time lord badge of honor");
        set_property("subscript","looseFK");
        foreach str in $strings[anemone,trench,bar]{
            if (get_property(pearls[str].donePref) == "false" || str == "bar"){
                if (numeric_modifier(pearls[str].ele_res) < 18)
                    abort();
                adv1(pearls[str].loc);
                break;
            }
        }
    }
        set_property("pantsOverride","");
}
void pearloP2(){
    if (get_property("_fishyPipeUsed") == "false")
        use ($item[fishy pipe]);
    if (have_effect($effect[Wet Willied]) == 0){
        use($item[willyweed]);
    }
    banishFish();
    foreach str in $strings[deepests,reef]{
        set_property("pantsOverride", ", equip really nice swim");
        set_property("famOverride", "comma chameleon");
        if (get_property(pearls[str].donePref) == "false" || str == "reef"){
            if (numeric_modifier(pearls[str].ele_res) < 18)
                abort();
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
    foreach str in $strings[anemone,bar,trench]{
        if (get_property(pearls[str].donePref) == "false" || str == "trench"){
            if (numeric_modifier(pearls[str].ele_res) < 18)
                abort();
            adv1(pearls[str].loc);
            break;
        }
    }
}
void gingerbread(){
    if (get_property("gingerbreadCityAvailable") == false){
        if (get_property("_gingerbreadCityToday") == false)
            use($item[counterfeit city]);
    }
    retrieve_item(29,$item[gingerbread cigarette]);
    while (get_property("_gingerbreadCityTurns").to_int() < 30){
        mimicPrep();
        adv1($location[Gingerbread Upscale Retail District]);
        if (get_property("_gingerbreadCityTurns").to_int() == 9)
            adv1($location[Gingerbread civic center]);
        if (get_property("_gingerbreadCityTurns").to_int() == 19)
            adv1($location[Gingerbread civic center]);
    }
}
void habitatRecall(){
    while (to_int(get_property("_monsterHabitatsRecalled")) < 3 || to_int(get_property("_monsterHabitatsFightsLeft")) > 0 || get_property("beGregariousFightsLeft").to_int() > 0){
        banishFish();
        if (to_int(get_property("_monsterHabitatsFightsLeft")) == 0 && to_int(get_property("_monsterHabitatsRecalled")) < 3){
            mimicPrep();
            cli_execute("reminisce black crayon mer-kin");
        }
        while (to_int(get_property("_monsterHabitatsFightsLeft")) > 0 || get_property("beGregariousFightsLeft").to_int() > 0){
            mimicPrep();
            MobiusMaybe();
            if (get_property("beGregariousFightsLeft").to_int() == 1 && get_property("beGregariousCharges").to_int() == 0 && to_int(get_property("_monsterHabitatsRecalled")) == 3 && get_property("ascensionsToday") == "0"){
                if (mall_price($item[flask of embalming fluid]) > 1000)
                    abort("reanimated reanimator is too expensive rn");
                retrieve_item($item[flask of embalming fluid]);
                visit_url("inv_equip.php?which=2&action=equip&whichitem=6785");
            }
            pearloP2();
        }
        set_property("offOverride","");
        set_property("acc2Override","");
    }
}
void backup(){
    while (to_int(get_property("_backUpUses")) < 11){
        if (to_int(get_property("_mimicEggsObtained")) < 11 && $familiar[chest mimic].experience > 100){
            set_property("famOverride","chest mimic");
        } else
            set_property("famOverride","comma chameleon");
        if (have_effect($effect[everything looks purple]) == 0 && get_property("famOverride") == "comma chameleon"){
            set_property("offOverride",", equip roman candel");
        } else
            set_property("offOverride","");
        set_property("maxOverride","familiar weight, equip eternity codpiece");
        set_property("pantsOverride",", equip really nice swim");
        set_property("acc3Override",", equip backup camera");
        pearloP3();
    }
    set_property("pantsOverride","");
    set_property("acc3Override","");
}
void mimicEgg(){
    while (item_amount($item[mimic egg]) > 0 && get_property("ascensionsToday") == 0){
        mimicPrep();
        main@preadventure( );
        cli_execute("c2t_megg fight Black Crayon Mer-kin");
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
    while (get_property("_locketMonstersFought").split_string(",").count() < 3){
        foreach mon in $monsters[black crayon golem, black crayon spiraling shape]{
            if (get_property("_locketMonstersFought").contains_text(mon.to_int()))
                continue;
            mimicPrep();
            main@preadventure( );
            cli_execute("reminisce " + mon);
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
        cli_execute("equip adobe adze");
        main@preadventure( );
        use($item[figurine of a wretched-looking seal]);
    }
    set_property("mainOverride","");
}
void weakMonsters(){
    step("phase: weakMonsters start");
    set_property("acc3Override",", equip time lord badge of honor");
    set_property("subscript","weakling");
    retrieve_item($item[shard of double-ice]);
    if (have_effect($effect[coldform]) == 0)
        use($item[phial of coldness]);
    equip($slot[acc3],$item[time lord badge of honor]);
    int highStat = max(my_buffedstat($stat[muscle]),my_buffedstat($stat[mysticality]),my_buffedstat($stat[moxie]));
    while ((highStat/2) + 10 > numeric_modifier("monster level")){
        highStat = max(my_buffedstat($stat[muscle]),my_buffedstat($stat[mysticality]),my_buffedstat($stat[moxie]));
        print(highStat);
        print ((highStat/2));
        uneffectBuff();
    }
    step("phase: weakMonsters gingerbread");
    if (get_property("_gingerbreadCityTurns").to_int() < 30){
        set_property("subscript","weakling");
        gingerbread();
    }
    step("phase: weakMonsters pearl P1");
    if (looseFK() && get_property("ascensionsToday") == "1"){
        pearloP1();
    }
    set_property("subscript","weakling");
    step("phase: weakMonsters speakeasy");
    while (to_int(get_property("_speakeasyFreeFights")) < 3){
        mimicPrep();
        adv1($location[An Unusually Quiet Barroom Brawl]);
    }
    step("phase: weakMonsters leaf monsters");
    while (to_int(get_property("_leafMonstersFought")) < 5){
        mimicPrep();
        main@preadventure( );
        visit_url("campground.php?preaction=leaves");
        visit_url("choice.php?"+my_hash()+"&whichchoice=1510&option=1&leaves=11");
        run_combat();
        main@postadventure( );
    }
    step("phase: weakMonsters tied-up leaflets");
    if (get_property("_tiedUpFlamingLeafletFought") == false){
        main@preadventure( );
        use($item[tied-up flaming leaflet]);
        main@postadventure( );
    }
    if (get_property("_tiedUpFlamingMonsteraFought") == false && mall_price($item[tied-up flaming monstera]) < 15000){
        main@preadventure( );
        use($item[tied-up flaming monstera]);
        main@postadventure( );
    }
    if (get_property("_tiedUpLeaviathanFought") == false && mall_price($item[tied-up leaviathan ]) < 15000){
        main@preadventure( );
        use($item[tied-up leaviathan ]);
        main@postadventure( );
    }
    step("phase: weakMonsters cargo shorts");
    shorts();
    step("phase: weakMonsters BRICKO");
    while (get_property("_brickoFights").to_int() < 10){
        mimicPrep();
        main@preadventure( );
        use($item[bricko ooze]);
        main@postadventure( );
    }
    step("phase: weakMonsters lynyrd snare");
    while (to_int(get_property("_lynyrdSnareUses")) < 3){
        mimicPrep();
        main@preadventure( );
        use($item[lynyrd snare]);
    }
    step("phase: weakMonsters trick-or-treat");
    while (contains_text(get_property("_trickOrTreatBlock"), "D")){
        mimicPrep();
        set_property("hatOverride",", equip beholed bedsheet");
        main@preadventure( );
        candy("fight");
    }
    set_property("hatOverride","");
    step("phase: weakMonsters glark cable / zeppelin");
    while (to_int(get_property("_glarkCableUses")) < 5 && can_adventure($location[A Mob of Zeppelin Protesters])) {
        if (get_property("questL11Ron") == "step4")
            set_property("mainOverride",", equip legendary seal-clubbing club");
        else
            set_property("mainOverride","");
        mimicPrep();
        MobiusMaybe();
        retrieve_item(5,$item[glark cable]);
        adv1($location[the red zeppelin]);
    }
    set_property("acc2Override","");
    step("phase: weakMonsters archaeologist");
    if (can_adventure( $location[The Red Zeppelin])){
        while (to_int(get_property("_archSpadeDigs")) < 11){
            set_property("archSkeleton","true");
            mimicPrep();
            archaeologist();
        }
        set_property("archSkeleton","false");
    }
    set_property("mainOverride","");
    step("phase: weakMonsters august skills");
    august();
    step("phase: weakMonsters paranormal ghost");
    if (get_property("questPAGhost") == "unstarted" && total_turns_played() >= get_property("nextParanormalActivity").to_int()){
        use($item[almost-dead walkie-talkie]);
        mimicPrep();
        MobiusMaybe();
        adv1 (to_location(get_property("ghostLocation")));
    }
    set_property("acc2Override","");
    step("phase: weakMonsters sandworm (quad tom)");
    while (get_property("_aprilBandTomUses").to_int() < 3){
        sandworm();
    }
    set_property("acc3Override","");
    set_property("offOverride","");
    set_property("subscript","");
}
void bulkFK(){
    step("phase: bulkFK start");
    set_property("inSpendAdv","true");
    set_property("script","FreeKill");
    // Arm the player's combat macro as the native auto-attack so a standalone
    // bulkFK() run (FKPrep skipped because the express card is already used) still fights.
    starter();
    aa("facsimile");
    if (get_property("_aprilBandTomUses").to_int() < 3){
        weakMonsters();
    }
    //need to finish: science tent
    //eat eldritch pizza
    step("phase: bulkFK spleen (Extrovermectin)");
    if (item_amount($item[4-D camera]) == 0)
        retrieve_item($item[4-D camera]);
    if (item_amount($item[pulled green taffy]) == 0)
        retrieve_item($item[pulled green taffy]);
    if (my_spleen_use() < spleen_limit() && get_property("ascensionsToday") == "0"){
        int toChew = floor((spleen_limit()-my_spleen_use())/2);
        chew (toChew,$item[Extrovermectin&trade;]);
        int mojo = 3-get_property("currentMojoFilters").to_int();
        use(mojo,$item[mojo filter]);
        toChew = floor((spleen_limit()-my_spleen_use())/2);
        chew (toChew,$item[Extrovermectin&trade;]);
    }
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
    while (have_effect($effect[shadow affinity]) > 0 && get_property("ascensionsToday") == "0"){
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
    NCforce();
    while (get_property("noncombatForcerActive") == true){
        shadowRealmFK();
        NCforce();
    }
    step("phase: machine elf");
    if (get_property("_machineTunnelsAdv").to_int() < 5){
        if (get_property("commaFamiliar") != "Machine Elf"){
            retrieve_item($item[self-dribbling basketball]);
            visit_url("inv_equip.php?which=2&action=equip&whichitem=8707");
            set_property("commaFamiliar","Machine Elf");
        }
        if (have_effect($effect[Inside The Snowglobe]) == 0)
            use($item[Deep Machine Tunnels snowglobe]);
        while (get_property("_machineTunnelsAdv").to_int() < 5){
            set_property("subscript","NonSMFK");
            set_property("maxOverride","item drop");
            set_property("famOverride","commaChameleon");
            adv1($location[The Deep Machine Tunnels]);
        }
        set_property("subscript","");
        set_property("maxOverride","familiar weight");
    }
    if (get_property("_pocketProfessorLectures").to_int() == 0 && get_property("_locketMonstersFought").split_string(",").count() < 3){
        set_property("maxOverride","familiar weight");
        set_property("pantsOverride",", equip tearaway Pants");
        set_property("offOverride", ", equip kol con");
        set_property("acc1Override", ", equip Mr. Cheeng's spectacles");
        set_property("acc2Override", ", equip Lucky gold ring");
        set_property("offOverride", ", equip Portable Laughing Stock");
        if (get_property("commaFamiliar") != "Pocket Professor"){
            retrieve_item($item[Pocket Professor memory chip]);
            visit_url("inv_equip.php?which=2&action=equip&whichitem=10324");
            set_property("commaFamiliar","Pocket Professor");
        }
        main@preadventure();
        cli_execute("reminisce Black Crayon Flower");
        while (get_property("_chainedRelativityMonster") == "Black Crayon Flower")
            run_combat();
        set_property("pantsOverride","");
        set_property("offOverride", "");
        set_property("acc1Override", "");
        set_property("acc2Override", "");
        set_property("offOverride", "");
    }
    step("phase: bulkFK reminisce");
    reminisce();
    step("phase: bulkFK glitch monster");
    if (get_property("_glitchMonsterFights") == 0){
        mimicPrep();
        main@preadventure( );
        eat($item[[glitch season reward name]]);
    }
    set_property("hatOverride","");
    step("phase: bulkFK god lobster");
    while (get_property("_godLobsterFights") < 3){
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
    if (get_property("ascensionsToday") == "1" && fullness_limit() - my_fullness() >= 1){
        equip($item[devilbone corset]);
        equip($slot[acc3],$item[angelbone chopsticks]);
        if (fullness_limit() - my_fullness() >= 3)
            eat($item[eldritch mushroom pizza]);
        cli_execute("unequip devilbone corset; unequip angelbone chopsticks");
    }
    step("phase: bulkFK seals");
    seals();
    cli_execute("ptrack add postFK");
    while (get_property("_aprilBandSaxophoneUses").to_int() < 3 && get_property("ascensionsToday") == "0"){
        if (get_property("commaFamiliar") != "Robortender"){
            retrieve_item($item[toggle switch (Bartend)]);
            visit_url("inv_equip.php?which=2&action=equip&whichitem=9402");
            set_property("commaFamiliar","Robortender");
        }
        set_property("subscript","embezzler");
        set_property("maxOverride","meat drop");
        if (have_effect($effect[Lucky!]) == 0){
            getLucky();
            adv1($location[Cobb's knob treasury]);
        }
    }
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
            cli_execute("ptrack add preprep");
            FKPrep();
            cli_execute("ptrack add postprep");
        }
        bulkFK();
    } finally {
        finisher();
    }
}
