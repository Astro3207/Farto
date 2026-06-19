cli_execute ("hagnk all");
if (my_basestat($stat[moxie]) < 200 || my_basestat($stat[mysticality]) < 200) {
    use_familiar($familiar[cooler yeti]);
    maximize("cold res",false);
    cli_execute("gain cold res 1200 maxmeatspent; " + $effect[scariersauce].default + "; ");
    while (my_basestat($stat[moxie]) < 200 || my_basestat($stat[mysticality]) < 200)
        use(1, $item[Mmm-brr! brand mouthwash]);
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
        adv1( $location[The Outskirts of Cobb\'s Knob] , 0, "");
    } until (item_amount($item[11-inch knob sausage]) > 0);
    set_auto_attack(0); 
    visit_url ("guild.php?place=challenge");
    cli_execute ("acquire bitchin");
    visit_url ("guild.php?place=paco");
    visit_url ("guild.php?place=paco");
    visit_url ("guild.php?place=paco");
    run_turn();
}
if (item_amount($item[Platinum Yendorian Express Card]) > 0){
    visit_url("showclan.php?whichclan=2047009940&action=joinclan&confirm=on");
    if (get_clan_id( ) == 2047009940 && get_clan_name( ) == "Best Friends Club")
        put_stash( 1, $item[Platinum Yendorian Express Card] );
    else
        abort("Wrong PYEC clan");
    visit_url("showclan.php?whichclan=72876&action=joinclan&confirm=on");
}