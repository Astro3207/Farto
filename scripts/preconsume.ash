void astral(){
    //get salty mouth the night before
    if (item_amount($item[astral six-pack])>0){
        use($item[astral six-pack]);
    }
    if (item_amount($item[astral pilsner]) > 0){
        cli_execute("cast ode");
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
        cli_execute("/whitelist fart sauce annex");
        int n;
        repeat {
            visit_url("clan_buytraining.php?action=buyround&members=1&size=1&whichgift=9");
            n += 1;
        } until (n>=15);
    }
}
void cupOf13s(){
    if (get_property("_cupOf13sJewels") == 13){
        if (to_int(get_property("valueOfAdventure")) > 10000){
            if (closet_amount($item[eelskin shield]) > 2){
                take_closet($item[eelskin shield]);
            }
            cli_execute("acquire 2 WA");
            visit_url("inventory.php?action=cupof13s");
            visit_url("choice.php?option=1&whichchoice=1601&"+my_hash()+"&whichitem1=3519&whichitem2=623&whichitem3=623");
        } else {
            cli_execute("make 6 asbestos meat stack");
            visit_url("inventory.php?action=cupof13s");
            visit_url("choice.php?option=1&whichchoice=1601&"+my_hash()+"&whichitem1=376&whichitem2=376&whichitem3=376");
            visit_url("inventory.php?action=cupof13s");
            visit_url("choice.php?option=1&whichchoice=1601&"+my_hash()+"&whichitem1=376&whichitem2=376&whichitem3=376");
        }
    }
}
void partialConsume(int leaveStomach, int leaveLiver, int leaveSpleen){
    int toEat = fullness_limit() - my_fullness() - leaveStomach;
    int toDrink = inebriety_limit() - my_inebriety() - leaveLiver;
    int toSpleen = spleen_limit() - my_spleen_use() - leaveSpleen;
    cli_execute("CONSUME ORGANS " + max(0,toEat) + " " + max(0,toDrink) + " " + max(0,toSpleen));
}
void yeti(){
    if ($familiar[cooler yeti].experience > 400 && get_property("_coolerYetiAdventures") == "false"){
        cli_execute("CONSUME ORGANS 2 3 0");
        use_familiar($familiar[cooler yeti]);
        visit_url("main.php?talktoyeti=1", false);    
        run_choice(2);
        cli_execute("drink doc clock's t");
    }
}
void legendaryPasta(){
    if (get_property("_legendaryNoodlesSpleen") == false){
        set_property("choiceAdventure1599","1");
        item [item] pastaIngredient = {
            $item[hot honey ant]:$item[Formica e Pepe],
            $item[tomb aspic]:$item[Tubetto Gelatto],
            $item[later tots]:$item[Gnocci Domani]
        };
        item cheap_pasta;
        int lowest_value = 999999999;

        foreach it in pastaIngredient {
            if (it.mall_price() < lowest_value) {
                lowest_value = it.mall_price();
                cheap_pasta = pastaIngredient[it];
            }
        }
        use($item[mini kiwi aioli]);
        eat(cheap_pasta);
    }
}

string organType(item it){
    if (it.fullness > 0)
        return "fullness";
    if (it.inebriety > 0)
        return "inebriety";
    if (it.spleen > 0)
        return "spleen";
    return "none";
}

float expectedAdventures(item it){
    string range = it.adventures;
    if (range == "")
        return 0.0;
    if (!range.contains_text("-"))
        return range.to_float();
    string [int] bounds = split_string(range, "-");
    return (bounds[0].to_float() + bounds[1].to_float()) / 2.0;
}

int costPerAdv(item it){
    if (organType(it) == "none"){
        print("a none food item");
        return 0;
    } else {
        if (organType(it) == "inebriety")
            return (mall_price(it)/expectedAdventures(it)/it.inebriety);
        if (organType(it) == "fullness")
            return (mall_price(it)/expectedAdventures(it)/it.fullness);
        if (organType(it) == "spleen")
            return (mall_price(it)/expectedAdventures(it)/it.spleen);
    }
    return 0;
}

// savedResources() marks these four dailies as already-used so nothing else
// tries to spend them mid-run. unsaveResources() is supposed to give them
// back afterward, but resetting straight to a fixed "unused" value is only
// correct if they actually were unused before savedResources() ran -- if
// e.g. _aug16Cast was already "true" for the day, blindly clearing it back
// to "false" would lie about that resource being available again. Record
// the real prior value in a backup pref before overwriting, and restore
// that instead of a fixed default.
string [string] saveResourceBackupProp = {
    "_docClocksThymeCocktailDrunk": "pcBackup_docClocksThymeCocktailDrunk",
    "currentMojoFilters": "pcBackup_currentMojoFilters",
    "spiceMelangeUsed": "pcBackup_spiceMelangeUsed",
    "_aug16Cast": "pcBackup_aug16Cast"
};

void savedResources(){
    foreach prop, backup in saveResourceBackupProp
        set_property(backup, get_property(prop));
    set_property("_docClocksThymeCocktailDrunk","true");
    set_property("currentMojoFilters","3");
    set_property("spiceMelangeUsed","true");
    set_property("_aug16Cast", "true");
}

void unsaveResources(){
    foreach prop, backup in saveResourceBackupProp
        set_property(prop, get_property(backup));
}

boolean littleMore(){
    savedResources();
    cli_execute("CONSUME ORGANS 0 5 0");
    unsaveResources();
    return true;
}

void main(){
 //   legendaryPasta();
    cupOf13s();
    timeArrow();
    clanAdv();
    if (get_property("ascensionsToday") == 0){
        astral();
        yeti();
        if (get_property("_borrowedTimeUsed") == false){
        //    use($item[borrowed time]);
        }
        partialConsume(0,1,0);
    } else {
        savedResources();
        cli_execute("CONSUME ORGANS 1 0 0");
    //    partialConsume(10,10,15);
        unsaveResources();
    }
}
