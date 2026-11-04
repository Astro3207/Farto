import iotm.ash;

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
        return my_familiar() == $familiar[comma chameleon] || my_familiar() == $familiar[stocking mimic];

    // Underwater, or in the zone the Sea *dent wave flooded.
    boolean wet()
        return my_location().environment == "underwater" || my_location() == to_location(get_property("_seadentWaveZone"));

    boolean gazeReady()
        return (my_basestat($stat[submysticality]) - 62500) > BCZcost("RefractedGazeCasts");

// ─── KILL / RUN ───────────────────────────────────────────────────────────────

    void free_kill(string ptext) {
        foreach sk in $skills[Spit jurassic acid, Darts: Aim for the Bullseye] {
            if (!contains_text(ptext, to_string(sk)))
                continue;
            if (sk == $skill[Darts: Aim for the Bullseye] && my_adventures() <= bullseyeCooldown() && dayType() == 0)
                continue;
            if (sk == $skill[Spit jurassic acid] && my_adventures() < 100 && dayType() == 0)
                continue;
            use_skill(sk);
            if (sk == $skill[Darts: Aim for the Bullseye])
                while (to_int(get_property("_dartsLeft")) > 0 && current_round() > 0) use_skill(sk);
        }
        if (get_property("script") == "farto" || (get_property("script") == "FreeKill" && get_property("subscript") != "looseFK"))
            return;
        foreach sk in $skills[Assert your Authority, Fire the Jokester's Gun,
            BCZ: Sweat Bullets, Shattering Punch,
            Gingerbread Mob Hit, Club 'Em Back in Time] {
            if (my_location() == $location[hobopolis town square] && sk == $skill[Club 'Em Back in Time])
                continue;
            if (sk == $skill[BCZ: Sweat Bullets] && ((my_basestat($stat[submoxie]) - 62500) <= BCZcost("SweatBulletsCasts") || get_property("_bczSweatBulletsCasts").to_int() >= 13))
                continue;
            if (contains_text(ptext, to_string(sk)))
                use_skill(sk);
        }
        if (item_amount($item[interesting coin]) > 0 && get_property("_interestingCoinHeads") == "false" && !contains_text(get_property("lastCombatActions"),"it11311")){
            while (get_property("_interestingCoinHeads") == "false" && current_round() > 0 && current_round() < 30)
                throw_item($item[interesting coin]);
        }
        if (available_amount($item[partial tombstone]) > 0 && get_property("_partialTombstonesUsed").to_int() < 11)
            throw_item($item[partial tombstone]);
        if (available_amount($item[shadow brick]) > 0 && get_property("_shadowBricksUsed").to_int() < 13)
            throw_item($item[shadow brick]);
    }

    // Free runs on the page (curveball first unless it's the copy target), then the boots.
    void free_run(string ptext) {
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
            runaway();
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
        if (have_item($item[pulled red taffy]))
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
        skill replacer;
        if (have_equipped($item[Powerful Glove]) && get_property("_powerfulGloveBatteryPowerUsed").to_int() <= 90)
            replacer = $skill[CHEAT CODE: Replace Enemy];
        else if (have_skill($skill[Macrometeorite]) && get_property("_macrometeoriteUses").to_int() < 10)
            replacer = $skill[Macrometeorite];
        use_skill(replacer);
        if (last_monster() != copyTarget)
            abort("Replacement chain: did not produce " + copyTarget + ".");
    }

    void waffleShadowGuy(){
        float itDropMult = item_drop_modifier()/100 + 1;
        int shadowGuyValue = item_drops_array($monster[shadow guy])[0].rate/100 * itDropMult * mall_price(item_drops_array($monster[shadow guy])[0].drop);
        int avgPrice = (mall_price($item[shadow brick]) + mall_price($item[shadow stick]))/2;
        int otherGuyValue = (item_drops_array($monster[shadow slab])[0].rate/100 * itDropMult * avgPrice) - mall_price($item[waffle]);
        if (have_effect($effect[fishy]) < 1030)
            use_skill($skill[Sea *dent: Talk to Some Fish]);
        else if (shadowGuyValue < otherGuyValue)
            throw_item($item[waffle]);
    }

// ─── 1. OPENERS ───────────────────────────────────────────────────────────────
    // Each may act and leave the fight running for the next stage.

    // The Evoke Eldritch Horror fight: melee/sauce finisher while disguised, then attack.
    void eldritchHorror(){
        if (have_effect($effect[Crappily Disguised as a Waiter]) > 0){
            skill finisher = my_buffedstat($stat[Muscle]) > my_buffedstat($stat[Mysticality])
                && (current_hit_stat() == $stat[Muscle] || item_type(equipped_item($slot[weapon])) == "knife")
                ? $skill[Lunging Thrust-Smack] : $skill[Saucegeyser];
            while (current_round() > 0 && have_skill(finisher) && my_mp() >= mp_cost(finisher))
                use_skill(finisher);
        }
        while (current_round() > 0) attack();
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

    // Copy target: habitats / gregarious / wink, circadian, candle, putty; then the
    // dive-bar gregarious replace.
    void copyTargetOpeners(){
        if (last_monster() == copyTarget){
            if (get_property("_monsterHabitatsFightsLeft") == 0 && to_int(get_property("_monsterHabitatsRecalled")) < 3){
                use_skill($skill[RECALL FACTS: MONSTER HABITATS]);
            } else if (get_property("_monsterHabitatsFightsLeft") == 0 && get_property("beGregariousFightsLeft").to_int() == 0 && get_property("beGregariousCharges").to_int() > gregsToSave() && dayType() == 1){
                use_skill($skill[Be Gregarious]);
            } else if (my_familiar() == $familiar[reanimated reanimator] && get_property("_badlyRomanticArrows") == "0"){
                use_skill($skill[Wink at]);
            }
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

    // subscript "stompingBoots": bander runaway (sauce the God Lobster first).
    void stompingBoots(){
        if (get_property("subscript") != "stompingBoots")
            return;
        if (last_monster() == $monster[infinite meat bug])
            abort();
        if (last_monster() == $monster[God Lobster])
            sauce(4);
        if (last_monster() != copyTarget && have_skill($skill[Bowl a Curveball]))
            use_skill($skill[Bowl a Curveball]);
        runaway();
    }

    // FreeKill: the Shadow Rift bosses.
    void shadowBosses(){
        if (get_property("script") != "FreeKill")
            return;
        if (last_monster() == $monster[shadow spire] || last_monster() == $monster[shadow scythe]){
            if (have_equipped($item[wicker slicker])){
                while (current_round() > 0 && current_round() < 10)
                    use_skill($skill[shell up]);
            } else {
                foreach sk in $skills[Silent Slam,Sauceshell,shell up]{
                    if (have_skill(sk))
                        use_skill(sk);
                }
            }
            if (current_round() > 0)
                use_skill($skill[saucegeyser]);
        }
        if (last_monster() == $monster[shadow orrery]){
            for i from 1 to 9 { throw_item($item[facsimile dictionary]); }
            attack(30);
        } else if ($monsters[shadow cauldron, shadow matrix, shadow tongue] contains last_monster()){
            while (current_round() > 0 && current_round() < 10)
                throw_item($item[facsimile dictionary]);
        }
    }

    // Every-fight buffs (avalanche/spikolodon/steal/sing along/reanimate/bowling
    // ball/kill-a-lot). Shadow scythe/spire, guard turtle and bladdering skip them;
    // the spire gets sauced instead.
    void commonOpeners(){
        if (last_monster() != $monster[shadow scythe] && last_monster() != $monster[shadow spire] && last_monster() != $monster[Guard turtle] && get_property("subscript") != "bladdering") {
            if (have_skill($skill[McHugeLarge Avalanche]))         use_skill($skill[McHugeLarge Avalanche]);
            if (have_skill($skill[Launch spikolodon spikes]))      use_skill($skill[Launch spikolodon spikes]);
            if (my_primestat() == $stat[moxie] || have_equipped($item[mime army infiltration glove])) steal();
            if (have_skill($skill[sing along]) && my_familiar() != $familiar[peace turkey] && my_familiar() != $familiar[pair of stomping boots]
                && chameleon() != $familiar[pair of stomping boots] && my_location() != $location[guano junction] && my_location() != $location[The Defiled Cranny])
                use_skill($skill[sing along]);
            reanimate();
            if (item_amount($item[cosmic bowling ball]) > 0 && (have_effect($effect[Cosmic Ball in the Air]) < 22 || dayType() == 0 || have_equipped($item[backup camera])) && my_location() != $location[Cobb's Knob Treasury])
                use_skill($skill[Bowl Straight Up]);
            if (item_amount($item[cosmic bowling ball]) > 0 && get_property("subscript") == "replacing")
                use_skill($skill[Bowl Straight Up]);
            if (to_int(last_monster()) == to_int(get_property("killThisGuy")) && get_property("swordSniff") == true)
                use_skill($skill[%fn, kill a lot of these guys]);
        } else if (last_monster() == $monster[shadow spire]){
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
        if (gregsToSave().to_boolean() == true && get_property("beGregariousMonster").to_monster() != copyTarget && get_property("beGregariousCharges").to_int() > 0)
            use_skill($skill[Be Gregarious]);
    }

    // Mimic familiars vs the monstera / leaviathan: wear it down, then lasso.
    void leafBosses(){
        if (!isMimicFam() || (last_monster() != $monster[flaming monstera] && last_monster() != $monster[leaviathan]))
            return;
        while (current_round() > 0 && current_round() < 10 && monster_hp() > 9)
            throw_item($item[facsimile dictionary]);
        throw_items($item[lit leaf lasso],$item[lit leaf lasso]);
        if (current_round() > 0)
            abort();
    }

// ─── 2. ROUTINES THAT END THE FIGHT ───────────────────────────────────────────
    // Each returns true when it handled (finished) the fight.

    // Mimic familiar + subscript "weakling": stretch to round 30 for familiar weight.
    boolean weaklingFight(){
        if (!isMimicFam() || get_property("subscript") != "weakling")
            return false;
        reanimate();
        while (current_round() > 0 && current_round() < 30 && monster_hp() > 9){
            if (have_equipped($item[april shower thoughts shield]))
                use_skill($skill[shieldbutt]);
            else {
                throw_item($item[facsimile dictionary]);
                if (current_round() > 10)
                    break;
            }
            heal(100);
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
        if (have_equipped($item[unwrapped knock-off retro superhero cape]))
            use_skill($skill[saucegeyser]);
        while (current_round() > 0 && current_round() < 30 && monster_hp() > 9){
            if (have_equipped($item[april shower thoughts shield]))
                use_skill($skill[shieldbutt]);
            else {
                use_skill($skill[saucegeyser]);
                attack();
            }
        }
        while (current_round() < 30 && current_round() > 0)
            throw_item($item[facsimile dictionary]);
        if (item_amount($item[dry noodles]) > 0)
            use_skill($skill[carbohydrate cudgel]);
        else
            abort();
        return true;
    }

    // Pocket Professor: lectures (+ thesis on day 2), candle, then sauce.
    boolean professorFight(){
        if (chameleon() != $familiar[pocket professor] && my_familiar() != $familiar[pocket professor])
            return false;
        use_skill($skill[lecture on relativity]);
        if (dayType() == 1)
            use_skill($skill[deliver your thesis!]);
        purpleCandle();
        heal(500);
        sauce(4);
        return true;
    }

    // Stocking mimic in FreeKill: shieldbutt/dictionary to round 10 for the candies,
    // copy-target extras, then end it (free kill / curveball / sauce).
    boolean mimicFreeKill(string page_text){
        if ((chameleon() != $familiar[stocking mimic] && my_familiar() != $familiar[stocking mimic]) || get_property("script") != "FreeKill")
            return false;
        if (my_location().zone == "Shadow Rift" && last_monster().boss == false){
            while (to_int(get_property("_douseFoeUses")) < 3 && get_property("_douseFoeSuccess") == "false"
                && current_round() > 0 && current_round() < 25 && have_equipped($item[Flash Liquidizer Ultra Dousing Accessory]))
                use_skill($skill[douse foe]);
            if (to_int(get_property("_mildEvilPerpetrated")) < 3) use_skill($skill[perpetrate mild evil]);
            if (to_int(get_property("_batWingsSwoopUsed")) < 11)  use_skill($skill[swoop like a bat]);
        }
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
            if (wet() && !contains_text(get_property("_lastCombatActions"),"it6367") && item_amount($item[pulled red taffy]) > 0)
                throw_item($item[pulled red taffy]);
            heal(200);
        }
        if (get_property("FKRunEligible") == "true" && (get_property("freeMeat").to_int() + 3500) > my_meat())
            throw_item(wet() ? $item[pulled indigo taffy] : $item[stuffed yam stinkbomb]);
        if (my_location() == $location[Gingerbread Civic Center])
            throw_item($item[gingerbread cigarette]);
        if (last_monster() == $monster[shadow guy]){
            if (gazeReady()) {
                use_skill($skill[Sea *dent: Talk to Some Fish]);
                use_skill($skill[BCZ: Refracted Gaze]);
            } else
                waffleShadowGuy();
        }
        if (gazeReady() && last_monster() == $monster[sausage goblin] && have_equipped($item[peridot of peril]))
            use_skill($skill[BCZ: Refracted Gaze]);
        if (last_monster().max_meat > 0 && have_equipped($item[mafia pointer finger ring]) && current_round() < 28)
            attack();
        if (last_monster() == $monster[Black Crayon Crimbo Elf] && have_equipped($item[legendary seal-clubbing club]))
            use_skill($skill[Club 'Em Into Next Week]);
        boolean curveballed = get_property("_curveballMonster").to_monster() == last_monster() && get_property("_curveballFightsLeft").to_int() > 0;
        if (get_property("subscript") == "looseFK" && !curveballed && last_monster().boss == false)
            free_kill(page_text);
        if (curveballed){
            sauce(5);
            use_skill($skill[carbohydrate cudgel]);
        }
        if (get_property("subscript") == "looseFK" && current_round() > 0 && last_monster().boss == false
            && (my_location() != $location[Shadow Rift (The Misspelled Cemetary)] || have_effect($effect[shadow affinity]) == 0))
            abort();
        if (current_round() > 0 && current_round() < 10)
            abort();
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

void main(int round, monster mob, string page_text) {
    if (mob == $monster[Sssshhsssblllrrggghsssssggggrrgglsssshhssslblgl]){
        eldritchHorror();
        return;
    }
    replacementChain();
    printFightInfo();

    // 1. openers
    schoolOfMany();
    copyTargetOpeners();
    cyberConstructs();
    hiddenBowlingAlley();
    screech(page_text);
    stompingBoots();
    shadowBosses();
    if (get_property("subscript") == "citizen"){
        use_skill($skill[%fn, let's pledge allegiance to a Zone]);
        free_run(page_text);
    }
    commonOpeners();
    backupCamera();
    if (get_property("script") == "FreeKill" && have_equipped($item[heartstone]))
        use_skill($skill[Steal Monster's Heart]);
    leafBosses();

    // 2. routines that end the fight
    if (weaklingFight()) return;
    if (professorFight()) return;
    if (mimicFreeKill(page_text)) return;
    if (witchessFight()) return;
    if (voidFight()) return;
    fishyTopUp();
    if (last_monster() == $monster[Eldritch Tentacle] && chameleon() == $familiar[grey goose]){
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
