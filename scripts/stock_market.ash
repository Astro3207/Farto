int [item] special = {
    $item[pocket wish]:47000,
    $item[waffle]:1000,
    $item[rotten tomato]:1000,
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
    $item[11-leaf clover]:24000,
    //consumables that spiked in price suring crimbo like the CS drinks and spice melange and hobopolis stuff?
};

int itNum;
foreach current in $items[glass of goat's milk,potion of temporary gr8ness,Penultimate Fantasy chest,wreath-shaped Crimbo cookie,bell-shaped Crimbo cookie,red snowcone,hot hi mein,spooky hi mein,stinky hi mein,sleazy hi mein,milk of magnesium,philosopher's scone,groose grease,peppermint sprout,Rad Lib,home robotics kit,Tallowcreme Halloween Pumpkin,Flaskfull of Hollow,handful of Smithereens,grim fairy tale,lynyrd snare,black label,delicious candy,powdered gold,porcelain candy dish,pixel banana,perfect negroni,perfect dark and stormy,perfect mimosa,perfect old-fashioned ,perfect paloma ,Doc Clock's thyme cocktail,Mr. Burnsger]{
    if (special[current] > 0){
        buy(10,current,special[current]);
    } else {
        buy(10,current,mall_price(current)/5);
    }
}