if (my_inebriety() <= inebriety_limit()){
    cli_execute("/whitelist hyrule; Mood apathetic; use law of averages; uneffect cletus; familiar stooper; equip acc2 angelbone dice; equip acc3 devilbone rosary; refresh all; CONSUME ALL");
    if ($familiar[cooler yeti].experience >= 400 && mall_price($item[vintage smart drink]) < 110000){
        cli_execute ("familiar cooler yeti");
        visit_Url("main.php?talktoyeti=1", false);    
        run_choice(2);
        if(mall_price($item[emergency margarita]) < mall_price($item[vintage smart drink])){
            cli_execute("familiar stooper; cast ode; drink emergency margarita;garbo ascend nobarf");
        } else{
            cli_execute("familiar stooper; cast ode; drink vintage smart drink;garbo ascend nobarf");
        }
    } else {
        cli_execute("CONSUME NIGHTCAP");
    }
}
if (gametime_to_int( ) < 86300000)
    cli_execute("garbo ascend -59");
cli_execute("equip angelbone totem; equip acc1 angelbone chopsticks; equip devilbone corset; equip devilbone greaves; refresh all; CONSUME ALL");
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
    if (my_primestat() == $stat[moxie]){
        if ( shop_amount($item[bottle of Ooze-O]) < shop_amount($item[bottle of sewage schnapps]) && stills_available( ) > 0){
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
if (have_skill($skill[That's not a knife]))
    use_skill($skill[That's not a knife]);
if (have_skill($skill[Summon Kokomo Resort Pass]))
    use_skill($skill[Summon Kokomo Resort Pass]);
cli_execute ("maximize adv; av-snapshot.ash");
int peevp = pvp_attacks_left();
if (peevp > 70) {
    cli_execute("pvpcombat");
}
if (get_property("_workshedItemUsed") == "false" && get_workshed( ) != $item[TakerSpace letter of Marque]){
    cli_execute("use takerspace");
}
if (get_property("_augSkillsCast") < 5){
    cli_execute("cast Aug. 13th");
    if (get_property("_augSkillsCast") < 5)
        cli_execute("cast Aug. 7th");
}
int monkeyWish = to_int(get_property("_monkeyPawWishesUsed"));
if (monkeyWish < 5 && closet_amount($item[cursed monkey's paw]) > 0){
    cli_execute("closet take cursed monkey's paw");
}
switch (monkeyWish){
    case 0:
        cli_execute("monkeypaw effect Braaaaaains");
        monkeyWish += 1;
    case 1:
        cli_execute("monkeypaw effect Frosty");
        monkeyWish += 1;
    case 2:
        cli_execute("monkeypaw effect Let's Go Shopping!");
        monkeyWish += 1;
    case 3:
        cli_execute("monkeypaw effect Low on the Hog");
        monkeyWish += 1;
    case 4:
        cli_execute("monkeypaw effect Leisurely Amblin'");
}
if (!contains_text(visit_url("campground.php?action=inspectdwelling"),"maid2"))
    cli_execute("use clockwork maid");
cli_execute("familiar jill;maximize adv");
cli_execute("refresh inv");
float wastedAdv = to_float(my_adventures()) + to_float(numeric_modifier("Adventures")) + 40 - 200;
if (wastedAdv > 0){
    if (user_confirm("Use "+ (wastedAdv/5) + " day shorteners?")){
        use(ceil(wastedAdv/5),$item[day shortener]);
    }
}
cli_execute("philter;maximize adv");
if (my_meat() - 3000000 > 0){ 
    int new_meat = my_meat() - 3000000;
    visit_Url("closet.php?addtake=add&action=addtakeclosetmeat&quantity=" + new_meat);
}

string messages(){
    return visit_url("messages.php");
}
int deleted = 0;
foreach str in $strings[3690803,1053259,1699424,1533476]{
    matcher m = create_matcher("name=\"sel(\\d+)\"></td><td class=small><b>From</b> <a href=\"showplayer\\.php\\?who=" + str, messages());
    while (m.find()){
        visit_url("messages.php?the_action=delete&box=Inbox&sel"+ m.group(1) + "=on");
        deleted += 1;
    }
}
matcher m = create_matcher("name=\"sel(\\d+)\"></td><td class=small><b>From</b> The Loathing Postal Service", messages());
while (m.find()){
    visit_url("messages.php?the_action=delete&box=Inbox&sel"+ m.group(1) + "=on");
    deleted += 1;
}

print( deleted + " messages deleted");