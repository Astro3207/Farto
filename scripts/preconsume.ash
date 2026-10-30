import iotm.ash;

void astral(){
    //get salty mouth the night before
    if (item_amount($item[astral six-pack])>0)
        use($item[astral six-pack]);
    if (item_amount($item[astral pilsner]) > 0){
        castATSong($skill[The Ode to Booze]);
        drink(item_amount($item[astral pilsner]), $item[astral pilsner]);
    }
}
void timeArrow(){
    if (to_int(get_property("valueOfAdventure"))*5 > mall_price($item[time's arrow])){
        retrieve_item($item[time's arrow]);
        cli_execute("csend time's arrow to botticelli");
    }
}
void clanAdv(){
    if (to_int(get_property("valueOfAdventure")) > 10000){
        whitelist("Fart Sauce Annex");
        for i from 1 to 15
            visit_url("clan_buytraining.php?action=buyround&members=1&size=1&whichgift=9");
    }
}
// Day-2 Cup of 13s: same Runneth picks as the free-kill run, but each adventure
// an ingredient adds is also worth valueOfAdventure.
void cupOf13s(){
    if (my_inebriety() >= inebriety_limit())
        return;
    drinkCupOf13s(get_property("valueOfAdventure").to_float());
}

void partialConsume(int leaveStomach, int leaveLiver, int leaveSpleen){
    int toEat = fullness_limit() - my_fullness() - leaveStomach;
    int toDrink = inebriety_limit() - my_inebriety() - leaveLiver;
    int toSpleen = spleen_limit() - my_spleen_use() - leaveSpleen;
    cli_execute("CONSUME ORGANS " + max(0,toEat) + " " + max(0,toDrink) + " " + max(0,toSpleen));
}

void yeti(){
    if (get_property("coolerYetiMode") == "adventures"){
        if (my_fullness() < 2)
            cli_execute("CONSUME ORGANS 2 3 0");
        retrieve_item($item[doc clock's thyme cocktail]);
        drink($item[doc clock's thyme cocktail]);
    }
    if ($familiar[cooler yeti].experience <= 400 || get_property("_coolerYetiAdventures") != "false")
        return;
    boolean thymeLeft = get_property("_docClocksThymeCocktailDrunk") == "false";
    if (thymeLeft && my_fullness() < 2)
        cli_execute("CONSUME ORGANS 2 3 0");
    yetiTalk();
    if (thymeLeft)
        drink($item[doc clock's thyme cocktail]);
    else {
        retrieve_item($item[Hodgman's blanket]);
        drink($item[Hodgman's blanket]);
    }
}

// Clear the song / buff effects that shouldn't ride along into the organ fill.
void dropOrganBuffs(){
    foreach ef in $effects[dirge of dreadfulness, Ur-Kel's Aria of Annoyance,Inigo's Incantation of Inspiration]{
        if (have_effect(ef) > 0)
            cli_execute("uneffect "+ef);
    }
}

string [string] saveResourceBackupProp = {
    "_docClocksThymeCocktailDrunk": "pcBackup_docClocksThymeCocktailDrunk",
    "currentMojoFilters": "pcBackup_currentMojoFilters",
    "spiceMelangeUsed": "pcBackup_spiceMelangeUsed",
    "_aug16Cast": "pcBackup_aug16Cast",
    "_mimeArmyShotglassUsed": "pcBackup_mimeArmyShotglassUsed",
    "_sweatOutSomeBoozeUsed": "pcBackup_sweatOutSomeBoozeUsed"
};

void savedResources(){
    foreach prop, backup in saveResourceBackupProp
        set_property(backup, get_property(prop));
    set_property("_docClocksThymeCocktailDrunk","true");
    set_property("currentMojoFilters","3");
    set_property("spiceMelangeUsed","true");
    set_property("_aug16Cast", "true");
    set_property("_mimeArmyShotglassUsed","true");
    set_property("_sweatOutSomeBoozeUsed","3");
}

void unsaveResources(){
    foreach prop, backup in saveResourceBackupProp
        set_property(prop, get_property(backup));
}

void eatSausage(){
    while (get_property("_sausagesEaten").to_int() < 23){
        if (!eat(1,$item[magical sausage]))
            break;
        manaBurn(700);
    }
}

// Day-1 organ expanders, used once each when their daily pref is still "false".
// onlyIfHave: don't buy it, just skip; needsDrunk: only once inebriety > 0.
record dailyUse {
    string pref;
    item it;
    boolean onlyIfHave;
    boolean needsDrunk;
};

dailyUse [int] organExpanders = {
    0: new dailyUse("_borrowedTimeUsed",         $item[borrowed time],           false, false),
    1: new dailyUse("_syntheticDogHairPillUsed", $item[synthetic dog hair pill], true,  false),
    2: new dailyUse("_distentionPillUsed",       $item[distention pill],         true,  true),
    3: new dailyUse("_sweetToothUsed",           $item[sweet tooth],             false, false),
    4: new dailyUse("_voraciTeaUsed",            $item[Cuppa Voraci tea],        false, false),
    5: new dailyUse("_sobrieTeaUsed",            $item[Cuppa Sobrie tea],        false, true)
};

void main(){
    if (dayType() == 0 && get_campground() contains $item[Source Terminal])
        cli_execute("terminal educate digitize.edu; terminal educate extract.edu; terminal enquiry familiar.enq");
    if (my_inebriety() >= inebriety_limit()-1)
        return;
    if (item_amount($item[Mayo Minder&trade;]) > 0 && get_property("mayoMinderSetting") != "")
        use($item[Mayo Minder&trade;]);
    timeArrow();
    clanAdv();
    eatSausage();
    if (dayType() == 1){
        cupOf13s();
        dropOrganBuffs();
        yeti();
        astral();
        if (isFartScauce())
            set_property("valueOfAdventure","9600");
        if (get_property("_borrowedTimeUsed") == "false")
            use($item[borrowed time]);
        partialConsume(0,2,0);
    } else {
        savedResources();
        foreach i, u in organExpanders {
            if (get_property(u.pref) != "false")
                continue;
            if (u.onlyIfHave && item_amount(u.it) == 0)
                continue;
            if (u.needsDrunk && my_inebriety() == 0)
                continue;
            use(u.it);
        }
        dropOrganBuffs();
        if (isFartScauce()){
            if (get_property("bladderMax") == "true")
                set_property("valueOfAdventure","20000");
            else
                set_property("valueOfAdventure","5400");
        }
        if (get_property("_milkOfMagnesiumUsed") == "false")
            cli_execute("CONSUME ORGANS 0 0 0");
        unsaveResources();
    }
}
