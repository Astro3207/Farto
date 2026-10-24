import iotm.ash;
import StockingMimic.ash;

// ═══ Dinner.ash ══════════════════════════════════════════════════════════════
// End-of-day wind-down chores.

// ─── PHASES ──────────────────────────────────────────────────────────────────

void fillOrgans(){
    int availableLiver = inebriety_limit() - my_inebriety() + to_int(!have_equipped($item[angelbone dice])) + to_int(!have_equipped($item[devilbone rosary])) + to_int((my_familiar() != $familiar[stooper]));
    if (availableLiver > 0)
        dinnerLiverSpleen();
    int availableStomach = fullness_limit() - my_fullness() + to_int(!have_equipped($item[devilbone corset])) + to_int(!have_equipped($item[angelbone chopsticks]));
    if (availableStomach >= 3){
        equip($item[devilbone corset]);
        equip($item[angelbone chopsticks]);
        eat($item[eldritch mushroom pizza]);
    }
}

void augSkills(){
    if (get_property("_augSkillsCast").to_int() < 5){
        cli_execute("cast Aug. 13th");
        if (get_property("_augSkillsCast").to_int() < 5)
            cli_execute("cast Aug. 7th");
    }
}

void certificates(){
    while (item_amount($item[Stock Certificate]) > 0){
        string turns = get_property("stockCertificateTurns");
        string[int] stocks = split_string(turns, ",");
        if (stocks[0] == "" || total_turns_played() - stocks[0].to_int() < 500)
            break;
        if (!use(1, $item[Stock Certificate]))
            break;
        // mafia didn't drop the used certificate's turn -- stop rather than loop
        if (get_property("stockCertificateTurns") == turns)
            break;
    }
}

void YetiRO(){
    if ($familiar[cooler yeti].experience > 400 && get_property("_coolerYetiAdventures") == "false")
        yetiTalk();
}

void pvpCombat(){
    int peevp = pvp_attacks_left();
    if (peevp > 70)
        cli_execute("PVP_MAB");
}

void takerspaceStart(){
    if (get_property("_workshedItemUsed") == "false" && get_workshed( ) != $item[TakerSpace letter of Marque])
        cli_execute("use takerspace");
}

void finalOutfit(){
    if (numeric_modifier("familiar weight") > 350)
        cli_execute("maximize pvp fights, equip spacegate military insignia, equip ratskin pajama pants");
    else
        cli_execute("familiar jill; maximize adv");
}

void closingMeatChores(){
    if (get_property("_universalSeasoningsUsed").to_int() == 0)
        use($item[universal seasoning]);
    take_closet(closet_amount($item[sand dollar]),$item[sand dollar]);
    cli_execute("philter");
    if (my_meat() - 3000000 > 0){
        int new_meat = my_meat() - 3000000;
        visit_url("closet.php?addtake=add&action=addtakeclosetmeat&quantity=" + new_meat);
    }
}

int get_price( item itm ){
    if ( historical_age( itm ) < 14 ) return historical_price( itm );
    return mall_price( itm );
}

boolean is_pvpable( item thing ){
    return thing.tradeable && thing.discardable && !thing.gift && !thing.quest;
}

void pvpCleanup(){
    int expensiveValue = 1000;
    batch_open();
    foreach it in get_inventory(){
        if ( is_pvpable( it ) && get_price( it ) > expensiveValue ){
            put_closet( item_amount( it ), it);
        }
    }
    batch_close();
}

// ── Fart Scauce only ────────────────────────────────────────────────────────
string messages(){
    return visit_url("messages.php");
}

void fartScauceInboxCleanup(){
    if (!isFartScauce())
        return;
    int deleted = 0;
    foreach str in $strings[3690803,1053259,1699424,1533476,3877087]{
        matcher m = create_matcher("name=\"sel(\\d+)\"></td><td class=small><b>From</b> <a href=\"showplayer\\.php\\?who=" + str, messages());
        while (m.find()){
            visit_url("messages.php?the_action=delete&box=Inbox&sel"+ m.group(1) + "=on");
            deleted += 1;
        }
    }
    matcher m = create_matcher("name=\"sel(\\d+)\"></td><td class=small><b>From</b> The Loathing Postal Service", messages());
    while (m.find()){
        visit_url("messages.php?the_action=delete&box=Inbox&sel"+ m.group(1) + "=on");
        deleted += 1;
    }

    print( deleted + " messages deleted");
}

// ─── NOT CALLED ──────────────────────────────────────────────────────────────

void dayShorteners(){
    float wastedAdv = to_float(my_adventures()) + to_float(numeric_modifier("Adventures")) + 40 - 200;
    if (wastedAdv > 0){
        if (user_confirm("Use "+ (wastedAdv/5) + " day shorteners?")){
            use(ceil(wastedAdv/5),$item[day shortener]);
        }
    }
}

void clockworkMaid(){
    if (!contains_text(visit_url("campground.php?action=inspectdwelling"),"maid2"))
        cli_execute("use clockwork maid");
}

// ─── ENTRY ───────────────────────────────────────────────────────────────────

void main(){
    step("phase: nightcap");
    fillOrgans();

    step("phase: leftover charges");
    augSkills();
    certificates();
    while ((my_basestat($stat[submoxie]) - 118881) > BCZcost("SweatEquityCasts"))
        use_skill($skill[BCZ: Sweat Equity]);
    YetiRO();

    step("phase: pvp");
    pvpCombat();

    step("phase: tomorrow setup");
    takerspaceStart();
    set_property("banishedPhylaSaved",get_property("banishedPhyla"));

    step("phase: snapshot");
    cli_execute ("av-snapshot.ash");

    step("phase: final outfit");
    finalOutfit();

    step("phase: closing meat chores");
    closingMeatChores();
    pvpCleanup();
    ptrackOnce("postFarmD1");

    step("phase: inbox cleanup");
    fartScauceInboxCleanup();
}
