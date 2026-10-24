import iotm.ash;

// ═══ breakfast.ash ══════════════════════════════════════════════════════════
// Start-of-day chores

void step(string msg){
    print("BF: " + msg, "blue");
}

void dailyUpdate(){
    if (get_property("_gitUpdated").to_boolean())
        return;
    cli_execute("git update");
    if (isFartScauce())
        cli_execute("stock_market");
}

void takerSpace(){
    if (get_property("_workshedItemUsed").to_boolean() || get_workshed() != $item[TakerSpace letter of Marque])
        return;
    if (get_property("takerSpaceGold").to_int() >= 1 && get_property("takerSpaceMast").to_int() >= 1
        && get_property("takerSpaceAnchor").to_int() >= 3 && get_property("takerSpaceRum").to_int() >= 1)
        create($item[anchor bomb]);
    if (get_property("takerSpaceSpice").to_int() >= 1 && get_property("takerSpaceRum").to_int() >= 2)
        create($item[tankard of spiced rum]);
    while (get_property("takerSpaceMast").to_int() >= 2)
        if (!create($item[harpoon]))
            break;
    while (get_property("takerSpaceSpice").to_int() >= 1)
        if (!create($item[spices]))
            break;
    if (available_amount($item[model train set]) > 0)
        use($item[model train set]);
}

void clanBreakfasts(){
    if (get_property("_chipBags").to_int() < 3){
        whitelist("Bonus Adventures from Hell");
        cli_execute("breakfast; chips radium; chips wintergreen; chips ennui");
        visit_url("clan_rumpus.php?action=click&spot=5&furni=1");
    }
    if (get_property("_clanRumpusSpot3Visited") == "false"){
        whitelist("Fart Sauce Annex");
        cli_execute("breakfast");
    }
    whitelist("homeclan");
}

void photoBooth(){
    if (get_property("_photoBoothEquipment").to_int() != 0)
        return;
    whitelist("Bonus Adventures from Hell");
    foreach part in $strings[Sheriff badge, Sheriff pistol, Sheriff moustache]
        cli_execute("photobooth item " + part);
    whitelist("homeclan");
}

void perilsForeseen(){
    if (!isFartScauce() || get_property("_perilsForeseen").to_int() != 0)
        return;
    codpiece("none");
    visit_url("inventory.php?action=foresee");
    foreach who in $ints[2463557, 1197090, 4409, 2456712]
        visit_url("choice.php?whichchoice=1558&option=1&who=" + who);
}

void spookyTapes(){
    int credits = get_property("availableMrStore2002Credits").to_int();
    if (credits > 0)
        create(credits, $item[Spooky VHS Tape]);
}

void alliedRadio(){
    if (!have_item($item[Allied Radio Backpack]) || get_property("_alliedRadioDropsUsed").to_int() >= 3)
        return;
    visit_url("inventory.php?action=requestdrop");
    while (get_property("_alliedRadioDropsUsed").to_int() < 3){
        int used = get_property("_alliedRadioDropsUsed").to_int();
        visit_url("choice.php?request=radio&whichchoice=1561&option=1");
        if (get_property("_alliedRadioDropsUsed").to_int() == used)
            return;
    }
}

void unaccompaniedMiner(){
    if (!have_skill($skill[Unaccompanied Miner]))
        return;
    int fruitlessResets;
    while (get_property("_unaccompaniedMinerUsed").to_int() < 5){
        cli_execute("acquire miner's helmet; acquire 7-Foot Dwarven mattock; acquire miner's pants");
        cli_execute("outfit mining gear");
        if (my_hp() == 0)
            cli_execute("restore hp");
        string wall = visit_url("mining.php?intro=1&mine=1");
        matcher chunk = create_matcher(
            "(?i)which=(\\d+)(?:(?!</a>)[\\s\\S]){0,200}?promising chunk of wall", wall);
        if (chunk.find()){
            visit_url("mining.php?mine=1&which=" + chunk.group(1));
            fruitlessResets = 0;
        } else {
            visit_url("mining.php?mine=1&reset=1");
            fruitlessResets += 1;
            if (fruitlessResets >= 20){
                print("BF: unaccompaniedMiner: 20 resets with no reachable chunk, giving up", "red");
                return;
            }
        }
    }
}

