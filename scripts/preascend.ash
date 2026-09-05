import iotm.ash;

// ═══ preascend.ash ══════════════════════════════════════════════════════════
// Day-N-of-ascension chore list, run before pulling the ascension trigger at
// the end. This pass is a pure reshape of the old top-to-bottom flat script
// into named phases -- it preserves every guard as-is. One known reentrancy
// gap remains in ascend() (see chat): the `looping` flag is cleared before
// the ascend/afterlife sequence actually completes, and none of the
// visit_url() calls in that sequence check whether an earlier one already
// succeeded. Not fixed here -- ask if you want that addressed separately.

void step(string msg){
    print("PA: " + msg, "blue");
}

// ─── PHASES ──────────────────────────────────────────────────────────────────

// Mood/law-of-averages pass and a nightcap, once not already overdrunk.
void dailyMoodAndNightcap(){
    if (my_inebriety() > inebriety_limit())
        return;
    visit_url("showclan.php?whichclan=" + get_property("homeClanID").to_int() + "&action=joinclan&confirm=on");
    cli_execute("mood apathetic; uneffect cletus");
    if (get_property("lawOfAveragesAvailable") == true)
        use($item[law of averages]);
    use_familiar($familiar[Stooper]);
    equip($item[devilbone rosary]);
    equip($item[angelbone dice]);
    cli_execute("CONSUME NIGHTCAP");
}

// One more stench-airport-ticket farming pass, once today's ticket is spent.
void stenchAirportFarm(){
    if (my_adventures() <= 9 || have_equipped($item[devilbone greaves]))
        return;
    if (get_property("_stenchAirportToday") == "true"){
        cli_execute("garbo ascend -15");
    }
}

// Re-equip the bone gear (idempotent -- no-op if already on) and top off diet.
void equipBonesAndConsume(){
    cli_execute("equip angelbone totem; equip acc1 angelbone chopsticks; equip devilbone corset; equip devilbone greaves; refresh all; CONSUME ALL");
}

// Spend down to the count of unused Grimace Prime maps (so each remaining one
// still covers an adventure), then hand off to mapgrim() for the rest.
void spendGrimacePrimeMaps(){
    int n = item_amount($item[Map to Safety Shelter Grimace Prime]);
    while (my_adventures() > n){
        adv1($location[Shadow Rift (The Misspelled Cemetary)]);
    }
    if (item_amount($item[Map to Safety Shelter Grimace Prime]) > 0){
        mapgrim();
    }
}

void pvpCleanup(){
    int peevp = pvp_attacks_left();
    if (peevp > 0 && count(current_pvp_stances()) > 0){
        cli_execute("PVP_MAB; unequip pants");
    }
}

// Spend down BCZ substat casts while they're still cheaper than the current threshold.
void bczCasts(){
    while (my_basestat($stat[submuscle]) > BCZcost("BloodThinnerCasts"))
        use_skill($skill[BCZ: Create Blood Thinner]);
    while (my_basestat($stat[submoxie]) > BCZcost("PheromoneCocktailCasts"))
        use_skill($skill[BCZ: Craft a Pheromone Cocktail]);
    while (my_basestat($stat[submysticality]) > BCZcost("SpinalTapasCasts"))
        use_skill($skill[BCZ: Prepare Spinal Tapas]);
}

