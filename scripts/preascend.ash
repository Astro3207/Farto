import iotm.ash;

// ═══ preascend.ash ══════════════════════════════════════════════════════════

void step(string msg){
    print("PA: " + msg, "blue");
}

// ─── PHASES ──────────────────────────────────────────────────────────────────

// Mood/law-of-averages pass and a nightcap, once not already overdrunk.
void Nightcap(){
    if (my_inebriety() > inebriety_limit())
        return;
    whitelist("homeclan");
    cli_execute("mood apathetic; uneffect cletus");
    if (get_property("lawOfAveragesAvailable").to_boolean())
        use($item[law of averages]);
    use_familiar($familiar[Stooper]);
    equip($slot[acc3],$item[devilbone rosary]);
    equip($slot[acc2],$item[angelbone dice]);
    cli_execute("CONSUME NIGHTCAP");
    cli_execute("unequip devilbone rosary; unequip angelbone dice");
    equip($item[drunkula's wineglass]);
}

// One overdrunk Marinara Trench turn with the wineglass on; the caller picks the familiar.
void trenchTurn(){
    set_property("maxOverride","3.25 meat drop, 7 item drop, sea");
    set_property("offOverride",", equip drunkula's wineglass");
    adv1($location[The Marinara Trench],0,"");
}

void drunkInko(){
    if (have_equipped($item[angelbone totem]))
        return;
    starter();
    set_property("script","farto");
    while (my_adventures() > 0){
        altFam($familiar[robortender]);
        trenchTurn();
    }
}

// Re-equip the bone gear (idempotent -- no-op if already on) and top off diet.
void equipBonesAndConsume(){
    cli_execute("equip angelbone totem; equip acc1 angelbone chopsticks; equip devilbone corset; equip devilbone greaves; CONSUME ALL");
}

// Spend down to the count of unused Grimace Prime maps (so each remaining one
// still covers an adventure), then hand off to mapgrim() for the rest.
void spendGrimacePrimeMaps(){
    equip($item[drunkula's wineglass]);
    equip($item[angelbone totem]);
    int n = item_amount($item[Map to Safety Shelter Grimace Prime]);
    while (my_adventures() > n){
        if (!pearlsDone()){
            if (!get_property("_unblemishedPearlDiveBar").to_boolean()){
                set_property("maxOverride","sleaze resistance");
                adv1($location[The Dive Bar]);
            } else {
                abort();
            }
        } else if (get_property("farmKnucklebones").to_boolean() == true){
            set_property("famOverride","skeleton of crimbo past");
            set_property("maxOverride","drops items");
            adv1($location[the skeleton store]);
        } else {
            // One turn per pass: the outer loop stops at n so the maps keep their adventures.
            if (have_familiar($familiar[robortender]))
                set_property("famOverride","robortender");
            else if (get_property("commaFamiliar") == "Robortender")
                set_property("famOverride","comma chameleon");
            else
                set_property("famOverride","sword of Swords");
            trenchTurn();
        }
    }
    finisher();
    if (item_amount($item[Map to Safety Shelter Grimace Prime]) > 0)
        mapgrim();
}

// Spend the remaining PvP fights while a season is running.
void pvpFights(){
    int peevp = pvp_attacks_left();
    if (peevp > 0 && count(current_pvp_stances()) > 0){
        cli_execute("PVP_MAB; unequip pants");
    }
}

// Cast sk while the substat still covers its next BCZ cost; stops if a cast fails
// or doesn't spend any substat.
void bczSpend(stat sub, string castsPref, skill sk){
    while (my_basestat(sub) > BCZcost(castsPref)){
        int before = my_basestat(sub);
        if (!use_skill(sk, 1) || my_basestat(sub) >= before)
            break;
    }
}

// Spend down BCZ substat casts while they're still cheaper than the current threshold.
void bczCasts(){
    bczSpend($stat[submuscle],      "BloodThinnerCasts",      $skill[BCZ: Create Blood Thinner]);
    bczSpend($stat[submoxie],       "PheromoneCocktailCasts", $skill[BCZ: Craft a Pheromone Cocktail]);
    bczSpend($stat[submysticality], "SpinalTapasCasts",       $skill[BCZ: Prepare Spinal Tapas]);
}

// Spend the day's 5 Monkey's Paw wishes on shadow bricks. Reads
// _monkeyPawWishesUsed fresh each call, so this is safe to resume mid-way.
void monkeyPawWishes(){
    int monkeyWish = to_int(get_property("_monkeyPawWishesUsed"));
    if (monkeyWish < 5 && closet_amount($item[cursed monkey's paw]) > 0){
        cli_execute("closet take cursed monkey's paw");
    }
    while (get_property("_monkeyPawWishesUsed").to_int() < 5){
        int before = get_property("_monkeyPawWishesUsed").to_int();
        cli_execute("monkeypaw item shadow brick");
        if (get_property("_monkeyPawWishesUsed").to_int() <= before)
            break;
    }
}

void septEmberCrafting(){
    while (to_int(get_property("availableSeptEmbers")) >= 2){
        int before = to_int(get_property("availableSeptEmbers"));
        cli_execute("make Mmm-brr! brand");
        if (to_int(get_property("availableSeptEmbers")) >= before)
            break;
    }
    if (to_int(get_property("availableSeptEmbers")) == 1)
        cli_execute("make wheel of camembert");
}

// Accordion Thieves burn the LP-ROM; everyone else runs the TakerSpace
// crafting queue (one-shot at rollover) before handing the workshed over.
void workshedSetup(){
    if (my_class() == $class[accordion thief]){
        if (get_property("_workshedItemUsed") == "false" && get_workshed() != $item[warbear LP-ROM burner])
            use($item[warbear LP-ROM burner]);
        return;
    }
    if (get_property("_workshedItemUsed") == "false" && item_amount($item[TakerSpace letter of Marque]) > 0)
        cli_execute("use takerspace");
    if (get_workshed() != $item[TakerSpace letter of Marque])
        return;
    visit_url("campground.php?action=workshed");
    // Each loop bails on the first failed craft instead of spinning if a
    // sub-ingredient runs out mid-run (the takerSpace* prefs wouldn't move).
    while (to_int(get_property("takerSpaceGold")) >= 1 && to_int(get_property("takerSpaceMast")) >= 1
        && to_int(get_property("takerSpaceAnchor")) >= 3 && to_int(get_property("takerSpaceRum")) >= 1){
        if (!create($item[anchor bomb])) break;
    }
    while (to_int(get_property("takerSpaceSpice")) >= 1 && to_int(get_property("takerSpaceRum")) >= 2){
        if (!create($item[tankard of spiced rum])) break;
    }
    while (to_int(get_property("takerSpaceSilk")) >= 2){
        if (!create($item[silky pirate drawers])) break;
    }
    while (to_int(get_property("takerSpaceMast")) >= 2){
        if (!create($item[harpoon])) break;
    }
    while (to_int(get_property("takerSpaceSpice")) >= 1){
        if (!create($item[spices])) break;
    }
}

// Last odds and ends before the ascend: sweatpants, garden, knife skill,
// once-per-account/day acquires, snapshot, CCS, pearls in the codpiece.
void finalChores(){
    if (to_int(get_property("sweat")) > 50 && my_adventures() == 0){
        use_skill($skill[Make Sweat-Ade]);
    }
    if (item_amount($item[interesting coin]) == 7){
        create($item[Roth IPA]);
        create($item[homeowner's loam]);
    }
    cli_execute("garden pick");
    if (have_item($item[packet of rock seeds]))
        use($item[packet of rock seeds]);
    cli_execute("garden pick");
    if (have_skill($skill[That's not a knife]))
        use_skill($skill[That's not a knife]);
    cli_execute("av-snapshot.ash");
    set_ccs("hobopolis");
    retrieve_item(5, $item[unblemished pearl]);
    codpiece("unblemished pearl,unblemished pearl,unblemished pearl,unblemished pearl,unblemished pearl");
}

// Grab a PYEC (automatically if `looping` was left set, otherwise ask) and
// pull the actual ascension trigger. NOTE: `looping` is cleared before the
// ascend/afterlife sequence below actually completes, and none of the
// visit_url() calls check whether an earlier one already succeeded -- both
// carried over unchanged from the original script (see chat).
void ascend(){
    set_property("postAscensionScript","postascend.ash");
    if (get_property("looping") == "true"){
        cli_execute("acquire 1 one-day ticket to Dinseylandfill; acquire 1 Calzone of Legend; acquire 1 Deep Dish of Legend; acquire 1 Pizza of Legend; acquire 1 borrowed time; acquire 1 abstraction: category");
        set_property("looping","false");
        visit_url("showclan.php?whichclan=2047009940&action=joinclan&confirm=on");
        take_stash(1,$item[Platinum Yendorian Express Card]);
        visit_url("showclan.php?whichclan=" + get_property("homeClanID").to_int() + "&action=joinclan&confirm=on");
        visit_url("ascend.php?action=ascend&confirm=on&confirm2=on");
        visit_url("afterlife.php?action=pearlygates");
        visit_url("afterlife.php?place=deli");
        visit_url("afterlife.php?action=buydeli&whichitem=5046");
        visit_url("afterlife.php?action=ascend&asctype=2&whichclass=6&gender=1&whichpath=55&whichsign=8");
        visit_url("afterlife.php?action=ascend&confirmascend=1&whichsign=8&gender=1&whichclass=6&whichpath=55&asctype=2&lamesignok=1&nopetok=1");
        visit_url("main.php");
        run_choice(-1);
    } else if (isFartScauce() && get_property("runType") == "world event" && user_confirm("Grab PYEC?")){
        visit_url("showclan.php?whichclan=2047009940&action=joinclan&confirm=on");
        take_stash(1,$item[Platinum Yendorian Express Card]);
        set_property("garbo_valueOfFreeFight","1000");
        visit_url("showclan.php?whichclan=" + get_property("homeClanID").to_int() + "&action=joinclan&confirm=on");
        visit_url("ascend.php?action=ascend&confirm=on&confirm2=on");
        visit_url("afterlife.php?action=pearlygates");
        visit_url("afterlife.php?place=deli");
        visit_url("afterlife.php?action=buydeli&whichitem=5046");
        visit_url("afterlife.php?action=ascend&asctype=2&whichclass=6&gender=1&whichpath=55&whichsign=8");
        visit_url("afterlife.php?action=ascend&confirmascend=1&whichsign=8&gender=1&whichclass=6&whichpath=55&asctype=2&lamesignok=1&nopetok=1");
        visit_url("main.php");
        run_choice(-1);
    } else {
        set_property("garbo_valueOfFreeFight",get_property("valueOfAdventure").to_int() + 1);
        visit_url("ascend.php?action=ascend&confirm=on&confirm2=on");
        visit_url("afterlife.php?action=pearlygates");
        visit_url("afterlife.php?place=deli");
        visit_url("afterlife.php?action=buydeli&whichitem=5046");
        visit_url("afterlife.php?action=ascend&asctype=2&whichclass=1&gender=1&whichpath=55&whichsign=4");
        visit_url("afterlife.php?action=ascend&confirmascend=1&whichsign=4&gender=1&whichclass=1&whichpath=55&asctype=2&lamesignok=1&nopetok=1");
        visit_url("main.php");
        run_choice(-1);
    }
}

// ─── ENTRY ───────────────────────────────────────────────────────────────────

void main(){
    starter();
    step("phase: Organ phase 1");
    if (isFartScauce())
        set_property("valueOfAdventure","7400");
    step("phase: nightcap");
    Nightcap();
    ptrackOnce("overdrunkStart");
    drunkInko();
    ptrackOnce("overdrunkEnd");
    if (isFartScauce())
        set_property("valueOfAdventure","7100");
    equipBonesAndConsume();
    ptrackOnce("overorganStart");
    try {
        step("phase: over Organed");
        spendGrimacePrimeMaps();
    } finally {
        finisher();
    }
    ptrackOnce("overorganEnd");
    step("phase: pvp");
    pvpFights();
    step("phase: other iotm todos");
    bczCasts();
    monkeyPawWishes();
    septEmberCrafting();
    workshedSetup();
    step("phase: ascension prep");
    finalChores();
    ptrackOnce("postFarmD2");
    step("phase: ascend");
    ascend();
}
