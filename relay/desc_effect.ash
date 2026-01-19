//

boolean showDrops=to_boolean(get_property("dnShowDrops")); //drops from mon, coinmaster, creatable

void main(){

buffer page = visit_url();

page.replace_string("</head>","\n<script src=\"https://code.jquery.com/jquery-3.6.4.min.js\"></script>\n</head>");
page.replace_string("</head>","<link rel=\"stylesheet\" type=\"text/css\" href=\"desc.css\"></head>");

//extract effect id, display it and build a wiki link
string effid=page.group_string("<[^<>]+effectid: (\\d+)[^<>]+>")[0][1];
effect eff1=to_effect(effid);

string [string] DIP={
	"show source":"dnShowDrops",
	};
string mbox="<form id=\"descMenu\"><div id=menuBox>";
foreach str,P in DIP
	mbox+="<label><input type=\"checkbox\" "+(get_property(P)=="true"?"checked":"")+" id=\""+P+"\">"+str+"</label><br>";	
mbox+="</div></form>";

string wiki="<a href=\"https://wiki.kingdomofloathing.com/"+eff1.name+"\" target=\"_blank\" style=\"float: right;\">[wiki]</a>";
page.replace_string("description\">","description\"><div id=icon>☰</div> "+mbox+effid+wiki);

//add "source: " to the page under enchantment
string source;
// two tries to populate source, then we give em "???" later so it isn't blank
if (eff1.default != "")
	source=eff1.default;
else
	foreach a in eff1.all
		source+="<i>"+a+"</i> ";

//we're trying to match "use 1 blah blah" to turn it into an item or skill and generate a link
//its usually 1 but sometimes 5 (hair spray), oh well
item c;
if (showDrops && contains_text(source,"1") && !contains_text(source,"either") ){
	switch (split_string(source," 1 ")[0]){
		case "cast" :
			skill b = to_skill(split_string(source," 1 ")[1]);
			if (to_skill(b.id) != $skill[none])
				source = "<b><a style=\"text-decoration: none;\" href=\"desc_skill.php?whichskill="+b.id+"\">"+b+" (skill)</a></b>";
			break;
		case "use":
		case "drink":
		case "eat":
		case "chew":
			c = to_item(split_string(source," 1 ")[1]);
			source = c==$item[none] ? "":"<b><a style=\"text-decoration: none;\" href=\"desc_item.php?whichitem="+c.descid+"\">"+c+"</a></b>";
			break;
//		default:
//			print(source); //dont really care tbh
		}
	}

if (source=="")
	source="???";
if (showDrops)
	page.replace_string("</b></font></center></font>","</b></font></center></font><br>source: "+source+"");

//Avatar preview. Looks through monsters for item drop to determine image to preview. Mostly works
if (item_type(c)=="avatar potion" && showDrops){
monster MOTD;//monster of the day
foreach mon in $monsters[]
	if (item_drops(mon) contains c){
		MOTD=mon;
		break;
		}
	
page.replace_string("source:","<center><img src=/images/adventureimages/"+MOTD.image+" onerror=\"this.style.display='none'\"></center><br>source:");
}

//start building up glyphs in bottom right corner
string [string] effGlyphs = {
"noremove":"<img src=/images/itemimages/powder.gif style=\"opacity: 0.5;\" title='noremove'>", 
"nohookah":"<img src=/images/itemimages/hookah.gif style=\"opacity: 0.5;\" title='nohookah'>", 
"nopvp":"<img src=/images/itemimages/flower.gif style=\"opacity: 0.5;\" title='nopvp'>", 
"notcrs":"<img src=/images/itemimages/dice.gif style=\"opacity: 0.5;\" title='notcrs'>", //??
"song":"<img src=/images/itemimages/notes.gif title='song'>", 
"hottub": "hottub",//just used for Coated in Slime
};

string out;
/*
// useless and mostly wrong
switch(eff1.quality){
	case "good" : out+="<img title='good' src=images/itemimages/timehalo.gif>"; break;
	case "neutral":out+="<img title='neutral' src=images/itemimages/powderpile1.gif>"; break;
	case "bad":out+="<img title='bad' src=images/itemimages/demonflavor.gif>"; break;
	default:print(eff1.quality);
	}
*/

foreach index,attr in split_string(eff1.attributes,",")
	out+=effGlyphs[attr];
string toAdd="<div style=\"position: absolute; bottom: 5px; right:20px;\">"+out+"</div>";
page.replace_string("</body>",toAdd+"</body>");
page.replace_string("document.getElementById('description').offsetHeight;","document.body.offsetHeight;");
page.replace_string("var resizetries = 0;","var resizetries = 11;");
page.replace_string("</body>","<script src=desc.js></script></body>");
page.write();
}

