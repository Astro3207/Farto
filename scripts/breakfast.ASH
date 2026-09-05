import iotm.ash;

// ═══ breakfast.ash ══════════════════════════════════════════════════════════
// Start-of-day chores for the farto / free-kill environment: workshed crafting,
// clan-hopping breakfasts, daily skills/summons, the free mining and Allied
// Radio pulls, and the assorted once-a-day IOTM buttons. Run once after
// rollover, before any farming script.
//
// ─── PER-ACCOUNT CONFIG ─────────────────────────────────────────────────────
//  * Reads the homeClanID preference for the clan to return to between hops
//    (set once via FartoController.ash, or `set homeClanID=<id>`).
//  * Clan ids 90485 (snack machine + fortune teller) and 2047010939 (Fart
//    Sauce Annex) are public whitelist clans, not this account's own -- swap
//    them for your own or drop clanBreakfasts() / clanFortune() if you have
//    neither.
//  * Blocks gated on isFartScauce() are hand-tuned to this character (a
//    private stock-trading script, hard-coded Foresee Peril targets) and are
//    skipped entirely on any other account.
//  * Everything else self-guards on have_skill / have_item / have_familiar, so
//    an account missing a given IOTM just skips that chore instead of
//    aborting or hanging.

// Progress marker: prints "BF: phase: XXX" so an abort mid-run is easy to
// place (mirrors UnderTheSea's step()).
void step(string msg){
    print("BF: " + msg, "blue");
}

// True only for the script's author; gates the hand-tuned personal chores.
boolean isFartScauce(){
    return my_name().to_lower_case() == "fart scauce";
}

// Forest Village zone-opening chores (crackpot mystic, etc). Not written yet.
void zoneOpening(){
}

// ─── FIRST BREAKFAST ────────────────────────────────────────────────────────

// git update every rollover; the author also refreshes a private stock script
// that would just error out (harmlessly) on anyone else's account.
void dailyUpdate(){
    if (get_property("_gitUpdated").to_boolean())
        return;
    cli_execute("git update");
    if (isFartScauce())
        cli_execute("stock_market");
}

// Spend the TakerSpace's daily crafting materials, then hand the workshed to
// the model train set for the rest of the day. Order matters: the TakerSpace
// craft is a one-shot at rollover, the train set is what should be running
// while farming. Each while-loop bails on the first failed craft instead of
// spinning if a required sub-ingredient runs out.
void takerSpace(){
    if (get_property("_workshedItemUsed").to_boolean() || get_workshed() != $item[TakerSpace letter of Marque])
        return;
    if (get_property("takerSpaceGold").to_int() >= 1 && get_property("takerSpaceMast").to_int() >= 1
        && get_property("takerSpaceAnchor").to_int() >= 3 && get_property("takerSpaceRum").to_int() >= 1)
        create($item[anchor bomb]);
    if (get_property("takerSpaceSpice").to_int() >= 1 && get_property("takerSpaceRum").to_int() >= 2)
        create($item[tankard of spiced rum]);
    while (get_property("takerSpaceMast").to_int() >= 2){
        if (!create($item[harpoon]))
            break;
    }
    while (get_property("takerSpaceSpice").to_int() >= 1){
        if (!create($item[spices]))
            break;
    }
    if (available_amount($item[model train set]) > 0)
        use($item[model train set]);
}

// Collect the day's clan-VIP breakfasts: the snack-machine clan (chip bags)
// and the Fart Sauce Annex, then return to homeClanID. The caller is
// responsible for getting back to wherever it actually started.
void clanBreakfasts(){
    if (get_property("_chipBags").to_int() < 3){
        visit_url("showclan.php?whichclan=90485&action=joinclan&confirm=on");
        cli_execute("breakfast; chips radium; chips wintergreen; chips ennui");
        visit_url("clan_rumpus.php?action=click&spot=5&furni=1");
    }
    visit_url("showclan.php?whichclan=2047010939&action=joinclan&confirm=on");
    cli_execute("breakfast");
    visit_url("showclan.php?whichclan=" + get_property("homeClanID").to_int() + "&action=joinclan&confirm=on");
}

// Chest Mimic rides along through breakfast to soak up familiar xp.
void primeFamiliar(){
    if (have_familiar($familiar[Chest Mimic]))
        use_familiar($familiar[Chest Mimic]);
}

// Photobooth the Sheriff costume pieces for the day's free equipment.
void photoBooth(){
    if (get_property("_photoBoothEquipment").to_int() != 0)
        return;
    foreach part in $strings[Sheriff badge, Sheriff pistol, Sheriff moustache]
        cli_execute("photobooth item " + part);
}

