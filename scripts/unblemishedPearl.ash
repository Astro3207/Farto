import iotm;
string fishyMon;
record pearl {
    location loc;
    modifier ele_res;
	string donePref;
};
pearl[string] pearls = {
	"anemone":  new pearl($location[Anemone Mine],              $modifier[spooky resistance],   "_unblemishedPearlAnemoneMine"),
	"bar":	    new pearl($location[The Dive Bar],              $modifier[sleaze resistance],   "_unblemishedPearlDiveBar"),
	"reef":	    new pearl($location[Madness Reef],              $modifier[stench resistance],   "_unblemishedPearlMadnessReef"),
	"trench":	new pearl($location[The Marinara Trench],       $modifier[hot resistance],      "_unblemishedPearlMarinaraTrench"),
	"deepests":	new pearl($location[The Briniest Deepests],     $modifier[cold resistance],     "_unblemishedPearlTheBriniestDeepests"),
};
void equipment(string str,string override){
    if (!have_equipped($item[devilbone greaves])){
        if (str == "anemone"){  
            cli_execute("maximize item drop, equip elf guard scuba, equip hodgman's disgusting technicolor, equip marble medallion, equip white earbuds, equip unkillable skeleton's shield" + override);
        } else if (str == "bar"){  
            cli_execute("maximize item drop, equip elf guard scuba, equip hodgman's disgusting technicolor, equip tonguebone, equip topiary necktie, equip unkillable skeleton's shield, equip hardened slime hat" + override);
        } else if (str == "reef"){  
            cli_execute("maximize item drop, equip elf guard scuba, equip hodgman's disgusting technicolor, equip guts necklace, equip hardened slime pants, equip fiberglass fetish, equip perfume-soaked bandana" + override);
        } else if (str == "trench"){  
            cli_execute("maximize item drop, equip elf guard scuba, equip hodgman's disgusting technicolor, equip iShield, equip vial of hot blood, equip heat-resistant gloves, equip hardened slime hat" + override);
        } else if (str == "deepests"){  
            cli_execute("maximize item drop, equip elf guard scuba, equip hodgman's disgusting technicolor, equip staff of the grand flam, equip bootonniere, equip elizabeth's dollie" + override);
        }  
    } else {
        cli_execute("maximize  "+ pearls[str].ele_res +" , equip elf guard scuba, equip devilbone corset, equip devilbone greaves, equip angelbone totem, equip drunkula's wineglass, equip angelbone chopstick" + override);
    }
}
void pearls(){
    set_property("hpAutoRecovery",0.75);
    set_property("hpAutoRecoveryTarget",0.95);
    foreach str in $strings[anemone,bar,reef,trench,deepests]{
        if (have_effect($effect[fishy]) < 10){
            print(have_effect($effect[fishy]));
            break;
        }
        if (get_property(pearls[fishyMon].donePref) == "false"){
            while (get_property(pearls[fishyMon].donePref) == "false"){
                use_familiar($familiar[grouper groupie]);
                if (!contains_text(get_property("_perilLocations"),"195"))
                    equipment (fishyMon,", equip peridot of peril");
                else 
                    equipment (fishyMon,"");
                if (numeric_modifier(pearls[fishyMon].ele_res) < 18){
                    cli_execute("gain 18 " + pearls[fishyMon].ele_res);
                    if (numeric_modifier(pearls[fishyMon].ele_res) < 18)
                        abort(numeric_modifier(pearls[fishyMon].ele_res)+ " str");
                }
                set_property("betweenBattleScript","");
                adv1(pearls[fishyMon].loc,0,"");
            }
        } else {
            while (get_property(pearls[str].donePref) == "false"){
                use_familiar($familiar[grouper groupie]);
                equipment (str, "");
                if (numeric_modifier(pearls[str].ele_res) < 18){
                    cli_execute("gain 18 " + pearls[str].ele_res);
                    if (numeric_modifier(pearls[str].ele_res) < 18)
                        abort(numeric_modifier(pearls[str].ele_res)+ " str");
                }
                set_property("betweenBattleScript","");
                adv1(pearls[str].loc,0,"");
            }
        }
    }
}

void main(){
    try{
        if (my_fullness() <= 2 && my_adventures() < 30){
            cli_execute("CONSUME ORGANS 3 3 3");
        }
        set_property("choiceAdventureScript","generalChoice.ash");
        if (!have_equipped($item[devilbone greaves])){
            set_property("script","unblemisedPearl");
            set_property("afterAdventureScript","postadventure.ash");
        } else {
            if (have_effect($effect[null afternoon]) == 0)
                use(2, $item[null-day exploit]);
        }
            set_auto_attack(0);
            set_property("battleAction", "custom combat script");
            buffer ccs = "consult unlockerCCS.ash \n abort";
            write_ccs(ccs, "CCCS");
            set_ccs ("CCCS");
        if (get_property("_fishyPipeUsed") == "false")
            use($item[fishy pipe]);
        if (get_property("_skateBuff1") == "false"){
            cli_execute("equip elf guard scuba; familiar grouper groupie");
            visit_url("sea_skatepark.php?action=state2buff1");
        }
        if (my_class() == $class[accordion thief])
            fishyMon = "trench";
        foreach str in $strings[anemone,bar,reef,trench,deepests]{
            pearlsDoneToday += to_int(to_boolean(get_property(pearls[str].donePref)));
        }
        if (pearlsDoneToday < 5)
            pearls();
        while (contains_text(get_property("elementaryQueue"),"398") && !have_equipped($item[devilbone greaves])){
            cli_execute("familiar peace turkey; maximize -combat, equip Mer-kin scholar mask, equip Mer-kin scholar tailpiece, equip little bitty; gain -35 combat 500 maxmeatspent");
            if (contains_text(get_property("banishedMonsters"),"hacker"))
                cli_execute("equip monodent");
            put_closet(item_amount($item[mer-kin hallpass]),
                $item[mer-kin hallpass]);
            adv1($location[mer-kin elementary school],0,"");
            put_closet(item_amount($item[mer-kin hallpass]),
                $item[mer-kin hallpass]);
        }
    } finally {
        finisher();
    }
}
