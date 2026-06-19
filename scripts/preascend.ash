import iotm;
if (my_inebriety() <= inebriety_limit()){
    cli_execute("/whitelist hyrule; Mood apathetic; use law of averages; uneffect cletus; familiar stooper; equip acc2 angelbone dice; equip acc3 devilbone rosary; refresh all; CONSUME ALL");
    if ($familiar[cooler yeti].experience >= 400 && mall_price($item[vintage smart drink]) < 110000){
        cli_execute ("familiar cooler yeti");
        visit_Url("main.php?talktoyeti=1", false);    
        run_choice(2);
        if(mall_price($item[emergency margarita]) < mall_price($item[vintage smart drink])){
            cli_execute("familiar stooper; cast ode; drink emergency margarita;garbo ascend ascend nobarf");
        } else{
            cli_execute("familiar stooper; cast ode; drink vintage smart drink;garbo ascend ascend nobarf");
        }
    } else {
        cli_execute("CONSUME NIGHTCAP");
    }
}
if (my_adventures() > 9 && !have_equipped($item[devilbone greaves])){
    if (get_property("_stenchAirportToday") == "true"){
        cli_execute("garbo ascend -32");
    } else {
        cli_execute("sewerdump");
    }
}
cli_execute("equip angelbone totem; equip acc1 angelbone chopsticks; equip devilbone corset; equip devilbone greaves; refresh all; CONSUME ALL");
if (my_adventures() > 9){
    cli_execute("unblemishedpearl");
}
if (my_adventures() == 5){
    int n;
    while (to_int(get_property("_holidayMultitaskingUsed")) < 3){
        if (get_property("hasRange") == false){
            use($item[Dramatic&trade; range]);
        }
        foreach it in $items[hot cluster, cold cluster, stench cluster, spooky cluster, sleaze cluster]{
            if (shop_amount(it) > 0){
                cli_execute("acquire " + it + ", scrumdiddlyumptious solution");
                craft("cook",1,it,$item[scrumdiddlyumptious solution]);
            }
            if (to_int(get_property("_holidayMultitaskingUsed")) == 3)
                break;
        }
        if (my_primestat() == $stat[moxie] && to_int(get_property("_holidayMultitaskingUsed")) < 3 && stills_available( ) > 0){
            if ( shop_amount($item[bottle of Ooze-O]) < shop_amount($item[bottle of sewage schnapps])){
                cli_execute("make bottle of Ooze-O");
            }
        }
        if ( shop_amount($item[sewer wad]) < shop_amount($item[sewer nuggets])/5){
            int wado = ((shop_amount($item[sewer nuggets])/5-shop_amount($item[sewer wad]))/2)*5;
            cli_execute("acquire " + wado +" sewer nuggets; csend " + wado + " sewer nuggets to smashbot");
        }
        if (to_int(get_property("_holidayMultitaskingUsed")) < 3){
            if ( shop_amount($item[C.H.U.M. chum]) > shop_amount($item[unfortunate dumplings])){
                if (shop_amount($item[savory dry noodles]) == 0 && item_amount($item[savory dry noodles]) == 0){
                    cli_execute("make savory dry noodles");
                } else {
                    cli_execute("acquire savory dry noodles; make unfortunate dumplings");
                }
            }
        }
    }
    use($item[day shortener]);
}
while (my_adventures() > 0){
    adv1($location[Shadow Rift (The Misspelled Cemetary)]);
}
int peevp = pvp_attacks_left();
if (peevp > 0) {
     cli_execute("PVP_MAB; unequip pants");
}
while (my_basestat( $stat[submuscle]) > BCZcost("BloodThinnerCasts"))
        use_skill($skill[BCZ: Create Blood Thinner]);
while (my_basestat( $stat[submoxie]) > BCZcost("PheromoneCocktailCasts"))
        use_skill($skill[BCZ: Craft a Pheromone Cocktail]);