void healUp(){
    if (have_effect($effect[Beaten Up]) > 0)
        cli_execute("cast tongue of the walrus; cast cannelloni cocoon");
}

void stillsuit(){
    if (!have_item($item[tiny stillsuit]) || !have_familiar($familiar[tickle-me emilio]))
        return;
    use_familiar($familiar[tickle-me emilio]);
    equip($item[tiny stillsuit]);
}

void grabAccessories(){
    foreach it in $items[mother's necklace, pearl diver's necklace, giant yellow hat, perfume-soaked bandana,filthy knitted dread sack, mini kiwi bikini]
        retrieve_item(it);
}

void mayamRings(){
    if (get_property("_mayamSymbolsUsed") != "" || !have_item($item[Mayam Calendar]))
        return;
    if (have_familiar($familiar[Chest Mimic]))
        use_familiar($familiar[Chest Mimic]);
    cli_execute("mayam rings vessel yam cheese explosion;"
        + " mayam rings fur lightning eyepatch yam;"
        + " mayam rings eye meat yam clock");
}

void unlockLocations(){
    if (available_amount($item[continuum transfunctioner]) == 0){
        visit_url("place.php?whichplace=forestvillage&action=fv_mystic");
        run_choice(-1);
    }
    if (get_property("questM23Meatsmith") == "unstarted"){
        visit_url("shop.php?whichshop=meatsmith&action=talk");
        run_choice(1);
    }
    if (get_property("questM25Armorer") == "unstarted"){
        visit_url("shop.php?whichshop=armory&action=talk");
        run_choice(1);
    }
    if (get_property("questM24Doc") == "unstarted"){
        visit_url("shop.php?whichshop=doc&action=talk");
        run_choice(1);
    }
    if (get_property("questM19Hippy") == "unstarted"){
        visit_url("place.php?whichplace=woods&action=woods_smokesignals");
        run_choice(1);
        run_choice(2);
    }
    if (get_property("questM22Shirt") == "unstarted")
        use($item[Letter for Melvign the Gnome]);
    if (get_property("questL08Trapper") == "started")
        visit_url("place.php?whichplace=mclargehuge&action=trappercabin");
    if (get_property("questL04Bat") == "started"){
        use(2, $item[sonar-in-a-biscuit]);
        equip($slot[acc1],$item[spring shoes]);
        use($item[enchanted bean]);
    }
}

void makeSausage(){
    if (!have_item($item[Kramco Sausage-o-Matic&trade;]))
        return;
    while (get_property("_sausagesMade").to_int() < 23){
        while (get_property("sausageGrinderUnits").to_int() < 3000){
            retrieve_item(3,$item[dense meat stack]);
            visit_url("inventory.php?action=grind");
            visit_url("choice.php?pwd="+ my_hash() +"&whichchoice=1339&option=1&qty=3&iid=258");
        }
        visit_url("inventory.php?action=grind");
        visit_url("choice.php?pwd="+ my_hash() +"&whichchoice=1339&option=2");
    }
}

void pantogram(){
    if (available_amount($item[portable pantogram]) > 0 && dayType() == 1 && get_property("_pantogramModifier") == ""){
        retrieve_item(11,$item[lead necklace]);
        retrieve_item(1,$item[porquoise]);
        visit_url("inv_use.php?whichitem=9573");
        visit_url("choice.php?whichchoice=1270&pwd="+my_hash()+"&option=1&m=3&e=2&s1=-1,0&s2=706,1&s3=865,11");
    }
}

void dailySkills(){
    foreach sk in $skills[Lunch Break, Spaghetti Breakfast, Grab a Cold One,
        Summon Kokomo Resort Pass, Perfect Freeze, Acquire Rhinestones,
        Prevent Scurvy and Sobriety, That's Not a Knife,Bowl Full of Jelly,Eye and a Twist,Chubby and Plump]{
        if (have_skill(sk))
            use_skill(sk);
    }
}

