// insterts wiki and mall links to item description. exposes item ID and Last Available Date (from in html comments). optioanlly adds pricegun and other item hints, also LAD is optional too. 

void pricegunJS(buffer page, string itemid){
//uses ajax to make the waiting less bad for real time price checks. we're not storing any data
page.replace_string("</head>","</head>\n<script src=\"https://cdn.jsdelivr.net/npm/plotly.js-dist-min@2.32.0\"></script>");
string jsFetch="\
  <script>\
    apiUrl = 'https://pricegun.loathers.net/api/"+itemid+"';\
    console.log(apiUrl);\
function printTimeAgo(pastDate) {\
  const now = new Date();\
  const diffMs = now - pastDate;\
  const secs = Math.floor(diffMs / 1000) % 60;\
  const mins = Math.floor(diffMs / (1000 * 60)) % 60;\
  const hrs  = Math.floor(diffMs / (1000 * 60 * 60)) % 24;\
  const days = Math.floor(diffMs / (1000 * 60 * 60 * 24));\
  return `${days}d ${hrs}h ${mins}m ago`;\
}\
    async function PGAPI() {\
        try {\
        const data = await $.getJSON(apiUrl);\
        //var lastsold=data.sales[0].unitPrice;\
        var lastsold=data.value.__decimal__\
        var altText=\"Last sale: \"+data.sales[0].quantity+\" sold @ \"+data.sales[0].unitPrice.__decimal__+\" meat, \"+printTimeAgo(new Date(data.sales[0].date));\        $('#priceGun').attr('title',altText).text(parseInt(lastsold).toLocaleString('en-US', {minimumFractionDigits: 0})+' meat / '+data.volume.toLocaleString()+' sold').css('cursor', 'pointer').one('click', function() {\
//	alert(altText);\
function drawWhenResized() {\
  window.removeEventListener('resize', drawWhenResized);\
  loadGraph(data);//graph is loaded into #description\
}\
window.resizeTo(750, 600);\
$('#description').empty();\
window.addEventListener('resize', drawWhenResized);\
	});\
        $('#priceGun').text(data.error);\
        console.log(altText);\
		}\
		catch (error) {\
			if (error.status==404)\
            	$('#priceGun').text(error.responseJSON.error);\
            else\
            	$('#priceGun').text('Pricegun returned: error '+error.status);\
            console.log(error);\
        }\
	}\
    $(document).ready(function() {\
      PGAPI();\
    });\
</script>";

page.replace_string("</body>",jsFetch+"</body>");
}

