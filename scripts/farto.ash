import iotm.ash;
import preadventure.ash;
import zlib.ash; // for sell_val() -- item valuation for itemDropValueAt()

// ─── farto.ash ───────────────────────────────────────────────────────────────
// ─── drop-value weighting (garbo's modeValueOfMeat/modeValueOfItem) ─────────

float baseMeatAt(location loc){
    float average;
    foreach mon, rate in appearance_rates(loc){
        if (rate > 0)
            average += rate/100 * meat_drop(mon);
    }
    return average + 25;
}

float itemDropValueAt(location loc){
    float total;
    foreach mon, rate in appearance_rates(loc){
        if (rate <= 0 || mon == $monster[none])
            continue;
        foreach idx, rec in item_drops_array(mon){
            if (rec.type != "n" && rec.type != "")
                continue;
            float worth = sell_val(rec.drop);
            if (worth <= 0)
                continue;
            total += (rate / 100.0) * (rec.rate / 100.0) * worth;
        }
    }
    return total / 100.0; // per-adventure expected value -> value of 1% Item Drop
}

void setDropWeighting(location loc){
    string mod = loc.environment == "underwater" ? ",sea, -tie" : "";
    set_property("maxOverride", to_string(baseMeatAt(loc) / 100.0) + " Meat Drop," + to_string(itemDropValueAt(loc)) + " Item Drop" + mod);
}

// ─── shared zone helpers ─────────────────────────────────────────────────────

void dartHolster(){
    set_property("acc1Override", everfullReady() ? "" : ", equip everfull dart holster");
}

void returnPantsgiving(){
    int count = get_property("_pantsgivingCount").to_int();
    if (available_amount($item[pantsgiving]) > 0 && count >= (dayType() == 0 ? 50 : 500))
        stashreturn($item[pantsgiving]);
}

void advWithBanish(location loc, boolean needBanish){
    item banItem = needBanish ? banishGear(loc) : $item[none];
    if (banItem != $item[none])
        equip(banItem);
    adv1(loc, 0, "");
    if (banItem != $item[none])
        set_property(to_string(to_slot(banItem)) + "Override", "");
}

// ─── zones ───────────────────────────────────────────────────────────────────

