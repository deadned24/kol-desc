//
buffer page = visit_url();

//extract effect id, display it and build a wiki link
string effid=page.group_string("<[^<>]+effectid: (\\d+)[^<>]+>")[0][1];
effect eff1=to_effect(effid);

string wiki="<a href=\"https://wiki.kingdomofloathing.com/"+eff1.name+"\" target=\"_blank\" style=\"float: right;\">[wiki]</a>";
page.replace_string("description\">","description\"># "+effid+wiki);

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
if ( contains_text(source,"1") && !contains_text(source,"either") ){
	switch (split_string(source," 1 ")[0]){
		case "cast" :
			skill b = to_skill(split_string(source," 1 ")[1]);
			if (to_skill(b.id) != $skill[none])
				source = "<a style=\"text-decoration: none;\" href=desc_skill.php?whichskill="+b.id+">"+b+" (skill)</a>";
			break;
		case "use":
		case "drink":
		case "eat":
		case "chew":
			item c = to_item(split_string(source," 1 ")[1]);
			source = c==$item[none] ? "":"<a style=\"text-decoration: none;\" href=desc_item.php?whichitem="+c.descid+">"+c+"</a>";
			break;
//		default:
//			print(source); //dont really care tbh
		}
	}

if (source=="")
	source="???";
page.replace_string("</center></font>","</center></font><br><b>source:</b> "+source+"");


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
page.write();
