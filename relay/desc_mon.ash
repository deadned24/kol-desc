//monster description page
/*
small popup that shows monster, drops, location.
*/
void main(){

if (form_field("id")!="")
	set_property(form_field("id"),form_field("checked"));

buffer page;
//use kol's css & js. copied and modified from kol's desc_item
page.append("<html><head>\
<title>Monster Description</title>\
<link rel=\"stylesheet\" type=\"text/css\" href=\"/images/styles.20230117d.css\">\
<style>\
span.item {\
	cursor: pointer;\
  	font-weight: bold;\
}\
</style>\
<script language=Javascript src=\"/images/scripts/window.20111231.js\"></script>\
<script language=\"Javascript\" src=\"/basics.js\"></script><link rel=\"stylesheet\" href=\"/basics.1.css\" /></head>\
<style>a.link {	cursor: pointer; text-decoration: none;}</style>\
<body>");

//monster is is passed to this page via mon parameter. eg desc_mon.php?mon=123
monster MOTD=to_monster(form_field("mon"));

//we are limited to monsters kolmafia knows about. exit if monster isn't found
if (MOTD ==$monster[none]){
	page.append("<center><img src=images/adventureimages/nopic.gif><br>Jick: [describe me] ("+form_field("mon")+")</center>");
	page.write();
	return;
	}

//start writing the page. 
string wiki="<a href=\"https://wiki.kingdomofloathing.com/"+MOTD+"\" target=\"_blank\" style=\"float: right;\">[wiki]</a>";
page.append("# "+MOTD.id+wiki+"<br>");
page.append("<center>");
page.append("<img src=images/adventureimages/"+MOTD.image+"></a><br>");
page.append("<b>"+MOTD.article+" "+MOTD.name+"</b>"+(MOTD.group>1?" (x"+MOTD.group+")":""));
page.append("</center>");

//copied and modified from the wiki's phylum template
string [string] flavor={"beast":"beastflavor.gif", "bug":"stinkbug.gif", "constellation":"star.gif", "elf":"elfflavor.gif", "crimbo":"elfflavor.gif", "demon":"demonflavor.gif", "demihuman":"demonflavor.gif", "dude":"happy.gif", "elemental":"rrainbow.gif", "fish":"fish.gif", "goblin":"goblinflavor.gif", "hippy":"hippyflavor.gif", "hobo":"hoboflavor.gif", "humanoid":"statue.gif", "horror":"skull.gif", "mer-kin":"merkinflavor.gif", "construct":"sprocket.gif", "object":"sprocket.gif", "orc":"frattyflavor.gif", "penguin":"bowtie.gif", "pirate":"pirateflavor.gif", "plant":"leafflavor.gif", "slime":"sebashield.gif", "weird":"weirdflavor.gif", "strange":"weirdflavor.gif", "undead":"spookyflavor.gif"};
//color coding for monster elements
string [string] color={"none":"black","hot":"red","cold":"blue","spooky":"grey","sleaze":"purple","stench":"green"};

//phylum and element, using maps from above for styling.
page.append("<br>Phylum: <b>"+MOTD.phylum+"</b><img src=images/itemimages/"+flavor[to_string(MOTD.phylum)]+">");
page.append("<br>Element: <span style=\"font-weight:bold; color:"+color[to_string(MOTD.defense_element)]+"\">"+MOTD.defense_element+"</span>");

//build a map for monster locations. eg MonLoc[$location[spooky forest]]=true
boolean [location] MonLoc;
foreach loc in $locations[]
	if (get_location_monsters(loc) contains MOTD)
		MonLoc[loc]=true;
if (count(MonLoc)==0)
	page.append("<br>Location: <b>unknown</b>");
else if (count(MonLoc)==1)
	foreach loc in MonLoc
		page.append("<br>Location: <b><a class=link title='wiki' target=_blank href=\"https://wiki.kingdomofloathing.com/"+loc+"\">"+loc+"</a></b>");
else{
	page.append("<br>Location:");
	foreach loc in MonLoc
		page.append("<br>🞄 <b><a class=link title='wiki' target=_blank href=\"https://wiki.kingdomofloathing.com/"+loc+"\">"+loc+"</a></b>");
	}	

//Meat drops
page.append("<br>Meat: <b>"+meat_drop(MOTD)+"</b>");
//Item drops. uses item_drops_array which exposes data/monsters.txt
page.append("<br>Drops:");
string [string] dropType = { "n":"no pp","c":"conditional","p":"pp only","m":"multidrop","f":"fixed rate","a":"stealable accordion"};
foreach a,it in item_drops_array(MOTD)
	page.append("<br>🞄 <span class=item onclick=descitem("+it.drop.descid+")>"+it.drop+"</span> ("+it.rate.to_string("%1.0f")+"%) <b>"+dropType[it.type]+"</b>");

//special attributes (No Banish, no copy, free fight, etc)
string monAtt;
string [string] monAbility= {
"NOBANISH":"<img src=/images/itemimages/divpopper.gif style=\"opacity: 0.5;\" title='NOBANISH'>", 
"FREE": "<img src=/images/itemimages/exclam.gif title='Free Fight'>", 
"Scale:": "<img src=/images/itemimages/scales.gif title=\"Scaling Cap: "+MOTD.attributes.group_string("Cap: (\\d+)")[0][1]+"\">", //Cap data is crap data (because mafia doesn't usually have it).
//"BOSS": "<img src=/images/itemimages/fig2_1.gif title='BOSS'>", //TP NS. use mon.boss proxy instead
//"NOCOPY" : "<img src=/images/itemimages/camera.gif style=\"opacity: 0.5;\" title='NOCOPY'>", //  use mon.copyable proxy instead
"NOWISH": "<img src=/images/itemimages/gbottle_cork.gif style=\"opacity: 0.5;\" title='NOWISH'>", 
"WANDERER": "<img src=/images/itemimages/footprints.gif title='WANDERER'>", //wandering monster, like Candied Yam Golem
};
foreach index,ability in split_string(MOTD.attributes," ")
	monAtt+=monAbility[ability];
if (MOTD.boss)
	monAtt+="<img src=/images/itemimages/fig2_1.gif title='BOSS'>"; //TP NS
if (!MOTD.copyable)
	monAtt+="<img src=/images/itemimages/camera.gif style=\"opacity: 0.5;\" title='NO COPY'>";
page.append("<p>"+monAtt);

//window resizing. copied from kol's desc_item.php.
page.append("<script type= \"text/javascript \">\
	<!--\
	var resizetries = 11;\
	var fsckinresize;\
	setTimeout(fsckinresize = function ()  {\
		var desch = document.body.offsetHeight;\
		if (desch < 100 && resizetries < 5) {\
			setTimeout(fsckinresize, 100);\
			resizetries++;\
		}\
		if (desch < 100) desch = 200; \
		//alert('resizing on try #' + resizetries);\
		if (self.resizeTo && window.outerHeight) { \
			self.resizeTo(400, desch + (window.outerHeight - window.innerHeight) + 50); \
		}\
		else if (self.resizeTo ) { self.resizeTo(400, desch+130); }\
		else { window.innerHeight = newh; }\
	}, 100);\
	//-->\
	</script>\
	</div>\
	</body>\
	<script src= \"/onfocus.1.js \"></script></html>");
page.write();
}