// Fart Scauce only -- Foresee Peril on a hand-picked set of targets after
// clearing the Eternity Codpiece slots (Foresee Peril requires an empty
// codpiece). The who= ids are personal, so this is skipped on every other
// account rather than firing on someone else's targets.
void perilsForeseen(){
    if (!isFartScauce() || get_property("_perilsForeseen").to_int() != 0)
        return;
    codpiece("none");
    visit_url("inventory.php?action=foresee");
    foreach who in $ints[2463557, 1197090, 4409, 2456712]
        visit_url("choice.php?whichchoice=1558&option=1&who=" + who);
}

// Burn any 2002 Mr. Store credits on Spooky VHS Tapes (free-kill wanderers).
void spookyTapes(){
    int credits = get_property("availableMrStore2002Credits").to_int();
    if (credits > 0)
        create(credits, $item[Spooky VHS Tape]);
}

// Pull the day's 3 free Allied Radio drops. Guarded on owning the backpack --
// without it _alliedRadioDropsUsed never moves and the loop would spin
// forever; the inner loop also bails if a pull stops making progress.
void alliedRadio(){
    if (!have_item($item[Allied Radio Backpack]) || get_property("_alliedRadioDropsUsed").to_int() >= 3)
        return;
    visit_url("inventory.php?action=requestdrop");
    while (get_property("_alliedRadioDropsUsed").to_int() < 3){
        int used = get_property("_alliedRadioDropsUsed").to_int();
        visit_url("choice.php?request=radio&whichchoice=1561&option=1");
        if (get_property("_alliedRadioDropsUsed").to_int() == used)
            return;
    }
}

// Spend the day's 5 free Unaccompanied Miner trips in the Itznotyerzitz Mine.
// Digs only a Promising Chunk that sits inside its own <a ...which=N> link:
// that link is exactly what marks a chunk as adjacent to open space, the only
// kind KoL lets you mine. Object Detection labels every chunk in the wall,
// linked or not, so matching the bare "(x,y)" text (the old approach) could
// target an unmineable square -- the use counter would never advance and the
// loop would spin forever. When nothing reachable is showing, reset the wall
// (free) and look again; give up after 20 fruitless resets rather than spin
// indefinitely if the wall genuinely never cooperates.
void unaccompaniedMiner(){
    if (!have_skill($skill[Unaccompanied Miner]))
        return;
    int fruitlessResets;
    while (get_property("_unaccompaniedMinerUsed").to_int() < 5){
        cli_execute("acquire miner's helmet; acquire 7-Foot Dwarven mattock; acquire miner's pants");
        cli_execute("outfit mining gear");
        if (my_hp() == 0)
            cli_execute("restore hp");
        string wall = visit_url("mining.php?intro=1&mine=1");
        matcher chunk = create_matcher(
            "(?i)which=(\\d+)(?:(?!</a>)[\\s\\S]){0,200}?promising chunk of wall", wall);
        if (chunk.find()){
            visit_url("mining.php?mine=1&which=" + chunk.group(1));
            fruitlessResets = 0;
        } else {
            visit_url("mining.php?mine=1&reset=1");
            fruitlessResets += 1;
            if (fruitlessResets >= 20){
                print("BF: unaccompaniedMiner: 20 resets with no reachable chunk, giving up", "red");
                return;
            }
        }
    }
}

// Tongue of the Walrus off a Beaten Up before it eats into the day's turns.
void healUp(){
    if (have_effect($effect[Beaten Up]) > 0)
        cli_execute("cast tongue of the walrus; cast cannelloni cocoon");
}

// Park the tiny stillsuit on tickle-me Emilio so it brews a free drink.
void stillsuit(){
    if (!have_item($item[tiny stillsuit]) || !have_familiar($familiar[tickle-me emilio]))
        return;
    use_familiar($familiar[tickle-me emilio]);
    equip($item[tiny stillsuit]);
}

// Pull a few cheap meat/init accessories into inventory for the day.
void grabAccessories(){
    foreach it in $items[mother's necklace, pearl diver's necklace, giant yellow hat, perfume-soaked bandana]
        retrieve_item(it);
}

// Spend the day's three Mayam Calendar resonance rings (guarded so a second
// call is a no-op).
void mayamRings(){
    if (get_property("_mayamSymbolsUsed") != "" || !have_item($item[Mayam Calendar]))
        return;
    if (have_familiar($familiar[Chest Mimic]))
        use_familiar($familiar[Chest Mimic]);
    cli_execute("mayam rings vessel yam cheese explosion;"
        + " mayam rings fur lightning eyepatch yam;"
        + " mayam rings eye meat yam clock");
}

