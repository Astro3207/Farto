void closetShinies(){
    foreach it in $items[prismatic beret, unbreakable umbrella,cincho de mayo, 2002 mr. store catalog, august scepter,candy cane sword cane,spring shoes, everfull dart holster,mayam calendar,  roman candelabra, tearaway pants, bat wings, takerspace letter of marque,mchugelarge duffel bag, toy cupid bow,shrunken head,Allied Radio Backpack , jurassic parka,june cleaver, kolcon 13 snowglobe,backup camera, cursed monkey's paw, tiny stillsuit, designer sweatpants, black and white apron meal kit,, model train set,server room key,S.I.T. Course Completion Certificate,Unwrapped knock-off retro superhero cape ]{
        if (item_amount(it) > 0)
            put_closet(it);
    }
}

void main(){
    visit_url("peevpee.php?action=smashstone&pwd&confirm=on&shatter=Smash+that+Hippy+Crap%21");
    visit_url("showclan.php?whichclan=72876&action=joinclan&confirm=on");
    int [int] clanIds = {2047010985,2047010683,2047010572,2047010988,2047010986,2047010667,2047010939};
    foreach num in clanIds{
        set_property(clanIds[num] + "SewersDone", "false");
        set_property(clanIds[num] + "LargeYodelDone","false");
    }
    if (my_path() == $path[11,037 Leagues Under the Sea]){
        set_property("UnderTheSeaStage","stage0");
        set_property("seaAftercore","true");
        wait(10);
//        closetShinies();
        cli_execute("underthesea");
    } else if (my_path() == $path[Community Service]){
        set_property("seaAftercore","false");
        use($item[TakerSpace letter of Marque]);
        if(user_confirm("Closet Monkey paw?") && my_path() != $path[11,037 Leagues Under the Sea]){
            cli_execute("Closet put cursed monkey's paw");
    }
    }
}