void glitchItem(){
    if (!get_property("_glitchItemImplemented").to_boolean() && available_amount($item[[glitch season reward name]]) > 0)
        use($item[[glitch season reward name]]);
}

void votingBooth(){
    if (have_item($item[&quot;I Voted!&quot; sticker]))
        return;
    if (have_item($item[voter registration form])){
        use($item[voter registration form]);
    } else {
        retrieve_item($item[absentee voter ballot]);
        use($item[absentee voter ballot]);
    }
}

void aprilShower(){
    if (!get_property("_aprilShower").to_boolean())
        cli_execute("shower cold");
}

void burningLeaves(){
    while (get_property("_leafLassosCrafted").to_int() < 3){
        if (!create($item[lit leaf lasso]))
            break;
    }
    if (!get_property("_leafDayShortenerCrafted").to_boolean())
        create($item[day shortener]);
}

void candyRichBlock(){
    boolean mapUsed = get_property("_mapToACandyRichBlockUsed").to_boolean();
    if (!mapUsed)
        use($item[Map to a candy-rich block]);
    if (mapUsed && !contains_text(get_property("_trickOrTreatBlock"), "L"))
        return;
    if (have_outfit("Ceramic Suit"))
        cli_execute("outfit Ceramic Suit");
    else if (have_outfit("Eldritch Equipage"))
        cli_execute("outfit Eldritch Equipage");
    else
        abort("Don't have the right outfit for trick or treating. Let FS know to find a different one");
    candy("treat");
}

void speakeasyPool(){
    if (get_property("_speakeasyPool") != "true"){
        cli_execute("maximize pool skill");
        visit_url("place.php?whichplace=speakeasy&action=olivers_pooltable");
        set_property("_speakeasyPool","true");
    }
}

void printScreenButton(){
    if (get_property("_internetPrintScreenButtonBought") == "false")
        create($item[print screen button]);
}

void devilCandyEggs(){
    while (get_property("_candyEggsDeviled").to_int() < 3){
        int made = get_property("_candyEggsDeviled").to_int();
        cli_execute("devilcandyegg daffy taffy");
        if (get_property("_candyEggsDeviled").to_int() == made)
            return;
    }
}

void netiPot(){
    if (!get_property("_porkElfNetiPotUsed").to_boolean() && available_amount($item[Pork Elf neti pot]) > 0)
        use($item[Pork Elf neti pot]);
}

void mummeryMeat(){
    if (!have_item($item[mumming trunk]))
        return;
    if (contains_text(get_property("_mummeryMods"), "Meat Drop"))
        return;
    if (have_familiar($familiar[robortender]))
        use_familiar($familiar[robortender]);
    else if (have_familiar($familiar[comma chameleon]))
        use_familiar($familiar[comma chameleon]);
    else
        return;
    cli_execute("mummery meat");
}

void firstBreakfast(){
    step("phase: daily update");
    dailyUpdate();
    takerSpace();
    clanBreakfasts();
    unlockLocations();
    makeSausage();
    if (my_garden_type( ) != "black_rose")
        cli_execute("garden pick");
    photoBooth();
    pantogram();
    perilsForeseen();
    spookyTapes();
    alliedRadio();
    if (have_item($item[SongBoom&trade; BoomBox]) && get_property("boomBoxSong") != "Total Eclipse of Your Meat")
        use($item[SongBoom&trade; BoomBox]);

    step("phase: unaccompanied miner");
    unaccompaniedMiner();

    healUp();
    stillsuit();
    grabAccessories();
    mayamRings();
    step("phase: daily skills");
    dailySkills();
    glitchItem();
    votingBooth();
    step("phase: clan fortune");
    clanFortune();
    aprilShower();
    speakeasyPool();
    printScreenButton();
    burningLeaves();
    candyRichBlock();
    aprilBand();
    mummeryMeat();
    devilCandyEggs();
    netiPot();
}

// ─── ENTRY ───────────────────────────────────────────────────────────────────

void main(){
    step("phase: breakfast");
    firstBreakfast();
}