void firstBreakfast(){
    int startClan = get_clan_id();

    step("phase: daily update");
    dailyUpdate();
    step("phase: workshed");
    takerSpace();

    step("phase: clan breakfasts");
    clanBreakfasts();

    step("phase: daily buttons");
    primeFamiliar();
    cli_execute("garden pick");
    photoBooth();
    perilsForeseen();
    spookyTapes();
    alliedRadio();

    step("phase: unaccompanied miner");
    unaccompaniedMiner();

    healUp();
    stillsuit();
    grabAccessories();

    // clanBreakfasts() only guarantees homeClanID; get back to wherever this
    // run actually started.
    visit_url("showclan.php?whichclan=" + startClan + "&action=joinclan&confirm=on");

    step("phase: mayam rings");
    mayamRings();
}

// ─── SECOND BREAKFAST ───────────────────────────────────────────────────────

// Cast every free daily buff/summon skill the account actually has.
void dailySkills(){
    foreach sk in $skills[Lunch Break, Spaghetti Breakfast, Grab a Cold One,
        Summon Kokomo Resort Pass, Perfect Freeze, Acquire Rhinestones,
        Prevent Scurvy and Sobriety, That's Not a Knife]{
        if (have_skill(sk))
            use_skill(sk);
    }
}

// Eat the glitch season reward item once it's implemented, if we have one.
void glitchItem(){
    if (!get_property("_glitchItemImplemented").to_boolean() && available_amount($item[[glitch season reward name]]) > 0)
        use($item[[glitch season reward name]]);
}

// Clan fortune-teller onlyfax for the day's 3 free consults (needs a clan
// with a fortune teller; 90485 is a public one -- see the config note above).
void clanFortune(){
    if (get_property("_clanFortuneConsultUses").to_int() != 0)
        return;
    visit_url("showclan.php?whichclan=90485&action=joinclan&confirm=on");
    for i from 1 to 3 {
        cli_execute("fortune onlyfax pizza batman thick");
        if (i < 3)
            wait(10);
    }
    visit_url("showclan.php?whichclan=" + get_property("homeClanID").to_int() + "&action=joinclan&confirm=on");
}

// April Shower for the day's buff.
void aprilShower(){
    if (!get_property("_aprilShower").to_boolean())
        cli_execute("shower hot");
}

// Craft the 3 daily lit leaf lassos and the free day shortener from burning
// leaves; the loop bails early if a craft fails instead of spinning.
void burningLeaves(){
    while (get_property("_leafLassosCrafted").to_int() < 3){
        if (!create($item[lit leaf lasso]))
            break;
    }
    if (!get_property("_leafDayShortenerCrafted").to_boolean())
        create($item[day shortener]);
}

// Walk the day's trick-or-treat block with the Map to a candy-rich block:
// use the map for its own house (if not already used), then treat every
// remaining "L" house on the block.
void candyRichBlock(){
    boolean mapUsed = get_property("_mapToACandyRichBlockUsed").to_boolean();
    if (mapUsed && !contains_text(get_property("_trickOrTreatBlock"), "L"))
        return;
    if (!mapUsed && available_amount($item[Map to a candy-rich block]) > 0)
        use($item[Map to a candy-rich block]);
    cli_execute("outfit Ceramic Suit");
    candy("treat");
}

// Build the day's 2 free Apriling Band instruments (tuba, then quad tom).
void aprilBand(){
    if (get_property("_aprilBandInstruments").to_int() >= 2)
        return;
    if (get_property("_aprilBandInstruments").to_int() == 0)
        cli_execute("aprilband item tuba");
    cli_execute("aprilband item quad tom");
}

// Deviled candy eggs (3/day); bail if the command stops making progress
// instead of spinning when the account has no candy egg to devil.
void devilCandyEggs(){
    while (get_property("_candyEggsDeviled").to_int() < 3){
        int made = get_property("_candyEggsDeviled").to_int();
        cli_execute("devilcandyegg daffy taffy");
        if (get_property("_candyEggsDeviled").to_int() == made)
            return;
    }
}

// Pork Elf neti pot for the day's free effect, if we have one.
void netiPot(){
    if (!get_property("_porkElfNetiPotUsed").to_boolean() && available_amount($item[Pork Elf neti pot]) > 0)
        use($item[Pork Elf neti pot]);
}

void secondBreakfast(){
    step("phase: daily skills");
    dailySkills();
    glitchItem();

    step("phase: clan fortune");
    clanFortune();

    step("phase: daily buttons");
    aprilShower();
    burningLeaves();
    candyRichBlock();
    zoneOpening();
    aprilBand();
    devilCandyEggs();
    netiPot();
}

// ─── ENTRY ───────────────────────────────────────────────────────────────────

void main(){
    try {
        set_property("script", "turnburn");
        step("phase: first breakfast");
        firstBreakfast();
        step("phase: second breakfast");
        secondBreakfast();
    } finally {
        finisher();
    }
}
