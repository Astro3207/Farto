//unused resources: august scepter daily, august scepter
//post ascension: map to candy rich block (but I would have a hard time using it), habitat recall (but I can't use it), lucky sax
//CS issues: drum machine, science tent, fortune clan consult???, ELR, shattering punch, jokester gun, gingerbread mob hit, assert your authority, perpetrate mild evil (can't use)
//thoughts: jill o lantern, do clan quest, jokester gun fire and other free kills, when map drops habitat recall the free fights and olfact and eagle screech, then continue at outskirts, then you have 10 free seal fights

if (get_property("ascensionsToday") == "0") {
	if (get_property("_gitUpdated") == false)
		cli_execute("breakfast.ash");
	if (my_fullness() < fullness_limit())
		cli_execute("garbo nobarf");
	if (my_adventures() > 0 && my_inebriety() <= inebriety_limit())
		cli_execute("farto");
	set_property("looping","true");
	if ((my_adventures() == 0 && my_inebriety() == inebriety_limit()) || (my_adventures() > 0 && my_inebriety() > inebriety_limit()))
		cli_execute("preascend");
}
if (get_property("ascensionsToday") == "1") {
	if (my_path_id() == 55){
		cli_execute("underthesea");
	} else {
		if (have_effect($effect[fishy]) > 0)
			cli_execute("unblemishedpearl");
		if (my_fullness() < fullness_limit())
			cli_execute("garbo nobarf");
		if (my_adventures() > 0 && my_inebriety() <= inebriety_limit())
			cli_execute("farto");
		if (my_adventures() == 0 && (my_inebriety() < inebriety_limit() || my_fullness() < fullness_limit()))
			cli_execute("CONSUME ALL");
		if (my_adventures() > 0 && my_inebriety() <= inebriety_limit())
			cli_execute("farto");
		if (my_adventures() == 0 && my_inebriety() == inebriety_limit())
			cli_execute("dinner");
	}
}