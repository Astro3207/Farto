import iotm.ash;
set_property("choiceAdventureScript","generalChoice.ash");
cli_execute ("hagnk all");
if (my_basestat($stat[moxie]) < 200 || my_basestat($stat[mysticality]) < 200) {
    use_familiar($familiar[cooler yeti]);
    maximize("cold res",false);
    cli_execute("gain cold res 1200 maxmeatspent; " + $effect[scariersauce].default + "; ");
    while (my_basestat($stat[moxie]) < 200 || my_basestat($stat[mysticality]) < 200){
        int before = my_basestat($stat[moxie]) + my_basestat($stat[mysticality]);
        if (!use(1, $item[Mmm-brr! brand mouthwash])
            || my_basestat($stat[moxie]) + my_basestat($stat[mysticality]) <= before){
            print("postloop: mouthwash isn't raising moxie/myst toward 200 -- bailing", "red");
            break;
        }
    }
}
cli_execute("breakfast; breakfast.ash");
cli_execute ("familiar jill-of-all");
if (get_property("questG09Muscle") == "unstarted" && (my_class() == $class[seal clubber] || my_class() == $class[turtle tamer])) {
    set_property ("choiceAdventure930" , 1);
    visit_url ("guild.php?place=challenge");
    set_ccs("hobopolis");
    set_property ("choiceAdventure1525" , 1);
    set_property ("choiceAdventure118" , 1);
    repeat {
        cli_execute ("equip adobe adze; equip carnivorous potted plant; equip acc1 mafia thumb ring ");
        if (have_effect($effect[Everything Looks Red]) == 0 ) {
            cli_execute( "equip acc2 Everfull Dart Holster");
        }
        if (!adv1( $location[The Outskirts of Cobb\'s Knob] , 0, ""))
            abort("postloop: can't adventure at the Outskirts of Cobb's Knob for the 11-inch knob sausage");
    } until (item_amount($item[11-inch knob sausage]) > 0 || my_adventures() == 0);
    if (item_amount($item[11-inch knob sausage]) == 0)
        print("postloop: out of adventures before the 11-inch knob sausage dropped -- guild challenge left unfinished", "red");
    set_auto_attack(0); 
    visit_url ("guild.php?place=challenge");
    cli_execute ("acquire bitchin");
    visit_url ("guild.php?place=paco");
    visit_url ("guild.php?place=paco");
    visit_url ("guild.php?place=paco");
    run_turn();
}
if (item_amount($item[Platinum Yendorian Express Card]) > 0){
    stashreturn($item[Platinum Yendorian Express Card]);
}