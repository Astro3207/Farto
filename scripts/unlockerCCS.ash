import mimicMacroBuilders.ash;

// ─── unlockerCCS.ash ──────────────────────────────────────────────────────────
// Combat consult script. main() runs in three stages:
//   1. openers       -- run in order; each may act and leave the fight going
//   2. routines      -- familiar/script/category fights that end the combat
//   3. zone routines -- per-location fights, then the generic fallback
// Order matters: earlier stages see the fight first.

// ─── COMBAT PRIMITIVES ────────────────────────────────────────────────────────

    void sauce(int n)  { for i from 1 to n { use_skill($skill[saucegeyser]); } }
    void attack(int n) { for i from 1 to n { attack(); } }
    void hurt(int n)   { for i from 1 to n { throw_items($item[new age hurting crystal],$item[new age hurting crystal]); } }
    void heal_hurt()   { throw_items($item[new age healing crystal],$item[new age hurting crystal]); }

    void heal(int below){
        if (my_hp() < below)
            throw_items($item[new age healing crystal],$item[new age healing crystal]);
    }

    void reanimate(){
        if (have_skill($skill[Prepare to reanimate your Foe]))
            use_skill($skill[Prepare to reanimate your Foe]);
    }

    void purpleCandle(){
        if (have_effect($effect[everything looks purple]) == 0 && have_equipped($item[roman candelabra]))
            use_skill($skill[Blow the Purple Candle!]);
    }

    void crit(){
        if (my_class() == $class[seal clubber])
            use_skill($skill[Furious Wallop]);
        else
            attack();
    }

    void cleanUp() {
        int loopCount = 0;
        while (current_round() > 0) {
            int round = current_round();
            use_skill($skill[saucegeyser]);
            if (round == current_round()) {
                loopCount += 1;
                if (loopCount > 3)
                    abort("May be stuck in an infinite attack loop");
            }
        }
    }

// ─── CATEGORY SETS ────────────────────────────────────────────────────────────
    boolean [location] sauceLocs = $locations[Cyberzone 1, Cyberzone 2, Cyberzone 3,
        The Secret Government Laboratory, Seaside Megalopolis, The Jungles of Ancient Loathing,
        The Bubblin' Caldera, The Red Queen's Garden, The Laugh Floor, Infernal Rackets Backstage,
        Vanya's Castle, Megalo-City, Hero's Field, The Fungus Plains];
    boolean [monster] sauceMobs = $monsters[terrible mutant, slime blob, government bureaucrat,
        angry ghost, annoyed snake, time cop];

    // Whole combat is hurt(n) -- new age hurting crystals.
    boolean [location] hurtLocs = $locations[the cursed village];
    boolean [monster] hurtMobs = $monsters[Beast with X Ears, Beast with X Eyes,
        X Bottles of Beer on a Golem, Pharaoh Amoon-Ra Cowtep];

    // Phylum the patriotic screech banishes in each zone.
    phylum [location] screechPhylum = {
        $location[the briniest deepests]: $phylum[fish],
        $location[madness bakery]:        $phylum[construct]
    };

    // Elemental bonus spell per monster element.
    skill [element] elementBonus = {
        $element[hot]:    $skill[Eggsplosion],
        $element[spooky]: $skill[Awesome Balls of Fire],
        $element[cold]:   $skill[Raise Backup Dancer],
        $element[sleaze]: $skill[Snowclone],
        $element[stench]: $skill[Grease Lightning]
    };

    // Cyrus adjective each memory base pair adds.
    string [item] basePairs = {
        $item[memory of a CT base pair]: "more attractive",
        $item[memory of a CG base pair]: "smarter",
        $item[memory of a CA base pair]: "stronger",
        $item[memory of a GT base pair]: "more resilient",
        $item[memory of an AT base pair]: "more aggressive",
        $item[memory of an AG base pair]: "faster"
    };

// ─── STATE CHECKS ─────────────────────────────────────────────────────────────

    boolean free_location(){
        return $locations[cyberzone 3, cyberzone 2, cyberzone 1, The Red Zeppelin, An Unusually Quiet Barroom Brawl] contains my_location();
    }

    // A Glacier of Jerks native, not a zoneless monster (tentacle, wanderer) that only inherits my_location().
    boolean glacierFight(){
        return my_location() == $location[The Glacier of Jerks]
            && $monsters[Hugo Von Douchington, Wacky Zack Flacky, Dolores D. Smiley, Vivian Vibrian Vumian Varr, Brock "Rocky" Flox] contains last_monster();
    }

    // True when this fight won't cost a turn however it ends.
    boolean free_monster() {
        if (contains_text(last_monster().attributes, "FREE") || contains_text(last_monster().name, "hacker"))
            return true;
        if (my_location().zone == "Shadow Rift" && have_effect($effect[shadow affinity]) > 0)
            return true;
        if (free_location())
            return true;
        return $monsters[black crayon golem, time cop,
            kid who is too old to be Trick-or-Treating,
            suburban security civilian, vandal kid, terrible mutant,
            slime blob, government bureaucrat, Moleman, giant sandworm] contains last_monster();
    }

    boolean isMimicFam()
        return mimic_is_stocking();

    // Underwater, or in the zone the Sea *dent wave flooded.
    boolean wet()
        return my_location().environment == "underwater" || my_location() == to_location(get_property("_seadentWaveZone"));

    boolean gazeReady(){
        return (my_basestat($stat[submysticality]) - 62500) > BCZcost("RefractedGazeCasts");
    }

