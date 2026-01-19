//describes familiars as only mafia can

/*
override script displays primative familiar types in description using mafia's familiars.txt data file. 
	eg smiling rat will show an image of a vollyball to indicate its a vollyball-like

mafia has tags for type described in familiars.txt, we map it to images and write it to the page.
* if mafia adds a new type, it wont be displayed until our map is updated

script also builds and inserts a link to the wiki (from parsed familiar name).
*/

buffer page = visit_url();

page.replace_string("</head>","\n<script src=\"https://code.jquery.com/jquery-3.6.4.min.js\"></script>\n</head>");
page.replace_string("</head>","<link rel=\"stylesheet\" type=\"text/css\" href=\"desc.css\"></head>");

record famType {string name; string image; string type;};
famType [int] famMap;
string out;

//use data override if we have one, otherwise use mafia's built-in data
file_to_map("familiars.txt", famMap);
if (famMap[1].name=="") //returns blank if file doesn't exist
	file_to_map("data/familiars.txt", famMap);

string fam=page.group_string("<b>(.*?)<\/b>")[0][1]; //familiar name (matching text between <b> tag)
	
//see familiars.txt for ability descriptions
string [string] famAbility = {
"none": "<img src=/images/itemimages/familiar45.gif title='Nothing'>", //pet rock
"stat0": "<img src=/images/itemimages/familiar12.gif title='Vollyball-like stats'>",
"stat1": "<img src=/images/itemimages/hat2.gif title='Sombrero-like stats'>",
"item0":"<img src=/images/itemimages/familiar15.gif title='Item Drop'>", //fairy
"item1":"<img src=/images/itemimages/bowl.gif title='Food Drop'>",
"item2":"<img src=/images/itemimages/fruitym.gif title='Booze Drop'>",
"item3":"<img src=/images/itemimages/candy.gif title='Candy Drop'>",
"meat0":"<img src=/images/itemimages/familiar2.gif title='Meat Drop'>", //leprechaun
"combat0": "<img src=/images/itemimages/club.gif title='Physical Attack'>",
"combat1":"<img src=/images/itemimages/raincloud.gif title='Elemental Attack'>",
//many "special drop" familiars don't have proxy field data, but we'll display it if it does
"drop":"<img src=/images/itemimages/missingwine.gif title='Special drop"+(to_familiar(fam).drop_name!=""?": ":"")+to_familiar(fam).drop_name+"'>",
"block":"<img src=/images/itemimages/familiar3.gif title='Blocks like a Potato'>",
"delevel0":"<img src=/images/itemimages/familiar8.gif title='Delevels at start of combat'>",
"delevel1": "<img src=/images/itemimages/familiar19.gif title='Delevels during combat'>",
"hp0":"<img src=/images/itemimages/familiar1.gif title='Restore hp during combat'>", //mosquito
"mp0":"<img src=/images/itemimages/familiar17.gif title='Restore mp during combat'>", //starfish
"meat1":"<img src=/images/itemimages/familiar16.gif title='Drops meat during combat'>", //cocoabo
"stat2":"<img src=/images/itemimages/music.gif title='Grants stats during combat'>",
"other0":"<img src=/images/itemimages/confused.gif title='Does other things during combat'>",
"hp1":"<img src=/images/itemimages/hp.gif title='Restore hp after combat'>", 
"mp1":"<img src=/images/itemimages/mp.gif title='Restore mp after combat'>", 
"stat3":"<img src=/images/itemimages/mortarboard.gif title='Stats after combat (non-volley)'>",
"other1":"<img src=/images/itemimages/mysterybox.gif title='Does other things after combat'>",
"passive":"<img src=/images/itemimages/cherry.gif title='Passive'>",
"underwater":"<img src=/images/itemimages/bubbles2.gif title='Breaths underwater'>",
"pokefam":"<img src=/images/itemimages/spiritorb.gif title='Pokefam-only familiar'>",
"variable":"<img src=/images/itemimages/familiar40.gif title='Varies according to equipment or other factors'>",
};

out=" <a href=\"https://wiki.kingdomofloathing.com/"+fam+"\" target='_blank' title='thekolwiki' style='float: right;'>[wiki]</a>";

string [string] DIP={
	"show extra info":"dnShowDrops",
	"show Standard dates":"dnShowLAD",
	};
string mbox="<form id=\"descMenu\"><div id=menuBox>";
foreach str,P in DIP
	mbox+="<label><input type=\"checkbox\" "+(get_property(P)=="true"?"checked":"")+" id=\""+P+"\">"+str+"</label><br>";	
mbox+="</div></form>";

string famID=form_field("which");
page.replace_string("description\">","description\"><div id=icon>☰</div> "+mbox+famID+out);

//oh boy, last available date. Sometimes it isn't on the page though?
string LAD=page.group_string("<[^<>]+Last Available Date: (\\w+-\\w+)[^<>]+>")[0][1];
if (LAD=="")
	LAD="Last Available Date: <font style=\"color:black; font-weight:bold;\" title='probably'>Evergreen</font>";
else if (to_int(now_to_string('YYYY')) <= to_int(format_date_time('YYYY-MM',LAD,'YYYY'))+2){

	//shows time left in standard. Is this even useful information? 
	string LAD2=(to_int(format_date_time('YYYY-MM',LAD,'YYYY'))+2);//LAD plus 2 years
	string exp=timestamp_to_date( date_to_timestamp("yyyyMMdd",LAD2+"1231") - date_to_timestamp("yyyyMMdd",now_to_string('yyyyMMdd')),"M 'months' d 'days'"); //will report year from 197x because we're using epoach as difference point
	//doing years separately (time math is hard).
	string years=to_string(to_int(format_date_time('YYYY-MM',LAD,'YYYY'))+2-to_int(now_to_string('YYYY')) );
	years=(years==1?"1 year":years+" years"); //2,1 or 0

	//if we remove expire logic, need to remove/fix html title
	LAD="Last Available Date: <font style=\"color:black; font-weight:bold\" title=\""+years+" "+exp+" left in standard\">"+LAD+"</font>";
	}
else
	LAD="Last Available Date: <font style=\"color:grey; font-weight:bold\">"+LAD+"</font>";

if (to_boolean(get_property("dnShowDrops"))){
out="<center>";
foreach index,ability in split_string(famMap[to_familiar(fam).id].type,",")
	out+=famAbility[ability];
//page.replace_string("</body>",</body>");

//hatchling + equipment

item c=to_familiar(fam).hatchling;
string baby="Hatchling: "+(c==$item[none] ? "???" : "<b><a style=\"text-decoration: none;\" href=desc_item.php?whichitem="+c.descid+">"+c+"</a></b>");

item FE=familiar_equipment(to_familiar(fam));
string famEquip="Familiar Equipment: "+(FE==$item[none] ? "???" :"<b><a style='text-decoration: none;' href=desc_item.php?whichitem="+FE.descid+">"+FE.name+"</a></b>");
page.replace_string("</body>",out+"</center><p>"+baby+"<br>"+famEquip+"</body>");
}

if (to_boolean(get_property("dnShowLAD")))
	page.replace_string("</body>","<br>"+LAD+"</body>");

page.replace_string("document.getElementById('description').offsetHeight;","document.body.offsetHeight;");
page.replace_string("var resizetries = 0;","var resizetries = 11;");
page.replace_string("</body>","<script src=desc.js></script></body>");
page.write();

