int [item] special = {
    $item[pocket wish]:47000,
    $item[waffle]:1000,
    $item[handheld allied radio]:11000,
    $item[battery (9-Volt)]:14000,
    $item[battery (D)]:10500,
    $item[battery (AA)]:7000,
    $item[battery (AAA)]:3500,
    $item[cold wad]:950,
    $item[cold nugget]:190,
    $item[hot wad]:750,
    $item[hot nugget]:150,
    $item[spooky wad]:750,
    $item[spooky nugget]:150,
    $item[stench wad]:850,
    $item[stench nugget]:170,
    $item[sleaze wad]:850,
    $item[sleaze nugget]:170,
    $item[groveling gravel]:10000,
    $item[spice melange]:200000,
    $item[emergency margarita]:110000,
    $item[vintage smart drink]:110000,
    $item[11-leaf clover]:29000,
    //consumables that spiked in price suring crimbo like the CS drinks and spice melange and hobopolis stuff?
};

void main() {
    int itNum;
    foreach current in $items[glass of goat's milk,potion of temporary gr8ness,spooky hi mein,Penultimate Fantasy chest,handheld allied radio,milk of magnesium,delicious candy,perfect negroni,perfect dark and stormy,perfect mimosa,perfect old-fashioned ,perfect paloma,Mmm-brr! brand mouthwash]{
        if (special[current] > 0){
            buy(14,current,special[current]);
        } else {
            buy(10,current,mall_price(current)/5);
        }
    }
    foreach it in $items[cocoa of youth]{
        if (mall_price(it) < 60000)
        buy(1,it);
    }
    if (item_amount($item[phial of coldness]) == 0){
        int minPrice = 1000000;
        item cheapestItem;
        foreach it in $items[phial of coldness,cold cluster,BOOtonniere,drafty drawers,old ball and chain,remorseless knife,snowstick]{
            if (it.mall_price() < minPrice){
                minPrice = it.mall_price();
                cheapestItem = it;
            }
        }
        buy(cheapestItem);
        if (cheapestItem != $item[phial of coldness]){
            if (cheapestItem != $item[cold cluster]){
                cli_execute("kmail " + cheapestItem + " to smashbot || force");
            }
            if (item_amount($item[cold cluster]) == 0){
                waitq(5);
                cli_execute("refresh all");
            }
            create($item[phial of coldness]);
        }
    }
    if (item_amount($item[phial of stench]) == 0){
        int minPrice = 1000000;
        item cheapestItem;
        foreach it in $items[phial of stench,stench cluster,bag of unfinished business,cod cape,guts necklace,tailbone shield]{
            if (it.mall_price() < minPrice){
                minPrice = it.mall_price();
                cheapestItem = it;
            }
        }
        buy(cheapestItem);
        if (cheapestItem != $item[phial of stench]){
            if (cheapestItem != $item[stench cluster]){
                cli_execute("kmail " + cheapestItem + " to smashbot || force");
            }
            while (item_amount($item[stench cluster]) == 0){
                waitq(5);
                cli_execute("refresh all");
            }
            create($item[phial of stench]);
        }
    }
}