void dayOneUnlocks(){
    cli_execute("postadventure");
    if (get_property("questM16Temple") != "finished")
        findHiddenTemple();
    else if (available_amount($item[observational glasses]) == 0)
        azazelUnicornQuest();
    else if (get_property("questM10Azazel") != "finished" && have_effect($effect[Patent Aggression]) == 0){
        azazelUnicornQuest();
    }else if (to_int(get_property("blackForestProgress")) < 5)
        blackForest();
    else if ((get_property("questG09Muscle") != "finished" && my_class() == $class[seal clubber]) || get_property("questL05Goblin") == "started")
        outskirts();
    if (get_property("questL05Goblin") != "started" && available_amount($item[mayfly bait necklace]) > 0){
        if (get_property("questL05Goblin") == "step1"){
            set_property("hatOverride",", equip Knob Goblin harem veil");
            set_property("pantsOverride",", equip Knob Goblin harem pants");
            if (!outfit("Knob Goblin Harem Girl Disguise"))
                abort("I'm not dressed provocatively enough!");
            if (have_effect($effect[Knob Goblin Perfume]) == 0)
                use($item[Knob Goblin perfume]);
            adv1($location[Throne Room]);
            set_property("hatOverride","");
            set_property("pantsOverride","");
        }
        if (item_amount($item[Cobb's Knob Menagerie key]) == 0){
            set_property("acc1Override",", equip peridot of peril");
            adv1($location[Cobb's Knob Laboratory]);
            set_property("acc1Override","");
        }
        abort("Hunter use heartstone banish and monkeypaw slap and do the mayfly manually, send it to me and Ill script it in fully");
    }
}

void bladdering(){
    set_property("script","bladdering");
    if (have_item($item[mime army infiltration glove]) && my_primestat() != $stat[moxie])
        set_property("acc2Override", ", equip mime army infiltration glove");
    set_property("bonusOverride"," ");
    set_property("maxOverride","combat,-equip drunkula's wineglass");
    set_property("famOverride", "peace turkey");
    set_property("mainOverride",", equip june cleaver");
    set_property("acc3Override",", equip mafia thumb ring");
    if (have_effect($effect[Apriling Band Battle Cadence]) == 0 && total_turns_played() >= get_property("nextAprilBandTurn").to_int())
        cli_execute("aprilband effect c");
    adv1($location[cobb's knob treasury]);
    if (get_property("_seadentWaveUsed").to_boolean() == false)
        use_skill($skill[Sea *dent: Summon a Wave]);
    if (get_property("_seadentWaveZone") != "Cobb's Knob Treasury")
        abort("treasury isn't flooded");
}

void inko(){
    setDropWeighting($location[The Marinara Trench]);
    set_property("famOverride","");
    if (!have_familiar($familiar[robortender]))
        altFam($familiar[robortender]);
    dartHolster();
    returnPantsgiving();
    string banishedList = get_property("banishedMonsters");
    boolean needBanish = false;
    boolean monodent = false;
    if (!contains_text(banishedList,"fisherfish") || !contains_text(banishedList,"diving belle"))
        needBanish = true;
    else if (!contains_text(banishedList,"Mer-kin diver")){
        if (have_effect($effect[fishy]) < my_adventures() && my_class() == $class[seal clubber]){
            set_property("mainOverride",", equip monodent of the sea");
            monodent = true;
        } else {
            set_property("mainOverride","");
            needBanish = true;
        }
    }
    advWithBanish($location[The Marinara Trench], needBanish);
    if (monodent)
        set_property("mainOverride","");
}

void cowo(){
    setDropWeighting($location[the coral corral]);
    set_property("famOverride","");
    dartHolster();
    returnPantsgiving();
    advWithBanish($location[The Coral Corral],
        !contains_text(get_property("banishedMonsters"),"Mer-kin rustler")
        || !contains_text(get_property("banishedMonsters"),"sea cowboy"));
}

void garbo(){
    setDropWeighting($location[barf mountain]);
    set_property("famOverride", have_effect($effect[Citizen of a Zone]) == 0 ? "patriotic eagle" : "");
    set_property("backOverride","");
    string tracked = get_property("trackedMonsters");
    int knuckles = to_int(get_property("_knuckleboneDrops"));
    boolean slashGarbage = !contains_text(tracked, "garbage tourist:McHugeLarge Slash") && knuckles == 100;
    boolean slashAngry   = !contains_text(tracked, "angry tourist:McHugeLarge Slash") && knuckles < 100;
    set_property("offOverride", slashGarbage || slashAngry ? ", equip McHugeLarge left pole" : "");
    set_property("acc3Override", slashGarbage ? ", equip peridot of peril" : "");
    dartHolster();
    returnPantsgiving();
    adv1($location[barf mountain],0,"");
}

// ─── called from postadventure ───────────────────────────────────────────────

void shadowRealmNCForce(){
    if (get_property("script") == "stick" || get_property("script") == "coat")
        return;
    if (get_property("_shadowAffinityToday") == "false" || have_effect($effect[shadow affinity]) > 0){
        if (get_property("questRufus")== "unstarted"){
            use($item[closed-circuit pay phone]);
        }
        while (have_effect($effect[shadow affinity]) > 0){
            shadowRealm();
        }
    }
    if (have_effect($effect[null afternoon]) == 0)
        use($item[null-day exploit]);
    string bbs = get_property("betweenBattleScript");
    while (get_property("noncombatForcerActive") == "true"){
        set_property("acc2Override",", equip petrified wood wizard's pouch");
        use($item[closed-circuit pay phone]);
        if (get_property("_mcHugeLargeAvalancheUses").to_int() < 3)
            set_property("acc3Override",", equip McHugeLarge left ski");
        if (get_property("_spikolodonSpikeUses").to_int() < 5){
            set_property("shirtOverride",", equip parka spikolodon");
        }
        if (get_property("rufusQuestTarget") == "shadow scythe")
            use_skill($skill[Cannelloni Cocoon]);
        if (get_property("rufusQuestTarget") == "shadow orrery"){
            set_property("betweenBattleScript","");
            cli_execute("maximize elemental damage");
        }
        adv1($location[Shadow Rift (The Nearby Plains)],0,"");
        use($item[closed-circuit pay phone]);
        if (item_amount($item[Rufus's shadow lodestone]) > 0)
            adv1($location[Shadow Rift (The Nearby Plains)],0,"");
    }
    set_property("betweenBattleScript", bbs);
    set_property("shirtOverride","");
    set_property("acc2Override","");
    set_property("acc3Override","");
    set_property("maxOverride","");
}

// ─── ENTRY ───────────────────────────────────────────────────────────────────

void main(){
    try {
        starter();
        if (to_int(get_property("_pantsgivingCount")) < 50 && available_amount($item[pantsgiving]) == 0)
            stashgrab($item[pantsgiving]);
        set_property("script","farto");
        while (my_adventures() > 0){
            if (numeric_modifier("sleaze damage") + numeric_modifier("sleaze spell damage") > 1600)
                unlock_zeppelin();
            if (dayType() == 0 && (get_property("questM16Temple") != "finished" || get_property("questM10Azazel") != "finished" || to_int(get_property("blackForestProgress")) < 5 || get_property("questL05Goblin") == "started")){
                dayOneUnlocks();
            } else if (dayType() == 0 && get_property("bladderMax").to_boolean() == true && have_effect($effect[fishy]) > 0){
                bladdering();
            } else if ((my_class() == $class[accordion thief] || have_effect($effect[fishy]) > 0) || dayType() == 0){
                if (dayType() == 0){
                    ptrackOnce("InkoD1");
                    if (my_class() == $class[seal clubber] && have_effect($effect[imagining guts]) > my_adventures())
                        visit_url("account.php?am=1&pwd="+my_hash()+"&action=flag_disablefacts&value=1&ajax=1");
                }
                inko();
            } else if (my_class() == $class[pastamancer] && numeric_modifier($modifier[meat drop]) > 1700){
                cowo();
            }else{
                if (get_property("_stenchAirportToday") == "false")
                    use($item[one-day ticket to Dinseylandfill]);
                garbo();
            }
        }
    } finally {
        visit_url("account.php?am=1&pwd="+my_hash()+"&action=flag_disablefacts&value=0&ajax=1");
        finisher();
    }
}
