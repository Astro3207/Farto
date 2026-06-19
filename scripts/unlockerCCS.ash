import iotm.ash;

int darts = to_int(get_property("_dartsLeft"));

// ─── HELPERS ──────────────────────────────────────────────────────────────────

void sauce(int n) { for i from 1 to n { use_skill($skill[saucegeyser]); } }
void atk(int n)   { for i from 1 to n { attack(); } }
void hurt(int n)  { for i from 1 to n { throw_items($item[new age hurting crystal],$item[new age hurting crystal]); } }
void heal_hurt()  { throw_items($item[new age healing crystal],$item[new age hurting crystal]); }
skill butts(){
    int butts_int;
    matcher butts_matcher = create_matcher("(\\d+):butt", get_property("_currentDartboard")); 
    if (butts_matcher.find()){
        butts_int = butts_matcher.group(1).to_int();
    } else {
        butts_int = 0;
    }
    return to_skill(butts_int);
}
void dart()       { 
    while (darts > 0 && have_equipped($item[everfull dart holster])) { 
        if (have_effect($effect[everything looks red]) == 0) {
            use_skill($skill[Darts: Aim for the Bullseye]);
        } else if (have_skill(butts())){
            use_skill(butts());
        } else {
            use_skill($skill[Darts: Throw at %part1]); 
        }
        darts -= 1; } }