while (my_basestat( $stat[submysticality]) > BCZcost("SpinalTapasCasts"))
        use_skill($skill[BCZ: Prepare Spinal Tapas]);
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
while (to_int(get_property("availableSeptEmbers")) >= 2){
    cli_execute("make Mmm-brr! brand");
}
while (to_int(get_property("availableSeptEmbers")) == 1){
    cli_execute("make wheel of camembert");
}
if (get_property("_workshedItemUsed") == "false" && item_amount($item[TakerSpace letter of Marque]) > 0)
    cli_execute("use takerspace");
if (get_workshed() == $item[TakerSpace letter of Marque]){
    visit_url("campground.php?action=workshed");
    while (to_int(get_property("takerSpaceGold")) >= 1 && to_int(get_property("takerSpaceMast")) >= 1 && to_int(get_property("takerSpaceAnchor")) >= 3 && to_int(get_property("takerSpaceRum")) >= 1){
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
    while (to_int(get_property("takerSpaceGold")) >= 1 && to_int(get_property("takerSpaceMast")) >= 1 && to_int(get_property("takerSpaceAnchor")) >= 3 && to_int(get_property("takerSpaceRum")) >= 1){
        cli_execute("make anchor bomb");
    }
}
    if (to_int(get_property("sweat")) > 50 && my_adventures() == 0){
        use_skill($skill[Make Sweat-Ade]);
    }
    cli_execute("garden pick");
if (have_skill($skill[That's not a knife]))
    use_skill($skill[That's not a knife]);
cli_execute("acquire 1 one-day ticket to Dinseylandfill; acquire 1 Calzone of Legend; acquire 1 Deep Dish of Legend; acquire 1 Pizza of Legend; acquire 1 borrowed time; acquire 1 abstraction: category; acquire 1 non-Euclidean angle");
cli_execute("av-snapshot.ash");
set_ccs("hobopolis");
codpiece ("unblemished pearl,unblemished pearl,unblemished pearl,unblemished pearl,unblemished pearl");
cli_execute("philter");
set_property("afterAdventureScript","");
if (get_property("looping") == "true"){
    set_property("looping","false");
    visit_url("showclan.php?whichclan=2047009940&action=joinclan&confirm=on");
    take_stash(1,$item[Platinum Yendorian Express Card]);
    visit_url("showclan.php?whichclan=72876&action=joinclan&confirm=on");
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
    visit_url("showclan.php?whichclan=72876&action=joinclan&confirm=on");
    visit_url("ascend.php?action=ascend&confirm=on&confirm2=on");
	visit_url("afterlife.php?action=pearlygates");
	visit_url("afterlife.php?place=deli");
	visit_url("afterlife.php?action=buydeli&whichitem=5046");
    visit_url("afterlife.php?action=ascend&asctype=2&whichclass=6&gender=1&whichpath=55&whichsign=8");
    visit_url("afterlife.php?action=ascend&confirmascend=1&whichsign=8&gender=1&whichclass=6&whichpath=55&asctype=2&lamesignok=1&nopetok=1");
    visit_url("main.php");
    run_choice(-1);
}

//make spiky turtle shoulderpads, spirit Precipice, sponge helmet, spongy shield, square sponge pants, squeaky staff, Squeezebox of the Ages, Staff of the Headmaster's Victuals, Staff of the November Jack-O-Lantern, staph of homophones, starchy crossbow, starchy staff, sticky meat pants, sticky meat skirt, styrofoam crossbow, styrofoam staff, teflon spatula, teflon swim fins, thicksilver spurs, ticksilver spurs, time helmet, time sword, time trousers, tortoboggan shield, Tropical Crimbo Hat, Tropical Crimbo Shorts, Tropical Crimbo Sword, tuxedo shirt, velcro boots, velcro broadsword, velcro paddle ball, velcro shield, Vicar's Tutu, villainous scythe, vinyl boots, vinyl shield, white belt, white snakeskin duster, white whip, wicksilver spurs, wiffle-flail, Work is a Four Letter Sword, yak whip, yakskin buckler, yakskin kilt, yakskin pants, yakskin skirt, zombie dinosaur egg
