import iotm.ash;
string mimic_skill(skill sk){ return "skill " + to_int(sk) + ";"; }

string mimic_item(item it){ return "use " + to_int(it) + ";"; }

string mimic_if(string condition, string body){ return "if " + condition + ";" + body + "endif;"; }

string mimic_while(string condition, string body){ return "while " + condition + ";" + body + "endwhile;"; }

string mimic_heal(int hp){
    string crystal = to_int($item[new age healing crystal]);
    return mimic_if("!pastround 28 && hpbelow " + hp, "use " + crystal + "," + crystal + ";");
}

string mimic_available_skill(skill sk){
    return mimic_if("!pastround 28 && hasskill " + to_int(sk), mimic_skill(sk));
}

boolean mimic_familiar_cached;
familiar mimic_familiar_effective;

void mimic_reset_familiar(){
    mimic_familiar_cached = false;
}
familiar mimic_active_familiar(){
    familiar actual = my_familiar();
    if (actual != $familiar[Comma Chameleon]) return actual;
    if (!mimic_familiar_cached){
        mimic_familiar_effective = chameleon();
        mimic_familiar_cached = true;
    }
    return mimic_familiar_effective;
}
boolean mimic_is_stocking(){
    return mimic_active_familiar() == $familiar[Stocking Mimic];
}
boolean mimic_sing_allowed(){
    return !($familiars[Peace Turkey, Pair of Stomping Boots] contains mimic_active_familiar())
        && !($locations[Guano Junction, The Defiled Cranny] contains my_location());
}
boolean mimic_bowling_allowed(){
    return item_amount($item[cosmic bowling ball]) > 0
        && (((have_effect($effect[Cosmic Ball in the Air]) < 22 || dayType() == 0
            || have_equipped($item[backup camera])) && my_location() != $location[Cobb's Knob Treasury])
            || get_property("subscript") == "replacing");
}
boolean[monster] mimic_gingerbread_natives = $monsters[gingerbread convict,
    gingerbread finance bro, gingerbread gentrifier, gingerbread lawyer,
    gingerbread tech bro, judge fudge];

string mimic_before(int round){ return "!pastround " + (round - 1); }

// Optional actions may not consume the reserved round-29 finishing slot.
string mimic_optional(string action){ return mimic_if(mimic_before(29), action); }

string mimic_finisher_action(string action){
    return mimic_if("pastround 29", "abort \"Finisher reached too late; final round left open\";") + action;
}

string mimic_cudgel_finish(){
    if (item_amount($item[dry noodles]) == 0) return "abort \"No dry noodles for Cudgel\";";
    return mimic_finisher_action(mimic_skill($skill[Carbohydrate Cudgel]))
        + "abort \"Cudgel did not finish; final round left open\";";
}

string mimic_pad_macro(int targetRound){
    return mimic_while(mimic_before(targetRound),
        mimic_item($item[facsimile dictionary]));
}

// Stop healing before the finishing window so it cannot consume a reserved action.
string mimic_late_pad(int targetRound, string extraCondition){
    string beforeFinish = mimic_before(targetRound);
    return mimic_while(beforeFinish + extraCondition, mimic_item($item[facsimile dictionary])
        + mimic_if(beforeFinish, mimic_heal(200)));
}
string mimic_late_pad(int targetRound){ return mimic_late_pad(targetRound, ""); }

// Shared loop mechanics; callers retain their existing round/HP/healing policies.
string mimic_stasis_loop(int targetRound, boolean checkHP, string action,
    int healBelow, int breakAfter, string label){
    string condition = mimic_before(targetRound);
    if (checkHP) condition += " && monsterhpabove 9";
    if (breakAfter > 0)
        action += mimic_if("pastround " + breakAfter, "goto " + label + ";");
    if (healBelow > 0) action += mimic_heal(healBelow);
    return mimic_while(condition, action) + (label == "" ? "" : "mark " + label + ";");
}

string mimic_ordinary_stasis(string macro, boolean reanimatedInPrefix, string copies){
    boolean shield = have_equipped($item[April shower thoughts shield]);
    if (shield)
        macro += mimic_stasis_loop(29, true,
            mimic_if("!hasskill " + to_int($skill[Shieldbutt]), "abort \"Shieldbutt unavailable\";")
            + mimic_skill($skill[Shieldbutt]), 100, 0, "");
    if (!reanimatedInPrefix)
        macro += mimic_available_skill($skill[Prepare to reanimate your Foe]);
    string dictionary = mimic_item($item[facsimile dictionary]);
    if (have_equipped($item[roman candelabra]))
        dictionary += mimic_if("!haseffect " + to_int($effect[Everything Looks Purple]),
            mimic_skill($skill[Blow the Purple Candle!]));
    string beforeTen = mimic_before(11);
    if (copies != "")
        macro += mimic_if(beforeTen, dictionary + copies + mimic_heal(200));
    macro += mimic_stasis_loop(11, false, dictionary, 200, 0, "");
    macro += mimic_if(beforeTen, "abort \"Mimic dictionary stasis ended early\";");
    if (shield)
        macro += mimic_if(mimic_before(29) + " && monsterhpabove 9",
            "abort \"Mimic Shieldbutt stasis ended early\";");
    return macro;
}
void mimic_pad_ash(int targetRound){
    if (current_round() == 0) return;
    monster foe = last_monster();
    string macro = mimic_pad_macro(targetRound) + "abort \"TGWH_PADDING_COMPLETE\";";
    set_property("lastMacroError", "");
    string page = visit_url("fight.php?action=macro&macrotext=" + url_encode(macro), true, true);
    if (current_round() == 0) return;
    if (last_monster() != foe || !contains_text(page, "TGWH_PADDING_COMPLETE")
        || !contains_text(get_property("lastMacroError"), "TGWH_PADDING_COMPLETE"))
        abort("Mimic server padding failed; inspect combat before continuing.");
    set_property("lastMacroError", "");
}

// Common actions before BACK-UP; heart stealing belongs after that boundary.
string mimic_basic_openers(){
    string macro = mimic_available_skill($skill[McHugeLarge Avalanche])
        + mimic_available_skill($skill[Launch spikolodon spikes]);
    if (my_primestat() == $stat[moxie] || have_equipped($item[mime army infiltration glove]))
        macro += "pickpocket;";
    if (mimic_sing_allowed()) macro += mimic_available_skill($skill[Sing Along]);
    macro += mimic_available_skill($skill[Prepare to reanimate your Foe]);
    if (mimic_bowling_allowed())
        macro += mimic_available_skill($skill[Bowl Straight Up]);
    if (to_int(last_monster()) == get_property("killThisGuy").to_int()
        && get_property("swordSniff") == "true")
        macro += mimic_skill($skill[%fn, kill a lot of these guys]);
    return macro;
}

string mimic_common_openers(){
    string macro = mimic_basic_openers();
    if (have_equipped($item[heartstone]))
        macro += mimic_available_skill($skill[Steal Monster's Heart]);
    return macro;
}

string mimic_gingerbread_body(){
    string macro = mimic_common_openers();
    if (have_equipped($item[April shower thoughts shield]))
        macro += mimic_stasis_loop(29, true,
            mimic_if("!hasskill " + to_int($skill[Shieldbutt]), "abort \"Shieldbutt unavailable\";")
            + mimic_skill($skill[Shieldbutt]), 100, 0, "");
    else
        macro += mimic_stasis_loop(11, true, mimic_item($item[facsimile dictionary]),
            100, 10, "mimic_gingerbread_finish");
    // Preserve the ten-round floor, then give the cigarette priority as HP falls.
    macro += mimic_pad_macro(11) + mimic_late_pad(29, " && monsterhpabove 100");
    int cigarette = to_int($item[gingerbread cigarette]);
    return macro + mimic_if("!hascombatitem " + cigarette, "abort \"Gingerbread cigarette unavailable\";")
        + mimic_finisher_action(mimic_item($item[gingerbread cigarette]));
}
