import iotm.ash;
set_property("choiceAdventureScript","generalChoice.ash");
if (my_storage_meat( ) > 0)
    cli_execute ("hagnk all");
if (my_basestat($stat[moxie]) < 200 || my_basestat($stat[mysticality]) < 200) {
    use_familiar($familiar[cooler yeti]);
    maximize("cold res",false);
    cli_execute("gain cold res 1200 maxmeatspent; " + $effect[scariersauce].default + "; ");
    while (my_basestat($stat[moxie]) < 200 || my_basestat($stat[mysticality]) < 200){
        int before = my_basestat($stat[moxie]) + my_basestat($stat[mysticality]);
        if (!use(1, $item[Mmm-brr! brand mouthwash])
            || my_basestat($stat[moxie]) + my_basestat($stat[mysticality]) <= before){
            print("postloop: mouthwash isn't raising moxie/myst toward 200 -- bailing", "red");
            break;
        }
    }
}
cli_execute("breakfast; breakfast.ash");
if (item_amount($item[Platinum Yendorian Express Card]) > 0){
    stashreturn($item[Platinum Yendorian Express Card]);
}