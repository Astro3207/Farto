import iotm;

void stashgrab(item it){
    visit_url("showclan.php?whichclan=2047009940&action=joinclan&confirm=on");
    if (stash_amount(it) > 0)
        take_stash(it, 1 );
    visit_url("showclan.php?whichclan=72876&action=joinclan&confirm=on");
    if (get_property("_clanFortuneConsultUses") == 0){
        cli_execute("/whitelist Bonus Adventures from Hell");
        cli_execute("/whitelist Hyrule");
    }
}

void stashreturn(item it){
    visit_url("showclan.php?whichclan=2047009940&action=joinclan&confirm=on");
    cli_execute("unequip "+ it);
    if (available_amount(it) > 0)
        put_stash(it, 1 );
    visit_url("showclan.php?whichclan=72876&action=joinclan&confirm=on");
}

int total_power(){
    int n;
    foreach sl in $slots[hat,shirt,pants]{
        n += get_power(equipped_item(sl));
    }
    return n;
}

void beretBusking(){
    if (get_property("_beretBuskingUses") == 0){
        cli_execute("equip prismatic beret, conquistador's breastplate, lynyrdskin breeches");
        if (total_power() == 440){
            use_skill($skill[ Beret Busking]);
        } else {
            abort("Beret abort");
        }
    }
    if (get_property("_beretBuskingUses") == 1){
        cli_execute("equip Private Pepper's Lonely Hearts Club Jacket,Warms-Your-Tush");
        if (total_power() == 750){
            use_skill($skill[ Beret Busking]);
        } else {
            abort("Beret abort");
        }
    }
    if (get_property("_beretBuskingUses") == 2){
        cli_execute("equip duct tape shirt,alpha-mail pants");
        if (total_power() == 495){
            use_skill($skill[ Beret Busking]);
        } else {
            abort("Beret abort");
        }
    }
    if (get_property("_beretBuskingUses") == 3){
        cli_execute("equip SMOOCH breastplate,dubious loincloth");
        if (total_power() == 575){
            use_skill($skill[ Beret Busking]);
        } else {
            abort("Beret abort");
        }
    }
    if (get_property("_beretBuskingUses") == 4){
        cli_execute("equip duct tape shirt,dubious loincloth");
        if (total_power() == 665){
            use_skill($skill[ Beret Busking]);
        } else {
            abort("Beret abort");
        }
    }
}

void zoneOpening(){
    //crackpock mystic

}

void chibibuddy(){

}

void zatara(){
    visit_url("showclan.php?whichclan=90485&action=joinclan&confirm=on");
    cli_execute("fortune onlyfax pizza batman thick");
    cli_execute("fortune onlyfax pizza batman thick");
    cli_execute("fortune onlyfax pizza batman thick");
    visit_url("showclan.php?whichclan=72876&action=joinclan&confirm=on");
}

void IVoted(){
    //Price check? Probably worth it anyway if I get S word into the mix
}

void secondBreakfast(){
    foreach sk in $skills[Lunch Break,Spaghetti Breakfast,Grab a Cold One,Summon Kokomo Resort Pass,Perfect Freeze,Acquire Rhinestones,Prevent Scurvy and Sobriety,Aug. 24th: Waffle Day]
        use_skill(sk);
    if (get_property("_glitchItemImplemented") == false)
        use($item[glitch season reward name]);
    if (get_property("_clanFortuneConsultUses") == "0")
        zatara();
    if (get_property("_aprilShower") == false)
        cli_execute("shower hot");
    while (to_int(get_property("_leafLassosCrafted")) < 3)
        create($item[lit leaf lasso]);
    if (get_property("_leafDayShortenerCrafted") == "false")
        create($item[day shortener]);
    if (get_property("_mapToACandyRichBlockUsed") == false || contains_text(get_property("_trickOrTreatBlock"),"L")) {
        cli_execute("outfit Ceramic Suit");
        candy("treat");
    }

    //shrunken head the plastered frat orc
    //s Word target
}

void FKPrep(){
    //chibibuddy can be handled by garbo tbh
    beretBusking();
    foreach it in $items[defective Game Grid token,BittyCar MeatCar]{
        stashgrab(it);
        if (have_item(it))
            use(it);
        stashreturn(it);   
    }
    if (get_property("_glennGoldenDiceUsed") == "false")   
        use($item[Glenn's golden dice]);
    while (to_int(get_property("_poolGames")) < 3)
        cli_execute("pooL 1");
    if (get_property("friarsBlessingReceived") == "false")
        cli_execute("friars blessing 2");
    if (get_property("_portableSteamUnitUsed") == false)
        cli_execute("use portable steam unit");
    if (get_property("_madTeaParty") == "false")
        cli_execute("hatter filthy knitted dread sack");


}

void bulkFK(){

}

//order of second breakfast

void garbo(){
    set_property("maxOverride", "2.5 Meat Drop,0.72 Item Drop");
    if (have_effect($effect[Citizen of a Zone]) == 0){
        set_property("famOverride","patriotic eagle");
    } else if (get_property("_cookbookbatQuestIngredient") != "Yeast of Boris"){
        set_property("famOverride","cookbookbat");
    } else {
        set_property("famOverride","");
    }
    if (!contains_text(get_property("trackedMonsters"),"garbage tourist:McHugeLarge Slash") && to_int(get_property("_knuckleboneDrops")) == 100){
        set_property("offOverride",", equip McHugeLarge left pole");
        set_property("acc1Override",", equip peridot of peril");
    } else if (!contains_text(get_property("trackedMonsters"),"angry tourist:McHugeLarge Slash") && to_int(get_property("_knuckleboneDrops")) < 100){
        set_property("offOverride",", equip McHugeLarge left pole");
    } else {
        set_property("offOverride","");
        set_property("acc1Override","");
    }
    if (!everfullReady()) {
        set_property("acc1Override",", equip everfull dart holster");
    } else {
        set_property("acc1Override","");
    }
    if (to_int(get_property("_pantsgivingCount")) >= 500){
        if (available_amount($item[pantsgiving]) > 0)
            stashreturn($item[pantsgiving]);
        if (my_fullness() < fullness_limit())
            cli_execute("CONSUME ALL");
    }
    adv1($location[barf mountain],0,"");
}

//unusued, bunchu free kills, spooky VHS tape (shadow rift is a great target), god lobster,  red zeppelin? debatable tbh
//since I can only get 1k meat from FK, should save FK and relavant wanderers for cyberzone
//For the same reason I can see with FK is better to farm spice melange.... Hypothetically pearl farming has higher value???? ~4k
void main(){
    try {
        starter();
        if (to_int(get_property("_pantsgivingCount")) < 500)
            stashgrab($item[pantsgiving]);
        set_property("script","farto");
        if (get_property("_stenchAirportToday") == "false")
            use($item[one-day ticket to Dinseylandfill]);
        while (my_adventures() > 0)
            garbo();
    } finally {
        finisher();
        stashreturn($item[pantsgiving]);
    }
}