void main(){

buffer page = visit_url();

page.replace_string("</head>","\n<script src=\"https://code.jquery.com/jquery-3.6.4.min.js\"></script>\n</head>");
page.replace_string("</head>","<link rel=\"stylesheet\" type=\"text/css\" href=\"desc.css\"></head>");

page.replace_string("</blockquote>","<tagdn></blockquote>");//<tagdn> is the hook for our addons.

if (to_boolean(get_property("dnShowLAD"))){
//oh boy, last available date. if blank or not found, it is "evergreen" (?)
string LAD=page.group_string("<[^<>]+Last Available Date: (\\w+-\\w+)[^<>]+>")[0][1];
if (LAD=="")
	LAD="Last Available Date: <font style=\"color:black; font-weight:bold;\" title='probably'>Evergreen</font>";
else if (now_to_string('YYYY') <= to_int(format_date_time('YYYY-MM',LAD,'YYYY'))+2)
	LAD="Last Available Date: <font style=\"color:black; font-weight:bold\">"+LAD+"</font>";
else
	LAD="Last Available Date: <font style=\"color:grey; font-weight:bold\">"+LAD+"</font>";
page.replace_string("<tagdn>","<tagdn><p>"+LAD);//want this to be last.
}

//negative item ids are possible (npc shops)
string itemid=page.group_string("<[^<>]+itemid: (-?\\d+)[^<>]+>")[0][1]; 
item descIt=to_item(itemid); //convert parsed item id to mafia item 

string wiki="<a href=\"https://wiki.kingdomofloathing.com/"+descIt.name+"\" target=\"_blank\" style=\"float: right;\">[wiki]</a>";
string pg_mall=(descIt.tradeable ? "<span id=priceGun></span><a href=\"mall.php?pudnuggler="+url_encode(descIt.name)+"\" target=\"mainpane\" style=\"float: right;\">[mall]</a>": "");

string [string] DIP={
	"pricegun (<b>unsupported</b>)":"dnUsePricegun",
	"consumable helper":"dnShowAdvs",
	"show \"Drops from\"":"dnShowDrops",
	"show Standard dates":"dnShowLAD",
	};
string mbox="<form id=\"descMenu\"><div id=menuBox>";
foreach str,P in DIP
	mbox+="<label><input type=\"checkbox\" "+(get_property(P)=="true"?"checked":"")+" id=\""+P+"\">"+str+"</label><br>";	
mbox+="</div></form>";
page.replace_string("<body>","<body><div id=icon>☰</div> "+mbox+itemid+wiki+"<br>"+pg_mall+"<br>");


if (to_boolean(get_property("dnShowAdvs"))){
//add in hint for (base) adv range and adv/full.
if ( descIt.adventures > 0 ){
	//matches text in desc based on item type (eg a "food" will match for the text "Size:")
	static string[string] consumeType = {
	  "food": "Size:",
	  "booze":"Potency:",
	  "spleen item":"Toxicity:",
	  };
	string typeC=consumeType[item_type(descIt)];

	float counter=0;
	//computes the average from size 1 or 2 array. either (0+value)/1 or (value1+value2)/2 depending on the array length
	foreach c,d in split_string(descIt.adventures,"-")
		counter=(counter+to_int(d))/(c+1);
	//actual calculation is the sum of full+drunk+spleen. usually 2 of the 3 are "0"
	counter/=max(1,descIt.fullness+descIt.inebriety+descIt.spleen);//set denominator to 1 if 0 to avoid divide by zero errors
//	print(counter); //for debugging

	string specialOut; //show mafia's special categories handling as "notes" if keywords are found in the word jumble below
	foreach index,attr in split_string(descIt.notes,", ")
		if ( contains_text("BEANSCANNEDBEERLASAGNAMARTINIPIZZASALADSAUCYTACOWINE",attr) ) //Beans Canned Beer ...
			specialOut+=to_lower_case(attr)+" ";
	//format and display if it isn't all just spaces.
	specialOut=( (length(specialOut)>=4) ? "Category: <b>"+specialOut+"</b><br>" : "" );

	page.replace_string(typeC,specialOut+"Advs: <b>"+descIt.adventures+"</b> ("+to_string(counter,"%.1f")+" adv/full)<br>"+typeC);
	}
}
//adds link to familiar for non-generic familiar equipment items
if (item_type(descIt) == "familiar equipment"){
	matcher famMatch=create_matcher("<br>Familiar: <b>([^<]*)</b>",page);
	if (famMatch.find()){
		string fam=famMatch.group(1);
		if (fam != "any"){
			int famID=to_familiar(fam).id;
			page.replace_string(famMatch.group(0),"<br>Familiar: <b><a class=nounder href=desc_familiar.php?which="+famID+">"+famMatch.group(1)+"</a></b>");
		}
	}
}


if (to_boolean(get_property("dnShowDrops"))){

//Avatar preview. Looks through monsters for item drop to determine image to preview. Mostly works
monster MOTD;//monster of the day
if (item_type(descIt)=="avatar potion"){
foreach mon in $monsters[]
	if (item_drops(mon) contains descIt){
		MOTD=mon;
		break;
		}
page.replace_string("<tagdn>","<center><br><img src=/images/adventureimages/"+MOTD.image+" onerror=\"this.style.display='none'\"><br><b style='cursor: pointer;' onclick=poop('desc_mon.php?mon="+MOTD.id+"','',400,400,'')>"+MOTD+"</b></center><tagdn>");
}
else {
//shows the monster that drops this item (if it isn't an avatar potion). desc_mon is a relay script
boolean [monster] MonMen;
	foreach mon in $monsters[]
		if (item_drops(mon) contains descIt)
			MonMen[mon]=true;
	if (count(MonMen)==1)
		foreach mon in MonMen
			page.replace_string("<tagdn>","<br>Drops from: <b style='cursor: pointer;' onclick=poop('desc_mon.php?mon="+mon.id+"','',400,350,'')>"+mon+"</b><tagdn>");
	else if (count(MonMen)>1){
		page.replace_string("<tagdn>","<br>Drops from: <tagdn>");
		foreach mon in MonMen
			page.replace_string("<tagdn>","<br>🞄 <b style='cursor: pointer;' onclick=poop('desc_mon.php?mon="+mon.id+"','',400,400,'')>"+mon+"</b><tagdn>");
		}
}

if (descIt.is_npc_item()){
	int [string] [string] [item] npcStore;
	file_to_map("data/npcstores.txt", npcStore);
	foreach seller,b,c in npcStore {
	if (c==descIt){
		page.replace_string("<tagdn>","<br>Source: <b>"+seller+"</b>&nbsp;("+to_string(npcStore[seller][b][c],"%,d")+"&nbsp;meat)<tagdn>");
		break;
		}
	}
}

if (descIt.is_coinmaster_item())
	page.replace_string("<tagdn>","<br>Source: <b>"+descIt.seller+"</b><tagdn>");
else if (craft_type(descIt)!="[cannot be created]" && descIt!=$item[none]){
/*
if it's craftable, it's usually A + B, except for multi-use things, and sushi (but sushi isn't real), and gnomish super tinkering (uses 3 items).
special clause for multi use and general case for everything else.
general case checks if items aren't "none" to at least make the page look okay. 
are craftable items ever sold by npc stores?

bugs:
"TERMINAL" type fails b/c it isn't flagged as mult-use and "source essence (10)" isn't an item
wads are wrong (spooky wad = Created by Malus of Forethought: twinkly wad, cold wad) b/c concoctions.txt has 2 creation methods and maps can only have 1 key.
bottle of ___ fails b/c the map key is "bottle of gin (3)", a non-item. 
making marbles fail b/c it's actually multi-use but labled as single use? "brown crock marble	SUSE	green peawee marble (2)"
brickos monsters are wrong b/c matching is complicated and I'm just passing along the string of item 2, which most multi-use recipies don't have
"Summon Clip Art" is wrong: "toasted brie	CLIPART	5	5	6" = "Summon Clip Art: pasta spoon, pasta spoon, ravioli hat"
*/
	if (craft_type(descIt)=="Summon Clip Art")
		page.replace_string("<tagdn>","<br>Created by "+craft_type(descIt)+"<tagdn>");
	else if ( contains_text(craft_type(descIt),"multi-use") ){
		record resultz {string action; string thing1; string thing2;};
		resultz [item] instructable;
		file_to_map("data/concoctions.txt", instructable);
		matcher museThing=create_matcher("(.+?) \\((\\d+)\\)", instructable[descIt].thing1 );
		if (museThing.find()){
			item itt1=to_item(museThing.group(1));
			string museNum=museThing.group(2);
			page.replace_string("<tagdn>","<br>Created by "+craft_type(descIt)+": <span style=\"cursor: pointer; font-weight:bold;\" onclick=item("+itt1.descid+")>"+itt1+"</span> (x"+museNum+") "+(instructable[descIt].thing2!=""?instructable[descIt].thing2:"")+"<tagdn>");
		}
	}
	else{
		record resultz {string action; item it1; item it2; item it3;};
		resultz [item] instructable;
		file_to_map("data/concoctions.txt", instructable);

		item itt1=instructable[descIt].it1;
		item itt2=instructable[descIt].it2;
		item itt3=instructable[descIt].it3;
		page.replace_string("<tagdn>","<br>Created by "+craft_type(descIt)+
		(itt1!=$item[none]?": <span style=\"cursor: pointer; font-weight:bold;\" onclick=item("+itt1.descid+")>"+itt1+"</span>":"")+
		(itt2!=$item[none]?", <span style=\"cursor: pointer; font-weight:bold;\" onclick=item("+itt2.descid+")>"+itt2+"</span>":"")+
		(itt3!=$item[none]?", <span style=\"cursor: pointer; font-weight:bold;\" onclick=item("+itt3.descid+")>"+itt3+"</span>":"")+
		"<tagdn>");
	}
//print(descIt+": "+ craft_type(descIt));
}

// do we care about zap and fold groups? I don't
//foreach it in get_related(descIt, "zap") // "zap" or "fold",??
//	print("> "+it);
}
if (to_boolean(get_property("dnUsePricegun")) && descIt.tradeable)
	pricegunJS(page,itemid);

//kol builds window sizes around the div in the popup (because its fetched in shop mouseovers), but we've added stuff and now the page scrolls. We'll use size of <body> instead
page.replace_string("document.getElementById('description').offsetHeight;","document.body.offsetHeight;");
page.replace_string("</body>","<script src=desc.js></script></body>");
page.replace_string("var resizetries = 0;","var resizetries = 11;");
page.write();
}


