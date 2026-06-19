float transport(){
    float transport_float = have_effect($effect[Transpondent]) - item_amount($item[Map to Safety Shelter Grimace Prime]);
    return (transport_float);
}

void equipment(){
    buffer maximize;
    if (!contains_text(get_property("banishedPhyla"),"horror")){
        use_familiar($familiar[Patriotic Eagle]);
    } else {
        use_familiar($familiar[jill-of-all-trades]);
    }
    append(maximize, "item drop");
    if (to_int(get_property("_douseFoeUses")) < 3){
        append(maximize, ", equip flash liquid ultra");
    }
    if (to_int(get_property("_douseFoeUses")) < 3){
        append(maximize, ", equip flash liquid ultra");
    }
    if (to_int(get_property("_batWingsSwoopUsed")) < 11){
        append(maximize, ", equip bat wings");
    }
    if (total_turns_played() >= to_int(get_property("clubEmNextWeekMonsterTurn")) + 8){
        append(maximize, ", equip legendary seal-clubbing club");
    }
    if (!maximize(to_string(maximize),false)){
        abort();
    }
}

if ((item_amount($item[distention pill]) == 0 || item_amount($item[synthetic dog hair pill]) == 0) || have_effect($effect[Transpondent]) > 0){
    if (have_effect($effect[Transpondent]) == 0){
        use($item[transporter transponder]);
    }
    buffer ccs = "consult unlockerCCS.ash \n abort";
    write_ccs(ccs, "CCCS");
    set_auto_attack(0);
    set_property("battleAction", "custom combat script");
    set_ccs("CCCS");
    use_familiar($familiar[jill-of-all-trades]);
    cli_execute("equip LED candle; ledcandle item; maximize item");
    cli_execute("gain 900 item drop 15 turns");
    while (transport() > item_amount($item[Map to Safety Shelter Grimace Prime])){
        equipment();
        if  (numeric_modifier("item drop") < 900){
            cli_execute("gain 900 item drop");
        }
        adv1($location[Domed City of Grimacia], 0, "");
    }
    while (have_effect($effect[Transpondent]) > 0 && item_amount($item[Map to Safety Shelter Grimace Prime]) > 0){
        if (item_amount($item[distention pill]) > item_amount($item[synthetic dog hair pill])){
            set_property("choiceAdventure536", "2");
        } else {
            set_property("choiceAdventure536", "1");
        }
        use($item[Map to Safety Shelter Grimace Prime]);
    }
}