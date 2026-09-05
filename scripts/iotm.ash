// ═══ iotm.ash ═══════════════════════════════════════════════════════════════
    // Shared helpers for the farto / free-kill environment.
    //   1. Globals
    //   2. General utilities
    //   3. Banish utilities
    //   4. Clan & instance access
    //   5. IOTM & item helpers   (one sub-section per item)
    //   6. Adventuring-state checks
    //   7. Unblemished pearls
    //   8. Universe calculator
    //  10. Script lifecycle

// ─── 1. GLOBALS ──────────────────────────────────────────────────────────────

    int uniInt, uniAdv, pearlsDoneToday;
    string clan = get_clan_name();
    int estimatedTurns;
    boolean [monster] haveLocketMonster = get_locket_monsters();

    // Mafia state snapshot, read once at import so finisher() can hand the account
    // back exactly what it had. starter() repoints the between-battle / after-
    // adventure / choice hooks, swaps in the CCCS custom combat script, pins the
    // auto-recovery levels and clears the native auto-attack; these captures happen
    // before the entry script's main() calls starter(), so restoring them is safe
    // even on an account with no garbo install.
    string ccsStorage                   = get_property("customCombatScript");
    string battleActionStorage          = get_property("battleAction");
    string autoAttackStorage            = get_property("defaultAutoAttack");
    string betweenBattleScriptStorage   = get_property("betweenBattleScript");
    string afterAdventureScriptStorage  = get_property("afterAdventureScript");
    string choiceAdventureScriptStorage = get_property("choiceAdventureScript");
    string hpAutoRecoveryStorage        = get_property("hpAutoRecovery");
    string hpAutoRecoveryTargetStorage  = get_property("hpAutoRecoveryTarget");
    string mpAutoRecoveryStorage        = get_property("mpAutoRecovery");
    string mpAutoRecoveryTargetStorage  = get_property("mpAutoRecoveryTarget");

// ─── 2. GENERAL UTILITIES ────────────────────────────────────────────────────

    int count_substring(string text, string sub) {
        int count = 0;
        int pos = 0;
        while (true) {
            pos = index_of(text, sub, pos);
            if (pos == -1) break;
            count += 1;
            pos += length(sub);
        }
        return count;
    }

    void aa(string str){
        set_auto_attack(str);
        if (get_auto_attack() == 0)
            cli_execute("/aa " + str);
        if (get_auto_attack() == 0)
            visit_url("account.php?am=1&value="+ get_property("combatMacroID") +"&ajax=1");
        if (get_auto_attack() == 0)
            abort("autoattack not set properly. Most likely mafia is a little broken and requires a restart");
    }

    item [effect] ETIManualAssignment = {
        $effect[beefy heart]:$item[Black and White Apron Meal Kit]
    };

    item effect_to_item(effect ef){
        if (contains_text(ef.default,"drink 1 ") || contains_text(ef.default,"chew 1 ")){
            return delete(to_buffer(ef.default),0,7).to_item();
        } else if (contains_text(ef.default,"eat 1 ") || contains_text(ef.default,"use 1 ")){
            return delete(to_buffer(ef.default),0,6).to_item();
        } else
            return ETIManualAssignment[ef];
    }

    // Use a skill if it appears as an option on the current page
    void use_if_have_skill(string page_text, skill sk) {
        if (contains_text(page_text, to_string(sk)))
            use_skill(sk);
    }

    // Returns true if the item exists anywhere accessible (inventory, equipped, storage, closet)
    boolean have_item(item it) {
        return item_amount(it) > 0
            || have_equipped(it)
            || storage_amount(it) > 0;
    }

    // Returns session log text from the current turn onward
    string LastAdvTxt() {
        string lastlog = session_logs(1)[0];
        int nowmark = max(
            last_index_of(lastlog, "[" + my_turncount() + "]"),
            last_index_of(lastlog, "[" + (my_turncount() + 1) + "]")
        );
        return substring(lastlog, nowmark);
    }

    boolean lastAdvWasCombat(){
        return (contains_text(lastAdvTxt(),"Round 1"));
    }

    boolean pullSequence(item it) {
        if (pulls_remaining() == 0)
            return false;
        if (!contains_text(get_property("_roninStoragePulls"), to_int(it))) {
            if (storage_amount(it) == 0){
                if (mall_price(it) > to_int(get_property("autoBuyPriceLimit"))){
                    if (!user_confirm("Price of " + it + " exeeds autoBuyPriceLimit, skip?"))
                        abort("Price of " + it + " exeeds autoBuyPriceLimit");
                }
                buy_using_storage(it);
            }
            return take_storage(1, it);
        }
        return false;
    }

