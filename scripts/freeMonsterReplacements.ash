import iotm.ash;

// copyTarget is the shared free-fight target configured in iotm.ash.
// A last Gregarious/Habitats charge is not forced on a normal zone roll,
// but a monster replacement can still roll it. Preserve it until after backups.
boolean replacementSourceReady(){
    if (get_property("beGregariousFightsLeft").to_int()
        + get_property("_monsterHabitatsFightsLeft").to_int() != 1)
        return false;
    return (get_property("beGregariousFightsLeft").to_int() == 1
            && to_monster(get_property("beGregariousMonster")) == copyTarget)
        || (get_property("_monsterHabitatsFightsLeft").to_int() == 1
            && to_monster(get_property("_monsterHabitatsMonster")) == copyTarget);
}

boolean replacementReady(skill replacer){
    if (replacer == $skill[Macrometeorite])
        return have_skill($skill[Meteor Lore]) && get_property("_macrometeoriteUses").to_int() < 10;
    if (replacer == $skill[CHEAT CODE: Replace Enemy])
        return available_amount($item[Powerful Glove]) > 0
            && get_property("_powerfulGloveBatteryPowerUsed").to_int() <= 90;
    return false;
}

int replacementUses(skill replacer){
    return get_property(replacer == $skill[Macrometeorite]
        ? "_macrometeoriteUses" : "_powerfulGloveBatteryPowerUsed").to_int();
}

boolean reserveReplacementSource(){
    if (!replacementSourceReady() || get_property("_monsterHabitatsRecalled").to_int() < 3)
        return false;
    // Finish earlier Gregarious charges normally; only hold the final source.
    if (dayType() == 1 && get_property("beGregariousCharges").to_int() > 0)
        return false;
    return replacementReady($skill[Macrometeorite]) || replacementReady($skill[CHEAT CODE: Replace Enemy]);
}

// Called before any damage, copying, or generic free-kill actions in the CCS.
void replaceFreeMonster(){
    if (get_property("script") != "FreeKill" || get_property("subscript") != "replacementChain")
        return;
    if (last_monster() == copyTarget) return;
    if (my_location() != $location[Noob Cave] || last_monster() != $monster[crate])
        abort("Replacement chain: unexpected encounter; leaving combat open.");
    if (!replacementSourceReady())
        abort("Replacement chain: the reserved free-monster source is unavailable.");
    skill replacer = to_skill(get_property("fartoReplacementSkill"));
    if (!replacementReady(replacer) || !have_skill(replacer))
        abort("Replacement chain: selected replacement is unavailable.");
    int before = replacementUses(replacer);
    use_skill(replacer);
    if (replacementUses(replacer) <= before || last_monster() != copyTarget)
        abort("Replacement chain: replacement did not produce " + copyTarget + "; leaving combat open.");
}