// ─── KILL / RUN ───────────────────────────────────────────────────────────────

    boolean looseRiftKillTarget(){
        monster foe = last_monster();
        return get_property("script") == "FreeKill" && get_property("subscript") == "looseFK"
            && my_location() == $location[Shadow Rift (The Misspelled Cemetary)]
            && !foe.boss && foe != copyTarget && !free_monster()
            && !contains_text(foe.attributes, "NOINSTAKILL");
    }

    // Shared eligibility for both the ASH fallback and the macro planner.
    boolean freeKillSkillAllowed(skill sk, string page){
        if (sk == $skill[Chest X-Ray])
            return looseRiftKillTarget() && have_equipped($item[Lil' Doctor&trade; bag])
                && have_skill(sk) && get_property("_chestXRayUsed").to_int() < 3;
        if (!contains_text(page, to_string(sk))) return false;
        if (sk == $skill[Spit jurassic acid] && my_adventures() < 100 && dayType() == 0) return false;
        if (sk == $skill[Darts: Aim for the Bullseye] && my_adventures() <= bullseyeCooldown() && dayType() == 0) return false;
        if (sk == $skill[Club 'Em Back in Time]
            && (my_location() == $location[Hobopolis Town Square] || last_monster() == $monster[giant sandworm])) return false;
        if (sk == $skill[BCZ: Sweat Bullets]
            && ((my_basestat($stat[submoxie]) - 62500) <= BCZcost("SweatBulletsCasts")
                || get_property("_bczSweatBulletsCasts").to_int() >= 13)) return false;
        return true;
    }

    boolean freeKillItemAllowed(item it){
        if (it == $item[replica bat-oomerang])
            return looseRiftKillTarget() && item_amount(it) > 0 && get_property("_usedReplicaBatoomerang").to_int() < 3;
        if (it == $item[interesting coin])
            return item_amount(it) > 0 && get_property("_interestingCoinHeads") == "false"
                && !contains_text(get_property("lastCombatActions"), "it11311");
        if (it == $item[partial tombstone])
            return available_amount(it) > 0 && get_property("_partialTombstonesUsed").to_int() < 11;
        if (it == $item[shadow brick])
            return available_amount(it) > 0 && get_property("_shadowBricksUsed").to_int() < 13;
        return false;
    }

    void free_kill(string ptext) {
        foreach sk in $skills[Spit jurassic acid, Darts: Aim for the Bullseye] {
            if (!freeKillSkillAllowed(sk, ptext)) continue;
            use_skill(sk);
            if (sk == $skill[Darts: Aim for the Bullseye])
                while (to_int(get_property("_dartsLeft")) > 0 && current_round() > 0) use_skill(sk);
        }
        if (get_property("script") == "farto" || (get_property("script") == "FreeKill" && get_property("subscript") != "looseFK"))
            return;
        foreach sk in $skills[Assert your Authority, Fire the Jokester's Gun,
            BCZ: Sweat Bullets, Shattering Punch,
            Gingerbread Mob Hit, Club 'Em Back in Time, Chest X-Ray] {
            if (current_round() == 0) return;
            if (freeKillSkillAllowed(sk, ptext))
                use_skill(sk);
        }
        if (current_round() > 0 && freeKillItemAllowed($item[replica bat-oomerang]))
            throw_item($item[replica bat-oomerang]);
        if (current_round() == 0) return;
        if (freeKillItemAllowed($item[interesting coin])){
            while (get_property("_interestingCoinHeads") == "false" && current_round() > 0 && current_round() < 30)
                throw_item($item[interesting coin]);
        }
        if (freeKillItemAllowed($item[partial tombstone]))
            throw_item($item[partial tombstone]);
        if (freeKillItemAllowed($item[shadow brick]))
            throw_item($item[shadow brick]);
    }

    void finishFreeRunTentacle();

    // Free runs on the page (curveball first unless it's the copy target), then the boots.
    void free_run(string ptext) {
        if (get_property("script") == "FreeKill" && last_monster() == $monster[Eldritch Tentacle]){
            finishFreeRunTentacle();
            return;
        }
        if (last_monster() == $monster[Knob Goblin Embezzler])
            abort("Trying to run from an embezzler");
        if (last_monster() != copyTarget && have_skill($skill[Bowl a Curveball]))
            use_skill($skill[Bowl a Curveball]);
        foreach sk in $skills[spring away, snokebomb] {
            if (!contains_text(ptext, to_string(sk)))
                continue;
            if (my_location() == $location[hobopolis town square] && sk == $skill[snokebomb]) continue;
            if (sk == $skill[spring away] && dayType() == 0 && my_adventures() < 30) continue;
            use_skill(sk);
        }
        if (my_familiar() == $familiar[pair of stomping boots]
            || (my_familiar() == $familiar[comma chameleon] && get_property("commaFamiliar") == "Pair of Stomping Boots"))
        {
            if (current_round() > 0 && get_property("_banderRunaways").to_int() >= floor((my_familiar().familiar_weight() + weight_adjustment()) / 5.0))
                abort("No free boot runaways remain with the current equipment.");
            if (current_round() > 0) runaway();
        }
    }

    // Instakills that end the fight but aren't "free kills".
    void insta_kill(string ptext) {
        set_property("choiceAdventure1589", 2);
        foreach sk in $skills[northern explosion, Club 'Em Into Next Week,
            Club 'Em Across the Battlefield, monkey slap] {
            if (sk == $skill[northern explosion]
                && (get_property("_aprilShowerNorthernExplosion") == "true"
                    || !have_equipped($item[April Shower Thoughts shield])))
                continue;
            if (contains_text(ptext, to_string(sk))) use_skill(sk);
        }
    }

// ─── DARTS & FARMING ──────────────────────────────────────────────────────────

    skill butts(){
        matcher m = create_matcher("(\\d+):butt", get_property("_currentDartboard"));
        return m.find() ? to_skill(m.group(1).to_int()) : to_skill(0);
    }

    void dart() {
        while (to_int(get_property("_dartsLeft")) > 0 && current_round() > 0 && have_equipped($item[everfull dart holster])) {
            if (have_effect($effect[everything looks red]) == 0 && (my_adventures() > bullseyeCooldown() || dayType() == 1))
                use_skill($skill[Darts: Aim for the Bullseye]);
            else if (have_skill(butts()))
                use_skill(butts());
            else
                use_skill($skill[Darts: Throw at %part1]);
            if (get_property("script") == "6-kiss")
                return;
        }
    }

    void farmingStuff(){
        dart();
        if (have_skill($skill[extract]))
            use_skill($skill[extract]);
        if (have_item($item[porquoise-handled sixgun]))
            throw_item($item[porquoise-handled sixgun]);
        if (have_item($item[pulled red taffy]) && last_monster() != $monster[Eldritch Tentacle])   // Attunement tentacles aren't underwater
            throw_item($item[pulled red taffy]);
        if (have_skill($skill[pocket crumbs]) && to_int(get_property("_pantsgivingCrumbs")) < 9)
            use_skill($skill[pocket crumbs]);
    }

// ─── TRACKING & COPIES ────────────────────────────────────────────────────────

    boolean isTracked(monster mons, skill sk){
        return contains_text(":" + get_property("trackedMonsters"), ":" + mons + ":" + sk + ":");
    }

    void sniff(monster mons){
        foreach sk in $skills[McHugeLarge Slash, Transcendent Olfaction, Gallapagosian Mating Call] {
            if (have_skill(sk) && !isTracked(mons, sk) && sk.timescast < sk.dailylimit)
                use_skill(1, sk);
        }
    }

    void replace(){
        if (last_monster() == copyTarget)
            return;
        if (is_banished(copyTarget))
            abort("Replacement chain: " + copyTarget + " is banished. Clear its banish before replacing.");
        skill replacer;
        if (have_equipped($item[Powerful Glove]) && get_property("_powerfulGloveBatteryPowerUsed").to_int() <= 90)
            replacer = $skill[CHEAT CODE: Replace Enemy];
        else if (have_skill($skill[Macrometeorite]) && get_property("_macrometeoriteUses").to_int() < 10)
            replacer = $skill[Macrometeorite];
        if (replacer == $skill[none])
            abort("Replacement chain: no replacement skill remains; stopping before combat setup.");
        use_skill(replacer);
        if (last_monster() != copyTarget)
            abort("Replacement chain: did not produce " + copyTarget + ".");
    }

    boolean shadowHatReady(){
        return have_equipped($item[snowman-enchanting tophat])
            && get_property("_snowmanHatPlaceUsed").to_int() < 3
            && have_skill($skill[PLACE YOUR HAT ON THEIR HEAD]);
    }
    boolean shadowGuyWaffleWorthwhile(){
        float itDropMult = item_drop_modifier()/100 + 1;
        int shadowGuyValue = item_drops_array($monster[shadow guy])[0].rate/100 * itDropMult * mall_price(item_drops_array($monster[shadow guy])[0].drop);
        int avgPrice = (mall_price($item[shadow brick]) + mall_price($item[shadow stick]))/2;
        int otherGuyValue = (item_drops_array($monster[shadow slab])[0].rate/100 * itDropMult * avgPrice) - mall_price($item[waffle]);
        return shadowGuyValue < otherGuyValue;
    }

    void waffleShadowGuy(){
        if (shadowHatReady())
            use_skill($skill[PLACE YOUR HAT ON THEIR HEAD]);
        else if (have_effect($effect[fishy]) < 1020){
            if (have_skill($skill[Sea *dent: Talk to Some Fish]))
                use_skill($skill[Sea *dent: Talk to Some Fish]);
        }
        else if (shadowGuyWaffleWorthwhile())
            throw_item($item[waffle]);
    }

// Build the remaining ordinary Mimic combat once, then let BALLS run it.




string mimic_repeat(int n, string body){ return mimic_while("!times " + n + " && !pastround 29", body); }


string mimic_failed_probe;
int mimic_started;
int mimic_reads;
// Monster identity survives ordinary actions; replacements invalidate HP readiness.
monster mimic_consult_monster;
string mimic_consult_stamp;
boolean mimic_requires_hp;
boolean mimic_stasis_batched;
string mimic_probe_key(){
    return last_monster() + ";" + my_location() + ";" + get_property("_backUpUses")
        + ";" + get_property("_macrometeoriteUses") + ";" + get_property("_powerfulGloveBatteryPowerUsed");
}
boolean mimic_macro_ready(boolean needsHP){
    mimic_started = now_to_int();
    mimic_reads = 0;
    mimic_requires_hp = needsHP;
    if (!have_skill($skill[Ambidextrous Funkslinging])) return false;
    if (needsHP && contains_text(last_monster().attributes, "NOMANUEL")){
        set_property("lastMacroError", "");
        return false;
    }
    string probeKey = mimic_probe_key();
    if (needsHP && mimic_failed_probe == probeKey) return false;
    if (!needsHP || (last_monster() == mimic_consult_monster && probeKey == mimic_consult_stamp)){
        return true;
    }
    // After a replacement, probe only when the recipe actually needs HP predicates.
    mimic_reads = 1;
    string probe = "if knowmonster;abort \"TGWH_MANUEL_KNOWN\";endif;abort \"TGWH_MANUEL_UNKNOWN\";";
    string page = visit_url("fight.php?action=macro&macrotext=" + url_encode(probe), true, true);
    set_property("lastMacroError", "");
    if (!contains_text(page, "TGWH_MANUEL_KNOWN")){
        mimic_failed_probe = probeKey;
        return false;
    }
    mimic_consult_monster = last_monster();
    mimic_consult_stamp = probeKey;
    return true;
}
boolean mimic_macro_ready(){ return mimic_macro_ready(true); }

boolean mimic_submit(string macro, string continuation, int minRound, item capture){
    if (current_round() == 0) return true;
    monster expectedMonster = last_monster();
    int capturesBefore = capture == $item[none] ? 0 : item_amount(capture);
    int submittedRound = current_round();
    int submittedTurns = my_turncount();
    string submittedActions = get_property("_lastCombatActions");
    if (mimic_requires_hp)
        macro = "if !knowmonster;abort \"TGWH_NEEDS_ASH_HP\";endif;" + macro;
    if (continuation != ""){
        // A minimum is sufficient; optional actions may legitimately finish later.
        if (minRound > 1) macro += mimic_if(mimic_before(minRound),
            "abort \"Mimic continuation reached before minimum stasis\";");
        macro += "abort \"" + continuation + "\";";
    }
    boolean timing = get_property("tgwh_fartoTiming") != "false";
    if (timing) print("[Mimic timing] batch_start round=" + submittedRound + " reads=" + mimic_reads
        + " monster=" + expectedMonster, "gray");
    set_property("lastMacroError", "");
    buffer response = visit_url("fight.php?action=macro&macrotext=" + url_encode(macro), true, true);
    if (timing) print("[Mimic timing] batch_end elapsed_ms=" + (now_to_int() - mimic_started)
        + " round=" + current_round(), "gray");
    string macroError = get_property("lastMacroError");
    // Only this no-action entry guard permits the original ASH route to resume.
    if (contains_text(macroError, "TGWH_NEEDS_ASH_HP")
        && contains_text(response, "TGWH_NEEDS_ASH_HP")
        && current_round() == submittedRound && my_turncount() == submittedTurns
        && last_monster() == expectedMonster
        && get_property("_lastCombatActions") == submittedActions){
        mimic_failed_probe = mimic_probe_key();
        set_property("lastMacroError", "");
        return false;
    }
    boolean continued = continuation != "" && contains_text(macroError, continuation)
        && contains_text(response, continuation);
    boolean captured = capture != $item[none] && item_amount(capture) > capturesBefore
        && contains_text(response, "You snare your foe and tie them up in a neat little bundle.");
    string failure;
    if (continued){
        if (last_monster() != expectedMonster || current_round() == 0)
            failure = "Mimic macro reached an unexpected continuation state.";
        else {
            set_property("lastMacroError", "");
            return true;
        }
    } else if (macroError != "")
        failure = "Mimic macro failed: " + macroError;
    else if (current_round() > 0)
        failure = "Mimic macro stopped at round " + current_round() + "; combat left open.";
    else if (get_property("_lastCombatWon") != "true" && !captured)
        failure = "Mimic macro ended without a win or confirmed capture.";
    if (failure != ""){
        string diagnostic = "mimic-macro-diagnostics/" + now_to_string("yyyyMMdd-HHmmss-SSS");
        buffer details;
        details.append("Monster: " + expectedMonster + "\nLocation: " + my_location()
            + "\nSubscript: " + get_property("subscript") + "\nMafia round at submission: " + submittedRound
            + "\nFailure: " + failure + "\n\n" + macro + "\n");
        boolean savedDetails = buffer_to_file(details, diagnostic + ".txt");
        boolean savedResponse = buffer_to_file(response, diagnostic + ".html");
        if (savedDetails && savedResponse)
            print("[Mimic macro] diagnostics=data/" + diagnostic, "gray");
        else print("Could not save all Mimic macro diagnostics.", "red");
        abort(failure);
    }
    return true;
}


boolean mimic_submit(string macro){ return mimic_submit(macro, "", 1, $item[none]); }

void finishFreeRunTentacle(){
    if (current_round() == 0) return;
    skill geyser = $skill[Saucegeyser];
    boolean stasis = isMimicFam();
    if (mimic_macro_ready(false)){
        string macro = stasis ? (last_monster().boss ? mimic_pad_macro(11) : mimic_late_pad(25)) : "";
        macro += mimic_while(mimic_before(30) + " && hasskill " + to_int(geyser), mimic_skill(geyser));
        macro += "abort \"Tentacle survived: Saucegeyser unavailable or round limit reached\";";
        if (mimic_submit(macro)) return;
    }

    if (stasis) mimic_pad_ash(11);
    while (current_round() > 0 && current_round() <= 29 && have_skill(geyser) && my_mp() >= mp_cost(geyser)){
        int round = current_round();
        use_skill(geyser);
        if (current_round() == round) break;
    }
    if (current_round() > 0) abort("Tentacle did not finish; refusing to run away.");
}

// Actions that intentionally hand control back to ASH for a live decision.
boolean mimic_phase(string macro){
    if (current_round() == 0 || macro == "") return true;
    if (!mimic_macro_ready(false)) return false;
    return mimic_submit(macro, "TGWH_PHASE_COMPLETE", 1, $item[none]);
}

boolean mimic_weakling_combat(string openers){
    if (current_round() == 0) return true;
    boolean snowman = last_monster() == $monster[X-32-F Combat Training Snowman];
    // These branches have their own finishers or resource decisions below.
    if ($monsters[Eldritch Tentacle, flaming leaflet, Ron "The Weasel" Copperhead] contains last_monster()
        || $locations[The Red Zeppelin, Gingerbread Upscale Retail District, Gingerbread Civic Center] contains my_location()
        || glacierFight()
        || get_property("FKRunEligible") == "true" || !mimic_macro_ready(!snowman))
        return false;
    boolean shield = have_equipped($item[April shower thoughts shield]);
    string dictionary = mimic_item($item[facsimile dictionary]);
    string action = shield ? mimic_skill($skill[Shieldbutt]) : "attack;";
    string macro = openers;
    if (shield)
        macro += mimic_stasis_loop(29, !snowman, action, 100, 0, "");
    else
        macro += mimic_stasis_loop(29, !snowman, dictionary, 100, 10, "mimic_padding");
    if (have_equipped($item[unwrapped knock-off retro superhero cape]))
        macro += (last_monster().boss ? mimic_pad_macro(11) : mimic_late_pad(28))
            + mimic_optional(mimic_skill($skill[Saucegeyser]));
    macro += mimic_stasis_loop(29, !snowman, action, 0, 0, "")
        + mimic_pad_macro(29)
        + mimic_cudgel_finish();
    return mimic_submit(macro);
}
boolean mimic_weakling_combat(){ return mimic_weakling_combat(""); }

// Special weaklings still need live runaway/glark/capture decisions. Batch the
// stasis around those boundaries instead of forcing the whole fight into ASH.
boolean mimic_weakling_stasis(){
    boolean snowman = last_monster() == $monster[X-32-F Combat Training Snowman];
    if (!mimic_macro_ready(!snowman)) return false;
    string macro;
    if (have_equipped($item[April shower thoughts shield]))
        macro = mimic_stasis_loop(29, !snowman, mimic_skill($skill[Shieldbutt]), 100, 0, "");
    else
        macro = mimic_stasis_loop(29, !snowman, mimic_item($item[facsimile dictionary]),
            100, 10, "mimic_weakling_decision");
    return mimic_submit(macro + mimic_pad_macro(11), "TGWH_STASIS_COMPLETE", 10, $item[none]);
}

boolean mimic_weakling_finish(){
    boolean snowman = last_monster() == $monster[X-32-F Combat Training Snowman];
    if (!mimic_macro_ready(!snowman)) return false;
    string action = have_equipped($item[April shower thoughts shield]) ? mimic_skill($skill[Shieldbutt]) : "attack;";
    return mimic_submit(mimic_stasis_loop(29, !snowman, action, 0, 0, "")
        + mimic_pad_macro(29)
        + mimic_cudgel_finish());
}

boolean mimic_red_taffy_eligible(){
    return my_location() != $location[none]
        && last_monster() != $monster[Eldritch Tentacle]   // Attunement chains report the previous zone but aren't underwater
        && !($strings[replacing,Macrometeorite,CHEAT CODE: Replace Enemy] contains get_property("subscript"))
        && last_monster() != copyTarget
        && (my_location().environment == "underwater" || my_location() == to_location(get_property("_seadentWaveZone")));
}

string mimic_copy_actions(){
    string actions;
    if (last_monster() == copyTarget){
        if (!contains_text(get_property("_lastCombatActions"), "it6363;")
            && item_amount($item[pulled green taffy]) > 0 && item_amount($item[envyfish egg]) == 0
            && get_property("_envyfishEggUsed") == "false")
            actions += mimic_if("environment underwater", mimic_item($item[pulled green taffy]));
        if (dayType() == 1 && item_amount($item[4-d camera]) > 0 && item_amount($item[shaking 4-d camera]) == 0
            && get_property("_cameraUsed") == "false")
            actions += mimic_item($item[4-d camera]);
    }
    if (dayType() == 0 && last_monster() == $monster[Frozen Bag of Tortellini]
        && item_amount($item[4-d camera]) > 0 && item_amount($item[shaking 4-d camera]) == 0
        && get_property("_cameraUsed") == "false")
        actions += mimic_item($item[4-d camera]);
    if (mimic_red_taffy_eligible()
        && !contains_text(actions, mimic_item($item[pulled green taffy]))
        && !contains_text(get_property("_lastCombatActions"), "it6363;")
        && !contains_text(get_property("_lastCombatActions"), "it6367") && item_amount($item[pulled red taffy]) > 0)
        actions += mimic_if("environment underwater", mimic_item($item[pulled red taffy]));
    return actions;
}

string mimic_stasis_body(string prefix, boolean reanimatedInPrefix){
    return mimic_ordinary_stasis(prefix, reanimatedInPrefix, mimic_copy_actions());
}

string mimic_finish_prefix(boolean shadowSetupDone){
    string macro = mimic_if(mimic_before(10), "abort \"Mimic finisher reached before round ten\";");
    boolean shortFinish = last_monster().boss || get_property("subscript") == "looseFK";
    if (!shadowSetupDone && last_monster() == $monster[shadow guy] && shadowHatReady())
        macro += (shortFinish ? "" : mimic_late_pad(28))
            + mimic_finisher_action(mimic_skill($skill[PLACE YOUR HAT ON THEIR HEAD]));
    else if (!shadowSetupDone && last_monster() == $monster[shadow guy]){
        boolean gaze = gazeReady() && have_skill($skill[BCZ: Refracted Gaze]);
        if ((gaze || have_effect($effect[Fishy]) < 1020) && have_skill($skill[Sea *dent: Talk to Some Fish]))
            macro += mimic_optional(mimic_skill($skill[Sea *dent: Talk to Some Fish]));
        if (gaze) macro += mimic_optional(mimic_skill($skill[BCZ: Refracted Gaze]));
    }
    if (last_monster() == $monster[sausage goblin] && have_equipped($item[peridot of peril])
        && gazeReady() && have_skill($skill[BCZ: Refracted Gaze]))
        macro += mimic_optional(mimic_skill($skill[BCZ: Refracted Gaze]));
    if (last_monster().max_meat > 0 && have_equipped($item[mafia pointer finger ring]))
        macro += (shortFinish ? "" : mimic_late_pad(27)) + mimic_if(mimic_before(28), "attack;");
    if (last_monster() == $monster[Black Crayon Crimbo Elf] && have_equipped($item[legendary seal-clubbing club]))
        macro += (shortFinish ? "" : mimic_late_pad(28))
            + mimic_finisher_action(mimic_skill($skill[Club 'Em Into Next Week]));
    return macro;
}

boolean locketTortelliniCudgelReady(){
    return get_property("script") == "FreeKill" && get_property("subscript") == "locketTortellini"
        && last_monster() == $monster[Frozen Bag of Tortellini]
        && have_skill($skill[Carbohydrate Cudgel]) && item_amount($item[dry noodles]) > 0;
}

string mimic_sauce_finish(boolean curveballed){
    string macro;
    if (curveballed)
        macro += mimic_repeat(5, mimic_skill($skill[Saucegeyser]))
            + (item_amount($item[dry noodles]) > 0 ? mimic_finisher_action(mimic_skill($skill[Carbohydrate Cudgel]))
                : "abort \"No dry noodles for Cudgel\";");
    monster foe = last_monster();
    if (foe == $monster[spawn of wally])
        macro += mimic_repeat(10, "attack;");
    else if (!curveballed && !foe.boss && get_property("subscript") != "looseFK"){
        // Ordinary fights get two geysers; Tentacles can need more.
        int finishRound = foe == $monster[Eldritch Tentacle] ? 25 : 28;
        macro += mimic_late_pad(finishRound);
    }
    if (!curveballed && locketTortelliniCudgelReady())
        return macro + mimic_available_skill($skill[Saucegeyser]) + mimic_cudgel_finish();
    return macro + mimic_repeat(20, mimic_skill($skill[Saucegeyser]))
        + "abort \"Kill sequence exhausted its attempts or round budget; combat left open\";";
}

boolean mimic_regular_combat(string openers, boolean reanimatedInPrefix){
    if (current_round() == 0) return true;
    if (get_property("FKRunEligible") == "true" || get_property("subscript") == "looseFK"
        || last_monster() == $monster[shadow guy] || last_monster().boss
        || my_location() == $location[Gingerbread Civic Center] || glacierFight()
        || (last_monster() == $monster[sausage goblin] && have_equipped($item[peridot of peril]))
        || (last_monster() == $monster[Black Crayon Crimbo Elf] && have_equipped($item[legendary seal-clubbing club]))
        || (get_property("_curveballMonster").to_monster() == last_monster()
            && get_property("_curveballFightsLeft").to_int() > 0)
        || !mimic_macro_ready())
        return false;
    string macro = mimic_stasis_body(openers, reanimatedInPrefix)
        + mimic_finish_prefix(false) + mimic_sauce_finish(false);
    return mimic_submit(macro);
}
boolean mimic_regular_combat(string openers){ return mimic_regular_combat(openers, true); }
boolean mimic_regular_combat(){ return mimic_regular_combat("", false); }





boolean mimic_early_combat(){
    if (get_property("script") != "FreeKill"
        || !(my_familiar() == $familiar[stocking mimic]
            || (my_familiar() == $familiar[comma chameleon] && mimic_active_familiar() == $familiar[stocking mimic]))
        || (get_property("subscript") != "" && get_property("subscript") != "weakling")
        || my_location().zone == "Shadow Rift" || last_monster() == copyTarget
        || $monsters[flaming monstera, leaviathan] contains last_monster()
        || (have_equipped($item[backup camera]) && get_property("lastCopyableMonster").to_monster() == copyTarget)
        || (to_int(last_monster()) == get_property("killThisGuy").to_int() && get_property("swordSniff") == "true"))
        return false;
    if (get_property("subscript") == "weakling")
        return mimic_weakling_combat(mimic_common_openers());
    return mimic_regular_combat(mimic_common_openers());
}

// Native Gingerbread dudes: include common openers before shield stasis and the free kill.


boolean mimic_gingerbread_combat(){
    if (!isMimicFam() || get_property("script") != "FreeKill" || get_property("subscript") != "weakling"
        || !($locations[Gingerbread Upscale Retail District, Gingerbread Civic Center] contains my_location())
        || !(mimic_gingerbread_natives contains last_monster())
        || last_monster().phylum != $phylum[dude]
        || get_property("FKRunEligible") == "true" || last_monster() == copyTarget
        || (have_equipped($item[backup camera]) && get_property("lastCopyableMonster").to_monster() == copyTarget)
        || (to_int(last_monster()) == get_property("killThisGuy").to_int() && get_property("swordSniff") == "true"))
        return false;
    if (current_round() == 0) return true;
    if (item_amount($item[gingerbread cigarette]) == 0)
        abort("No gingerbread cigarette; stopping before stasis.");
    if (!mimic_macro_ready()) return false;
    return mimic_submit(mimic_gingerbread_body());
}


// Full Affinity fights use the same stasis and ending builders as split fights.
boolean mimic_affinity_combat(){
    monster foe = last_monster();
    if (get_property("script") != "FreeKill" || get_property("subscript") != ""
        || !(my_familiar() == $familiar[stocking mimic]
            || mimic_active_familiar() == $familiar[stocking mimic])
        || my_location() != $location[Shadow Rift (The Misspelled Cemetary)]
        || have_effect($effect[shadow affinity]) <= 0
        || !($monsters[shadow slab, shadow tree] contains foe)
        || foe == copyTarget
        || (get_property("_curveballMonster").to_monster() == foe && get_property("_curveballFightsLeft").to_int() > 0)
        || get_property("FKRunEligible") == "true"
        || (have_equipped($item[backup camera]) && get_property("lastCopyableMonster").to_monster() == copyTarget)
        || (get_property("swordSniff") == "true" && get_property("killThisGuy").to_int() == to_int(foe))
        || (have_equipped($item[Flash Liquidizer Ultra Dousing Accessory])
            && get_property("_douseFoeUses").to_int() < 3 && get_property("_douseFoeSuccess") == "false")
        || current_round() <= 0 || !mimic_macro_ready())
        return false;

    string macro = mimic_if(mimic_before(10), mimic_common_openers());
    if (get_property("_mildEvilPerpetrated").to_int() < 3)
        macro += mimic_available_skill($skill[Perpetrate Mild Evil]);
    if (get_property("_batWingsSwoopUsed").to_int() < 11)
        macro += mimic_available_skill($skill[Swoop Like a Bat]);
    macro = mimic_stasis_body(macro, true);
    macro += mimic_finish_prefix(false);
    int turns = total_turns_played();
    if (!mimic_submit(macro + mimic_sauce_finish(false))) return false;
    if (total_turns_played() != turns) abort("Shadow Affinity batch spent a turn.");
    return true;
}

// Default two-part path for ordinary Mimic fights not handled by a full macro.
// Keep replacements, captures, and location-specific routines at their old boundaries.
boolean mimic_decision_combat(){
    if (get_property("script") != "FreeKill" || !isMimicFam()
        || (get_property("subscript") != "" && get_property("subscript") != "looseFK")
        || current_round() <= 0 || last_monster().boss
        || ($monsters[flaming monstera, leaviathan, flaming leaflet, Eldritch Tentacle,
            Ron "The Weasel" Copperhead, Guard turtle] contains last_monster())
        || ($locations[Gingerbread Civic Center, Gingerbread Upscale Retail District,
            The Hidden Bowling Alley, Cyberzone 1, Cyberzone 2, Cyberzone 3] contains my_location())
        || (have_equipped($item[backup camera]) && get_property("lastCopyableMonster").to_monster() == copyTarget)
        || (get_property("_curveballMonster").to_monster() == last_monster()
            && get_property("_curveballFightsLeft").to_int() > 0)
        || (my_location().zone == "Shadow Rift" && have_equipped($item[Flash Liquidizer Ultra Dousing Accessory])
            && get_property("_douseFoeUses").to_int() < 3 && get_property("_douseFoeSuccess") == "false")
        || !mimic_macro_ready(have_equipped($item[April shower thoughts shield])))
        return false;
    string macro = mimic_if(mimic_before(10), mimic_common_openers());
    if (my_location().zone == "Shadow Rift"){
        if (get_property("_mildEvilPerpetrated").to_int() < 3)
            macro += mimic_available_skill($skill[Perpetrate Mild Evil]);
        if (get_property("_batWingsSwoopUsed").to_int() < 11)
            macro += mimic_available_skill($skill[Swoop Like a Bat]);
    }
    // Openers/copies/healing can legitimately carry the handoff past round 12.
    if (!mimic_submit(mimic_stasis_body(macro, true),
        "TGWH_STASIS_COMPLETE", 10, $item[none])) return false;
    mimic_stasis_batched = true;
    return true;
}

// After replacements/openers have already run, batch only the remaining stasis.
boolean mimic_remaining_stasis(){
    if (current_round() <= 0 || last_monster().boss
        || !mimic_macro_ready(have_equipped($item[April shower thoughts shield]))) return false;
    return mimic_submit(mimic_stasis_body("", false),
        "TGWH_STASIS_COMPLETE", 10, $item[none]);
}

record mimic_kill_plan {
    string initial;
    string beforeCoin;
    string items;
    boolean darts;
    boolean coin;
};

// Preserve free_kill's resource priority and account-specific caps.
mimic_kill_plan mimic_free_kill_plan(string page){
    mimic_kill_plan plan;
    if (last_monster() == $monster[giant sandworm] && get_property("shockingLickCharges").to_int() > 0
        && have_skill($skill[Shocking Lick]))
        plan.initial += mimic_finisher_action(mimic_skill($skill[Shocking Lick]));
    foreach sk in $skills[Spit jurassic acid, Darts: Aim for the Bullseye]{
        if (!freeKillSkillAllowed(sk, page)) continue;
        plan.initial += mimic_finisher_action(mimic_skill(sk));
        if (sk == $skill[Darts: Aim for the Bullseye]){
            plan.darts = true;
            string available = "hasskill " + to_int(sk);
            plan.initial += mimic_while("!times " + max(1, get_property("_dartsLeft").to_int())
                + " && " + available + " && " + mimic_before(30), mimic_skill(sk));
            plan.initial += mimic_if("pastround 29",
                "abort \"Dart batch ran out of rounds\";");
            plan.initial += mimic_if(available,
                "abort \"Dart batch exceeded its supply bound\";");
        }
    }
    foreach sk in $skills[Assert your Authority, Fire the Jokester's Gun, BCZ: Sweat Bullets,
        Shattering Punch, Gingerbread Mob Hit, Club 'Em Back in Time, Chest X-Ray]{
        if (freeKillSkillAllowed(sk, page)) plan.beforeCoin += mimic_finisher_action(mimic_skill(sk));
    }
    if (freeKillItemAllowed($item[replica bat-oomerang]))
        plan.beforeCoin += mimic_finisher_action(mimic_item($item[replica bat-oomerang]));
    plan.coin = freeKillItemAllowed($item[interesting coin]);
    if (freeKillItemAllowed($item[partial tombstone]))
        plan.items += mimic_finisher_action(mimic_item($item[partial tombstone]));
    if (freeKillItemAllowed($item[shadow brick]))
        plan.items += mimic_finisher_action(mimic_item($item[shadow brick]));
    return plan;
}

boolean saberLooseKillReady(){
    monster foe = last_monster();
    return get_property("subscript") == "looseFK"
        && get_property("mainOverride") == ", equip Fourth of May Cosplay Saber"
        && my_location() == $location[Shadow Rift (The Misspelled Cemetary)]
        && foe.copyable && !foe.boss && foe != copyTarget
        && !free_monster() && have_equipped($item[Fourth of May Cosplay Saber])
        && have_skill($skill[Use the Force]) && get_property("_saberForceUses").to_int() < 5;
}

void saberLooseKill(){
    string previousChoice = get_property("choiceAdventure1387");
    int before = get_property("_saberForceUses").to_int();
    try {
        set_property("choiceAdventure1387", "3");
        use_skill($skill[Use the Force]);
        if (handling_choice() && last_choice() == 1387)
            run_choice(3);
        if (current_round() > 0 || handling_choice() || get_property("_saberForceUses").to_int() != before + 1)
            abort("Loose free kill: could not confirm saber choice 1387/3.");
    } finally {
        set_property("choiceAdventure1387", previousChoice);
    }
}

boolean mimic_finish_combat(string page, boolean shadowSetupDone){
    if (current_round() == 0) return true;
    // After stasis, let the Glacier route track Vivian and use its shadow brick.
    if (glacierFight()) return false;
    if (!mimic_macro_ready(false)) return false;
    string macro = mimic_finish_prefix(shadowSetupDone);
    boolean curveballed = get_property("_curveballMonster").to_monster() == last_monster()
        && get_property("_curveballFightsLeft").to_int() > 0;
    if (get_property("subscript") == "looseFK" && !curveballed && !last_monster().boss && last_monster() != $monster[Eldritch Tentacle]){
        if (saberLooseKillReady()){
            if (!mimic_phase(macro)) return false;
            if (current_round() > 0) saberLooseKill();
            return true;
        }
        mimic_kill_plan plan = mimic_free_kill_plan(page);
        macro += plan.initial;
        if (plan.darts){
            if (!mimic_submit(macro, "TGWH_BULLSEYE_UNAVAILABLE", 10, $item[none]))
                abort("Dart batch did not submit; refusing to replay its prefix.");
            if (current_round() == 0) return true;
            // The server reached the receipt only with Bullseye unavailable and time left.
            // Mafia can still parse the pre-macro dartboard as the current dart count.
            macro = "";
        }
        macro += plan.beforeCoin;
        if (plan.coin){
            // KoLmafia recognizes this same heads message; '*' tolerates HTML tags.
            string coin = to_int($item[interesting coin]);
            macro += mimic_while(mimic_before(29) + " && !match \"Heads,*you win!\"",
                mimic_if("!hascombatitem " + coin, "abort \"Interesting coin unavailable\";")
                + mimic_item($item[interesting coin]));
            if (!mimic_submit(macro, "TGWH_COIN_COMPLETE", 10, $item[none]))
                abort("Coin batch did not submit; refusing to replay its prefix.");
            if (current_round() == 0) return true;
            // The server loop can exit only on heads or its round budget; no local clock check.
            macro = "";
        }
        macro += plan.items;
        if (my_location() != $location[Shadow Rift (The Misspelled Cemetary)]
            || have_effect($effect[Shadow Affinity]) == 0)
            macro += "abort \"Loose free kill did not end the fight. Refusing a paid kill\";";
    }
    if (!mimic_submit(macro + mimic_sauce_finish(curveballed)))
        abort("Finisher did not submit; refusing to replay its prefix.");
    return true;
}

void mimic_shadow_guy_setup(){
    if (current_round() == 0) return;
    if (isMimicFam()){
        mimic_requires_hp = false;
        mimic_submit("", "TGWH_STASIS_COMPLETE", 10, $item[none]);
    }
    if (shadowHatReady()){
        string pad = !isMimicFam() || get_property("subscript") == "looseFK" ? "" : mimic_late_pad(28);
        if (!mimic_phase(pad + mimic_finisher_action(mimic_skill($skill[PLACE YOUR HAT ON THEIR HEAD]))))
            use_skill($skill[PLACE YOUR HAT ON THEIR HEAD]);
        return;
    }
    if (!gazeReady() || !have_skill($skill[BCZ: Refracted Gaze])){
        waffleShadowGuy(); // A waffle can replace the monster; inspect before finishing.
        return;
    }
    string macro;
    if (have_skill($skill[Sea *dent: Talk to Some Fish]))
        macro += mimic_skill($skill[Sea *dent: Talk to Some Fish]);
    macro += mimic_skill($skill[BCZ: Refracted Gaze]);
    if (mimic_phase(macro)) return;
    if (have_skill($skill[Sea *dent: Talk to Some Fish]))
        use_skill($skill[Sea *dent: Talk to Some Fish]);
    use_skill($skill[BCZ: Refracted Gaze]);
}

// ─── 1. OPENERS ───────────────────────────────────────────────────────────────
    // Each may act and leave the fight running for the next stage.

    // Spend every available round dealing damage before the Horror ejects us.
    void eldritchHorror(){
        if (current_round() == 0) return;
        if (!have_skill($skill[Shrap]) || item_amount($item[warbear whosit]) == 0)
            abort("Eldritch Horror: Shrap or its warbear whosit is unavailable.");
        visit_url("fight.php?action=macro&macrotext=" + url_encode(
            mimic_while("hasskill " + to_int($skill[Shrap]), mimic_skill($skill[Shrap]))
            + "abort \"Shrap unavailable\";"), true, true);
        if (current_round() > 0)
            abort("Eldritch Horror: Shrap stopped before the fight ended.");
    }

    // subscript names a replacer skill: Noob Cave crate -> copyTarget.
    void replacementChain(){
        skill replacer = to_skill(get_property("subscript"));
        if (!($skills[Macrometeorite, CHEAT CODE: Replace Enemy] contains replacer) || last_monster() == copyTarget)
            return;
        if (my_location() != $location[Noob Cave] || last_monster() != $monster[crate]
            || replacer == $skill[none] || !have_skill(replacer))
            abort("Replacement chain: unexpected encounter or unavailable replacement.");
        use_skill(replacer);
        if (last_monster() != copyTarget)
            abort("Replacement chain: did not produce " + copyTarget + ".");
    }

    void printFightInfo(){
        print("monster hp is " + last_monster().base_hp);
        print("monster attack is " + last_monster().base_attack);
        print("monster level is " + numeric_modifier("monster level"));
        print("high stat is " + max(my_buffedstat($stat[muscle]),my_buffedstat($stat[mysticality]),my_buffedstat($stat[moxie])));
    }

    // Vintner vs school of many: jug/shavings/spines, then dictionary, then ice.
    void schoolOfMany(){
        if (last_monster() != $monster[school of many] || my_familiar() != $familiar[vampire vintner])
            return;
        if (current_round() == 1)
            throw_items($item[grody jug],$item[pufferfish spine]);
        while (current_round() > 1 && current_round() < 4)
            throw_items($item[crayon shavings],$item[pufferfish spine]);
        while (current_round() > 3 && current_round() < 20)
            throw_items($item[pufferfish spine],$item[pufferfish spine]);
        while (current_round() > 19 && current_round() < 30)
            throw_item($item[facsimile dictionary]);
        throw_item($item[shard of double-ice]);
    }

    skill mimic_copy_tracking_skill(){
        if (get_property("_monsterHabitatsFightsLeft").to_int() == 0){
            if (get_property("_monsterHabitatsRecalled").to_int() < 3)
                return $skill[RECALL FACTS: MONSTER HABITATS];
            if (get_property("beGregariousFightsLeft").to_int() == 0
                && get_property("beGregariousCharges").to_int() > gregsToSave() && dayType() == 1)
                return $skill[Be Gregarious];
        }
        if (my_familiar() == $familiar[reanimated reanimator] && get_property("_badlyRomanticArrows") == "0")
            return $skill[Wink at];
        return $skill[none];
    }

    // Copy target: habitats / gregarious / wink, circadian, candle, putty; then the
    // dive-bar gregarious replace.
    void copyTargetOpeners(){
        if (last_monster() == copyTarget){
            skill tracking = mimic_copy_tracking_skill();
            if (tracking != $skill[none]) use_skill(tracking);
            if (get_property("_circadianRhythmsRecalled") == "false")
                use_skill($skill[RECALL FACTS: %PHYLUM CIRCADIAN RHYTHMS]);
            if (have_equipped($item[roman candelabra]))
                use_skill($skill[blow the purple candle!]);
            if (have_item($item[spooky putty sheet]) && get_property("spookyPuttyCopiesMade").to_int() < 5)
                throw_item($item[spooky putty sheet]);
        }
        if (to_monster(get_property("beGregariousMonster")) == copyTarget && get_property("beGregariousFightsLeft").to_int() > 0 && my_location() == $location[the dive bar])
            replace();
    }

    // Cyberzone constructs: cyber rocks, malware on the tough ones, logic grenade.
    void cyberConstructs(){
        if (!($locations[cyberzone 1,cyberzone 2,cyberzone 3] contains my_location()) || last_monster().phylum != $phylum[construct])
            return;
        if (current_round() > 0 && mimic_macro_ready(false)){
            boolean malware = $monsters[ICE barrier,corruption quarantine,parental controls,null container] contains last_monster();
            int finishRound = last_monster().boss || malware ? 27 : 28;
            string macro = mimic_while(mimic_before(finishRound) + " && !hpbelow " + (floor(my_maxhp() / 10.0) + 1),
                mimic_if("!hasskill " + to_int($skill[Throw Cyber Rock]), "abort \"Cyber rock unavailable\";")
                + mimic_skill($skill[Throw Cyber Rock]));
            if (malware) macro += mimic_skill($skill[Deploy Glitched Malware]);
            macro += mimic_skill($skill[Launch Logic Grenade]);
            if (mimic_submit(macro, "TGWH_CYBER_COMPLETE", 1, $item[none])) return;
        }
        while (current_round() > 0 && current_round() < 27 && my_hp() > my_maxhp()/10)
            use_skill($skill[throw cyber rock]);
        if ($monsters[ICE barrier,corruption quarantine,parental controls,null container] contains last_monster())
            use_skill($skill[deploy glitched malware]);
        use_skill($skill[Launch Logic Grenade]);
    }

    void hiddenBowlingAlley(){
        if (my_location() != $location[The Hidden Bowling Alley])
            return;
        if (last_monster() == $monster[pygmy bowler])
            use_skill($skill[Show them your ring]);
        if (last_monster() == $monster[pygmy orderlies]){
            use_skill($skill[spring kick]);
            use_skill($skill[spring away]);
        }
    }

    // subscript "screech": screech the zone's phylum, then get out.
    void screech(string page_text){
        if (get_property("subscript") != "screech" || last_monster().phylum != screechPhylum[my_location()])
            return;
        if (contains_text(last_monster().attributes,"WANDERER"))
            abort("wanderer");
        use_skill($skill[%fn, Release the Patriotic Screech!]);
        if (dayType() == 1){
            if (get_property("_snokebombUsed").to_int() < 3)
                use_skill($skill[snokebomb]);
            else
                throw_item($item[peppermint parasol]);
        } else {
            throw_item($item[stuffed yam stinkbomb]);
        }
        if (get_property("script") == "FreeKill") {
            free_run(page_text);
            if (current_round() > 0)
                abort("use free run");
        }
    }

    // subscript "stompingBoots": Curveball or a verified Boots runaway.
    void stompingBoots(){
        if (get_property("subscript") != "stompingBoots")
            return;
        if (last_monster() == $monster[infinite meat bug])
            abort();
        if (last_monster() != copyTarget && have_skill($skill[Bowl a Curveball]))
            use_skill($skill[Bowl a Curveball]);
        if (current_round() == 0)
            return;
        if (mimic_active_familiar() != $familiar[Pair of Stomping Boots])
            abort("Boots runaway requires Stomping Boots or a Comma Chameleon mimicking them.");
        if (get_property("_banderRunaways").to_int() >= floor((my_familiar().familiar_weight() + weight_adjustment()) / 5.0))
            abort("No free boot runaways remain with the current equipment.");
        runaway();
    }

    // Finish a known boss in one request when no host-side decision can intervene.
    boolean mimic_padded_shadow_boss(){
        monster foe = last_monster();
        if (!isMimicFam() || current_round() <= 0 || get_property("subscript") != ""
            || get_property("FKRunEligible") == "true" || foe == copyTarget
            || my_location() != $location[Shadow Rift (The Misspelled Cemetary)]
            || get_property("fartoShadowOutfitProfile") != "other"
            || (have_equipped($item[backup camera]) && get_property("lastCopyableMonster").to_monster() == copyTarget)
            || have_equipped($item[heartstone]) || have_equipped($item[April shower thoughts shield])
            || (get_property("_curveballMonster").to_monster() == foe && get_property("_curveballFightsLeft").to_int() > 0)
            || !mimic_macro_ready(false))
            return false;

        string macro = mimic_pad_macro(11) + mimic_basic_openers();
        return mimic_submit(macro + mimic_finish_prefix(false) + mimic_sauce_finish(false));
    }

    // FreeKill: the Shadow Rift bosses.
    void shadowBosses(){
        if (get_property("script") != "FreeKill")
            return;
        if (last_monster() == $monster[shadow spire] || last_monster() == $monster[shadow scythe]){
            boolean slicker = have_equipped($item[wicker slicker]);
            int finishRound = 11;
            if (isMimicFam() && current_round() > 0 && mimic_macro_ready(false)){
                string macro;
                if (slicker){
                    macro += mimic_while(mimic_before(finishRound),
                        mimic_if("!hasskill " + to_int($skill[Shell Up]), "abort \"Shell Up unavailable\";")
                        + mimic_skill($skill[Shell Up]));
                } else {
                    foreach sk in $skills[Silent Slam,Sauceshell,Shell Up]
                        if (have_skill(sk)) macro += mimic_skill(sk);
                    macro += mimic_pad_macro(finishRound);
                }
                macro += mimic_finisher_action(mimic_skill($skill[Saucegeyser]));
                if (mimic_submit(macro, "TGWH_SHADOW_BOSS_COMPLETE", 10, $item[none])) return;
            }
            if (slicker){
                while (current_round() > 0 && current_round() < finishRound){
                    int round = current_round();
                    use_skill($skill[Shell Up]);
                    if (current_round() == round)
                        abort("Shell Up did not advance the shadow boss fight.");
                }
            } else {
                foreach sk in $skills[Silent Slam,Sauceshell,Shell Up]{
                    if (have_skill(sk))
                        use_skill(sk);
                }
                if (isMimicFam()) mimic_pad_ash(finishRound);
            }
            if (current_round() > 0)
                use_skill($skill[saucegeyser]);
        }
        if (last_monster() == $monster[shadow orrery]){
            if (current_round() > 0){
                // Single-item padding and attacks do not require Funkslinging or Manuel.
                mimic_macro_ready(false);
                mimic_submit(mimic_pad_macro(11) + mimic_repeat(30, "attack;")
                    + "abort \"Orrery finisher did not win; combat left open\";");
            }
        } else if ($monsters[shadow cauldron, shadow matrix, shadow tongue] contains last_monster()){
            if (mimic_padded_shadow_boss()) return;
            if (isMimicFam() && current_round() > 0 && mimic_macro_ready(false)
                && mimic_submit(mimic_pad_macro(11),
                    "TGWH_SHADOW_PAD_COMPLETE", 10, $item[none])) return;
            mimic_pad_ash(11);
        }
    }

    // Every-fight buffs (avalanche/spikolodon/steal/sing along/reanimate/bowling
    // ball/kill-a-lot). Shadow scythe/spire, guard turtle and bladdering skip them;
    // the spire gets sauced instead.
    void commonOpeners(){
        if (last_monster() != $monster[shadow scythe] && last_monster() != $monster[shadow spire] && last_monster() != $monster[Guard turtle] && get_property("subscript") != "bladdering") {
            if (get_property("script") == "FreeKill" && current_round() > 0
                && mimic_phase(mimic_basic_openers())) return;
            if (have_skill($skill[McHugeLarge Avalanche]))         use_skill($skill[McHugeLarge Avalanche]);
            if (have_skill($skill[Launch spikolodon spikes]))      use_skill($skill[Launch spikolodon spikes]);
            if (my_primestat() == $stat[moxie] || have_equipped($item[mime army infiltration glove])) steal();
            if (have_skill($skill[sing along]) && mimic_sing_allowed())
            {
                int started = now_to_int();
                use_skill($skill[sing along]);
                if (get_property("script") == "FreeKill" && isMimicFam())
                    print("[Mimic timing] baseline_ms=" + (now_to_int() - started), "gray");
            }
            reanimate();
            if (mimic_bowling_allowed())
                use_skill($skill[Bowl Straight Up]);
            if (to_int(last_monster()) == to_int(get_property("killThisGuy")) && get_property("swordSniff") == true)
                use_skill($skill[%fn, kill a lot of these guys]);
        } else if (last_monster() == $monster[shadow spire]){
            if (get_property("script") == "FreeKill" && mimic_phase(mimic_repeat(4, mimic_skill($skill[Saucegeyser]))))
                return;
            sauce(4);
        }
    }

    // FreeKill with the backup camera on a copyTarget chain: back up, then eggs / gregarious.
    void backupCamera(){
        if (get_property("script") != "FreeKill" || !have_equipped($item[backup camera]) || get_property("lastCopyableMonster").to_monster() != copyTarget)
            return;
        if (last_monster() == $monster[Mer-kin tippler] && !isTracked($monster[Mer-kin tippler], $skill[Transcendent Olfaction])){
            use_skill($skill[Transcendent Olfaction]);
            if (have_skill($skill[Gallapagosian Mating Call]))
                use_skill($skill[Gallapagosian Mating Call]);
            use_skill($skill[McHugeLarge Slash]);
        }
        use_skill($skill[BACK-UP TO YOUR LAST ENEMY]);
        if (last_monster() != copyTarget)
            return;
        while (my_familiar() == $familiar[chest mimic] && to_int(get_property("_mimicEggsObtained")) < 11 && $familiar[chest mimic].experience > 50)
            use_skill($skill[%FN, LAY AN EGG]);
        // The last target persists after its chain ends; only active fights block reseeding.
        if (current_round() > 0 && gregsToSave() > 0
            && get_property("beGregariousFightsLeft").to_int() == 0
            && get_property("beGregariousCharges").to_int() > 0)
        {
            if (current_round() > 0 && (get_property("subscript") == "" || get_property("subscript") == "replacing")
                && (my_familiar() == $familiar[Stocking Mimic] || mimic_active_familiar() == $familiar[Stocking Mimic])
                && !have_equipped($item[heartstone])
                && mimic_regular_combat(mimic_available_skill($skill[Be Gregarious]), false)) return;
            use_skill($skill[Be Gregarious]);
        }
    }

    // Mimic familiars vs the monstera / leaviathan: wear it down, then lasso.
    void leafBosses(){
        if (!isMimicFam() || (last_monster() != $monster[flaming monstera] && last_monster() != $monster[leaviathan]))
            return;
        if (current_round() > 0 && mimic_macro_ready(false)){
            string lasso = to_int($item[lit leaf lasso]);
            string macro = mimic_while(mimic_before(10),
                mimic_item($item[facsimile dictionary]))
                + mimic_if("!hastwocombatitems " + lasso, "abort \"Missing paired leaf lassos\";")
                + mimic_finisher_action("use " + lasso + "," + lasso + ";");
            item capture = last_monster() == $monster[flaming monstera]
                ? $item[tied-up flaming monstera] : $item[tied-up leaviathan];
            if (mimic_submit(macro, "", 1, capture)) return;
        }
        mimic_pad_ash(11);
        throw_items($item[lit leaf lasso],$item[lit leaf lasso]);
        if (current_round() > 0)
            abort();
    }

// ─── 2. ROUTINES THAT END THE FIGHT ───────────────────────────────────────────
    // Each returns true when it handled (finished) the fight.

    boolean redButtonsCableFight(){
        if (last_monster() != $monster[man with the red buttons]
            || my_location() != $location[The Red Zeppelin]
            || get_property("NCtoC") != "false" || get_property("_glarkCableUses").to_int() >= 5)
            return false;
        if (item_amount($item[glark cable]) == 0)
            abort("Red Zeppelin: missing the glark cable for the Man with the Red Buttons.");

        // The shard can leave the boss within one round of passive damage.
        while (current_round() > 0 && current_round() < 11 && monster_hp() > 20){
            int roundBefore = current_round();
            throw_item($item[facsimile dictionary]);
            if (current_round() == roundBefore)
                break;
        }
        if (current_round() > 0)
            throw_item($item[glark cable]);
        if (current_round() > 0)
            abort("Red Zeppelin: the glark cable did not finish the fight.");
        return true;
    }

    // Mimic weaklings: reserve BALLS round 29 for Cudgel and leave the final slot open.
    boolean weaklingFight(){
        if (!isMimicFam() || get_property("subscript") != "weakling")
            return false;
        reanimate();
        if (redButtonsCableFight()) return true;
        if (mimic_weakling_combat()) return true;
        if (!mimic_weakling_stasis()){
        while (current_round() > 0 && current_round() < 30 && (last_monster() == $monster[X-32-F Combat Training Snowman] || monster_hp() > 9)){
            if (have_equipped($item[april shower thoughts shield]))
                use_skill($skill[shieldbutt]);
            else {
                throw_item($item[facsimile dictionary]);
                if (current_round() > 10)
                    break;
            }
            heal(100);
        }
        mimic_pad_ash(11);
        }
        if (glacierFight()){
            while (current_round() > 0 && last_monster() != $monster[Vivian Vibrian Vumian Varr] && item_amount($item[waffle]) > 0)
                throw_item($item[waffle]);
            if (current_round() > 0 && last_monster() == $monster[Vivian Vibrian Vumian Varr])
                use_skill($skill[Use the Force]);
        }
        if (last_monster() == $monster[eldritch tentacle])
            sauce(4);
        if (last_monster() == $monster[flaming leaflet])
            throw_items($item[lit leaf lasso],$item[lit leaf lasso]);
        if (last_monster() == $monster[Ron "The Weasel" Copperhead]){
            use_skill($skill[Club 'Em Back in Time]);
            while (current_round() > 0 && current_round() < 20)
                attack();
            use_skill($skill[saucegeyser]);
        }
        if (get_property("FKRunEligible") == "true" && (get_property("freeMeat").to_int() + 3500) > my_meat())
            throw_item($item[stuffed yam stinkbomb]);
        if (my_location() == $location[the red zeppelin] && get_property("_glarkCableUses").to_int() < 5 && get_property("NCtoC") == "false")
            throw_item($item[glark cable]);
        if (my_location() == $location[Gingerbread Upscale Retail District] || my_location() == $location[Gingerbread civic center]){
            if (last_monster().phylum == $phylum[dude])
                throw_item($item[gingerbread cigarette]);
            else if (last_monster() == $monster[eldritch tentacle]){
                while (current_round() > 0 && current_round() < 30)
                    use_skill($skill[shieldbutt]);
            }
        }
        if (have_equipped($item[unwrapped knock-off retro superhero cape])){
            string pad = last_monster().boss ? "" : mimic_late_pad(28);
            mimic_phase(pad + mimic_optional(mimic_skill($skill[Saucegeyser])));
        }
        if (current_round() == 0 || mimic_weakling_finish()) return true;
        while (current_round() > 0 && current_round() < 29 && (last_monster() == $monster[X-32-F Combat Training Snowman] || monster_hp() > 9)){
            if (have_equipped($item[april shower thoughts shield]))
                use_skill($skill[shieldbutt]);
            else
                attack();
        }
        if (current_round() > 0){
            // Finish in one server macro; a Mafia-derived !times count can overshoot.
            mimic_requires_hp = false;
            mimic_submit(mimic_pad_macro(29) + mimic_cudgel_finish());
        }
        return true;
    }

    // Pocket Professor: lectures (+ thesis on day 2), candle, then sauce.
    boolean professorFight(){
        if (mimic_active_familiar() != $familiar[pocket professor] && my_familiar() != $familiar[pocket professor])
            return false;
        if (current_round() > 0 && mimic_macro_ready(false)){
            string macro = mimic_available_skill($skill[lecture on relativity]);
            if (dayType() == 1 && !get_property("_thesisDelivered").to_boolean())
                macro += mimic_available_skill($skill[deliver your thesis!]);
            if (have_effect($effect[everything looks purple]) == 0 && have_equipped($item[roman candelabra]))
                macro += mimic_optional(mimic_skill($skill[Blow the Purple Candle!]));
            macro += mimic_heal(500) + mimic_repeat(4, mimic_skill($skill[Saucegeyser]));
            if (mimic_submit(macro)) return true;
        }
        if (have_skill($skill[lecture on relativity]))
            use_skill($skill[lecture on relativity]);
        if (dayType() == 1 && !get_property("_thesisDelivered").to_boolean() && have_skill($skill[deliver your thesis!]))
            use_skill($skill[deliver your thesis!]);
        purpleCandle();
        heal(500);
        sauce(4);
        return true;
    }

    // Stocking mimic in FreeKill: shieldbutt/dictionary to round 10 for the candies,
    // copy-target extras, then end it (free kill / curveball / sauce).
    boolean mimicFreeKill(string page_text){
        if ((mimic_active_familiar() != $familiar[stocking mimic] && my_familiar() != $familiar[stocking mimic]) || get_property("script") != "FreeKill")
            return false;
        if (!mimic_stasis_batched && my_location().zone == "Shadow Rift" && last_monster().boss == false){
            while (to_int(get_property("_douseFoeUses")) < 3 && get_property("_douseFoeSuccess") == "false"
                && current_round() > 0 && current_round() < 25 && have_equipped($item[Flash Liquidizer Ultra Dousing Accessory]))
                use_skill($skill[douse foe]);
            if (to_int(get_property("_mildEvilPerpetrated")) < 3) use_skill($skill[perpetrate mild evil]);
            if (to_int(get_property("_batWingsSwoopUsed")) < 11)  use_skill($skill[swoop like a bat]);
        }
        if (!mimic_stasis_batched){
            if (mimic_regular_combat()) return true;
            if (!mimic_remaining_stasis()){
                while (current_round() > 0 && current_round() < 30 && monster_hp() > 9 && have_equipped($item[april shower thoughts shield])){
                    use_skill($skill[shieldbutt]);
                    heal(100);
                }
                reanimate();
                while (current_round() > 0 && current_round() < 10){
                    throw_item($item[facsimile dictionary]);
                    purpleCandle();
                    if (last_monster() == copyTarget){
                        if (item_amount($item[pulled green taffy]) > 0 && item_amount($item[envyfish egg]) == 0 && get_property("_envyfishEggUsed") == "false")
                            throw_item($item[pulled green taffy]);
                        if (item_amount($item[4-d camera]) > 0 && item_amount($item[shaking 4-d camera]) == 0 && get_property("_cameraUsed") == "false" && dayType() == 1)
                            throw_item($item[4-d camera]);
                    }
                    if (item_amount($item[4-d camera]) > 0 && item_amount($item[shaking 4-d camera]) == 0 && get_property("_cameraUsed") == "false" && dayType() == 0 && last_monster() == $monster[Frozen Bag of Tortellini])
                        throw_item($item[4-d camera]);
                    if (mimic_red_taffy_eligible() && !contains_text(get_property("_lastCombatActions"),"it6363;")
                        && !contains_text(get_property("_lastCombatActions"),"it6367") && item_amount($item[pulled red taffy]) > 0)
                        throw_item($item[pulled red taffy]);
                    heal(200);
                }
                // The legacy HP fallback must prove the minimum on the server too.
                mimic_pad_ash(11);
            }
        }
        if (current_round() == 0) return true;
        if (get_property("FKRunEligible") == "true" && (get_property("freeMeat").to_int() + 3500) > my_meat())
            throw_item(wet() ? $item[pulled indigo taffy] : $item[stuffed yam stinkbomb]);
        if (current_round() == 0) return true;
        if (my_location() == $location[Gingerbread Civic Center])
            throw_item($item[gingerbread cigarette]);
        if (current_round() == 0) return true;
        if (my_location() == $location[Shadow Rift (The Misspelled Cemetary)]
            && have_equipped($item[legendary acorndion]) && have_skill($skill[Cadenza])){
            use_skill($skill[Cadenza]);
            if (current_round() == 0) return true;
        }
        boolean shadowSetupDone;
        if (last_monster() == $monster[shadow guy]
            && !shadowHatReady() && !(gazeReady() && have_skill($skill[BCZ: Refracted Gaze]))
            && have_effect($effect[Fishy]) >= 1020 && shadowGuyWaffleWorthwhile()){
            throw_item($item[waffle]);
            shadowSetupDone = true; // Inspect the replacement before building its ending.
        }
        if (current_round() == 0) return true;
        if (mimic_finish_combat(page_text, shadowSetupDone)) return true;
        // No-action setup fallback only. Submitted partial failures abort, never replay.
        if (!shadowSetupDone && last_monster() == $monster[shadow guy])
            mimic_shadow_guy_setup();
        if (current_round() == 0) return true;
        if (last_monster() == $monster[eldritch tentacle])
            sauce(4);
        if (glacierFight()){
            if (last_monster() == $monster[Vivian Vibrian Vumian Varr] && get_property("subscript") == "prebaseball"){
                if (!contains_text(get_property("trackedMonsters"),"Vivian Vibrian Vumian Varr:McHugeLarge Slash")){
                    if (!contains_text(get_property("trackedMonsters"),"Vivian Vibrian Vumian Varr:Transcendent Olfaction"))
                        use_skill($skill[transcendent olfaction]);
                    use_skill($skill[Gallapagosian Mating Call]);
                    if (have_equipped($item[McHugeLarge left pole]))
                        use_skill($skill[McHugeLarge Slash]);
                }
                if (current_round() > 0 && item_amount($item[shadow brick]) > 0){
                    int bricks = get_property("_shadowBricksUsed").to_int();
                    throw_item($item[shadow brick]);
                    if (get_property("_shadowBricksUsed").to_int() == bricks)
                        set_property("_shadowBricksUsed", bricks + 1);
                }
            } else {
                if (!contains_text(get_property("banishedMonsters"),"Baseball Diamond")){
                    if (current_round() > 0 && item_amount($item[shadow brick]) > 0){
                        int bricks = get_property("_shadowBricksUsed").to_int();
                        throw_item($item[shadow brick]);
                        if (get_property("_shadowBricksUsed").to_int() == bricks)
                            set_property("_shadowBricksUsed", bricks + 1);
                    }
                }
                while (last_monster() != $monster[Vivian Vibrian Vumian Varr] && current_round() > 0 && item_amount($item[waffle]) > 0)
                    throw_item($item[waffle]);
                if (current_round() > 0 && item_amount($item[shadow brick]) > 0){
                    int bricks = get_property("_shadowBricksUsed").to_int();
                    throw_item($item[shadow brick]);
                    if (get_property("_shadowBricksUsed").to_int() == bricks)
                        set_property("_shadowBricksUsed", bricks + 1);
                }
            }
        }
        if (current_round() == 0) return true;
        if (gazeReady() && have_skill($skill[BCZ: Refracted Gaze])
            && last_monster() == $monster[sausage goblin] && have_equipped($item[peridot of peril]))
            use_skill($skill[BCZ: Refracted Gaze]);
        if (last_monster().max_meat > 0 && have_equipped($item[mafia pointer finger ring]) && current_round() < 28)
            attack();
        if (last_monster() == $monster[Black Crayon Crimbo Elf] && have_equipped($item[legendary seal-clubbing club]))
            use_skill($skill[Club 'Em Into Next Week]);
        boolean curveballed = get_property("_curveballMonster").to_monster() == last_monster() && get_property("_curveballFightsLeft").to_int() > 0;
        if (get_property("subscript") == "looseFK" && !curveballed && last_monster().boss == false && last_monster() != $monster[Eldritch Tentacle]){
            if (current_round() > 0 && saberLooseKillReady()){
                saberLooseKill();
                return true;
            }
            if (last_monster() == $monster[giant sandworm] && get_property("shockingLickCharges").to_int() > 0)
                use_skill($skill[Shocking Lick]);
            free_kill(page_text);
        }
        if (curveballed){
            sauce(5);
            use_skill($skill[carbohydrate cudgel]);
        }
        if (get_property("subscript") == "looseFK" && current_round() > 0 && last_monster().boss == false && last_monster() != $monster[Eldritch Tentacle]
            && (my_location() != $location[Shadow Rift (The Misspelled Cemetary)] || have_effect($effect[shadow affinity]) == 0))
            abort();
        if (current_round() > 0) mimic_pad_ash(11);
        if (current_round() == 0) return true;
        if (!curveballed && locketTortelliniCudgelReady()){
            if (current_round() < 29 && have_skill($skill[Saucegeyser]) && my_mp() >= mp_cost($skill[Saucegeyser]))
                use_skill($skill[Saucegeyser]);
            if (current_round() > 0 && current_round() <= 29)
                use_skill($skill[Carbohydrate Cudgel]);
            if (current_round() > 0) abort("Locket tortellini survived its finishers.");
            return true;
        }
        if (last_monster() == $monster[spawn of wally])
            attack(10);
        sauce(20);
        return true;
    }

    // Witchess pieces and sausage goblins.
    boolean witchessFight(){
        if (!($monsters[witchess bishop, sausage goblin, witchess rook, witchess pawn, witchess knight] contains last_monster()))
            return false;
        purpleCandle();
        if (have_equipped($item[legendary seal-clubbing club]))
            use_skill($skill[Club 'Em Into Next Week]);
        sauce(2); attack(5);
        return true;
    }

    // Cursed magnifying glass void monsters.
    boolean voidFight(){
        if (!($monsters[void guy, void slab, void spider] contains last_monster()))
            return false;
        if (have_equipped($item[legendary seal-clubbing club]) && get_property("_voidFreeFights").to_int() < 4 && dayType() == 0)
            use_skill($skill[Club 'Em Into Next Week]);
        sauce(2); attack(5);
        return true;
    }

    // Day-1 seal clubber: top up Fishy in the Friars-side zones.
    void fishyTopUp(){
        if ($locations[The Laugh Floor, Infernal Rackets Backstage, The Dark Elbow of the Woods] contains my_location()
            && dayType() == 0 && my_class() == $class[seal clubber] && have_effect($effect[fishy]) < my_adventures())
            use_skill($skill[Sea *dent: Talk to Some Fish]);
    }

    // sauceLocs / sauceMobs: run if it would cost a turn, then sauce out.
    boolean sauceFight(string page_text){
        if (!sauceLocs[my_location()] && !sauceMobs[last_monster()])
            return false;
        if (!free_monster() && !free_location() && (my_location() != $location[The Laugh Floor] || last_monster().boss == false))
            free_run(page_text);
        if (current_round() > 0 && have_equipped($item[snowman-enchanting tophat]) && get_property("_snowmanHatPlaceUsed").to_int() < 3
            && $monsters[inkubus, serialbus, suckubus, BL Imp, CH Imp, Pr Imp] contains last_monster())
            use_skill($skill[PLACE YOUR HAT ON THEIR HEAD]);
        sauce(7);
        attack(3);
        return true;
    }

    // hurtLocs / hurtMobs: hurting crystals until it's over.
    boolean hurtFight(){
        if (!hurtLocs[my_location()] && !hurtMobs[last_monster()])
            return false;
        while (current_round() > 0) hurt(1);
        return true;
    }

// ─── 3. ZONE ROUTINES ─────────────────────────────────────────────────────────

    boolean barfMountain(string page_text){
        if (have_skill($skill[pocket crumbs]) && to_int(get_property("_pantsgivingCrumbs")) < 9)
            use_skill($skill[pocket crumbs]);
        if (my_familiar() == $familiar[patriotic eagle])
            use_skill($skill[%FN, LET'S PLEDGE ALLEGIANCE TO A ZONE]);
        if (last_monster() == $monster[garbage tourist] && to_int(get_property("_knuckleboneDrops")) == 100)
            sniff($monster[garbage tourist]);
        else if (last_monster() == $monster[angry tourist] && to_int(get_property("_knuckleboneDrops")) < 100)
            sniff($monster[angry tourist]);
        free_kill(page_text);
        free_run(page_text);
        dart();
        cleanUp();
        return true;
    }

    // NOTE: unreachable while the cyberzones are in sauceLocs (sauceFight() ends the fight first).
    boolean cyberzone(){
        if (have_equipped($item[heartstone]) && (last_monster() == $monster[greyhat hacker] || last_monster() == $monster[bluehat hacker]))
            use_skill($skill[Steal Monster's Heart]);
        if (get_property("_cyberFreeFights").to_int() == 9)
            use_skill($skill[sea *dent: throw a lightning bolt]);
        sauce(5);
        return true;
    }

    boolean redZeppelin(){
        if (to_int(get_property("_glarkCableUses")) < 5)
            throw_item($item[glark cable]);
        if (last_monster() == $monster[red skeleton])
            sauce(5);
        if (current_round() != 0)
            abort();
        return true;
    }

    // Dreadsylvania: shared opener, then per-zone finish. Woods monsters that aren't
    // bugbears/werewolves fall through to the fallback.
    boolean dreadsylvania(string page_text){
        free_run(page_text);
        free_kill(page_text);
        if (last_monster() != $monster[hot werewolf])
            dart();
        if (have_skill($skill[Slay the Dead])) use_skill($skill[Slay the Dead]);
        insta_kill(page_text);
        if (get_property("_monkeyPawWishesUsed") == "0" && have_equipped($item[cursed monkey's paw])){
            use_skill($skill[monkey slap]);
            return true;
        }
        string name = last_monster().name;
        switch (my_location()){
            case $location[Dreadsylvanian Woods]:
                if (contains_text(name,"bugbear")) {
                    if (contains_text(name,"cold"))
                        use_skill($skill[Carbohydrate Cudgel]);
                    attack(9);
                    return true;
                }
                if (contains_text(name,"werewolf")) {
                    if (!contains_text(name,"sleaze"))
                        attack(2);
                    for i from 1 to 5 { use_skill(elementBonus[monster_element()]); }
                    return true;
                }
                return false;
            case $location[Dreadsylvanian Village]:
                sauce(6);
                return true;
            case $location[Dreadsylvanian Castle]:
                if (contains_text(name,"skeleton") || contains_text(name,"vampire")) {
                    if (have_effect($effect[chilled to the bone]) > 0 && contains_text(name,"skeleton"))
                        throw_item($item[shadow brick]);
                    for i from 1 to 10 { use_skill(elementBonus[monster_element()]); }
                    use_skill($skill[stuffed mortar shell]);
                    attack(3); sauce(3); attack(24);
                    return true;
                }
                sauce(1);
                return true;
        }
        return false;
    }

    boolean hobopolis(string page_text){
        if (last_monster() == $monster[Frosty]) {
            throw_items($item[cinnamon troll doll],       $item[grape troll doll]);
            throw_items($item[blue raspberry troll doll], $item[bag of gross foreign snacks]);
            throw_items($item[crazy hobo notebook],       $item[hedgeturtle]);
            for i from 1 to 11 {
                throw_items($item[d8], $item[d8]);
                if (my_hp() < 100) throw_items($item[new age healing crystal], $item[d8]);
            }
            if (monster_hp() <= 18) attack();
            return true;
        }
        if ($monsters[Ol' Scratch, Oscus, Chester] contains last_monster()) {
            for i from 1 to 7 { use_skill($skill[snowclone]); }
            return true;
        }
        if (last_monster() == $monster[zombo]) {
            for i from 1 to 13 { hurt(1); if (my_hp() < 250) heal_hurt(); }
            return true;
        }
        switch (my_location()){
            case $location[A Maze of Sewer Tunnels]:
                steal();
                if (get_property("cleeshSewers") == "true"){
                    if (last_monster() == $monster[giant zombie goldfish])
                        use_skill($skill[spring kick]);
                    use_skill($skill[Sea *dent: Talk to some fish]);
                    reanimate();
                }
                if (last_monster() == $monster[giant zombie goldfish]) {
                    use_skill($skill[spring kick]); free_run(page_text); sauce(2);
                    return true;
                }
                if (last_monster() == $monster[Sewer gator]) {
                    use_skill($skill[Sea *dent: Throw a Lightning Bolt]); sauce(2);
                    return true;
                }
                free_run(page_text);
                free_kill(page_text);
                attack(); use_skill($skill[saucegeyser]); attack(); sauce(2); attack(3);
                break;
            case $location[Hobopolis Town Square]:
                free_run(page_text);
                free_kill(page_text);
                if ($strings[boots,skulls,eyes,crotches,guts] contains get_property("parts_collection")) {
                    use_skill($skill[Stuffed Mortar Shell]);
                    throw_item($item[seal tooth]);
                } else if (get_property("parts_collection") == "skins") {
                    use_skill($skill[Lunging Thrust-Smack]);
                }
                break;
            case $location[Exposure Esplanade]:
                free_run(page_text);
                free_kill(page_text);
                insta_kill(page_text);
                set_property("choiceAdventure1589","1&victim=690");
                sauce(4);
                break;
            case $location[The Ancient Hobo Burial Ground]:
                free_run(page_text);
                free_kill(page_text);
                attack(15);
                break;
            case $location[The Purple Light District]:
            case $location[The Heap]:
            case $location[Burnbarrel Blvd.]:
                if ((my_location() == $location[The Purple Light District] && to_int(get_property("PLD_left")) >= 50 && get_property("cleeshPLD") == "true")
                    || (my_location() == $location[The Heap] && get_property("cleeshHeap") == "true")){
                    use_skill($skill[Sea *dent: Talk to some fish]);
                    reanimate();
                }
                free_run(page_text);
                free_kill(page_text);
                sauce(4);
                break;
        }
        return true;
    }

    boolean fantasyRealm(){
        if (my_location() == $location[The Barrow Mounds])  { runaway(); return true; }
        if (my_location() == $location[The Troll Fortress]) { for i from 1 to 4 { use_skill($skill[Awesome Balls of Fire]); } return true; }
        if (last_monster() == $monster[Flock of every birds])    { for i from 1 to 9 { use_skill($skill[garbage nova]); } return true; }
        if (last_monster() == $monster[crypt creeper])           { for i from 1 to 6 { throw_items($item[gauze garter],$item[gauze garter]); } return true; }
        if (last_monster() == $monster[Sewage Treatment Dragon]) { for i from 1 to 3 { heal_hurt(); } return true; }
        if ($monsters[plywood cultists, Ley Incursion, quadfaerie] contains last_monster()) { attack(24); return true; }
        sauce(4);
        return true;
    }

    boolean gingerbreadCity(){
        if ($monsters[gingerbread convict, gingerbread finance bro,
            gingerbread gentrifier, gingerbread lawyer,
            gingerbread tech bro, judge fudge] contains last_monster()
            && item_amount($item[gingerbread cigarette]) > 0)
            throw_item($item[gingerbread cigarette]);
        sauce(9);
        return true;
    }

    boolean glaciest(string page_text){
        free_run(page_text);
        free_kill(page_text);
        if (my_location() == $location[the ice hotel]) {
            if (last_monster() == $monster[ice concierge]) {
                if (!isTracked($monster[ice concierge], $skill[McHugeLarge Slash]))
                    use_skill($skill[McHugeLarge Slash]);
                if (!isTracked($monster[ice concierge], $skill[Transcendent Olfaction]))
                    use_skill($skill[Transcendent Olfaction]);
            }
            if (get_property("walfordBucketItem") == "blood") attack();
            if (get_property("walfordBucketItem") == "ice")   use_skill($skill[Weapon of the Pastalord]);
            use_skill($skill[saucegeyser]);
        }
        if ($locations[the ice hole, VYKEA] contains my_location()) sauce(4);
        return true;
    }

    boolean springBreakBeach(string page_text){
        switch (my_location()){
            case $location[The Fun-Guy Mansion]:
                if (my_hp() < to_float(my_maxhp()) * 0.8872)
                    throw_item($item[new age healing crystal]);
                if (!free_monster())
                    free_kill(page_text);
                use_skill($skill[Saucegeyser]);
                throw_item($item[new age hurting crystal]);
                attack();
                break;
            case $location[Sloppy Seconds Diner]:
                if (last_monster() == $monster[Sloppy Seconds Sundae]){
                    foreach sk in $skills[Transcendent Olfaction, McHugeLarge Slash, Gallapagosian Mating Call]
                        if (!isTracked($monster[Sloppy Seconds Sundae], sk))
                            use_skill(sk);
                }
                if (contains_text(get_property("banishedMonsters"),"broctopus") && last_monster() == $monster[broctopus])
                    use_skill($skill[spring kick]);
                if (!free_monster())
                    free_kill(page_text);
                use_skill($skill[stuffed mortar shell]);
                sauce(2);
                break;
            case $location[The Sunken Party Yacht]:
                if (!contains_text(get_property("banishedMonsters"),"broctopus") && have_effect($effect[fishy]) >= 20)
                    use_skill($skill[spring kick]);
                if (!free_monster())
                    free_kill(page_text);
                use_skill($skill[stuffed mortar shell]);
                sauce(2);
                break;
        }
        return true;
    }

    boolean slimeTube(string page_text){
        // After a uvula is tickled we carry the rusty grave robbing shovel to
        // squeeze a gall bladder; doing so spends the shovel and empties the
        // weapon slot. Once it's gone, advance <clanId>Tickled to "done" so
        // slime.ash / preadventure.ash stop re-equipping it.
        if (get_property(get_clan_id() + "Tickled") == "tickled"){
            while (have_equipped($item[rusty grave robbing shovel]))
                throw_item($item[facsimile dictionary]);
            if (equipped_item($slot[weapon]) == $item[none])
                set_property(get_clan_id() + "Tickled","done");
        }
        // Mother Slime: stack Backup Dancers before the damage skills below.
        if (last_monster() == $monster[mother slime]){
            use_skill($skill[Raise Backup Dancer]);
            use_skill($skill[Raise Backup Dancer]);
        }
        free_kill(page_text); free_run(page_text); insta_kill(page_text);
        // Shadow bricks are the cheap kill while ML-farming on the purse rat.
        if (my_familiar() == $familiar[purse rat] && have_effect($effect[coated in slime]) > 10 && to_int(get_property("_shadowBricksUsed")) < 13)
            throw_item($item[shadow brick]);
        for i from 1 to 4 {
            if (my_hp() < 500 && my_hp() < my_maxhp()/2)
                throw_items($item[new age healing crystal],$item[new age healing crystal]);
            use_skill($skill[weapon of the pastalord]);
        }
        return true;
    }

    boolean grimacia(){
        if (last_monster().phylum == $phylum[horror])
            use_skill($skill[%fn, Release the Patriotic Screech!]);
        else {
            if (to_int(get_property("_mildEvilPerpetrated")) < 3) use_skill($skill[perpetrate mild evil]);
            if (to_int(get_property("_batWingsSwoopUsed")) < 11)  use_skill($skill[swoop like a bat]);
            while (to_int(get_property("_douseFoeUses")) < 3 && get_property("_douseFoeSuccess") == "false" && current_round() > 0 && !contains_text(get_property("_lastCombatActions"),"it11311"))
                use_skill($skill[douse foe]);
        }
        sauce(5);
        return true;
    }

    // Treasury: bladdering kit, GAP runaways, embezzlers get hit, else run.
    void treasury(string page_text){
        if (get_property("subscript") == "bladdering"){
            if (have_equipped($item[legendary acorndion])){
                if (get_property("_seadentWaveZone") == "Cobb's Knob Treasury" && have_skill($skill[Cadenza]))
                    use_skill($skill[cadenza]);
                else if (have_skill($skill[Accordion Bash]))
                    use_skill($skill[Accordion Bash]);
                if (current_round() == 0) return;
            }
            free_kill(page_text);
            free_run(page_text);
            steal();
            if (is_wearing_outfit("Hodgman's Regal Frippery")){
                use_skill($skill[SUMMON HOBO UNDERLING]);
                use_skill($skill[ASK THE HOBO FOR A DRINK]);
            }
            throw_item($item[ink bladder]);
        }
        if (have_equipped($item[greatest american pants]) && to_int(get_property("_navelRunaways")) < 3)
            runaway();
        if (last_monster() == $monster[Knob Goblin Embezzler])
            attack(5);
        else
            free_run(page_text);
    }

    // Coral Corral: banish rustlers/cowboys until fish are banished, then farm.
    boolean coralCorral(){
        if (!contains_text(get_property("banishedPhyla"), "fish") && $monsters[mer-kin rustler, sea cowboy] contains last_monster())
            use_skill(combatBan());
        farmingStuff();
        attack(3);
        cleanUp();
        return true;
    }

    // Marinara Trench: banish belles/fisherfish (divers get Fishy on seal clubbers), then farm.
    boolean marinaraTrench(string page_text){
        if (!contains_text(get_property("banishedPhyla"), "fish")){
            if ($monsters[diving belle,fisherfish] contains last_monster())
                use_skill(combatBan());
            if (last_monster() == $monster[Mer-kin diver]){
                if (have_effect($effect[fishy]) < my_adventures() && my_class() == $class[seal clubber])
                    use_skill($skill[Sea *dent: Talk to Some Fish]);
                else
                    use_skill(combatBan());
            }
        }
        farmingStuff();
        free_kill(page_text);
        if (current_round() == 0) return true;
        if (have_equipped($item[legendary acorndion])){
            if (have_skill($skill[Cadenza]))
                use_skill($skill[Cadenza]);
            if (current_round() > 0 && have_skill($skill[Cone of Zydeco]))
                use_skill($skill[Cone of Zydeco]);
            if (current_round() == 0) return true;
        }
        crit();
        attack(3);
        cleanUp();
        return true;
    }

    boolean shadowPlains(string page_text){
        if (last_monster() == $monster[shadow scythe]) sauce(2);
        if (last_monster() == $monster[shadow orrery]) attack(20);
        if (last_monster() == $monster[shadow matrix]) sauce(6);
        if (last_monster().elemental_resistance > 85){
            free_kill(page_text);
            free_run(page_text);
            for i from 1 to 20 { use_skill($skill[snowclone]); }
        } else
            sauce(20);
        return true;
    }

    // Misspelled Cemetary: steal, douse, septapus charm until the drop lands, extras, clean up.
    boolean shadowCemetary(){
        if (current_round() <= 0)
            return false;
        steal();
        if (last_monster() == $monster[shadow scythe]) abort();
        if (last_monster() == $monster[shadow orrery]) attack(20);
        if (last_monster() == $monster[shadow matrix]) sauce(6);
        if (last_monster().boss == true)
            cleanUp();
        if (last_monster() == $monster[shadow guy])
            throw_item($item[waffle]);
        while (to_int(get_property("_douseFoeUses")) < 3
            && get_property("_douseFoeSuccess") == "false"
            && current_round() < 25 && current_round() > 0 && have_equipped($item[Flash Liquidizer Ultra Dousing Accessory]))
            use_skill($skill[douse foe]);
        int itAmount = item_amount(item_drops_array(last_monster())[0].drop);
        while (current_round() < 25 && current_round() > 0 && item_amount($item[septapus summoning charm]) > 0 && itAmount == item_amount(item_drops_array(last_monster())[0].drop))
            throw_item($item[septapus summoning charm]);
        if (have_equipped($item[moss mace]) && my_fury() >= 3)
            use_skill($skill[moss mugging]);
        if (have_skill($skill[perpetrate mild evil]))
            use_skill($skill[perpetrate mild evil]);
        if (have_equipped($item[bat wings]))
            use_skill($skill[swoop like a bat]);
        if (have_equipped($item[monodent of the sea]))
            use_skill($skill[Sea *dent: Talk to Some Fish]);
        cleanUp();
        return true;
    }

    boolean plaintiveTelegram(){
        if (last_monster() == $monster[Former Sheriff Dan Driscoll])  attack(18);
        if (last_monster() == $monster[Snake-Eyes Glenn])             for i from 1 to 6 { use_skill($skill[grease lightning]); }
        if (last_monster() == $monster[Clara])                        for i from 1 to 6 { use_skill($skill[eggsplosion]); }
        if (last_monster() == $monster[Pharaoh Amoon-Ra Cowtep])      hurt(4);
        if (last_monster() == $monster[cow cultist] && contains_text(get_property("lastEncounter"),"reprehensible"))
            for i from 1 to 3 { use_skill($skill[toynado]); }
        sauce(6);
        return true;
    }

    // Primordial Soup: feed Cyrus the base pairs he still lacks.
    boolean primordialSoup(){
        if (last_monster() == $monster[Cyrus the Virus]) {
            foreach it, adjective in basePairs {
                if (item_amount(it) > 0 && !contains_text(get_property("cyrusAdjectives"), adjective))
                    throw_item(it);
            }
        }
        sauce(3);
        return true;
    }

    boolean deepDarkJungle(){
        if (get_property("_questESp") == "questESpSmokes") {
            if (last_monster() != $monster[smoke monster] && last_monster() != $monster[Mercenary of Fortune])
                use_skill(combatBan());
            sauce(3);
        }
        if (get_property("_questESp") == "questESpOutOfOrder") {
            if (last_monster() != $monster[Mercenary of Fortune]) use_skill(combatBan());
            sauce(3);
        }
        return true;
    }

    boolean skeletonTower(){
        string enc = get_property("lastEncounter");
        if (contains_text(enc,"shiny") || contains_text(enc,"disorienting")) {
            if (contains_text(enc,"dancing")) abort();
            if (contains_text(enc,"ghostly"))
                for i from 1 to 3 { throw_items($item[boozebomb],$item[boozebomb]); }
            hurt(6);
        } else {
            sauce(6);
        }
        return true;
    }

    // Per-location fights. True when the fight was handled; false falls through to
    // the generic finish in main(). Zones/locations are mutually exclusive, so the
    // order only matters around the two monster checks in the middle.
    boolean zoneFight(string page_text){
        switch (my_location()){
            case $location[barf mountain]:   return barfMountain(page_text);
            case $location[cyberzone 1]:
            case $location[cyberzone 2]:
            case $location[cyberzone 3]:     return cyberzone();
            case $location[the red zeppelin]: return redZeppelin();
            case $location[Dreadsylvanian Woods]:
            case $location[Dreadsylvanian Village]:
            case $location[Dreadsylvanian Castle]:
                if (dreadsylvania(page_text)) return true;
                break;
            case $location[Through the Spacegate]:
                if (last_monster() == $monster[spant soldier])
                    abort();
                sauce(6);
                return true;
        }
        switch (my_location().zone){
            case "Hobopolis":          return hobopolis(page_text);
            case "FantasyRealm":       return fantasyRealm();
            case "Gingerbread City":   return gingerbreadCity();
            case "The Glaciest":       return glaciest(page_text);
            case "Spring Break Beach": return springBreakBeach(page_text);
        }

        if (last_monster() == $monster[black crayon spiraling shape]){
            while (my_familiar() == $familiar[chest mimic] && to_int(get_property("_mimicEggsObtained")) < 11 && $familiar[chest mimic].experience > 100)
                use_skill($skill[%fn, lay an egg]);
            sauce(6);
            return true;
        }
        if (last_monster() == $monster[giant sandworm]){
            sauce(6);
            return true;
        }

        switch (my_location()){
            case $location[Convention Hall Lobby]:
                while (current_round() > 0) throw_item($item[bottle of G&uuml;-Gone]);
                return true;
            case $location[The Outer Compound]:
                while (current_round() > 0) use_skill($skill[Apprivoisez la tortue]);
                return true;
            case $location[The Slime Tube]:           return slimeTube(page_text);
            case $location[Domed City of Grimacia]:   return grimacia();
            case $location[The Broodling Grounds]:
                if (last_monster() == $monster[hellseal pup])
                    for i from 1 to 3 { throw_item($item[seal tooth]); }
                attack(3);
                return true;
            case $location[The Brinier Deepers]:
                if (last_monster() == $monster[trophyfish]) abort();
                return true;
            case $location[Mer-kin Elementary School]:
                if (contains_text(get_property("banishedMonsters"),"hacker"))
                    use_skill($skill[Sea *dent: Throw a Lightning Bolt]);
                break;
            case $location[cobb's knob treasury]:     treasury(page_text); break;
            case $location[The Dungeons of Doom]:     free_run(page_text); break;
            case $location[the black forest]:         free_kill(page_text); break;
            case $location[the coral corral]:         return coralCorral();
            case $location[guano junction]:
                if (last_monster() == $monster[doughbat] && !isTracked($monster[doughbat], $skill[Transcendent Olfaction])){
                    use_skill($skill[Transcendent Olfaction]);
                    if (have_skill($skill[Gallapagosian Mating Call]))
                        use_skill($skill[Gallapagosian Mating Call]);
                }
                free_kill(page_text);
                break;
            case $location[the marinara trench]:      return marinaraTrench(page_text);
            case $location[Anemone Mine]:             free_kill(page_text); break;
            case $location[Shadow Rift (The Nearby Plains)]:       return shadowPlains(page_text);
            case $location[Shadow Rift (The Misspelled Cemetary)]: if (shadowCemetary()) return true; break;
            case $location[The Spooky Forest]:        free_run(page_text); return true;
            case $location[The Outskirts of Cobb's Knob]: free_run(page_text); break;
            case $location[Investigating a Plaintive Telegram]: return plaintiveTelegram();
            case $location[The Primordial Soup]:      return primordialSoup();
            case $location[the deep dark jungle]:     return deepDarkJungle();
            case $location[The Mansion of Dr. Weirdeaux]:
                if (get_property("_questESp") == "questESpClipper")
                    for i from 1 to 3 { throw_item($item[military-grade fingernail clippers]); }
                sauce(3);
                return true;
            case $location[The Tower of Procedurally-Generated Skeletons]: return skeletonTower();
            case $location[the nightmare meatrealm]:
                use_skill($skill[spring away]); runaway();
                return true;
        }
        if (my_location().zone == "Le Marais D&egrave;gueulasse") {
            sauce(3);
            return true;
        }
        return false;
    }

// ─── MAIN ─────────────────────────────────────────────────────────────────────

void consultFight(int round, monster mob, string page_text) {
    mimic_reset_familiar();
    mimic_stasis_batched = false;
    mimic_failed_probe = "";
    mimic_consult_monster = last_monster();
    mimic_consult_stamp = mimic_probe_key();
    if (get_property("script") == "FreeKill" && get_property("subscript") == "peridot"
        && mob != $monster[Eldritch Tentacle] && !free_monster())
        abort("Peridot fishing encountered " + mob + "; stopping before a paid kill.");
    if (get_property("script") == "FreeKill" && mob == $monster[Eldritch Tentacle]
        && (get_property("subscript") == "stompingBoots" || get_property("FKRunEligible") == "true"
            || my_familiar() == $familiar[peace turkey])){
        finishFreeRunTentacle();
        return;
    }
    if (get_property("subscript") == "godLobster"){
        if (mob != $monster[God Lobster])
            abort("God Lobster dish encountered " + mob + "; stopping.");
        if (current_round() > 0 && mimic_macro_ready(false)
            && mimic_submit((isMimicFam() ? mimic_pad_macro(11) : "")
                + mimic_repeat(5, mimic_skill($skill[Saucegeyser])))) return;
        if (isMimicFam()) mimic_pad_ash(11);
        sauce(5);
        return;
    }
    if (get_property("script") == "FreeKill" && get_property("subscript") == "screech"
        && my_location() == $location[The Briniest Deepests] && mob.phylum != $phylum[fish]
        && !contains_text(mob.attributes,"FREE"))
        abort("Fish-banish setup encountered " + mob + "; stopping before a paid kill.");
    if (get_property("subscript") == "baseball"
        && mob != to_monster(get_property("_curveballMonster")))
        abort("Baseball expected " + get_property("_curveballMonster") + "; encountered " + mob + ".");

    if (mob == $monster[Sssshhsssblllrrggghsssssggggrrgglsssshhssslblgl]){
        eldritchHorror();
        return;
    }
    replacementChain();
    printFightInfo();

    // 1. openers
    schoolOfMany();
    if (mob == $monster[crate] && last_monster() == copyTarget
        && my_location() == $location[Noob Cave]
        && ($skills[Macrometeorite, CHEAT CODE: Replace Enemy] contains to_skill(get_property("subscript")))
        && get_property("script") == "FreeKill"
        && (my_familiar() == $familiar[Stocking Mimic] || mimic_active_familiar() == $familiar[Stocking Mimic])
        && !have_equipped($item[backup camera]) && !have_equipped($item[heartstone])
        && !(get_property("swordSniff") == "true" && get_property("killThisGuy").to_int() == to_int(copyTarget))){
        string prefix;
        skill tracking = mimic_copy_tracking_skill();
        if (tracking != $skill[none]) prefix += mimic_available_skill(tracking);
        if (get_property("_circadianRhythmsRecalled") == "false")
            prefix += mimic_available_skill($skill[RECALL FACTS: %PHYLUM CIRCADIAN RHYTHMS]);
        if (have_equipped($item[roman candelabra]))
            prefix += mimic_available_skill($skill[Blow the Purple Candle!]);
        if (item_amount($item[spooky putty sheet]) > 0 && get_property("spookyPuttyCopiesMade").to_int() < 5)
            prefix += mimic_item($item[spooky putty sheet]);
        if (mimic_regular_combat(prefix + mimic_common_openers())) return;
    }
    copyTargetOpeners();
    cyberConstructs();
    hiddenBowlingAlley();
    screech(page_text);
    stompingBoots();
    if (get_property("subscript") == "stompingBoots") return;
    shadowBosses();
    if (current_round() == 0) return;
    if (get_property("subscript") == "citizen"){
        use_skill($skill[%fn, let's pledge allegiance to a Zone]);
        free_run(page_text);
    }
    if (mimic_gingerbread_combat()) return;
    if (mimic_early_combat()) return;
    if (mimic_affinity_combat()) return;
    if (!mimic_decision_combat()){
        commonOpeners();
        backupCamera();
        if (current_round() == 0) return;
        if (get_property("script") == "FreeKill" && have_equipped($item[heartstone]))
            use_skill($skill[Steal Monster's Heart]);
        leafBosses();
    }
    if (current_round() == 0) return;

    // 2. routines that end the fight
    if (weaklingFight()) return;
    if (professorFight()) return;
    if (mimicFreeKill(page_text)) return;
    if (witchessFight()) return;
    if (voidFight()) return;
    fishyTopUp();
    if (last_monster() == $monster[Eldritch Tentacle] && mimic_active_familiar() == $familiar[grey goose]){
        use_skill($skill[Meatify Matter]);
    }
    if (sauceFight(page_text)) return;
    if (get_property("BoFaWishRWB") == "true")
        use_skill($skill[%fn, fire a Red, White and Blue Blast]);
    if (hurtFight()) return;

    // 3. zone routines, then the generic finish
    if (zoneFight(page_text)) return;
    insta_kill(page_text);
    sauce(30);
    attack();
}

void main(int round, monster mob, string page_text){
    if (get_property("script") != "FreeKill"
        || !($monsters[shadow cauldron, shadow matrix, shadow tongue, shadow orrery, shadow spire, shadow scythe] contains mob)){
        consultFight(round, mob, page_text);
        return;
    }
    int started = now_to_int();
    int turnsBefore = total_turns_played();
    try {
        consultFight(round, mob, page_text);
    } finally {
        boolean won = current_round() == 0 && get_property("_lastCombatWon") == "true";
        fartoTiming("shadow_boss_combat", started, " monster_id=" + to_int(mob)
            + " start_round=" + round + " end_round=" + current_round() + " won=" + won
            + " turn_delta=" + (total_turns_played() - turnsBefore));
    }
}