// ─── 3. BANISH UTILITIES ─────────────────────────────────────────────────────

    record ban {
        string pref;
        skill banSkill;
    };

    ban [item] banMap = {
        $item[spring shoes]:        new ban("Spring Kick",           $skill[spring kick]),
        $item[monodent of the sea]: new ban("Sea \\*dent",           $skill[Sea *dent: Throw a Lightning Bolt]),
        $item[Heartstone]:          new ban("Heartstone %banish",    $skill[Heartstone: %banish]),
        $item[none]:                new ban("snokebomb",             $skill[snokebomb]),
    };

    // Returns all locations a given monster can appear in
    location [int] monster_found_in(monster m) {
        location [int] output;
        foreach o in $locations[]
            if (o.get_location_monsters() contains m)
                output[count(output)] = o;
        return output;
    }

    // Returns the monster currently banished by a given banisher string
    monster banished(string banisher) {
        matcher m = create_matcher("([^:]+):\\Q" + banisher,
            get_property("banishedMonsters")
        );
        return m.find() ? to_monster(m.group(1)) : $monster[none];
    }

    // Returns true if the given banisher has been used on a monster at your current location
    boolean banishUsedAtYourLocation(string banisher) {
        foreach num in monster_found_in(banished(banisher)) {
            if (monster_found_in(banished(banisher))[num] == my_location())
                return true;
        }
        return false;
    }

    // Equips the appropriate banish gear for a location (that hasn't been used yet) and sets the slot override property.
    // NOTE: has the side effect of setting an Override property — callers should be aware.
    item banishGear(location loc) {
        item it;
        foreach ite in $items[spring shoes, monodent of the sea, Heartstone] {
            if (ite == $item[Heartstone] && get_property("heartstoneBanishUnlocked") == "false")
                continue;
            if (appearance_rates(loc)[banished(banMap[ite].pref)] == 0 && have_item(ite)) {
                it = ite;
                break;
            }
        }
        set_property(to_string(to_slot(it)) + "Override", ", equip " + it);
        print(to_string(to_slot(it)) + "Override");
        return it;
    }

    // Returns the combat banish skill for the first equipped banish item
    // whose target is no longer appearing at your location
    skill combatBan() {
        foreach ite in $items[spring shoes, monodent of the sea, Heartstone] {
            if (ite == $item[Heartstone] && get_property("heartstoneBanishUnlocked") == "false")
                continue;
            if (have_equipped(ite)
                && appearance_rates(my_location())[banished(banMap[ite].pref)] == 0) {
                print("Banish item being considered " + ite + " parsed banished monster is " + banished(banMap[ite].pref) + " and the calculated appearance rate at current location is " + appearance_rates(my_location())[banished(banMap[ite].pref)]);
                cli_execute("get banishedMonsters");
                return banMap[ite].banSkill;
            }
        }
        return $skill[none];
    }