// Spend the day's 5 Monkey's Paw wishes on shadow bricks. Reads
// _monkeyPawWishesUsed fresh each call, so this is safe to resume mid-way.
void monkeyPawWishes(){
    int monkeyWish = to_int(get_property("_monkeyPawWishesUsed"));
    if (monkeyWish < 5 && closet_amount($item[cursed monkey's paw]) > 0){
        cli_execute("closet take cursed monkey's paw");
    }
    switch (monkeyWish){
        case 0:
            cli_execute("monkeypaw item shadow brick");
            monkeyWish += 1;
        case 1:
            cli_execute("monkeypaw item shadow brick");
            monkeyWish += 1;
        case 2:
            cli_execute("monkeypaw item shadow brick");
            monkeyWish += 1;
        case 3:
            cli_execute("monkeypaw item shadow brick");
            monkeyWish += 1;
        case 4:
            cli_execute("monkeypaw item shadow brick");
    }
}

void septEmberCrafting(){
    while (to_int(get_property("availableSeptEmbers")) >= 2){
        cli_execute("make Mmm-brr! brand");
    }
    while (to_int(get_property("availableSeptEmbers")) == 1){
        cli_execute("make wheel of camembert");
    }
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
    while (to_int(get_property("takerSpaceGold")) >= 1 && to_int(get_property("takerSpaceMast")) >= 1
        && to_int(get_property("takerSpaceAnchor")) >= 3 && to_int(get_property("takerSpaceRum")) >= 1){
        cli_execute("make anchor bomb");
    }
    while (to_int(get_property("takerSpaceSpice")) >= 1 && to_int(get_property("takerSpaceRum")) >= 2)
        cli_execute("make tankard of spiced rum");
    while (to_int(get_property("takerSpaceSilk")) >= 2){
        cli_execute("make silky pirate drawers");
    }
    while (to_int(get_property("takerSpaceMast")) >= 2){
        cli_execute("make harpoon");
    }
    while (to_int(get_property("takerSpaceSpice")) >= 1){
        cli_execute("make spices");
    }
    while (to_int(get_property("takerSpaceGold")) >= 1 && to_int(get_property("takerSpaceMast")) >= 1
        && to_int(get_property("takerSpaceAnchor")) >= 3 && to_int(get_property("takerSpaceRum")) >= 1){
        cli_execute("make anchor bomb");
    }
}

// Last odds and ends before the ascend: sweatpants, garden, knife skill,
// once-per-account/day acquires, snapshot, CCS, pearls in the codpiece.
void finalChores(){
    if (to_int(get_property("sweat")) > 50 && my_adventures() == 0){
        use_skill($skill[Make Sweat-Ade]);
    }
    cli_execute("garden pick");
    if (have_skill($skill[That's not a knife]))
        use_skill($skill[That's not a knife]);
    cli_execute("acquire 1 one-day ticket to Dinseylandfill; acquire 1 Calzone of Legend; acquire 1 Deep Dish of Legend; acquire 1 Pizza of Legend; acquire 1 borrowed time; acquire 1 abstraction: category; acquire 1 non-Euclidean angle");
    cli_execute("av-snapshot.ash");
    set_ccs("hobopolis");
    retrieve_item(5, $item[unblemished pearl]);
    codpiece("unblemished pearl,unblemished pearl,unblemished pearl,unblemished pearl,unblemished pearl");
    cli_execute("philter");
    finisher();
}

// Grab a PYEC (automatically if `looping` was left set, otherwise ask) and
// pull the actual ascension trigger. NOTE: `looping` is cleared before the
// ascend/afterlife sequence below actually completes, and none of the
// visit_url() calls check whether an earlier one already succeeded -- both
// carried over unchanged from the original script (see chat).
void ascend(){
    if (get_property("looping") == "true"){
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
    } else if (user_confirm("Grab PYEC?")){
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
        set_property("garbo_valueOfFreeFight","6001");
        visit_url("ascend.php?action=ascend&confirm=on&confirm2=on");
        visit_url("afterlife.php?action=pearlygates");
        visit_url("afterlife.php?place=deli");
        visit_url("afterlife.php?action=buydeli&whichitem=5046");
        visit_url("afterlife.php?action=ascend&asctype=2&whichclass=1&gender=1&whichpath=55&whichsign=8");
        visit_url("afterlife.php?action=ascend&confirmascend=1&whichsign=8&gender=1&whichclass=1&whichpath=55&asctype=2&lamesignok=1&nopetok=1");
        visit_url("main.php");
        run_choice(-1);
    }
}

// ─── ENTRY ───────────────────────────────────────────────────────────────────

void main(){
    step("phase: mood/nightcap");
    dailyMoodAndNightcap();
    step("phase: burn semi useful overdrunk turns at barf");
    stenchAirportFarm();
    step("phase: finish nightcapping");
    equipBonesAndConsume();
    step("phase: grimace prime maps");
    spendGrimacePrimeMaps();
    step("phase: pvp");
    pvpCleanup();
    step("phase: other iotm todos");
    bczCasts();
    monkeyPawWishes();
    septEmberCrafting();
    workshedSetup();
    step("phase: ascension prep");
    finalChores();
    step("phase: ascend");
    ascend();
}
