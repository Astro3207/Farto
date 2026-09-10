import iotm.ash;
//List of all potentially account specific stuff
//preference homeClanID
//preference combatMacroID

void firstTimeSetup(){
    if (get_property("homeClanID") == ""){
        if (user_confirm("Your home clan will be set to " + get_clan_name() + ", is this correct?"))
            set_property("homeClanID",get_clan_id());
        else
            abort("Go to home clan, and rerun, this will be the clan you should return to at the end of the day");
    }
    if (get_property("combatMacroID") == ""){
        cli_execute("/aa facsimile");
        if (get_auto_attack() == 0)
            abort("Make combat macro facsimile");
        else
            set_property("combatMacroID",get_auto_attack());
        set_auto_attack(0);
    }
}

void main(){
    firstTimeSetup();
    if (dayType() == 1){
        cli_execute("breakfast.ash");
        cli_execute("stockingmimic");
        cli_execute("preconsume");
        cli_execute("farto");
        cli_execute("preascend");
    }
    if (dayType() == 0){
        cli_execute("postloop");
        cli_execute("preconsume");
    //    if (numeric_modifier("familiar weight") < 300)
            cli_execute("farto");
        cli_execute("stockingmimic");
        if (user_confirm("Ready to run dinner?"))
            cli_execute("dinner");
    }
}