// ─── 4. CLAN & INSTANCE ACCESS ───────────────────────────────────────────────

    int [string] clan_to_ID {
        "Hyrule" : 72876,
        "Dread and Final" : 2047010985,
        "Dread Mart" : 2047010683,
        "Dread Outlet Bargain Market" : 2047010572,
        "Dreadleys" : 2047010988,
        "DreadNugget" : 2047010986,
        "Dreadway" : 2047010667,
        "Fart Sauce Annex" : 2047010939
    };

    void whitelist(string clan){
        visit_url("showclan.php?whichclan="+clan_to_ID[clan]+"&action=joinclan&confirm=on");
    }

    void stashgrab(item it){
        visit_url("showclan.php?whichclan=2047009940&action=joinclan&confirm=on");
        if (stash_amount(it) > 0)
            take_stash(it, 1 );
        visit_url("showclan.php?whichclan=" + get_property("homeClanID").to_int() + "&action=joinclan&confirm=on");
        if (get_property("_clanFortuneConsultUses") == 0){
            cli_execute("/whitelist Bonus Adventures from Hell");
            visit_url("showclan.php?whichclan=" + get_property("homeClanID").to_int() + "&action=joinclan&confirm=on");
        }}

    void stashreturn(item it){
        visit_url("showclan.php?whichclan=2047009940&action=joinclan&confirm=on");
        cli_execute("unequip "+ it);
        if (available_amount(it) > 0)
            put_stash(it, 1 );
        visit_url("showclan.php?whichclan=" + get_property("homeClanID").to_int() + "&action=joinclan&confirm=on");}

    // Returns the number of chamois available in the clan slime tube
    int chamoixAmount() {
        matcher m = create_matcher("There are (\\d+) chamoi", visit_url("clan_slimetube.php?action=bucket"));
        return m.find() ? to_int(m.group(1)) : 0;
    }

    void camo() {
        if (chamoixAmount() < 1) {
            string current_clan = get_clan_id();
            try {
                foreach str in $strings[2046992052,2047010985,2047010683,2047010572,2047010988,2047010986,2047010667]{
                    visit_url("showclan.php?whichclan="+ str +"&action=joinclan&confirm=on");
                    if (chamoixAmount() >= 1)
                        break;
                    if (str == 2047010667)
                        abort("out of chamoix");
                }
                visit_url("clan_slimetube.php?action=chamois");
            } finally {
                visit_url("showclan.php?whichclan=" + current_clan + "&action=joinclan&confirm=on");
            }
        } else {
            visit_url("clan_slimetube.php?action=chamois");
        }
    }

