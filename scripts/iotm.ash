// ═══ iotm.ash ═══════════════════════════════════════════════════════════════
    // Shared helpers for the farto / free-kill environment.
    //   1. Globals
    //   2. General utilities
    //   3. Buffing
    //   4. ML tuning
    //   5. Valuation
    //   6. Banish utilities
    //   7. Clan & instance access
    //   8. IOTM & item helpers   (one sub-section per item)
    //   9. Adventuring-state checks
    //  10. Unblemished pearls
    //  11. Universe calculator
    //  12. Grimace maps
    //  13. Integrated busking
    //  99. Script lifecycle

// ─── 1. GLOBALS ──────────────────────────────────────────────────────────────

    int uniInt, uniAdv;
    string clan = get_clan_name();
    boolean [monster] haveLocketMonster = get_locket_monsters();
    // The monster the free-kill run chain-copies (locket -> habitat recall, mimic eggs).
    monster copyTarget = $monster[sausage goblin];

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

    int buffCount() {
        int n = 0;
        foreach eff, turns in my_effects()
            if (turns < 2147483647) n++;
        return n;
    }

    record EffectNote {
        int turns;
        effect ef;
        string modifier;
    };

    EffectNote [item] notes;

    // Parses "N Effect Name (modifier)" out of it.notes, caches it in `notes`, and
    // hands the record straight back -- so itemEffectNotes(it).ef / .turns works
    // in one call instead of calling this to populate `notes` then indexing it.
    EffectNote itemEffectNotes(item it){
        if (notes contains it)
            return notes[it];
        matcher m = create_matcher("(\\d+) (.+?) \\((.+?)\\)", it.notes);
        if (m.find()){
            notes[it].turns = m.group(1).to_int();
            notes[it].ef = m.group(2).to_effect();
            notes[it].modifier = m.group(3);
        }
        return notes[it];
    }

    int organSpace(item it){
        int n = max(it.fullness, it.spleen, it.inebriety);
        return max(n,1);
    }

    // Mean of it.adventures' "X-Y" range (or just X, for a fixed-adventure item).
    float averageAdventures(item it){
        if (it.adventures == "")
            return 0.0;
        string [int] range = it.adventures.split_string("-");
        float total;
        foreach key, v in range
            total += v.to_float();
        return total / range.count();
    }

    // Use a skill if it appears as an option on the current page
    void use_if_have_skill(string page_text, skill sk) {
        if (contains_text(page_text, to_string(sk)))
            use_skill(sk);
    }

    // True only for the script's author; gates the hand-tuned personal chores.
    // Add a ptrack checkpoint unless today's event list already has it.
    void ptrackOnce(string tag){
        if (!contains_text(get_property("thoth19_event_list"), tag))
            cli_execute("ptrack add " + tag);
    }

    // Switch to the cooler yeti and take its adventures-tomorrow option (choice 2).
    void yetiTalk(){
        use_familiar($familiar[cooler yeti]);
        visit_url("main.php?talktoyeti=1", false);
        run_choice(2);
    }

    boolean isFartScauce(){
        return my_name().to_lower_case() == "fart scauce";
    }

    // Returns true if the item exists anywhere accessible (inventory, equipped, storage)
    boolean have_item(item it) {
        return item_amount(it) > 0
            || have_equipped(it)
            || storage_amount(it) > 0;
    }

    // Returns session log text from the current turn onward.
    // Mafia flushes the session log a beat after the fight resolves, so a fast
    // caller can read it before the "[<turn>]" marker for this adventure has been
    // written -- nowmark is then -1 and substring() aborts. Re-read a few times
    // with a short wait, and fall back to "" (callers only contains_text() it).
    string LastAdvTxt() {
        string lastlog;
        int nowmark = -1;
        for tries from 1 to 5 {
            lastlog = session_logs(1)[0];
            nowmark = max(
                last_index_of(lastlog, "[" + my_turncount() + "]"),
                last_index_of(lastlog, "[" + (my_turncount() + 1) + "]")
            );
            if (nowmark != -1) break;
            waitq(1);
        }
        if (nowmark == -1) return "";
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

    // Turns of buff one acquisition of an effect grants: a skill cast
    // (turns_per_cast already folds in Inigo's / Empathy / path multipliers) or a
    // single use/eat/drink of the item that grants it (mafia's modifiers.txt
    // "Effect Duration"). Returns 0 when neither resolves -- the effect comes from
    // a choice or combat and the caller has to know the number itself.
    int effectDuration(effect ef){
        skill sk = to_skill(ef);
        if (sk != $skill[none])
            return turns_per_cast(sk);
        item src = effect_to_item(ef);
        if (src != $item[none])
            return numeric_modifier(src, "Effect Duration");
        return 0;
    }

    // 1 on a farming / aftercore day, 0 mid-ascension. This replaced the old
    // get_property("ascensionsToday") checks and is the INVERSE polarity: where
    // those read "0" this reads 1, where they read "1" this reads 0.
    int dayType(){
        if (my_daycount() == 1){
            return 0;
        } else if (my_daycount() == 2){
            return 1;
        }
        if (get_property("dayTypeCheck") != today_to_string( )){
            set_property("dayType",user_prompt("Type 0 for freekills at the end of the day, type 1 for free kills at the beginning of the day"));
            set_property("dayTypeCheck",today_to_string( ));
        }
        return get_property("dayType").to_int();
    }

// ─── 3. BUFFING ──────────────────────────────────────────────────────────────

    boolean [location] periledLocations() {
        boolean [location] periled;
        foreach i, id in split_string(get_property("_perilLocations"), ","){
            if (id.to_int() == 0)
                continue;
            periled[id.to_int().to_location()] = true;
        }
        return periled;
    }

    boolean [effect] manaBurnEffects = $effects[Only Dogs Love a Drunken Sailor, Legendary Pasta Eyeball,disco fever,Mariachi Mood,Blubbered Up,
        Singer's Faithful Ocelot, Leash of Linguini, Empathy, Thoughtful Empathy,Slippery as a Seal,Big,
        Polka of Plenty, Tubes of Universal Meat, Lubricating Sauce, Strength of the Tortoise,Musk of the Moose,Attracting Snakes];

    boolean [effect] manaBurnEffectsD1 = $effects[Only Dogs Love a Drunken Sailor,
        Singer's Faithful Ocelot, Leash of Linguini, Empathy, Thoughtful Empathy,
        Polka of Plenty, Tubes of Universal Meat, Lubricating Sauce, Strength of the Tortoise,Musk of the Moose,Attracting Snakes,Quiet Desperation,Song of Bravado,Ur-Kel's Aria of Annoyance,
        Drescher's Annoying Noise,Legendary Penne Fedora,Pride of the Puffin,Slippery as a Seal,Blubbered Up,Big,Blubbered Up,Disco State of Mind];

    void manaBurn(int reserve){
        if (dayType() == 0){
            if (have_effect($effect[ode to booze]) > 0)
                cli_execute("uneffect ode to booze");
            while (my_mp() > 800){
                effect best = $effect[none];
                foreach ef in manaBurnEffectsD1 {
                    if (!(periledLocations() contains $location[The Caliginous Abyss]) && (ef == $effect[Ur-Kel's Aria of Annoyance]|| ef ==$effect[Drescher's Annoying Noise]))
                        continue;
                    skill sk = to_skill(ef);
                    int turns = have_effect(ef);
                    if (!have_skill(sk))
                        continue;
                    if (turns >= my_adventures() || my_mp() - mp_cost(sk) < reserve)
                        continue;
                    if (best == $effect[none] || turns < have_effect(best))
                        best = ef;
                }
                if (best == $effect[none])
                    return;
                skill burnSkill = to_skill(best);
                int perCast = max(1, turns_per_cast(burnSkill));
                int needed = ceil((my_adventures() - have_effect(best)) / to_float(perCast));
                int casts = max(1, min(needed, (my_mp() - reserve) / mp_cost(burnSkill)));
                int before = have_effect(best);
                cli_execute(best.default.replace_string("cast 1 ", "cast " + casts + " "));
                if (have_effect(best) <= before)
                    return;
            }
        } else if (dayType() == 1){
            while (my_mp() > 800){
                int turnEst = my_fullness() < fullness_limit() ? 1000 : my_adventures();
                effect best = $effect[none];
                foreach ef in manaBurnEffects {
                    skill sk = to_skill(ef);
                    int turns = have_effect(ef);
                    if (!have_skill(sk))
                        continue;
                    if (turns >= turnEst || my_mp() - mp_cost(sk) < reserve)
                        continue;
                    if (best == $effect[none] || turns < have_effect(best))
                        best = ef;
                }
                if (best == $effect[none])
                    return;
                skill burnSkill = to_skill(best);
                int perCast = max(1, turns_per_cast(burnSkill));
                int needed = ceil((turnEst - have_effect(best)) / to_float(perCast));
                int casts = max(1, min(needed, (my_mp() - reserve) / mp_cost(burnSkill)));
                int before = have_effect(best);
                cli_execute(best.default.replace_string("cast 1 ", "cast " + casts + " "));
                if (have_effect(best) <= before)
                    return;
            }
        }
    }

// ─── 4. ML TUNING ────────────────────────────────────────────────────────────

    boolean [effect] mlEffects = $effects[Ur-Kel's Aria of Annoyance, Pride of the Puffin,
        Bloodbathed, Misplaced Rage, Manbait, Sweetbreads Flamb&eacute;, Red Lettered,
        Spangled Star, Tortious, Litterbug, Not Sharing, Para-lyzed Jaw,
        Contemptible Emanations, Lapdog, Ashen Burps, The Cupcake of Wrath, Gelded,
        Mysteriously Handsome];

    
    int mcd_max(){
        if (canadia_available()) return 11;
        if (gnomads_available()) return 10;
        if (knoll_available() && retrieve_item($item[detuned radio])) return 10;
        return 0;
    }

    
    int mlMiss(int base, int target, int maxMcd){
        if (base > target) return base - target;
        if (base + maxMcd < target) return target - maxMcd - base;
        return 0;
    }


    boolean [item] negMLEquip = $items[Space Trip safety headphones, HOA regulation book,
        pine cone necklace, red badge, mushroom badge, uncursed bat paw,
        imposing pilgrim's hat, water wings for babies, white earbuds, Drowsy Sword,
        pocketwatch on a chain, security flashlight, discarded bowtie, nasty rat mask,
        shoulder-mounted Trainbot, plush sea serpent, fishbone facemask];

    // A slot's override name as clearOverrides() spells it (<name>Override).
    // Weapon pins through main, and mafia calls the back slot container.
    string overrideName(slot sl){
        switch (sl){
            case $slot[weapon]: return "main";
            case $slot[off-hand]: return "off";
            case $slot[back]: return "back";
        }
        return sl.to_string();
    }


    void lowerMLWithGear(int targetML){
        int loopCount = 0;
        while (true){
            if (loopCount++ > 10)
                abort("lowerMLWithGear: looped over 10 times -- equip() is probably failing");
            int base = numeric_modifier("monster level").to_int() - current_mcd();
            int bestMiss = mlMiss(base, targetML, mcd_max());
            if (bestMiss == 0) return;
            item best = $item[none];
            slot bestSlot = $slot[none];

            foreach it in negMLEquip{
                if (available_amount(it) == 0 || have_equipped(it) || !can_equip(it)) continue;
                // A two-hander would knock out whatever offOverride is pinning.
                if (weapon_hands(it) > 1 && get_property("offOverride") != "") continue;
                slot itSlot = to_slot(it);   // accessories all report acc1
                foreach sl in $slots[hat, weapon, off-hand, back, shirt, pants, acc1, acc2, acc3]{
                    boolean fits = sl == itSlot
                        || (itSlot == $slot[acc1] && (sl == $slot[acc2] || sl == $slot[acc3]));
                    if (!fits || get_property(overrideName(sl) + "Override") != "") continue;
                    // Net change: the new item's ML minus whatever it displaces.
                    int ml = numeric_modifier(it, "Monster Level").to_int()
                        - numeric_modifier(equipped_item(sl), "Monster Level").to_int();
                    int miss = mlMiss(base + ml, targetML, mcd_max());
                    if (miss >= bestMiss) continue;
                    best = it;
                    bestSlot = sl;
                    bestMiss = miss;
                }
            }
            if (best == $item[none]) return;

            equip(bestSlot, best);
            string name = overrideName(bestSlot);
            set_property(name + "Override", ", equip " + best);
            set_property("tuneMLOverrides", get_property("tuneMLOverrides") + "," + name);
        }
    }

    void tuneML(int targetML){
        int base = numeric_modifier("monster level").to_int() - current_mcd();
        boolean [effect] tried;   // a failed cast/shrug (song cap, no MP) isn't retried
        int loopCount = 0;
        while (mlMiss(base, targetML, mcd_max()) > 0){
            if (loopCount++ > 30)
                abort("tuneML: looped over 30 times -- an effect's ML probably isn't what mafia predicts");
            effect best = $effect[none];
            boolean bestIsShrug;
            int bestMiss = mlMiss(base, targetML, mcd_max());

            foreach ef, turns in my_effects(){
                if (tried contains ef || turns == 2147483647) continue;
                if (to_skill(ef) == $skill[none]) continue;
                int ml = numeric_modifier(ef, "Monster Level").to_int();
                if (ml == 0) continue;
                int miss = mlMiss(base - ml, targetML, mcd_max());
                if (miss >= bestMiss) continue;
                best = ef;
                bestIsShrug = true;
                bestMiss = miss;
            }
            foreach ef in mlEffects{
                if (tried contains ef || have_effect(ef) > 0) continue;
                if (to_skill(ef) != $skill[none] && !have_skill(to_skill(ef))) continue;
                if (mall_price(effect_to_item(ef)) > mall_price($item[pocket wish])) continue;
                int ml = numeric_modifier(ef, "Monster Level").to_int();
                int miss = mlMiss(base + ml, targetML, mcd_max());
                if (miss >= bestMiss) continue;
                best = ef;
                bestIsShrug = false;
                bestMiss = miss;
            }
            if (best == $effect[none]) break;

            tried[best] = true;
            if (bestIsShrug)
                cli_execute("shrug " + best);
            else
                cli_execute(best.default);
            base = numeric_modifier("monster level").to_int() - current_mcd();
        }

        // Effects bottomed out above target (MCD can only add), so try gear.
        if (base > targetML){
            lowerMLWithGear(targetML);
            base = numeric_modifier("monster level").to_int() - current_mcd();
        }

        int mcd =max(0, min(mcd_max(), targetML - base));
        if (mcd != current_mcd())
            change_mcd(mcd);
        int got = numeric_modifier("monster level").to_int();
        print("tuneML: wanted " + targetML + ", got " + got
            + (got == targetML ? "" : " (off by " + (got - targetML) + ")"), got == targetML ? "blue" : "red");
        if (numeric_modifier("monster level") != targetML)
            abort();
    }

// ─── 5. VALUATION ────────────────────────────────────────────────────────────

    // Meat value of one item: mafia's saved mall price (no live search, so it's
    // safe in loops over $items[]), falling back to autosell when the price is 100
    // or less, which for most items means mall-minimum junk or no listing at all.
    float item_value(item it){
        int price = historical_price(it);
        return price <= 100 ? autosell_price(it) : price;
    }

    // Average item_value() over a set, each value capped at cap so one thinly
    // listed outlier can't skew a big drop pool (garbo caps its pools at 100k).
    float average_value(boolean [item] items, float cap){
        if (count(items) == 0) return 0;
        float total;
        foreach it in items
            total += min(item_value(it), cap);
        return total / count(items);
    }

    float average_value(boolean [item] items){
        return average_value(items, 999999999);
    }

    int valueOfOrgan(string organ){
        if (organ == "stomach"){
            //based off of baked veggie ricotta casserole
            return (8*get_property("valueOfAdventure").to_int()) - mall_price($item[St. Sneaky Pete's Whey]) - mall_price($item[St. Sneaky Pete's Whey]) - mall_price($item[Vegetable of Jarlsberg]) - mall_price($item[Vegetable of Jarlsberg]);
        } else if (organ == "liver"){
            //based off of  Sacramento wine
            return (5.5*get_property("valueOfAdventure").to_int()) - mall_price($item[Sacramento wine]);
        } else if (organ == "spleen"){
            //based off of synthesis greed
            return 30*300*3 - (mall_price($item[Crimbo candied pecan])*2);
        } else {
            abort("invalid organ");
        }
        return 0;
    }

    int adjusted_meat_drop(monster mon){
        int meat = (meat_drop(mon) + 25) * (numeric_modifier("meat drop")+100)/100;
        if (contains_text(mon.attributes,"FREE"))
            return min(1000,meat);
        else
            return meat;
    }

    // Drop weights for using a pulled red taffy underwater (Briny Deeps).
    float [item] redTaffyWeights = {
        $item[Alewife&trade; Ale]: 0.03,             $item[bazookafish bubble gum]: 0.03,
        $item[beefy fish meat]: 0.03,          $item[dull fish scale]: 0.0925,
        $item[eel battery]: 0.03,              $item[eel sauce]: 0.03,
        $item[glistening fish meat]: 0.03,     $item[high-pressure seltzer bottle]: 0.03,
        $item[imitation crab crate]: 0.03,     $item[ink bladder]: 0.03,
        $item[live nautical mine]: 0.03,       $item[Mer-kin healscroll]: 0.03,
        $item[Mer-kin lunchbox]: 0.0925,       $item[Mer-kin thingpouch]: 0.03,
        $item[pufferfish spine]: 0.03,         $item[rough fish scale]: 0.03,
        $item[salinated mint julep]: 0.03,     $item[sand dollar]: 0.125,
        $item[sea lace]: 0.03,                 $item[seaweed]: 0.03,
        $item[shark cartilage]: 0.03,          $item[slick fish meat]: 0.03,
        $item[slug of rum]: 0.03,              $item[slug of shochu]: 0.03,
        $item[slug of vodka]: 0.03,            $item[soggy seed packet]: 0.03,
    };

    float redTaffyValue() {
        float value;
        foreach it in redTaffyWeights
            value += redTaffyWeights[it] * mall_price(it);
        return value;
    }

// ─── 6. BANISH UTILITIES ─────────────────────────────────────────────────────

    record ban {
        item gear;          // $item[none] for a skill-only banish
        string pref;        // banisher name prefix as it appears in banishedMonsters
        skill banSkill;
        boolean canUse;
    };

    // Built fresh on every call rather than held in a global: a top-level map
    // literal is evaluated once at import, so its canUse flags would go stale as
    // daily counters tick up. Priority order -- gear banishes first so the
    // limited skill-only ones are saved. Keyed by int because the skill-only
    // entries all share $item[none].
    ban [int] banMap() {
        ban [int] bans = {
            0: new ban($item[spring shoes],        "Spring Kick",        $skill[spring kick],
                true),
            1: new ban($item[monodent of the sea], "Sea *dent",          $skill[Sea *dent: Throw a Lightning Bolt],
                get_property("_seadentLightningUsed").to_int() < 11),
            2: new ban($item[adobe adze],          "batter up!",             $skill[batter up!],
                my_class() == $class[seal clubber] && my_fury() >= 5),
            3: new ban($item[Heartstone],          "Heartstone %banish", $skill[Heartstone: %banish],
                get_property("heartstoneBanishUnlocked").to_boolean()
                    && get_property("_heartstoneBanishUsed").to_int() < 5),
            4: new ban($item[none],                "snokebomb",          $skill[snokebomb],
                get_property("_snokebombUsed").to_int() < 3)
        };
        return bans;
    }

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
        foreach i, b in banMap() {
            if (b.gear == $item[none] || !have_item(b.gear) || !b.canUse)
                continue;
            if (appearance_rates(loc)[banished(b.pref)] >= 0) {
                it = b.gear;
                break;
            }
            print(appearance_rates(loc)[banished(b.pref)]);
        }
        // No candidate leaves it at $item[none]; writing an override for it would
        // create a junk "noneOverride" property.
        if (it != $item[none]) {
            set_property(to_string(to_slot(it)) + "Override", ", equip " + it);
            print(to_string(to_slot(it)) + "Override");
        }
        return it;
    }

    // Returns the first usable banish skill whose current target isn't appearing
    // at your location. Gear banishes need the item equipped; skill-only ones
    // ($item[none]) need the skill. Both must have canUse set.
    skill combatBan() {
        foreach i, b in banMap() {
            if (b.gear != $item[none] && !have_equipped(b.gear))
                continue;
            if (b.gear == $item[none] && !have_skill(b.banSkill))
                continue;
            if (!b.canUse || appearance_rates(my_location())[banished(b.pref)] < 0)
                continue;
            print("Banish being considered " + b.banSkill + " parsed banished monster is " + banished(b.pref) + " and the calculated appearance rate at current location is " + appearance_rates(my_location())[banished(b.pref)]);
            cli_execute("get banishedMonsters");
            return b.banSkill;
        }
        return $skill[none];
    }

// ─── 7. CLAN & INSTANCE ACCESS ───────────────────────────────────────────────

    int [string] clan_to_ID {
        "Hyrule" : 72876,
        "Bonus Adventures from Hell" : 90485,
        "Dread and Final" : 2047010985,
        "Dread Mart" : 2047010683,
        "Dread Outlet Bargain Market" : 2047010572,
        "Dreadleys" : 2047010988,
        "DreadNugget" : 2047010986,
        "Dreadway" : 2047010667,
        "Fart Sauce Annex" : 2047010939,
        "Best Friends Club" : 2047009940,
        "Temporary" : 2047011181,
        "homeclan" : get_property("homeClanID").to_int()
    };

    void whitelist(string clan){
        visit_url("showclan.php?whichclan="+clan_to_ID[clan]+"&action=joinclan&confirm=on");
    }

    int [item] stashOwed(string prop){
        int [item] owed;
        foreach i, id in split_string(get_property(prop), ","){
            if (id.to_int() != 0)
                owed[id.to_int().to_item()] += 1;
        }
        return owed;
    }

    void stashOwedAdd(string prop, item it){
        string current = get_property(prop);
        set_property(prop, (current == "" ? "" : current + ",") + it.to_int());
    }

    void stashgrab(item it){
        whitelist("Temporary");
        if (stash_amount(it) > 0) {
            if (take_stash(it, 1))
                stashOwedAdd("stashReturnTemporary", it);
        } else if (isFartScauce()){
            whitelist("Best Friends Club");
            if (stash_amount(it) > 0 && take_stash(it, 1))
                stashOwedAdd("stashReturnBFC", it);
        }
        whitelist("homeclan");
    }

    void stashReturnTo(string clan, string prop, item only){
        string unreturned;
        foreach it, n in stashOwed(prop){
            boolean returning = only == $item[none] || it == only;
            if (returning){
                whitelist(clan);
                cli_execute("unequip "+ it);
            }
            for i from 1 to n {
                if (returning && available_amount(it) > 0 && put_stash(it, 1))
                    continue;
                unreturned += (unreturned == "" ? "" : ",") + it.to_int();
            }
        }
        set_property(prop, unreturned);
    }

    // Returns only `it` to whichever stash it came from; other borrowed items stay.
    void stashreturn(item it){
        stashReturnTo("Temporary", "stashReturnTemporary", it);
        stashReturnTo("Best Friends Club", "stashReturnBFC", it);
        whitelist("homeclan");
    }

    // Returns everything stashgrab() borrowed.
    void stashreturn(){
        stashreturn($item[none]);
    }

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

    // Clan fortune-teller onlyfax for the day's 3 free consults (needs a clan
    // with a fortune teller; 90485 is a public one -- see the config note above).
    void clanFortune(){
        if (get_property("_clanFortuneConsultUses").to_int() == 3)
            return;
        whitelist("Bonus Adventures from Hell");
        cli_execute("fortune onlyfax pizza batman thick");
        whitelist("homeclan");
    }

// ─── 8. IOTM & ITEM HELPERS ──────────────────────────────────────────────────

    // ── Everfull Dart Holster ────────────────────────────────────────────────────
    string perks = get_property("everfullDartPerks");
    boolean bullseyeReady() {
        perks = get_property("everfullDartPerks");
        int n = count_substring(perks, "25% Better bullseye targeting") + count_substring(perks, "25% better chance to hit bullseyes") + count_substring(perks, "25% More Accurate bullseye targeting");
        return (n >= 2);
    }

    boolean everfullReady(){
        perks = get_property("everfullDartPerks");
        if (!bullseyeReady())
            return false;
        return (contains_text(perks, "You are less impressed by bullseyes")
                && contains_text(perks, "Bullseyes do not impress you much"))
            || count_substring(perks, "Bullseyes do not impress you much") >= 2
            || count_substring(perks, "You are less impressed by bullseyes") >= 2;
    }

    int bullseyeCooldown(){
        perks = get_property("everfullDartPerks");
        int n = count_substring(perks, "You are less impressed by bullseyes") + count_substring(perks, "Bullseyes do not impress you much");
        return max(0, 50 - 10 * n);
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

    // ── Combat Baseball ──────────────────────────────────────────────────────────
    string [int] lineup = split_string(get_property("baseballTeam"), ",");
    int baseballPlayers(){
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
        if (baseballPlayers() != 9) return;

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
                if (FKPitchNum == 0 && $strings[768,2274,2278,2282] contains lineup[x-1]) {
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
            visit_url("inventory.php?pwd=" + my_hash() + "&action=pball",false);
            for x from 1 to 9 {
                string pitch = get_property("pitchNum" + x);
                run_choice(pitch == "" ? 4 : to_int(pitch));
            }
            run_choice(6);

        } finally {
            for x from 1 to 9 {
                set_property("pitchNum" + x, "");
            }
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
        visit_url("choice.php?forceoption=0&whichchoice=1485&option=1"
            + "&slot%5B0%5D=" + slots[0]
            + "&slot%5B1%5D=" + slots[1]
            + "&slot%5B2%5D=" + slots[2]
            + "&slot%5B3%5D=" + slots[3]
            + "&slot%5B4%5D=" + slots[4]
            + "&slot%5B5%5D=" + slots[5]
            + "&slot%5B6%5D=" + slots[6]
            + "&slot%5B7%5D=" + slots[7]);
        if (handling_choice() && last_choice() == 1485)
            visit_url("main.php");
    }

    string nextTrainStation(){
        string [int] stations = split_string(get_property("trainsetConfiguration"), ",");
        if (stations.count() != 8)
            return "";
        return stations[get_property("trainsetPosition").to_int() % 8];
    }

    // ── Combat Lover's Locket ────────────────────────────────────────────────────

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
        if (((get_property("_lastMobiusStripTurn").to_int() + mobiusEncounters[get_property("_mobiusStripEncounters").to_int() + 1]) - total_turns_played( )) > my_adventures() && dayType() == 0)
            return false;
        if (total_turns_played( ) > get_property("_lastMobiusStripTurn").to_int() + mobiusEncounters[get_property("_mobiusStripEncounters").to_int()])
            return true;
        return false;
    }

    // ── Apriling Band ────────────────────────────────────────────────────────────

    void aprilBand(){
        if (get_property("_aprilBandInstruments").to_int() >= 2)
            return;
        cli_execute("aprilband item quad tom");
        if (dayType() == 0)
            cli_execute("aprilband item tuba");
        else
            cli_execute("aprilband item saxophone");
    }

    // ── Comma Chameleon ──────────────────────────────────────────────────────────

    familiar chameleon(){
        matcher m = create_matcher("<b>\\d+</b> pound ([^,]+), Chameleon", visit_url("charpane.php"));
        if (m.find())
            return to_familiar(m.group(1));
        return $familiar[none];
    }

    void altFam(familiar fam){
        if (have_familiar(fam)){
            use_familiar(fam);
            set_property("famOverride",fam.to_string());
        } else {
            use_familiar($familiar[comma chameleon]);
            if (chameleon() != fam){
                visit_url("inv_equip.php?which=2&action=unequip&type=familiarequip");
                retrieve_item(item_amount(familiar_equipment(fam)) + 1,familiar_equipment(fam));
                visit_url("inv_equip.php?which=2&action=equip&whichitem=" + familiar_equipment(fam).to_int());
                if (chameleon() != fam)
                    abort();
                set_property("commaFamiliar",fam.to_string());
            }
            set_property("famOverride","comma chameleon");
        }
    }

    // ── August Scepter ───────────────────────────────────────────────────────────

    skill augToday(){
        return to_skill(7451 + today_to_string().substring(6).to_int());
    }

    void castAugToday(){
        if (available_amount($item[august scepter]) == 0)
            return;
        if (get_property("_augTodayCast").to_boolean())
            return;
        use_skill(1, augToday());
    }

    // ── Trick or Treat ───────────────────────────────────────────────────────────

    void candy(string action) {
        if (action == "fight"){
            int houseToVisit = index_of(get_property("_trickOrTreatBlock"), "D");
            visit_url("place.php?whichplace=town&action=town_trickortreat");
            visit_url("choice.php?whichchoice=804&pwd=" + my_hash() + "&option=3&whichhouse=" + houseToVisit);
            run_combat();
        } else if (action == "treat"){
            while (contains_text(get_property("_trickOrTreatBlock"),"L")){
                string before = get_property("_trickOrTreatBlock");
                int houseToVisit;
                if (contains_text(get_property("_trickOrTreatBlock"),"S")){
                    houseToVisit = index_of(before, "S");
                } else {
                    houseToVisit = index_of(before, "L");
                }
                visit_url("place.php?whichplace=town&action=town_trickortreat");
                visit_url("choice.php?whichchoice=804&pwd=" + my_hash() + "&option=3&whichhouse=" + houseToVisit);
                run_choice(-1);
                if (get_property("_trickOrTreatBlock") == before){
                    print("candy: trick-or-treat block unchanged after treating house " + houseToVisit + " -- stopping", "red");
                    break;
                }
            }
        }
    }

    // ── Macrometeorite / Powerful Glove ──────────────────────────────────────────

    int gregsToSave(){
        if ((have_skill($skill[Macrometeorite]) && get_property("_macrometeoriteUses").to_int() < 10) || 
            (available_amount($item[Powerful Glove]) > 0 && get_property("_powerfulGloveBatteryPowerUsed").to_int() <= 90))
            return 1;
        else
            return 0;
    }

    // ── Time Badges ──────────────────────────────────────────────────────────────

    item timeBadge(){
        if (available_amount($item[Time Bandit Badge of Courage]) > 0)
            return $item[Time Bandit Badge of Courage];
        return $item[Time Lord Badge of Honor];
    }

    // ── Cup of 13s ───────────────────────────────────────────────────────────────

    // Cup of 13s ingredients that give Runneth On Empty, with the turns each one adds.
    int [item] runnethOnEmptyItems = {
        $item[string of blue beads]: 20,
        $item[broken BRICKO brick]: 20,
        $item[Pok&euml;mann band-aid]: 20,
        $item[Mortimer's nostrum]: 20,
        $item[folder (barbarian)]: 20,
        $item[heavy duty umbrella]: 20,
        $item[Crimbot schematic: Nerding Module]: 20,
        $item[Crimbot schematic: Candle Lighter]: 20,
        $item[vermiculite shield]: 20,
        $item[goat]: 20,
        $item[clockwork crossbow]: 20,
        $item[gatorskin umbrella]: 20,
        $item[decaying wooden oar]: 20,
        $item[Alice's Army Coward]: 20,
        $item[mini-Mr. Accessory]: 20,
        $item[can of Br&uuml;talbr&auml;u]: 20,
        $item[Staff of the Headmaster's Victuals]: 20,
        $item[TI-9000 calculator]: 20,
        $item[Crimbot schematic: Really Big Head]: 20,
        $item[vibrating mushroom]: 20,
        $item[cuppa Uncertain tea]: 20,
        $item[gingerbread hoodie]: 20,
        $item[bottle of clam juice]: 20,
        $item[dedigitizer schematic: familiar-in-the-middle]: 20,
        $item[basic meat crossbow]: 20,
        $item[baconstone pendant]: 20,
        $item[vodka stratocaster]: 20,
        $item[styrofoam crossbow]: 20,
        $item[dubious peppermint]: 20,
        $item[scroll of Protection from Bad Stuff]: 20,
        $item[chicle de salchicha]: 20,
        $item[cuppa Flamibili tea]: 20,
        $item[enchanted eyepatch]: 20,
        $item[dusty right scapula]: 20,
        $item[natural fennel soda]: 20,
        $item[synthetic stuffing]: 20,
        $item[fixed-gear bicycle]: 20,
        $item[square CRIMBCOOKIE]: 20,
        $item[Flaming Caipiranha]: 20,
        $item[Chinese curse words]: 20,
        $item[demonic cow's blood]: 20,
        $item[nutcracking pliers]: 20,
        $item[pheromone cocktail]: 20,
        $item[Pork Elf toothpaste]: 20,
        $item[gnauga hide buckler]: 40,
        $item[clockwork maid head]: 40,
        $item[foon of fearfulness]: 40,
        $item[digital key lime pie]: 40,
        $item[evil paper umbrella]: 40,
        $item[six-rainbow shield]: 40,
        $item[tortoboggan shield]: 40,
        $item[noxious gas grenade]: 40,
        $item[Gene Tonic: Penguin]: 40,
        $item[Energy Buzz Pastaco]: 40,
        $item[cuppa Serendipi tea]: 40,
        $item[print screen button]: 40,
        $item[murderbot live wire]: 40,
        $item[temporary X tattoos]: 40,
        $item[bag of sausage links]: 40,
        $item[extra-strength goo]: 40,
        $item[asbestos meat stack]: 40,
        $item[stick-on-a-string]: 40,
        $item[spiky turtle shield]: 40,
        $item[pulled yellow taffy]: 40,
        $item[plaid pocket square]: 40,
        $item[drug cocktail sauce]: 40,
        $item[Party-in-a-Can&trade;]: 40,
        $item[Pesto alla Marziano]: 40,
        $item[glass of goat's milk]: 40,
        $item[gnatloaf casserole]: 40,
        $item[rusty piece of rebar]: 40,
        $item[floral-print skirt]: 40,
        $item[cuppa Improprie tea]: 40,
        $item[VYKEA instructions]: 40,
        $item[daddy shortlegs leg]: 40,
        $item[Elf Guard patrol cap]: 40,
        $item[dedigitizer schematic: pocket GPU]: 40,
        $item[clockwork chef head]: 60,
        $item[toy maglev monorail]: 60,
        $item[nauseating reagent]: 60,
        $item[rusty diving helmet]: 60,
        $item[Alice's Army Martyr]: 60,
        $item[Winifred's whistle]: 60,
        $item[tiny die-cast arc-welding Elfborg]: 60,
        $item[carrot-on-a-stick]: 60,
        $item[liquid rhinestones]: 60,
        $item[barrel beryl choker]: 60,
        $item[Aldebaran sardines]: 60,
        $item[Affirmation Cookie]: 60,
        $item[zero-trust tanktop]: 60,
        $item[bowl of lucky charms]: 60,
        $item[linoleum meat stack]: 60,
        $item[baconstone earring]: 60,
        $item[tiny plastic hermit]: 60,
        $item[dense meat crossbow]: 60,
        $item[Spooky Surprise Egg]: 60,
        $item[green peawee marble]: 60,
        $item[Massive Manual of Marauder Mockery]: 60,
        $item[ghast iron codpiece]: 60,
        $item[Cool Brunch Pastaco]: 60,
        $item[short glass of water]: 60,
        $item[sweet potato o' mine]: 60,
        $item[Linguini Ubriacapa]: 60,
        $item[porquoise necklace]: 80,
        $item[delicious stinkbug]: 80,
        $item[square sponge pants]: 80,
        $item[Gene Tonic: Mer-kin]: 80,
        $item[dark porquoise ring]: 80,
        $item[yellow pixel potion]: 80,
        $item[Daily Affirmation: Think Win-Lose]: 80,
        $item[dedigitizer schematic: 3d printed server room key]: 80
    };

    // Cup of 13s ingredients that give Runneth With The Pack, with the turns each one adds.
    int [item] runnethWithThePackItems = {
        $item[clockwork trench coat]: 20,
        $item[Serenity trading card]: 20,
        $item[Young Man's Cargo Load]: 20,
        $item[Gene Tonic: Elemental]: 20,
        $item[buzzing mushroom wine]: 20,
        $item[sprinkle-begging cup]: 20,
        $item[gingerbread dog treat]: 20,
        $item[primitive alien salad]: 20,
        $item[Sneaky Pete's key lime]: 20,
        $item[Ring of the Sewer Snake]: 20,
        $item[charpuce jub-jub bird]: 20,
        $item[potion of the field gar]: 20,
        $item[The Cooler Out of Space]: 20,
        $item[tiny die-cast CrimboTown Toy Factory]: 20,
        $item[Paint A Vulgar Pitcher]: 20,
        $item[Outer Wolf&trade; cologne]: 20,
        $item[Omphalotus Omphaloskepsis mushroom]: 20,
        $item[perfect cosmopolitan]: 20,
        $item[green-iced sweet roll]: 20,
        $item[industrial lubricant]: 20,
        $item[dedigitizer schematic: cryptocloak]: 20,
        $item[Skeleton Wars rations]: 20,
        $item[tassel]: 20,
        $item[tiny plastic sauceror]: 20,
        $item[red plastic oyster egg]: 20,
        $item[hot wad]: 20,
        $item[chintzy accordion pin]: 20,
        $item[miniature castagnets]: 20,
        $item[spangly mariachi vest]: 20,
        $item[cup of hickory chicory]: 20,
        $item[nanorhino credit card]: 20,
        $item[Artist's Cookie Cutter of Loneliness]: 20,
        $item[candy mountain oyster]: 20,
        $item[Pendant of Gargalesis]: 20,
        $item[zombie]: 20,
        $item[Newark]: 20,
        $item[vodka cranberry sauce]: 20,
        $item[eyedrops of the ocelot]: 20,
        $item[carbonated water lily]: 20,
        $item[Shot of the Living Dead]: 20,
        $item[wind-up vampire teeth]: 20,
        $item[Frigid Northern Beans]: 20,
        $item[elf army field rations]: 20,
        $item[eXpand]: 20,
        $item[samurai turtle helmet]: 40,
        $item[bugged b&Atilde;&para;n&plusmn;&Atilde;&copy;t]: 40,
        $item[scale-mail underwear]: 40,
        $item[warbear liquid lasers]: 40,
        $item[weasel stomping pants]: 40,
        $item[barrel beryl nose ring]: 40,
        $item[jolly roger tattoo kit]: 40,
        $item[blackberry moccasins]: 40,
        $item[Alice's Army Horseman]: 40,
        $item[pacification grenade]: 40,
        $item[water wings for babies]: 40,
        $item[Yeg's Motel mouthwash]: 40,
        $item[waffle]: 40,
        $item[candied yam pinky ring]: 40,
        $item[red paisley oyster egg]: 40,
        $item[tombstone-shaped Crimboween cookie]: 40,
        $item[super-absorbent tarp]: 40,
        $item[nugget of slicksilver]: 40,
        $item[worksite credentials]: 40,
        $item[melty plastic grenade]: 40,
        $item[leprechaun hatchling]: 60,
        $item[Knob Kitchen grab-bag]: 60,
        $item[metallic foil cat ears]: 60,
        $item[groovy prism necklace]: 60,
        $item[tiny die-cast Unionize the Elves Sign]: 60,
        $item[Gene Tonic: Construct]: 60,
        $item[eldritch concentrate]: 60,
        $item[murderbot shield unit]: 60,
        $item[mafia organizer badge]: 60,
        $item[cybeer]: 60,
        $item[Elf Farm Raffle ticket]: 60,
        $item[atomic vector plotter]: 60,
        $item[vampire pearl earring]: 60,
        $item[Alice's Army Lanceman]: 60,
        $item[bottle of Old Pugilist]: 60,
        $item[pebble of proud pyrite]: 60,
        $item[Morbidda trading card]: 80,
        $item[The Snake trading card]: 80,
        $item[pulled porquoise ring]: 80,
        $item[Alice's Army Foil Page]: 80,
        $item[tin cup]: 80,
        $item[anise-flavored venom]: 80,
        $item[complex mushroom wine]: 80,
        $item[capped red lava bottle]: 80,
        $item[depleted Crimbonium football helmet]: 80,
        $item[visual packet sniffer]: 80,
        $item[papier Mach 1 airplane]: 80
    };

    // Adventures each Runneth On Empty ingredient adds to the drink. Runneth With
    // The Pack ingredients aren't listed and count as 0.
    int [item] cupAdventures = {
        $item[string of blue beads]: 4,
        $item[broken BRICKO brick]: 4,
        $item[Pok&euml;mann band-aid]: 4,
        $item[Mortimer's nostrum]: 4,
        $item[folder (barbarian)]: 4,
        $item[heavy duty umbrella]: 4,
        $item[Crimbot schematic: Nerding Module]: 4,
        $item[Crimbot schematic: Candle Lighter]: 4,
        $item[vermiculite shield]: 4,
        $item[goat]: 3,
        $item[clockwork crossbow]: 3,
        $item[gatorskin umbrella]: 3,
        $item[decaying wooden oar]: 3,
        $item[Alice's Army Coward]: 3,
        $item[mini-Mr. Accessory]: 3,
        $item[can of Br&uuml;talbr&auml;u]: 3,
        $item[Staff of the Headmaster's Victuals]: 3,
        $item[TI-9000 calculator]: 3,
        $item[Crimbot schematic: Really Big Head]: 3,
        $item[vibrating mushroom]: 3,
        $item[cuppa Uncertain tea]: 3,
        $item[gingerbread hoodie]: 3,
        $item[bottle of clam juice]: 3,
        $item[dedigitizer schematic: familiar-in-the-middle]: 3,
        $item[basic meat crossbow]: 2,
        $item[baconstone pendant]: 2,
        $item[vodka stratocaster]: 2,
        $item[styrofoam crossbow]: 2,
        $item[dubious peppermint]: 2,
        $item[scroll of Protection from Bad Stuff]: 2,
        $item[chicle de salchicha]: 2,
        $item[cuppa Flamibili tea]: 2,
        $item[enchanted eyepatch]: 1,
        $item[dusty right scapula]: 1,
        $item[natural fennel soda]: 1,
        $item[synthetic stuffing]: 1,
        $item[fixed-gear bicycle]: 1,
        $item[square CRIMBCOOKIE]: 1,
        $item[Flaming Caipiranha]: 1,
        $item[Chinese curse words]: 1,
        $item[demonic cow's blood]: 1,
        $item[nutcracking pliers]: 1,
        $item[pheromone cocktail]: 1,
        $item[Pork Elf toothpaste]: 1,
        $item[gnauga hide buckler]: 3,
        $item[clockwork maid head]: 3,
        $item[foon of fearfulness]: 3,
        $item[digital key lime pie]: 3,
        $item[evil paper umbrella]: 3,
        $item[six-rainbow shield]: 3,
        $item[tortoboggan shield]: 3,
        $item[noxious gas grenade]: 3,
        $item[Gene Tonic: Penguin]: 3,
        $item[Energy Buzz Pastaco]: 3,
        $item[cuppa Serendipi tea]: 3,
        $item[print screen button]: 3,
        $item[murderbot live wire]: 3,
        $item[temporary X tattoos]: 3,
        $item[bag of sausage links]: 3,
        $item[extra-strength goo]: 3,
        $item[asbestos meat stack]: 2,
        $item[stick-on-a-string]: 2,
        $item[spiky turtle shield]: 2,
        $item[pulled yellow taffy]: 2,
        $item[plaid pocket square]: 2,
        $item[drug cocktail sauce]: 2,
        $item[Party-in-a-Can&trade;]: 2,
        $item[Pesto alla Marziano]: 2,
        $item[glass of goat's milk]: 1,
        $item[gnatloaf casserole]: 1,
        $item[rusty piece of rebar]: 1,
        $item[floral-print skirt]: 1,
        $item[cuppa Improprie tea]: 1,
        $item[VYKEA instructions]: 1,
        $item[daddy shortlegs leg]: 1,
        $item[Elf Guard patrol cap]: 1,
        $item[dedigitizer schematic: pocket GPU]: 1,
        $item[clockwork chef head]: 2,
        $item[toy maglev monorail]: 2,
        $item[nauseating reagent]: 2,
        $item[rusty diving helmet]: 2,
        $item[Alice's Army Martyr]: 2,
        $item[Winifred's whistle]: 2,
        $item[tiny die-cast arc-welding Elfborg]: 2,
        $item[carrot-on-a-stick]: 2,
        $item[liquid rhinestones]: 2,
        $item[barrel beryl choker]: 2,
        $item[Aldebaran sardines]: 2,
        $item[Affirmation Cookie]: 2,
        $item[zero-trust tanktop]: 2,
        $item[bowl of lucky charms]: 1,
        $item[linoleum meat stack]: 1,
        $item[baconstone earring]: 1,
        $item[tiny plastic hermit]: 1,
        $item[dense meat crossbow]: 1,
        $item[Spooky Surprise Egg]: 1,
        $item[green peawee marble]: 1,
        $item[Massive Manual of Marauder Mockery]: 1,
        $item[ghast iron codpiece]: 1,
        $item[Cool Brunch Pastaco]: 1,
        $item[short glass of water]: 1,
        $item[sweet potato o' mine]: 1,
        $item[Linguini Ubriacapa]: 1,
        $item[porquoise necklace]: 1,
        $item[delicious stinkbug]: 1,
        $item[square sponge pants]: 1,
        $item[Gene Tonic: Mer-kin]: 1,
        $item[dark porquoise ring]: 1,
        $item[yellow pixel potion]: 1,
        $item[Daily Affirmation: Think Win-Lose]: 1,
        $item[dedigitizer schematic: 3d printed server room key]: 1
    };

    // Best ingredient from one Runneth list: turns * meatPerTurn, plus the drink
    // adventures it adds valued at advValue, minus its mall price. always returns the
    // best tradeable one even at a loss; otherwise $item[none] when nothing profits.
    item bestCupIngredient(int [item] ingredients, int meatPerTurn, float advValue, boolean always){
        item best = $item[none];
        float bestProfit = 0;
        foreach it, turns in ingredients{
            int price = mall_price(it);
            if (!it.tradeable || price <= 0)
                continue;
            float profit = turns * meatPerTurn + cupAdventures[it] * advValue - price;
            if (profit > bestProfit || (always && best == $item[none])){
                best = it;
                bestProfit = profit;
            }
        }
        return best;
    }

    // Fill the Cup of 13s once the jewels are in: slot 1 is always the best Runneth
    // With The Pack item (150 meat/turn), slots 2-3 the best Runneth On Empty item
    // (325 meat/turn), falling back to the Pack item. advValue prices each adventure
    // an ingredient adds (0 ignores them). False when nothing was drunk.
    boolean drinkCupOf13s(float advValue){
        if (get_property("_cupOf13sJewels") != "13")
            return false;
        item pack = bestCupIngredient(runnethWithThePackItems, 150, advValue, true);
        if (pack == $item[none])
            return false;
        item empty = bestCupIngredient(runnethOnEmptyItems, 325, advValue, false);
        if (empty == $item[none])
            empty = pack;
        if (!retrieve_item(empty == pack ? 3 : 1, pack) || !retrieve_item(empty == pack ? 3 : 2, empty))
            return false;
        print("Cup of 13s: " + pack + ", " + empty + ", " + empty, "blue");
        visit_url("inventory.php?action=cupof13s");
        run_choice(1, "whichitem1=" + pack.to_int() + "&whichitem2=" + empty.to_int() + "&whichitem3=" + empty.to_int());
        return true;
    }

    boolean drinkCupOf13s(){
        return drinkCupOf13s(0);
    }

// ─── 9. ADVENTURING-STATE CHECKS ─────────────────────────────────────────────

    boolean evokeReady(){
        return get_property("_eldritchTentaclesFoughtToday").to_int() < 11
            && have_skill($skill[Evoke Eldritch Horror]) && !get_property("_eldritchHorrorEvoked").to_boolean()
            && (have_effect($effect[Crappily Disguised as a Waiter]) > 0
                || item_amount($item[crappy waiter disguise]) > 0
                || (mall_price($item[crappy waiter disguise]) > 0 && mall_price($item[crappy waiter disguise]) <= 10000));
    }

    // Day 2: shrug Eldritch Attunement once today's tentacle fights are used up
    // (10 when an Evoke is still coming, 11 otherwise).
    void dropEldritchAttunement(){
        if (dayType() == 1 && have_effect($effect[eldritch attunement]) > 0
            && get_property("_eldritchTentaclesFoughtToday").to_int() >= (evokeReady() ? 10 : 11))
            cli_execute("uneffect eldritch attunement");
    }

    // stack == false: pre-charge NC-forcing resources before a forcer is active (the
    // original call sites' behavior). stack == true: forceNoncombats() wants to spend
    // an additional resource to stack another forced NC on top of one already active.
    // Loops -- spending one resource per pass -- until noncombatForcerActive no longer
    // matches stack or today's free rests run out; a normal day can legitimately take
    // ~20 passes, so loopCount aborts well above that instead of at a tight bound, but
    // still catches the case where tuba/bell/cincho are all exhausted with free rests
    // still left, which would otherwise spin forever since nothing changes state.
    void NCforce(boolean stack) {
        int loopCount = 0;
        while (get_property("timesRested").to_int() < total_free_rests()){
            if (loopCount++ > 50)
                abort("NCforce: looped over 50 times with no progress -- probably out of tuba/bell/cincho to force NCs with");
            if (get_property("noncombatForcerActive").to_boolean() == true && stack == false)
                return;
            if (have_item($item[apriling band helmet]) && to_int(get_property("_aprilBandTubaUses")) < 3 && have_item($item[Apriling band tuba])) {
                print(1,"red");
                cli_execute("aprilband play tuba");
            }  else if (get_property("_claraBellUsed") == false && have_item($item[clara's bell])){
                print(2,"red");
                use($item[clara's bell]);
            } else if (have_item($item[Cincho de Mayo])){
                print(3,"red");
                int cinchRestLoopCount = 0;
                while (to_int(get_property("_cinchUsed")) > 40
                    && to_int(get_property("timesRested")) < total_free_rests()) {
                    if (cinchRestLoopCount++ > 50)
                        abort("NCforce: cincho rest-down looped over 50 times with no progress -- camp rest free is probably failing");
                    cli_execute("familiar Skeleton of Crimbo Past; unequip hat; equip apriling band helmet; camp rest free");
                    manaBurn(700);
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
        if (my_inebriety() > inebriety_limit())
            return false;
        if (to_int(get_property("_snokebombUsed")) < 3)
            return true;
        if (have_effect($effect[everything looks green]) == 0 && (my_adventures() > 60 || dayType() == 1))
            return true;
        if (have_effect($effect[Cosmic Ball in the Air]) > 10 && have_item($item[cosmic bowling ball]) && dayType() == 1)
            return true;
        return false;
    }

    boolean free_Kill(){
        if (my_inebriety() > inebriety_limit())
            return false;
        if (have_effect($effect[everything looks red]) == 0 && bullseyeReady() && (my_adventures() > bullseyeCooldown() || dayType() == 1))
            return true;
        if (have_effect($effect[everything looks yellow]) == 0 && (my_adventures() > 100 || dayType() == 1))
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
        if (get_property("cursedMagnifyingGlassCount").to_int() == 13 && get_property("_voidFreeFights").to_int() < 5)
            return true;
        return false;
    }

    boolean delay(){
        if (wanderer() || (free_Run() && dayType() == 0))
            return true;
        return false;
    }

    void getLucky() {
        if (have_effect($effect[Lucky!]) > 0)
            return;
        if (available_amount($item[heartstone]) > 0 && get_property("heartstoneLuckUnlocked") == true && get_property("_heartstoneLuckUsed") == false) {
            use_skill($skill[Heartstone: %luck]);
            if (have_effect($effect[Lucky!]) > 0)
                return;
        }
        if (have_skill($skill[Aug. 2nd: Find an Eleven-Leaf Clover Day])
            && get_property("_aug2Cast") == "false"
            && to_int(get_property("_augSkillsCast")) < 5) {
            use_skill($skill[Aug. 2nd: Find an Eleven-Leaf Clover Day]);
            if (have_effect($effect[Lucky!]) > 0)
                return;
        }
        if (item_amount($item[apriling band saxophone]) > 0 && get_property("_aprilBandSaxophoneUses").to_int() < 3)
            cli_execute("aprilband play saxophone");
        int n = mall_price($item[11-leaf clover])/700;
        if (n < (numeric_modifier($modifier[meat drop])/100 + 1)){
            use($item[11-leaf clover]);
            return;
        }
        if (have_effect($effect[lucky!]) == 0)
            abort("Did not acquire lucky");
    }

    int patrioticDelays(){
        int delay;
        if (can_adventure($location[the hidden bowling alley])){
            int n = 11 - get_property("_drunkPygmyBanishes").to_int();
            delay += n;
        }
        if (get_property("zigguratLianas") == 0)
            delay += 10;
        return delay;
    }

// ─── 10. UNBLEMISHED PEARLS ──────────────────────────────────────────────────

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

    boolean pearlsDone(){
        foreach str in $strings[anemone,bar,reef,deepests,trench]{
            if (get_property(pearls[str].donePref) == "false")
                return false;
        }
        return true;
    }

// ─── 11. UNIVERSE CALCULATOR ─────────────────────────────────────────────────

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

// ─── 12. GRIMACE MAPS ────────────────────────────────────────────────────────

    boolean mapgrim() {
        item it = $item[Map to Safety Shelter Grimace Prime];
        string out;
        while (my_adventures() >= 1 && available_amount(it) > 0) {
            //get effect to adventure in zone if needed
            if (have_effect($effect[Transpondent]) == 0){
                if (item_amount(it) < 5)
                    break;
                retrieve_item(1,$item[transporter transponder]);
                use($item[transporter transponder]);
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

// ─── 13. INTEGRATED BUSKING ──────────────────────────────────────────────────

    // Beret Busking (5 casts/day, tracked by _beretBuskingUses) grants buffs
    // decided by total equipment power and the cast index.
    // beret_busking_effects(power, cast) predicts the effects for any pairing.
    //
    // Power = sum over hat/shirt/pants of get_power(item) * slot multiplier:
    // shirt x1, hat x(Tao ? 2 : 1), pants x(Tao ? 2 : 1) + (Hammertime ? 3 : 0).
    // With a Mad Hatrack the beret rides the familiar and any hat fills the hat
    // slot; without one the beret is the hat.
    //
    // beretBusking(modifiers) sweeps every reachable power for each remaining
    // cast, scores the predicted effects against the weighted modifier spec,
    // assembles the cheapest outfit hitting the best power, and casts. Owned gear
    // only unless that can't solve, then it widens to mall buys up to
    // autoBuyPriceLimit per piece.

    int beretGearCap = get_property("autoBuyPriceLimit").to_int();   // max mall price per piece

    record beretOutfit {
        item hat;
        item shirt;
        item pants;
        boolean ok;
    };

    float[string]   beretWeights;    // modifier name -> weight, per beretBusking() call
    boolean[effect] beretWishlist;   // effects that should win a busk outright
    boolean         beretAllowMall;  // widen candidate gear to mall buys
    boolean       beretClothesCached;
    item[int]     beretHats;
    item[int]     beretPants;
    item[int]     beretShirts;

    // Power multiplier for a slot, as Beret Busking reads it.
    int beretMult(slot sl){
        int tao = have_skill($skill[Tao of the Terrapin]) ? 2 : 1;
        if (sl == $slot[shirt]) return 1;
        if (sl == $slot[hat])   return tao;
        if (sl == $slot[pants]) return tao + (have_effect($effect[Hammertime]) > 0 ? 3 : 0);
        return 0;
    }

    // Power of the currently equipped hat/shirt/pants, for the post-assembly check.
    int beretEquippedPower(){
        int n;
        foreach sl in $slots[hat, shirt, pants]
            n += beretMult(sl) * get_power(equipped_item(sl));
        return n;
    }

    // "Familiar Weight" | "5 Meat Drop, 10 Familiar Weight" -> {name: weight}.
    // Names go straight to numeric_modifier(), so they must be real modifier names.
    float[string] beretParseModifiers(string spec){
        float[string] out;
        foreach _, raw in split_string(spec, ","){
            matcher m = create_matcher("^\\s*(?:([0-9]+(?:\\.[0-9]+)?)\\s+)?(.+?)\\s*$", raw);
            if (!find(m) || m.group(2) == "") continue;
            out[m.group(2)] = m.group(1) == "" ? 1.0 : m.group(1).to_float();
        }
        return out;
    }

    // Comma-separated effect names -> set; unrecognised names are dropped.
    boolean[effect] beretParseEffects(string spec){
        boolean[effect] out;
        foreach _, raw in split_string(spec, ","){
            matcher m = create_matcher("^\\s*(.+?)\\s*$", raw);
            if (!find(m)) continue;
            effect e = to_effect(m.group(1));
            if (m.group(1).to_lower_case() == "hip to the jive") e = to_effect(1701);   // ambiguous name; always the 1701 one
            if (e != $effect[none]) out[e] = true;
        }
        return out;
    }

    // Value of one busk's predicted effects (meat payout skipped). A wishlist
    // effect is worth a huge constant so any busk granting one beats a busk that
    // only stacks modifiers; everything else scores as the weighted modifier sum.
    float beretScore(int[effect] effects){
        float total;
        foreach e, dur in effects{
            if (e == $effect[none]) continue;
            if (beretWishlist contains e){
                total += 1000000.0 + dur;
                continue;
            }
            foreach mod in beretWeights
                total += beretWeights[mod] * numeric_modifier(e, mod);
        }
        return total;
    }

    void beretResetClothes(){
        beretClothesCached = false;
        clear(beretHats);
        clear(beretPants);
        clear(beretShirts);
    }

    // Candidate gear per slot, built once per (owned-only / mall) pass.
    void beretBuildClothes(){
        if (beretClothesCached) return;
        boolean hatrack = have_familiar($familiar[Mad Hatrack]);
        foreach it in $items[]{
            slot sl = to_slot(it);
            if (sl != $slot[hat] && sl != $slot[pants] && sl != $slot[shirt]) continue;
            if (!can_equip(it)) continue;
            if (!have_item(it) && (!beretAllowMall || !it.tradeable || mall_price(it) > beretGearCap || mall_price(it) < 100)) continue;

            if (sl == $slot[hat]){
                if (hatrack) beretHats[count(beretHats)] = it;   // beret goes on the rack, not here
            } else if (sl == $slot[pants]){
                beretPants[count(beretPants)] = it;
            } else {
                beretShirts[count(beretShirts)] = it;
            }
        }
        if (hatrack) beretHats[count(beretHats)] = $item[none];
        else         beretHats[0] = $item[prismatic beret];
        beretPants[count(beretPants)]   = $item[none];
        beretShirts[count(beretShirts)] = $item[none];
        beretClothesCached = true;
    }

    // Every distinct power total the candidate wardrobe can reach.
    int[int] beretPowerSums(){
        beretBuildClothes();
        boolean[int] hp;
        boolean[int] pp;
        boolean[int] sp;
        foreach _, h in beretHats   hp[beretMult($slot[hat])   * get_power(h)] = true;
        foreach _, p in beretPants  pp[beretMult($slot[pants]) * get_power(p)] = true;
        foreach _, s in beretShirts sp[get_power(s)] = true;

        boolean[int] sums;
        foreach a in hp
            foreach b in pp
                foreach c in sp
                    sums[a + b + c] = true;

        int[int] out;
        foreach v in sums
            out[count(out)] = v;
        return out;
    }

    // The reachable power whose predicted busk scores highest for this cast.
    int beretBestPower(int cast){
        int[int] sums = beretPowerSums();
        int best;
        float bestScore;
        boolean seen;
        foreach _, power in sums{
            float sc = beretScore(beret_busking_effects(power, cast));
            if (!seen || sc > bestScore){
                seen = true;
                bestScore = sc;
                best = power;
            }
        }
        return best;
    }

    int beretPrice(item it){
        return (it == $item[none] || have_item(it)) ? 0 : mall_price(it);
    }

    // power -> cheapest single item reaching it in this slot; owned beats bought.
    item[int] beretItemsByPower(item[int] pool, int cap, int mult){
        item[int] m;
        foreach _, it in pool{
            int p = get_power(it) * mult;
            if (p > cap) continue;
            if (!(m contains p)){
                m[p] = it;
                continue;
            }
            if (!have_item(m[p]) && (have_item(it) || mall_price(it) < mall_price(m[p])))
                m[p] = it;
        }
        return m;
    }

    // Cheapest hat/shirt/pants whose multiplied powers sum to exactly `power`.
    beretOutfit beretFindOutfit(int power){
        beretBuildClothes();
        item[int] hats   = beretItemsByPower(beretHats,   power, beretMult($slot[hat]));
        item[int] pants  = beretItemsByPower(beretPants,  power, beretMult($slot[pants]));
        item[int] shirts = beretItemsByPower(beretShirts, power, 1);

        beretOutfit best;
        int bestPrice;
        boolean seen;
        foreach a, h in hats
            foreach b, p in pants
                foreach c, s in shirts{
                    if (a + b + c != power) continue;
                    int price = beretPrice(h) + beretPrice(p) + beretPrice(s);
                    if (seen && price >= bestPrice) continue;
                    seen = true;
                    bestPrice = price;
                    best.hat = h;
                    best.pants = p;
                    best.shirt = s;
                    best.ok = true;
                }
        return best;
    }

    // Equip one slot: unequip for none, buy up to the cap if we don't own it.
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

    // Solve and cast every remaining Beret Busking use.
    //   modifiers  weighted numeric modifiers, e.g. "Familiar Weight" or
    //              "5 Meat Drop, 10 Familiar Weight"  (pass "" to skip)
    //   effects    comma-separated effect names to prioritise; a busk granting
    //              one of these outscores any modifier-only busk  (pass "" to skip)
    void beretBusking(string modifiers, string effects){
        if (!have_item($item[prismatic beret]) && !have_skill($skill[Beret Busking]))
            return;
        beretWeights  = beretParseModifiers(modifiers);
        beretWishlist = beretParseEffects(effects);
        if (count(beretWeights) == 0 && count(beretWishlist) == 0)
            abort("beretBusking: nothing to value — modifiers '" + modifiers + "', effects '" + effects + "'");

        boolean hatrack = have_familiar($familiar[Mad Hatrack]);
        beretAllowMall = true;
        beretResetClothes();

        int cast = get_property("_beretBuskingUses").to_int();
        if (cast <= 4){
            int power = beretBestPower(cast);
            beretOutfit fit = beretFindOutfit(power);

            // Owned gear couldn't build it — widen to mall buys once, then stay widened.
            if (!fit.ok && !beretAllowMall){
                beretAllowMall = true;
                beretResetClothes();
                power = beretBestPower(cast);
                fit = beretFindOutfit(power);
            }
            if (!fit.ok)
                abort("beretBusking: no outfit reaches " + power + " power for cast " + cast);

            if (hatrack){
                use_familiar($familiar[Mad Hatrack]);
                equip($slot[familiar], $item[prismatic beret]);
            } else {
                retrieve_item($item[prismatic beret]);
            }
            beretEquip($slot[hat],   fit.hat);
            beretEquip($slot[shirt], fit.shirt);
            beretEquip($slot[pants], fit.pants);

            if (beretEquippedPower() != power)
                abort("beretBusking: wanted " + power + " power for cast " + cast
                    + ", assembled " + beretEquippedPower());

            print("Beret Busk " + (cast + 1) + ": power " + power + " — "
                + fit.hat + " / " + fit.shirt + " / " + fit.pants, "blue");
            use_skill($skill[Beret Busking]);
            cast += 1;
        }
    }

    void beretBusking(string modifiers){
        beretBusking(modifiers, "");
    }

// ─── 99. SCRIPT LIFECYCLE ────────────────────────────────────────────────────

    // starter(): point mafia's between-battle / after-adventure / choice hooks and the CCS at this environment.
    void starter(){
        set_auto_attack(0);
        set_property("battleAction", "custom combat script");
        buffer ccs = "consult unlockerCCS.ash \n abort";
            write_ccs(ccs, "CCCS");
        set_ccs ("CCCS");
        set_property("betweenBattleScript","preadventure.ash");
        set_property("afterAdventureScript","postadventure.ash");
        set_property("choiceAdventureScript", "generalChoice.ash");
    }

    void clearOverrides(boolean [string] slotNames){
        foreach slotName in slotNames {
            set_property(slotName + "Override", "");
        }
    }

    void clearMLOverrides(){
        boolean [string] pinned;
        foreach i, slotName in split_string(get_property("tuneMLOverrides"), ","){
            if (slotName != "") pinned[slotName] = true;
        }
        clearOverrides(pinned);
        set_property("tuneMLOverrides", "");
    }

    void clearOverrides(){
        clearMLOverrides();
        clearOverrides($strings[unconditional, max, fam, hat, main, weapon, off, back, shirt, pants, acc1, acc2, acc3, famEquip, bonus]);
    }

    void finisher() {
        set_property("script", "");
        set_property("subscript", "");
        set_property("betweenBattleScript",   betweenBattleScriptStorage);
        set_property("afterAdventureScript",  afterAdventureScriptStorage);
        set_property("battleAction",          battleActionStorage);
        set_property("hpAutoRecovery",        hpAutoRecoveryStorage);
        set_property("hpAutoRecoveryTarget",  hpAutoRecoveryTargetStorage);
        set_property("mpAutoRecovery",        mpAutoRecoveryStorage);
        set_property("mpAutoRecoveryTarget",  mpAutoRecoveryTargetStorage);
        set_property("FKRunEligible","false");
        // Numeric macro ids go through the int overload; a skill-name auto-attack
        // (to_int == 0) goes through the string one; empty / "0" just clears it.
        if (autoAttackStorage == "" || autoAttackStorage == "0")
            set_auto_attack(0);
        else if (autoAttackStorage.to_int() > 0)
            set_auto_attack(autoAttackStorage.to_int());
        else
            set_auto_attack(autoAttackStorage);
        clearOverrides();
        stashreturn();
        set_property("inSpendAdv","false");
    }