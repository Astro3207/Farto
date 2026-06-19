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
    switch (whichchoice){
        case 337:
            if (get_property(get_clan_id() + "Tickled") == "ML"){
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
        case 399:
        case 400:
        case 401:
            buffer elementaryQueue = to_buffer(get_property("elementaryQueue"));
            append(elementaryQueue, ", " + last_choice());
            delete(elementaryQueue,0,5);
            set_property("elementaryQueue",to_string(elementaryQueue));
        case 705:
            run_choice(1);
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
        case 920:
            run_choice(3);
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
        case 211:
            run_choice(1);
        case 1467:
            run_choice(3);
            break;
        case 1468:
            run_choice(4);
            run_choice(3);
            break;
        case 1469:
            run_choice(3);
            break;
        case 1470:
            run_choice(4);
            run_choice(2);
            break;
        case 1471:
            run_choice(1);
            break;
        case 1472:
            run_choice(1);
            break;
        case 1473:
            run_choice(4);
            run_choice(1);
            break;
        case 1474:
            run_choice(4);
            run_choice(2);
            break;
        case 1475:
            run_choice(1);
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
            if (my_location() == $location[the marinara trench] && my_class() == $class[accordion thief])
                run_choice(1, "bandersnatch=763");
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
        case 1562:
            if (whichchoice == 1562){
                string [int] choices = available_choice_options();
                foreach num, choice_text in choices {
                    if (contains_text(choice_text,"investment tips")){
                        run_choice(num);
                        exit;
                    }
                }
                foreach num, choice_text in choices {
                    if (contains_text(choice_text,"trifecta")){
                        run_choice(num);
                        exit;
                    }
                }
                foreach num, choice_text in choices {
                    if (contains_text(choice_text,"free gun")){
                        run_choice(num);
                        exit;
                    }
                }
                foreach num, choice_text in choices {
                    if (contains_text(choice_text,"Sell the gun")){
                        run_choice(num);
                        exit;
                    }
                }
            }
            break;

    }
}