// ─── 5. IOTM & ITEM HELPERS ──────────────────────────────────────────────────

    // ── Everfull Dart Holster ────────────────────────────────────────────────────
    string perks = get_property("everfullDartPerks");
    boolean bullseyeReady() {
        int n = count_substring(perks, "25% Better bullseye targeting") + count_substring(perks, "25% better chance to hit bullseyes") + count_substring(perks, "25% More Accurate bullseye targeting");
        return (n >= 2);
    }

    boolean everfullReady(){
        if (!bullseyeReady())
            return false;
        return (contains_text(perks, "You are less impressed by bullseyes")
                && contains_text(perks, "Bullseyes do not impress you much"))
            || count_substring(perks, "Bullseyes do not impress you much") >= 2
            || count_substring(perks, "You are less impressed by bullseyes") >= 2;
        return true;
    }

    void darts() {
        while (to_int(get_property("_dartsLeft")) > 0
            && have_equipped($item[everfull dart holster])
            && current_round() > 0) {
            if (contains_text(get_property("everfullDartPerks"), "Butt")) {
                matcher m = create_matcher("(\\d+):butt", get_property("_currentDartboard"));
                if (!m.find()) break;
                use_skill(to_skill(to_int(m.group(1))));
            } else {
                use_skill($skill[Darts: Throw at %part1]);
            }
        }
    }

    // ── Blood Cubic Zirconia ─────────────────────────────────────────────────────

    int BCZcost(string BCZskill) {
        int cast = to_int(get_property("_bcz" + BCZskill));
        if (cast == 12) return 420000;
        if (cast > 12) cast -= 1;
        int castMathFloor = floor(cast / 3);
        int castMathModulo = cast % 3;
        int substatBase;
        switch (castMathModulo) {
            case 0: substatBase = 11; break;
            case 1: substatBase = 23; break;
            case 2: substatBase = 37; break;
        }
        // Pattern: 11, 23, 37, 110, 230, 370, ... 13th cast handled separately but unreachable
        return substatBase * 10 ** ((cast < 12 || (cast > 12 && castMathModulo == 0))
            ? castMathFloor : castMathFloor + 1);
    }

    // ── The Eternity Codpiece ────────────────────────────────────────────────────

    void codpiece(string input) {
        visit_url("inventory.php?action=docodpiece");
        if (input == "none") {
            string verify = visit_url("inventory.php?action=docodpiece");
            if (!contains_text(verify, " mounted in slot #"))
                return;
            for slots from 1 to 5 {
                if (contains_text(verify," Empty slot #" + slots )){
                    continue;
                } else {
                    visit_url("choice.php?whichchoice=1588&option=2&which=" + slots);
                }
            }
        } else {
            string [int] slots = split_string(input, ",");
            foreach num in slots {
                if (available_amount(to_item(slots[num])) == 0 ){
                    slots[num] = "";
                    continue;
                }
                visit_url("choice.php?whichchoice=1588&option=1&which=" + (num + 1)
                    + "&iid=" + to_int(to_item(slots[num])));
            }
            // Verify all slots mounted correctly
            string verify = visit_url("inventory.php?action=docodpiece");
            foreach num in slots {
                if (!contains_text(verify, to_item(slots[num]) + " mounted in slot #" + (num + 1)))
                    abort("Codpiece slot incorrect");
            }
        }
        cli_execute("refresh inv");
    }

    // ── Prismatic Beret ──────────────────────────────────────────────────────────

    int beretGearCap = get_property("autoBuyPriceLimit").to_int();   // max mall price for one piece of busking gear

    // Total equipment power of hat + shirt + pants, as Beret Busking reads it (Tao doubles hat and pants).
    int total_power(){
        int n;
        foreach sl in $slots[hat, shirt, pants]{
            if (have_skill($skill[Tao of the Terrapin]) && (sl == $slot[hat] || sl == $slot[pants]))
                n += get_power(equipped_item(sl)) * 2;
            else
                n += get_power(equipped_item(sl));
        }
        return n;
    }

    // Distinct effective power -> an item giving it in `sl`; `mult` is the Tao multiplier (2 pants, 1 shirt). Key 0 = wear nothing.
    item [int] beretSlotOptions(slot sl, int mult, boolean allowMall){
        item [int] opts;
        opts[0] = $item[none];
        foreach it in $items[]{
            if (to_slot(it) != sl || !can_equip(it))
                continue;
            boolean owned = available_amount(it) > 0;
            boolean buyable = allowMall && it.tradeable && mall_price(it) < beretGearCap;
            if (!owned && !buyable)
                continue;
            int p = get_power(it) * mult;
            if ((opts contains p) && available_amount(opts[p]) > 0)
                continue;
            opts[p] = it;
        }
        return opts;
    }

    void beretEquip(slot sl, item it){
        if (it == $item[none]){
            if (equipped_item(sl) != $item[none])
                cli_execute("unequip " + sl);
            return;
        }
        if (available_amount(it) == 0)
            buy(1, it, beretGearCap);
        equip(sl, it);
    }

    // Prismatic beret on the head, then a pants+shirt pair whose total_power() hits `target` exactly. Owned gear first, then mall.
    void equipPower(int target){
        int mult = have_skill($skill[Tao of the Terrapin]) ? 2 : 1;

        retrieve_item($item[prismatic beret]);
        equip($slot[hat], $item[prismatic beret]);

        int remaining = target - get_power($item[prismatic beret]) * mult;
        if (remaining < 0)
            abort("equipPower: prismatic beret is " + (get_power($item[prismatic beret]) * mult) + " power, already over target " + target);

        boolean tryPools(boolean allowMall){
            item [int] pants  = beretSlotOptions($slot[pants], mult, allowMall);
            item [int] shirts = beretSlotOptions($slot[shirt], 1, allowMall);
            foreach pPow in pants{
                if (pPow > remaining)
                    continue;
                int need = remaining - pPow;
                if (!(shirts contains need))
                    continue;
                beretEquip($slot[pants], pants[pPow]);
                beretEquip($slot[shirt], shirts[need]);
                return true;
            }
            return false;
        }

        if (!tryPools(false) && !tryPools(true))
            abort("equipPower: no pants+shirt combination reaches " + remaining + " power for target " + target);
    }

    // Drain the day's remaining Beret Busking casts (5/day), hitting the target power for each cast index.
    // buffType is "meat" or anything containing "familiar weight".
    void beretBusking(string buffType){
        int [int] target;
        if (buffType == "meat"){
            target[0] = 440;
            target[1] = 750;
            target[2] = get_property("ascensionsToday").to_int() > 0 ? 780 : 495;
            target[3] = 575;
            target[4] = 665;
        } else if (contains_text(buffType, "familiar weight")){
            target[0] = 735;
            target[1] = 320;
            target[2] = 510;
            target[3] = 605;
            target[4] = 600;
        } else {
            abort("beretBusking: unknown buffType '" + buffType + "'");
        }

        foreach cast, want in target{
            if (cast < get_property("_beretBuskingUses").to_int())
                continue;
            if (get_property("_beretBuskingUses").to_int() >= 5)
                return;
            equipPower(want);
            if (total_power() != want)
                abort("beretBusking: wanted " + want + " power for cast " + cast + ", assembled " + total_power());
            use_skill($skill[Beret Busking]);
        }
    }

    // ── Combat Baseball ──────────────────────────────────────────────────────────

    int baseballPlayers(){
        string [int] lineup = split_string(get_property("baseballTeam"), ",");
        int players;
        foreach num in lineup { players = num + 1; }
        return players;
    }

    void fillPrereqs(int outcomeSlot, string pitchType) {
        int filled = 0;
        int before = outcomeSlot - 1;
        while (filled < 2 && before >= 1) {
            if (get_property("pitchNum" + before) == "") {
                set_property("pitchNum" + before, pitchType);
                filled += 1;
            }
            before -= 1;
        }
        if (filled < 2)
            abort("Not enough open slots to fill prereqs for outcome at slot " + outcomeSlot);
    }
    void baseballD() {
        codpiece("none");
        string [int] lineup = split_string(get_property("baseballTeam"), ",");
        int players;
        foreach num in lineup { players = num + 1; }
        if (players != 9) return;

        try {
            int YRPitchNum;
            int FKPitchNum;
            int BanishPitchNum;

            // Scan 9→3, take the latest slot for each outcome type
            for x from 9 to 3 {
                if (YRPitchNum == 0 && $strings[2278,2282] contains lineup[x-1]) {
                    YRPitchNum = x;
                    set_property("pitchNum" + x, "1");
                }
                if (FKPitchNum == 0 && $strings[2274,2278,2282] contains lineup[x-1]) {
                    FKPitchNum = x;
                    set_property("pitchNum" + x, "3");
                }
                // Banish (third pitch) only activates if slot 9 is already claimed by another outcome
                if (BanishPitchNum == 0 && $strings[2274] contains lineup[x-1]
                    && (YRPitchNum == 9 || FKPitchNum == 9)) {
                    BanishPitchNum = x;
                    set_property("pitchNum" + x, "2");
                }
            }

            if (YRPitchNum == 0 && FKPitchNum == 0) {
                print("No yellow ray or free kill pitchers in lineup, skipping.", "red");
                return;
            }

            // Assigning other pitches
            int [int] pitchOrder   = {1: YRPitchNum, 2: BanishPitchNum, 3: FKPitchNum};
            string [int] pitchChoice = {1: "1", 2: "2",        3: "3"};

            //Ordering pitches from latest to earliest
            for i from 1 to 3 {
                for j from 1 to (3 - i) {
                    if (pitchOrder[j] < pitchOrder[j+1]) {
                        int tmpS = pitchOrder[j];   pitchOrder[j]   = pitchOrder[j+1]; pitchOrder[j+1]   = tmpS;
                        string tmpP = pitchChoice[j]; pitchChoice[j] = pitchChoice[j+1]; pitchChoice[j+1] = tmpP;
                    }
                }
            }

            foreach i in pitchOrder {
                if (pitchOrder[i] > 0)
                    fillPrereqs(pitchOrder[i], pitchChoice[i]);
            }
            codpiece("none");
            visit_url("inventory.php?pwd&action=pball&pwd=" + my_hash() + "&action=pball", false);
            for x from 1 to 9 {
                string pitch = get_property("pitchNum" + x);
                run_choice(pitch == "" ? 4 : to_int(pitch));
            }
            run_choice(6);

        } finally {
            for x from 1 to 9 {
                set_property("pitchNum" + x, "");
            }
            codpiece("peridot of peril,blood cubic zirconia,baseball diamond,tuesday's ruby,tuesday's ruby");
        }
    }

    // ── Model Train Set ──────────────────────────────────────────────────────────

    void trainset() {
        int pos = to_int(get_property("trainsetPosition")) % 8;
        int [int] slots = {
            (pos)     % 8: 8,   // next station
            (pos + 1) % 8: 1,
            (pos + 2) % 8: 15,
            (pos + 3) % 8: 20,
            (pos + 4) % 8: 3,
            (pos + 5) % 8: 7,
            (pos + 6) % 8: 2,
            (pos + 7) % 8: 19
        };
        visit_url("choice.php?forceoption=0?whichchoice=1485&option=1"
            + "&slot%5B0%5D=" + slots[0]
            + "&slot%5B1%5D=" + slots[1]
            + "&slot%5B2%5D=" + slots[2]
            + "&slot%5B3%5D=" + slots[3]
            + "&slot%5B4%5D=" + slots[4]
            + "&slot%5B5%5D=" + slots[5]
            + "&slot%5B6%5D=" + slots[6]
            + "&slot%5B7%5D=" + slots[7]);
    }

    // Locket

    int locketAvailable(){
        int n;
        if (available_amount($item[combat lover's locket]) > 0){
            string [int] lockets = split_string(get_property("_locketMonstersFought"), ",");
            n += 3-count(lockets);
        }
        return n;
    }

    // ── Leprecondo ───────────────────────────────────────────────────────────────

    string [int] lepRoomToNum = {
        1:"buckets of concrete",        2:"thrift store oil painting",
        3:"boxes of old comic books",   4:"second-hand hot plate",
        5:"beer cooler",                6:"free mattress",
        7:"gigantic chess set",         8:"UltraDance karaoke machine",
        9:"cupcake treadmill",          10:"beer pong table",
        11:"padded weight bench",       12:"internet-connected laptop",
        13:"sous vide laboratory",      14:"programmable blender",
        15:"sensory deprivation tank",  16:"fruit-smashing robot",
        17:"ManCave™ sports bar set",   18:"couch and flatscreen",
        19:"kegerator",                 20:"fine upholstered dining table set",
        21:"whiskeybed",                22:"high-end home workout system",
        23:"complete classics library", 24:"ultimate retro game console",
        25:"Omnipot",                   26:"fully-stocked wet bar",
        27:"four-poster bed"
    };

    void leprecondo(string input) {
        string [int] rooms = split_string(input, ",");
        int [int] lepRoom;
        int count;
        foreach num in rooms {
            int val = to_int(rooms[num]);
            string discovered = get_property("leprecondoDiscovered");
            // Two-digit room numbers need a plain contains; single-digit need comma guards
            // to avoid matching "1" inside "10", "11", etc.
            boolean found = (val >= 10)
                ? contains_text(discovered, rooms[num])
                : contains_text(discovered, "," + rooms[num] + ",");
            if (found) {
                lepRoom[count] = val;
                count += 1;
            }
        }
        cli_execute("leprecondo furnish "
            + lepRoomToNum[lepRoom[3]] + ","
            + lepRoomToNum[lepRoom[2]] + ","
            + lepRoomToNum[lepRoom[1]] + ","
            + lepRoomToNum[lepRoom[0]]);
    }

    // ── Möbius Ring ──────────────────────────────────────────────────────────────

    int [int] mobiusEncounters = {
        0:0,
        1:4,
        2:7,
        3:13,
        4:19,
        5:25,
        6:31,
        7:41,
        8:41,
        9:41,
        10:41,
        11:41,
        12:51,
        13:51,
        14:51,
        15:51,
        16:51,
        17:76,
        18:76,
        19:76,
        20:76
    };

    boolean MobiusNCReady(){
        if (total_turns_played( ) > get_property("_lastMobiusStripTurn").to_int() + mobiusEncounters[get_property("_mobiusStripEncounters").to_int()])
            return true;
        return false;
    }

    // ── Comma Chameleon ──────────────────────────────────────────────────────────

    familiar chameleon(){
        matcher m = create_matcher("<b>\\d+</b> pound ([^,]+), Chameleon", visit_url("charpane.php"));
        if (m.find())
            return to_familiar(m.group(1));
        else
            visit_url("inv_equip.php?which=2&action=equip&whichitem=4329");
        return $familiar[none];
    }

    // ─── TRICK OR TREAT ───────────────────────────────────────────────────────

    void candy(string action) {
        if (action == "fight"){
            int houseToVisit = index_of(get_property("_trickOrTreatBlock"), "D");
            visit_url("place.php?whichplace=town&action=town_trickortreat");
            visit_url("choice.php?whichchoice=804&pwd=" + my_hash() + "&option=3&whichhouse=" + houseToVisit);
            run_combat();
        } else if (action == "treat"){
            while(contains_text(get_property("_trickOrTreatBlock"),"L")){
                int houseToVisit = index_of(get_property("_trickOrTreatBlock"), "L");
                visit_url("place.php?whichplace=town&action=town_trickortreat");
                visit_url("choice.php?whichchoice=804&pwd=" + my_hash() + "&option=3&whichhouse=" + houseToVisit);
            }
        }
    }

// ─── 6. ADVENTURING-STATE CHECKS ─────────────────────────────────────────────

    void NCforce() {
        if (get_property("noncombatForcerActive") != "true") {
            if (have_item($item[apriling band helmet]) && to_int(get_property("_aprilBandTubaUses")) < 3 && have_item($item[Apriling band tuba])) {
                cli_execute("aprilband play tuba");
            }  else if (get_property("_claraBellUsed") == false){
                use($item[clara's bell]);
            } else if (have_item($item[Cincho de Mayo])){
                while (to_int(get_property("_cinchUsed")) > 40
                    && to_int(get_property("timesRested")) < total_free_rests()) {
                    cli_execute("unequip hat; equip apriling band helmet; camp rest free");
                }
                if (to_int(get_property("_cinchUsed")) <= 40) {
                    equip($slot[acc3], $item[cincho de mayo]);
                    use_skill($skill[Cincho: Fiesta Exit]);
                }
            }
        }
    }

    // Returns true if there are free-run resources available to burn for delay.
    boolean free_Run() {
        if (to_int(get_property("_snokebombUsed")) < 3)
            return true;
        if (have_effect($effect[everything looks green]) == 0 && my_adventures() > 60)
            return true;
        return false;
    }

    boolean free_Kill(){
        if (have_effect($effect[everything looks red]) == 0 && bullseyeReady() && my_adventures() > 30)
            return true;
        if (have_effect($effect[everything looks yellow]) == 0 && my_adventures() > 100)
            return true;
        return false;
    }

    boolean wanderer() {
        if (total_turns_played() >= to_int(get_property("clubEmNextWeekMonsterTurn")) + 8
            && get_property("clubEmNextWeekMonster") != "")
            return true;
        // Fixed: was incorrectly checking clubEmNextWeekMonster for the VHS tape condition
        if (total_turns_played() >= to_int(get_property("spookyVHSTapeMonsterTurn")) + 8
            && get_property("spookyVHSTapeMonster") != "")
            return true;
            if (item_amount($item[&quot;I Voted!&quot; sticker]) > 0
            && total_turns_played() % 11 == 1
            && to_int(get_property("_voteFreeFights")) < 3)
            return true;
        return false;
    }

    boolean delay(){
        if (wanderer() || free_Run())
            return true;
        return false;
    }

    void getLucky() {
        if (have_effect($effect[Lucky!]) > 0)
            return;
        if (have_skill($skill[Aug. 2nd: Find an Eleven-Leaf Clover Day])
            && get_property("_aug2Cast") == "false"
            && to_int(get_property("_augSkillsCast")) < 5) {
            use_skill($skill[Aug. 2nd: Find an Eleven-Leaf Clover Day]);
            if (have_effect($effect[Lucky!]) > 0)
                return;
        }
        if (available_amount($item[heartstone]) > 0 && get_property("heartstoneLuckUnlocked") == true && get_property("_heartstoneLuckUsed") == false) {
            use_skill($skill[Heartstone: %luck]);
            if (have_effect($effect[Lucky!]) > 0)
                return;
        }
        if (item_amount($item[apriling band saxophone]) > 0 && get_property("_aprilBandSaxophoneUses").to_int() < 2)
            cli_execute("aprilband play saxophone");
        if (have_effect($effect[lucky!]) == 0)
            abort("Did not acquire lucky");
    }

// ─── 7. UNBLEMISHED PEARLS ───────────────────────────────────────────────────

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

// ─── 8. UNIVERSE CALCULATOR ──────────────────────────────────────────────────
    // Finds the adventure count at which the universe alignment hits 69.
    // Sets globals uniInt and uniAdv as a side effect and also returns uniAdv.

    int [string] sign = {
        "Mongoose":1, "Wallaby":2, "Vole":3,    "Platypus":4,
        "Opossum":5,  "Marmot":6,  "Wombat":7,  "Blender":8,
        "Packrat":9,  "Bad Moon":10
    };

    int universe() {
        for y from 0 to my_adventures() {
            for x from 1 to 99 {
                if (((x + my_ascensions() + sign[my_sign()])
                    * (my_spleen_use() + my_level())
                    + (my_adventures() - y)) % 100 == 69) {
                    uniInt = x;
                    uniAdv = my_adventures() - y;
                    break;
                }
            }
            if (uniInt > 0) break;
        }
        return uniAdv;
    }

// ─── 9. GRIMACE MAPS ──────────────────────────────────────────────────

    boolean mapgrim() {
        item it = $item[Map to Safety Shelter Grimace Prime];
        string out;
        while (my_adventures() > 1 && available_amount(it) > 0) {
            //get effect to adventure in zone if needed
            if (have_effect($effect[Transpondent]) == 0){
                if (item_amount(it) < 5)
                    break;
                retrieve_item(1,$item[transporter transponder]);
            }
            if (have_effect($effect[Transpondent]) == 0){
                print (`Unable to get the Transpondent effect. Still have {available_amount(it)} {available_amount(it) != 1?it.plural:it}.`);
                return false;
            }
            use (it);
        }

        if (available_amount(it) == 0) {
            print(`Finished using all {it.plural}.`,'blue');
            return true;
        }
        return false;
    }
// ─── 10. SCRIPT LIFECYCLE ────────────────────────────────────────────────────

    // starter(): point mafia's between-battle / after-adventure / choice hooks and the CCS at this environment.
    void starter(){
        set_property("hpAutoRecovery",0.75);
        set_property("hpAutoRecoveryTarget",0.95);
        set_property("mpAutoRecovery",0.25);
        set_property("mpAutoRecoveryTarget",0.3);
        set_auto_attack(0);
        set_property("battleAction", "custom combat script");
        buffer ccs = "consult unlockerCCS.ash \n abort";
            write_ccs(ccs, "CCCS");
        set_ccs ("CCCS");
        set_property("betweenBattleScript","preadventure.ash");
        set_property("afterAdventureScript","postadventure.ash");
        set_property("choiceAdventureScript", "generalChoice.ash");
    }

    // finisher(): undo everything starter() changed. Restores the hooks, CCS,
    // battle action and auto-recovery levels captured at import, drops the native
    // auto-attack, and clears this environment's own scratch properties (script /
    // subscript / inSpendAdv / every *Override).
    void finisher() {
        set_property("script", "");
        set_property("subscript", "");
        set_property("betweenBattleScript",   betweenBattleScriptStorage);
        set_property("afterAdventureScript",  afterAdventureScriptStorage);
        set_property("choiceAdventureScript", choiceAdventureScriptStorage);
        set_property("battleAction",          battleActionStorage);
        set_property("customCombatScript",    ccsStorage);
        set_property("hpAutoRecovery",        hpAutoRecoveryStorage);
        set_property("hpAutoRecoveryTarget",  hpAutoRecoveryTargetStorage);
        set_property("mpAutoRecovery",        mpAutoRecoveryStorage);
        set_property("mpAutoRecoveryTarget",  mpAutoRecoveryTargetStorage);
        // Numeric macro ids go through the int overload; a skill-name auto-attack
        // (to_int == 0) goes through the string one; empty / "0" just clears it.
        if (autoAttackStorage == "" || autoAttackStorage == "0")
            set_auto_attack(0);
        else if (autoAttackStorage.to_int() > 0)
            set_auto_attack(autoAttackStorage.to_int());
        else
            set_auto_attack(autoAttackStorage);
        foreach slotName in $strings[unconditional, max, fam, hat, main, weapon, off, back, shirt, pants, acc1, acc2, acc3, famEquip] {
            set_property(slotName + "Override", "");
        }
        set_property("inSpendAdv","false");
    }
