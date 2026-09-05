int ESPmission(string page){
    int num;
    if (contains_text(page, "ever-changing constellation")){
        num = 1;
    }
    if (contains_text(page, "circle of light")){
        num = 2;
    }
    if (contains_text(page, "waves a fly")){
        num = 3;
    }
    if (contains_text(page, "back to square one")){
        num = 4;
    }
    if (contains_text(page, "adds to your anxiety")){
        num = 5;
    }
    return num;
}

void main(int whichchoice, string page) {
    if (whichchoice == 536){
        item pill;
        int target;
        if (available_amount($item[distention pill]) < available_amount($item[synthetic dog hair pill])) {
            pill = $item[distention pill];
            target = 1;
        } else {
            pill = $item[synthetic dog hair pill];
            target = 2;
        }
        int start = available_amount(pill);

        //keep trying even on server errors
        int tries = 0,max = 5;
        repeat {
            //do the choice chain to evenly get pills
            if (available_choice_options()[1] == "Down the Hatch!")
                run_choice(1);
            if (available_choice_options()[1] == "Have a Drink")
                run_choice(1);
            if (available_choice_options()[2] == "Try That One Door")
                run_choice(2);
            if (available_choice_options()[1] == "Follow Captain Smirk")
                run_choice(target);
            //if still in choice, give it a few seconds before trying again
            if (handling_choice()) {
                print("problem encountered while handling the choice","blue");
                if (++tries < max) {
                    print("waiting a few seconds to try again","blue");
                    wait(5);
                }
                else {
                    print(`giving up after {tries} tries`,"red");
                }
            }
        } until (!handling_choice());
    }
    switch (whichchoice){
        // ── simple: a single fixed run_choice(#), grouped by that number, then by case # ──
        case 633:
        case 705:
        case 787:
        case 1344:
        case 1471:
        case 1472:
        case 1475:
        case 1566:
            run_choice(1);
            break;

        case 693:
        case 857:
        case 866:
        case 1202:
            run_choice(2);
            break;

        case 690:
        case 691:
        case 692:
        case 793:
        case 920:
        case 1467:
        case 1469:
        case 1596:
            run_choice(3);
            break;

        case 584:
            run_choice(4);
            break;

        case 781:
        case 783:
        case 791:
        case 1119:
        case 1237:
        case 1250:
            run_choice(6);
            break;

        // ── complex: conditional / multiple / dynamic run_choice, or none at all -- sorted by case # ──
        // Was `case 211: case 1310: run_choice(1);` falling through into 1467's
        // run_choice(3); inlined here so 1467 could move up to the simple run_choice(3)
        // group above.
        case 211:
        case 1310:
            run_choice(1);
            run_choice(3);
            break;
        case 218:
            if (get_property("choiceAdventure218") == "0"){
                buffer heapQueue = to_buffer(get_property("heapQueue"));
                append(heapQueue, ", " + last_choice());
                delete(heapQueue,0,5);
                set_property("heapQueue",to_string(heapQueue));
            }
            if (get_property("script") == "junko")
                user_confirm("Heap manually");
            break;
        case 337:
            if (get_property(get_clan_id() + "Tickled") == "done"){
                run_choice(2);
            } else if (get_property(get_clan_id() + "Tickled") == "ML"){
                run_choice(2);
            } else if (item_amount($item[caustic slime nodule]) > 0 && (get_property(get_clan_id() + "Tickled") != "finished" && get_property(get_clan_id() + "Tickled") != "ML" && get_property(get_clan_id() + "Tickled") != "tickled")){
                run_choice(1);
                set_property(get_clan_id() + "Tickled","tickled");
            } else {
                run_choice(2);
            }
            break;
        case 360:
            if (item_amount($item[memory of a glowing crystal]) == 0){
                run_choice(1);
                cli_execute("porkfuture");
            } else {
                run_choice(2);
            }
            break;
        // Was `case 399/400/401:` (queue update, no break) falling through into
        // `case 1344: case 705: run_choice(1);`; the run_choice(1) is inlined here so
        // 1344 and 705 could move up to the simple run_choice(1) group above.
        case 399:
        case 400:
        case 401:
            buffer elementaryQueue = to_buffer(get_property("elementaryQueue"));
            append(elementaryQueue, ", " + last_choice());
            delete(elementaryQueue,0,5);
            set_property("elementaryQueue",to_string(elementaryQueue));
            run_choice(1);
            break;
        case 443:
            cli_execute("chess solve");
            break;
        case 451:
            if (item_amount($item[plus sign]) == 0){
                run_choice(3);
            } else {
                run_choice(5);
            }
            break;
        case 580:
            run_choice(2);
            run_choice(4);
            run_choice(1);
            break;
        case 627:
            run_choice(to_int(get_property("chibiChoice1")));
            run_choice(to_int(get_property("chibiChoice2")));
            run_choice(7);
            break;
        case 696:
            if (get_property("maraisDarkUnlock") == "false"){
                run_choice(1);
            }
            if (get_property("maraisWildlifeUnlock") == "false"){
                run_choice(2);
            }
            break;
        case 697:
            if (get_property("maraisCorpseUnlock") == "false"){
                run_choice(1);
            }
            if (get_property("maraisWizardUnlock") == "false"){
                run_choice(2);
            }
            break;
        case 698:
            if (get_property("maraisBeaverUnlock") == "false"){
                run_choice(1);
            }
            if (get_property("maraisVillageUnlock") == "false"){
                run_choice(2);
            }
            break;
        // Was falling through into the run_choice(6) group above; the run_choice(6)
        // is inlined here so that group could stay a clean simple group.
        case 785:
            if (have_equipped($item[candy cane sword cane]))
                run_choice(4);
            run_choice(6);
            break;
        case 918:
            if (to_int(today_to_string()) > to_int(format_date_time("yyyy-MM-dd",get_property("umdLastObtained"),"yyyyMMdd"))){
                run_choice(1);
            } else {
                run_choice(3);
                run_choice(2);
            }
            break;
        case 919:
            if (to_int(get_property("_sloppyDinerBeachBucks")) < 4){
                run_choice(1);
            } else {
                run_choice(6);
            }
            break;
        case 923:
            if (get_property("candyCaneSwordBlackForest") == "false" && have_equipped($item[candy cane sword cane]))
                run_choice(5);
            run_choice(1);
            run_choice(1);
            break;
        case 989:
            print (ESPmission(page));
            break;
        case 1114:
            if (whichchoice == 1114){
                string [int] choices = available_choice_options();
                foreach num, choice_text in choices {
                    print(`{num}: {choice_text}`);
                }
                foreach task in $strings[moonbeams,blood,bolts, ice, chicken, chum, milk, rain]{
                    foreach num, choice_text in choices {
                        if (contains_text(choice_text,task)){
                            run_choice(num);
                            exit;
                        }
                    }
                }
                run_choice(1);
            }
            break;
        case 1115:
            if (get_property("_VYKEALoungeRaided") == false){
                run_choice(4);
            } else{
                run_choice(3);
            }
            break;
        case 1116:
            if (get_property("_iceHotelRoomsRaided") == false){
                run_choice(5);
            } else{
                run_choice(3);
            }
            break;
        case 1468:
            run_choice(4);
            run_choice(3);
            break;
        case 1470:
            run_choice(4);
            run_choice(2);
            break;
        case 1473:
            run_choice(4);
            run_choice(1);
            break;
        case 1474:
            run_choice(4);
            run_choice(2);
            break;
        case 1483:
            run_choice(1);
            run_choice(3);
            break;
        case 1497:
            if (have_effect($effect[shadow affinity]) > 0){
                run_choice(2);
            } else if (get_property("rufusDesiredEntity") == "shadow scythe"){
                run_choice(2);
            } else{
                run_choice(1);
            }
            break;
        case 1525:
            if (whichchoice == 1525){
                string [int] choices = available_choice_options();
                foreach num, choice_text in choices {
                    print(`{num}: {choice_text}`);
                }
                foreach perk in $strings[impress,better,targeting,butt]{
                    foreach num, choice_text in choices {
                        if (contains_text(choice_text,perk)){
                            run_choice(num);
                            exit;
                        }
                    }
                }
                run_choice(1);
            }
            break;
        case 1557:
            if (my_location() == $location[the black forest]){
                if (item_amount($item[broken wings]) == 0){
                    run_choice(1, "bandersnatch=416");
                } else if (item_amount($item[sunken eyes]) == 0){
                    run_choice(1, "bandersnatch=414");
                }
            }
            if (my_location() == $location[Madness Bakery])
                run_choice(1, "bandersnatch=1748");
            if (my_location() == $location[barf mountain])
                run_choice(1, "bandersnatch=1760");
            if (my_location() == $location[the marinara trench] && my_class() == $class[accordion thief])
                run_choice(1, "bandersnatch=763");
            else{
                run_choice(2);
            }
            break;
        case 1562:
            if (whichchoice == 1562){
                string [int] choices = available_choice_options();
                foreach num, choice_text in choices {
                    if (contains_text(choice_text,"investment tips")){
                        run_choice(num);
                        exit;
                    }
                    if (get_property("ascensionsToday") == "1"){
                        foreach str in $strings[Stop your arch-nemesis as a baby,Take the long odds on the trifecta,Hey, free gun!,Borrow meat from your future,Draw a goatee on yourself,Plant some seeds in the distant past,Peek in on your future,Plant some trees and harvest them in the future,Steal a cupcake from young Susie,Borrow a cup of sugar from yourself,Steal a club from the past,Go back and write a best-seller,Go back and take a 20-year-long nap]{
                            foreach num, choice_text in choices {
                                if (contains_text(choice_text,str)){
                                    run_choice(num);
                                    exit;
                                }
                            }
                        }
                    } else {
                        foreach num, choice_text in choices {
                            if (contains_text(choice_text,"Steal from your future self")){
                                run_choice(num);
                                exit;
                            }
                        }
                    }
                    foreach num, choice_text in choices {
                        if (contains_text(choice_text,"Steal from your future self")){
                            run_choice(num);
                            exit;
                        }
                    }
                }
            }
            break;
    }
}