void free_kill(string ptext) {
    foreach sk in $skills[Spit jurassic acid, Darts: Aim for the Bullseye,Assert your Authority, Fire the Jokester's Gun,
        BCZ: Sweat Bullets, Shattering Punch,
        Gingerbread Mob Hit,
        Club 'Em Back in Time] {
        if (my_location() == $location[hobopolis town square] && sk == $skill[Club 'Em Back in Time])
            continue;
        if ((my_basestat($stat[submoxie]) - 40000) <= BCZcost("SweatBulletsCasts") && sk == $skill[BCZ: Sweat Bullets])
            continue;
        if (contains_text(ptext, to_string(sk))) {
            use_skill(sk);
            if (sk == $skill[Darts: Aim for the Bullseye])
                while (to_int(get_property("_dartsLeft")) > 0 && current_round() > 0) use_skill(sk);
        }
    }
}

void free_run(string ptext) {
    foreach sk in $skills[spring away, snokebomb] {
        if (contains_text(ptext, to_string(sk))) {
            if (my_location() == $location[hobopolis town square] && sk == $skill[snokebomb]) continue;
            use_skill(sk);
        }
    }
}

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

skill [element] elementBonus = {
    $element[hot]:    $skill[Eggsplosion],
    $element[spooky]: $skill[Awesome Balls of Fire],
    $element[cold]:   $skill[Raise Backup Dancer],
    $element[sleaze]: $skill[Snowclone],
    $element[stench]: $skill[Grease Lightning]
};

string [item] basePairs = {
    $item[memory of a CT base pair]: "more attractive",
    $item[memory of a CG base pair]: "smarter",
    $item[memory of a CA base pair]: "stronger",
    $item[memory of a GT base pair]: "more resilient",
    $item[memory of an AT base pair]: "more aggressive",
    $item[memory of an AG base pair]: "faster"
};

// ─── CATEGORY SETS ────────────────────────────────────────────────────────────
// To add a new zone/monster to a category, just add it to the relevant set.
// No new else-if block needed.

// Zones where the entire combat is just saucegeyser x4
boolean [location] sauceLocs = {
    $location[Cyberzone 3]:                        true,
    $location[cyberzone 2]:                        true,
    $location[cyberzone 1]:                        true,
    $location[The Secret Government Laboratory]:   true,
    $location[Seaside Megalopolis]:                true,
    $location[The Jungles of Ancient Loathing]:    true,
    $location[The spooky forest]:                  true,
    $location[The Bubblin' Caldera]:               true,
    $location[The Red Queen's Garden]:             true,
    $location[The Laugh Floor]:                    true,
    $location[Infernal Rackets Backstage]:         true,
    $location[Vanya's Castle]:                     true,
    $location[Megalo-City]:                     true,
    $location[Hero's Field]:                     true,
    $location[The Fungus Plains]:                     true
};

// Monsters where combat is just saucegeyser x4 regardless of location
boolean [monster] sauceMobs = {
    $monster[terrible mutant]:       true,
    $monster[slime blob]:            true,
    $monster[government bureaucrat]: true,
    $monster[angry ghost]:           true,
    $monster[annoyed snake]:         true,
    $monster[time cop]:              true
};

void stasis(){
    if (!contains_text(get_property("_lastCombatActions"),"it8935"))
        throw_item($item[porquoise-handled sixgun]);
    while (current_round() < 20)
        throw_item($item[facsimile dictionary]);
}

void sniff (monster mons){
    foreach sk in $skills[McHugeLarge Slash, Transcendent Olfaction, Gallapagosian Mating Call] {
        if (!have_skill(sk))
            continue;
        string tracked = get_property("trackedMonsters");
        string skill_name = sk.to_string();
        boolean skill_missing = !contains_text(tracked, ":" + skill_name + ":");
        boolean wrong_monster = false;
        if (!skill_missing) {
            matcher m = create_matcher("([^:]+):" + skill_name + ":\\d+", tracked);

            while (m.find()) {
                string mon = group(m, 1);

                if (mon != to_string(mons)) {
                    wrong_monster = true;
                    break;
                }
            }
        }
        if ((skill_missing || wrong_monster) && sk.timescast < sk.dailylimit) {
            use_skill(1, sk);
        }
    }
}

void cleanUp() {
    int loopCount = 0; 
    while (current_round() > 0) {
        int round = current_round();
        attack();
        if (round == current_round()) {
            loopCount += 1;
            if (loopCount > 3)
                abort("May be stuck in an infinite attack loop");
        }
    }
}

boolean free_monster() {
    return $monsters[black crayon golem, time cop,
        kid who is too old to be Trick-or-Treating,
        suburban security civilian, vandal kid,terrible mutant,
        slime blob,government bureaucrat] contains last_monster();
}

boolean free_location(){
    return $locations[cyberzone 3, cyberzone 2, cyberzone 1] contains my_location();
}

// Zones where the entire combat is just hurt(n) — new age hurting crystals
boolean [location] hurtLocs = {
    $location[the cursed village]: true
};

// Monsters where combat is just hurt(n)
boolean [monster] hurtMobs = {
    $monster[Beast with X Ears]: true,
    $monster[Beast with X Eyes]: true,
    $monster[X Bottles of Beer on a Golem]: true,
    $monster[Pharaoh Amoon-Ra Cowtep]:      true
};

// ─── MAIN ─────────────────────────────────────────────────────────────────────

void main(int round, monster mob, string page_text) {

    if (get_property("BoFaWishRWB") == "true"){
        use_skill($skill[%fn, fire a Red, White and Blue Blast]);
    }
    // ── Universal opener (skip for shadow rift mobs that need special handling)
    if (mob != $monster[shadow scythe] && mob != $monster[shadow spire] && mob != $monster[Guard turtle]) {
        if (have_skill($skill[McHugeLarge Avalanche]))         use_skill($skill[McHugeLarge Avalanche]);
        if (have_skill($skill[Launch spikolodon spikes]))      use_skill($skill[Launch spikolodon spikes]);
        if (have_skill($skill[Prepare to reanimate your Foe])) use_skill($skill[Prepare to reanimate your Foe]);
    }

    if (mob == $monster[witchess bishop] || mob == $monster[sausage goblin] || mob == $monster[witchess rook] || mob == $monster[witchess pawn]) {
        if (have_effect($effect[everything looks purple]) == 0) use_skill($skill[Blow the Purple Candle!]);
        if (item_amount($item[4-d camera]) > 0) throw_item($item[4-d camera]);
        use_skill($skill[Club 'Em Into Next Week]); sauce(2); attack(); return;
    }

    // ── Category: pure sauce locations ────────────────────────────────────────
    if (sauceLocs[my_location()] || sauceMobs[mob]) {
        if (!free_monster() && !free_location()){
            free_run(page_text);
            free_kill(page_text);
        }
        sauce(4);
        attack();
        return;
    }

    // ── Category: pure hurt locations/monsters ────────────────────────────────
    if (hurtLocs[my_location()] || hurtMobs[mob]) {
        while (current_round() > 0) hurt(1);
        return;
    }

    // Garbo
    if (my_location() == $location[barf mountain]){
        if (have_skill($skill[pocket crumbs]) && to_int(get_property("_pantsgivingCrumbs")) < 9)
            use_skill($skill[pocket crumbs]);
        if (my_familiar() == $familiar[patriotic eagle])
            use_skill($skill[%FN, LET'S PLEDGE ALLEGIANCE TO A ZONE]);
        if (mob == $monster[garbage tourist] && to_int(get_property("_knuckleboneDrops")) == 100){
            sniff($monster[garbage tourist]);
        } else if (mob == $monster[angry tourist] && to_int(get_property("_knuckleboneDrops")) < 100){
            sniff($monster[angry tourist]);
        }
        if (item_amount($item[cosmic bowling ball]) > 0){
            use_skill($skill[Bowl Straight Up]);
        }
        dart();
        //stasis();
        cleanUp();
    }

    // ── Category: Dread (Woods, Village, Castle share opener) ─────────────────
    if ($locations[Dreadsylvanian Woods, Dreadsylvanian Village,
        Dreadsylvanian Castle] contains my_location()) {
        free_run(page_text);
        free_kill(page_text);
        dart();
        if (have_skill($skill[Slay the Dead])) use_skill($skill[Slay the Dead]);
        insta_kill(page_text);
        boolean paw = get_property("_monkeyPawWishesUsed") == "0"
            && have_equipped($item[cursed monkey's paw]);

        if (my_location() == $location[Dreadsylvanian Woods]) {
            if (paw && mob == $monster[hot werewolf]) { use_skill($skill[monkey slap]); return; }
            if (paw) { use_skill($skill[monkey slap]); return; }
            if (contains_text(to_string(mob.name),"bugbear")) { atk(9); return; }
            if (contains_text(to_string(mob.name),"werewolf")) {
                atk(2);
                for i from 1 to 5 { use_skill(elementBonus[monster_element()]); }
                return;
            }

        } else if (my_location() == $location[Dreadsylvanian Village]) {
            if (paw) { use_skill($skill[monkey slap]); return; }
            sauce(6);
            return;

        } else if (my_location() == $location[Dreadsylvanian Castle]) {
            if (paw) { use_skill($skill[monkey slap]); return; }
            if (contains_text(to_string(mob.name),"skeleton")
                || contains_text(to_string(mob.name),"vampire")) {
                if (have_effect($effect[chilled to the bone]) > 0
                    && contains_text(to_string(mob.name),"skeleton"))
                    throw_item($item[shadow brick]);
                for i from 1 to 10 { use_skill(elementBonus[monster_element()]); }
                use_skill($skill[stuffed mortar shell]);
                atk(3); sauce(3); atk(24);
                return;
            }
            sauce(1);
            return;
        }
    }

    // ── Category: Hobopolis ───────────────────────────────────────────────────
    if (my_location().zone == "Hobopolis") {
        if (mob == $monster[Frosty]) {
            throw_items($item[cinnamon troll doll],       $item[grape troll doll]);
            throw_items($item[blue raspberry troll doll], $item[bag of gross foreign snacks]);
            throw_items($item[crazy hobo notebook],       $item[hedgeturtle]);
            for i from 1 to 11 {
                throw_items($item[d8], $item[d8]);
                if (my_hp() < 100) throw_items($item[new age healing crystal], $item[d8]);
            }
            if (monster_hp() <= 18) attack();
            return;
        }
        if (mob == $monster[Ol' Scratch] || mob == $monster[Oscus] || mob == $monster[Chester]) {
            for i from 1 to 7 { use_skill($skill[snowclone]); }
            return;
        }
        if (mob == $monster[zombo]) {
            for i from 1 to 13 { hurt(1); if (my_hp() < 250) heal_hurt(); }
            return;
        }
        if (my_location() == $location[A Maze of Sewer Tunnels]) {
            steal();
            if (get_property("cleeshSewers") == "true"){
                if (last_monster() == $monster[giant zombie goldfish])
                    use_skill($skill[spring kick]);
                use_skill($skill[Sea *dent: Talk to some fish]);
                if (have_skill($skill[Prepare to reanimate your Foe])) use_skill($skill[Prepare to reanimate your Foe]);
            }
            if (last_monster() == $monster[giant zombie goldfish]) {
                use_skill($skill[spring kick]); free_run(page_text); sauce(2); return;
            }

            if (last_monster() == $monster[Sewer gator]) {
                use_skill($skill[Sea *dent: Throw a Lightning Bolt]); sauce(2); return;
            }
                free_run(page_text);
                free_kill(page_text);
                attack(); use_skill($skill[saucegeyser]); attack(); sauce(2);
        } else if (my_location() == $location[Hobopolis Town Square]) {
            free_run(page_text);
            free_kill(page_text);
            if ($strings[boots,skulls,eyes,crotches,guts] contains get_property("parts_collection")) {
                use_skill($skill[Stuffed Mortar Shell]);
                throw_item($item[seal tooth]);
            } else if (get_property("parts_collection") == "skins") {
                use_skill($skill[Lunging Thrust-Smack]);
            }
        } else if (my_location() == $location[Exposure Esplanade]) {
            set_property("choiceAdventure1589","1&victim=690");
            free_run(page_text);
            free_kill(page_text);
            insta_kill(page_text);
            sauce(4);
        } else if (my_location() == $location[The Ancient Hobo Burial Ground]) {
            free_run(page_text);
            free_kill(page_text);
            atk(5);
        } else if ($locations[The Purple Light District, The Heap,Burnbarrel Blvd.] contains my_location()) {
            if ((my_location() == $location[The Purple Light District] && to_int(get_property("PLD_left")) >= 50 && get_property("cleeshPLD") == "true") || 
            (my_location() == $location[The Heap]) && get_property("cleeshHeap") == "true"){
                use_skill($skill[Sea *dent: Talk to some fish]);
                if (have_skill($skill[Prepare to reanimate your Foe])) use_skill($skill[Prepare to reanimate your Foe]);
            }
            free_run(page_text);
            free_kill(page_text);
            sauce(4);
        }
        return;
    }

    // ── Category: FantasyRealm ────────────────────────────────────────────────
    if (my_location().zone == "FantasyRealm") {
        if (my_location() == $location[The Barrow Mounds])  { runaway(); return; }
        if (my_location() == $location[The Troll Fortress]) { for i from 1 to 4 { use_skill($skill[Awesome Balls of Fire]); } return; }
        if (mob == $monster[Flock of every birds])          { for i from 1 to 9 { use_skill($skill[garbage nova]); } return; }
        if (mob == $monster[crypt creeper])                 { for i from 1 to 6 { throw_items($item[gauze garter],$item[gauze garter]); } return; }
        if (mob == $monster[Sewage Treatment Dragon])       { for i from 1 to 3 { throw_items($item[new age healing crystal],$item[new age hurting crystal]); } return; }
        if ($monsters[plywood cultists, Ley Incursion, quadfaerie] contains mob) { atk(24); return; }
        sauce(4);
        return;
    }

    // ── Category: Gingerbread City ────────────────────────────────────────────
    if (my_location().zone == "Gingerbread City") {
        if ($monsters[gingerbread convict, gingerbread finance bro,
            gingerbread gentrifier, gingerbread lawyer,
            gingerbread tech bro, judge fudge] contains mob
            && item_amount($item[gingerbread cigarette]) > 0)
            throw_item($item[gingerbread cigarette]);
        sauce(8);
        return;
    }

    // ── Category: Glaciest ────────────────────────────────────────────────────
    if (my_location().zone == "The Glaciest") {
        free_run(page_text);
        free_kill(page_text);
        if (my_location() == $location[the ice hotel]) {
            if (mob == $monster[ice concierge]) {
                if (!contains_text(get_property("trackedMonsters"),"ice concierge:McHugeLarge Slash"))
                    use_skill($skill[MCHUGELARGE SLASH]);
                if (!contains_text(get_property("trackedMonsters"),"ice concierge:Transcendent Olfaction"))
                    use_skill($skill[TRANSCENDENT OLFACTION]);
            }
            if (get_property("walfordBucketItem") == "blood") attack();
            if (get_property("walfordBucketItem") == "ice")   use_skill($skill[Weapon of the Pastalord]);
            use_skill($skill[saucegeyser]);
        }
        if ($locations[the ice hole, VYKEA] contains my_location()) sauce(4);
        return;
    }

    // ── Category: Spring Break Beach ────────────────────────────────────────────────────
    if (my_location().zone == "Spring Break Beach") {
        if (my_location() == $location[The Fun-Guy Mansion]) {
                float minHP = to_float(my_maxhp())*0.8872;
                if (my_hp() < minHP){
                    throw_item($item[new age healing crystal]);
                }
                if (!free_monster())
                    free_kill(page_text);
                use_skill($skill[ Saucegeyser]);
                throw_item($item[new age hurting crystal]);
        }
        if (my_location() == $location[Sloppy Seconds Diner]) {
            if (!contains_text(get_property("trackedMonsters"),"Sloppy Seconds Sundae:Transcendent Olfaction")){
                use_skill($skill[ Transcendent Olfaction]);
            }
            if (!contains_text(get_property("trackedMonsters"),"Sloppy Seconds Sundae:McHugeLarge Slash")){
                use_skill($skill[McHugeLarge Slash]);
            }
            if (!contains_text(get_property("trackedMonsters"),"Sloppy Seconds Sundae:Gallapagosian Mating Call")){
                use_skill($skill[Gallapagosian Mating Call]);
            }
            if (contains_text(get_property("banishedMonsters"),"broctopus")){
                use_skill($skill[spring kick]);
            }
            if (!free_monster())
                free_kill(page_text);
            use_skill($skill[ stuffed mortar shell]);
            use_skill($skill[ Saucegeyser]);
            use_skill($skill[ Saucegeyser]);
        }
        if (my_location() == $location[The Sunken Party Yacht]) {
            if (!contains_text(get_property("banishedMonsters"),"broctopus") && have_effect($effect[fishy]) >= 20){
                use_skill($skill[spring kick]);
            }
            if (!free_monster())
                free_kill(page_text);
            use_skill($skill[ stuffed mortar shell]);
            use_skill($skill[ Saucegeyser]);
            use_skill($skill[ Saucegeyser]);
        }
        return;
    }

    // The Sea
    if (my_location() == $location[The Marinara Trench]){
        if (last_monster() == $monster[giant squid] && my_class() == $class[accordion thief]){
            sniff($monster[giant squid]);
        }
    }

    // ── Individual locations / monsters ───────────────────────────────────────

    if (my_location() == $location[Madness Bakery]) {
        if (have_effect($effect[Citizen of a Zone]) == 0)
            use_skill($skill[%fn, let's pledge allegiance to a Zone]);
        if (mob.phylum == $phylum[construct]) use_skill($skill[%fn, Release the Patriotic Screech!]);
        else abort("wrong mob in madness");
        free_run(page_text); attack(); return;
    }

    if (my_location()== $location[Convention Hall Lobby]){
        while (current_round() > 0){
            throw_item($item[bottle of G&uuml;-Gone]);
        }
    }

    if (my_location()== $location[The Outer Compound]){
        while (current_round() > 0){
            use_skill($skill[Apprivoisez la tortue]);
        }
    }

    if (my_location() == $location[The Slime Tube]) {
        if (get_property(get_clan_id() + "Tickled") == "tickled"){
            abort();
        }
        if (mob == $monster[mother slime]){
            use_skill($skill[Raise Backup Dancer]);
            use_skill($skill[Raise Backup Dancer]);
        }
        free_kill(page_text); free_run(page_text); insta_kill(page_text);
        if (my_familiar() == $familiar[purse rat] && have_effect($effect[coated in slime]) > 10 && to_int(get_property("_shadowBricksUsed")) < 13){
            throw_item($item[shadow brick]);
        }
        for i from 1 to 4 {
            if (my_hp() < 500 && my_hp() < my_maxhp()/2)
                throw_items($item[new age healing crystal],$item[new age healing crystal]);
            use_skill($skill[weapon of the pastalord]);
        }
        return;
    }

    if (my_location() == $location[Domed City of Grimacia]) {
        if (mob.phylum == $phylum[horror])
            use_skill($skill[%fn, Release the Patriotic Screech!]);
        else {
            if (to_int(get_property("_mildEvilPerpetrated")) < 3) use_skill($skill[perpetrate mild evil]);
            if (to_int(get_property("_batWingsSwoopUsed")) < 11)  use_skill($skill[swoop like a bat]);
            while (to_int(get_property("_douseFoeUses")) < 3 && get_property("_douseFoeSuccess") == "false")
                use_skill($skill[douse foe]);
        }
        sauce(5); return;
    }

    if (my_location() == $location[The Broodling Grounds]) {
        if (mob == $monster[hellseal pup]) {
            throw_item($item[seal tooth]);
            throw_item($item[seal tooth]);
            throw_item($item[seal tooth]);
        }
        atk(3); return;
    }

    if (my_location() == $location[The Brinier Deepers]) {
        if (mob == $monster[trophyfish]) abort();
        return;
    }
    if (my_location() == $location[Mer-kin Elementary School]) {
        if (contains_text(get_property("banishedMonsters"),"hacker"))
            use_skill($skill[Sea *dent: Throw a Lightning Bolt]);
    }

    if (my_location() == $location[Shadow Rift (The Nearby Plains)]) {
        if (mob == $monster[shadow scythe]) sauce(2);
        if (mob == $monster[shadow spire]) {
            for i from 1 to 4 {
                if (my_hp() <= my_maxhp()/2) heal_hurt();
                use_skill($skill[saucegeyser]);
            }
        }
        if (have_skill($skill[McHugeLarge Avalanche])
            && to_int(get_property("_mcHugeLargeAvalancheUses")) < 3)
            use_skill($skill[McHugeLarge Avalanche]);
        if (have_skill($skill[Launch spikolodon spikes]))
            use_skill($skill[Launch spikolodon spikes]);
        if (mob == $monster[shadow orrery]) atk(12); else sauce(10);
        return;
    }
    if (my_location() == $location[Shadow Rift (The Misspelled Cemetary)]) {
        steal();
        if (mob.boss == true){
            cleanUp();
        }
        if (mob == $monster[shadow guy]){
            if (have_equipped($item[blood cubic zirconia])){
                use_skill($skill[BCZ: Refracted Gaze]);
                use_skill($skill[swoop like a bat]);
            }
        } else if (have_equipped($item[bat wings])){
            use_skill($skill[swoop like a bat]);
        }
        free_kill(page_text);
        free_run(page_text);
    }

    if (my_location() == $location[The Spooky Forest]) { free_run(page_text); return; }

    if (my_location() == $location[Investigating a Plaintive Telegram]) {
        if (mob == $monster[Former Sheriff Dan Driscoll])  atk(18);
        if (mob == $monster[Snake-Eyes Glenn])             for i from 1 to 6 { use_skill($skill[grease lightning]); }
        if (mob == $monster[Clara])                        for i from 1 to 6 { use_skill($skill[eggsplosion]); }
        if (mob == $monster[Pharaoh Amoon-Ra Cowtep])      hurt(4);
        if (mob == $monster[cow cultist]
            && contains_text(get_property("lastEncounter"),"reprehensible"))
            for i from 1 to 3 { use_skill($skill[toynado]); }
        sauce(6); return;
    }

    if (my_location() == $location[The Primordial Soup]) {
        if (mob == $monster[Cyrus the Virus]) {
            foreach it in $items[memory of a CT base pair, memory of a CG base pair,
                memory of a CA base pair, memory of a GT base pair,
                memory of an AT base pair, memory of an AG base pair] {
                if (item_amount(it) > 0
                    && !contains_text(get_property("cyrusAdjectives"), basePairs[it]))
                    throw_item(it);
            }
        }
        sauce(3); return;
    }

    if (my_location() == $location[the deep dark jungle]) {
        if (get_property("_questESp") == "questESpSmokes") {
            if (mob != $monster[smoke monster] && mob != $monster[Mercenary of Fortune])
                use_skill(combatBan());
            sauce(3);
        }
        if (get_property("_questESp") == "questESpOutOfOrder") {
            if (mob != $monster[Mercenary of Fortune]) use_skill(combatBan());
            sauce(3);
        }
        return;
    }

    if (my_location() == $location[The Mansion of Dr. Weirdeaux]) {
        if (get_property("_questESp") == "questESpClipper")
            for i from 1 to 3 { throw_item($item[military-grade fingernail clippers]); }
        sauce(3); return;
    }

    if (my_location() == $location[The Tower of Procedurally-Generated Skeletons]) {
        if (contains_text(get_property("lastEncounter"),"shiny")
            || contains_text(get_property("lastEncounter"),"disorienting")) {
            if (contains_text(get_property("lastEncounter"),"dancing")) abort();
            if (contains_text(get_property("lastEncounter"),"ghostly"))
                for i from 1 to 3 { throw_items($item[boozebomb],$item[boozebomb]); }
            hurt(6);
        } else {
            sauce(6);
        }
        return;
    }

    if (my_location() == $location[the nightmare meatrealm]) {
        use_skill($skill[spring away]); runaway(); return;
    }

    if ($strings[Le Marais D&egrave;gueulasse] contains my_location().zone) {
        sauce(3); return;
    }

    // ── Fallback ──────────────────────────────────────────────────────────────
    free_kill(page_text);
    insta_kill(page_text);
    sauce(30);
    attack();
}