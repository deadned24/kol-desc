// insterts pricegun data, as well as wiki and mall links to item description. Also exposes item ID and Last Available Date (from in html comments)

/*
first run of the day (first item you look at), script will download pricegun data and generate data file. 
set "useRealTime" to 'true' for real time price checking. it is very slow though.
*/

//remove pricegun, stub pricegun functions
boolean useRealTime=false;
boolean usePricegun=false;//to_boolean(get_property("dnUsePricegun"));//if property is not set, it is false


record salez {int price; int volume;};

void buildPrices(){
//creates a data file from pricegun.loathers.net when called
print("updating pricegun data ...");

salez [string] mapi;//map api

string a=visit_url("https://pricegun.loathers.net/api/all");
//string a='[ { "value": 81364629.79381362, "volume": 888, "date": "2025-05-14T23:29:56.607Z", "itemId": 194 }, { "value": 82368171.50536558, "volume": 20, "date": "2025-05-14T23:29:56.607Z", "itemId": 11904 }, ...';

foreach x,str in split_string(a,"}"){
	matcher m1=create_matcher( "\"itemId\": (\\d+)", str );
	matcher m2=create_matcher( "\"value\": \"(\\d+\\.\\d+)\"", str );
	matcher m3=create_matcher( "\"volume\": (\\d+)", str );
	if (find(m1) && find(m2) && find(m3))
		mapi[m1.group(1)]=new salez(to_int(m2.group(1)), to_int(m3.group(1)));
	}
map_to_file(mapi,"dn_pricegunz");

print("done");
set_property("_pricegunz", "true" );
}

salez returnPrice(string itemid){
//real time item checking. is. very. slow.
string a=visit_url("https://pricegun.loathers.net/api/"+itemid);
//string a='{ "value": 999.8897091383719, "volume": 9, "date": "2025-05-24T06:15:49.180Z", "itemId": 11596}
print("checking pricegun.loathers.net for \""+to_item(itemid)+"\"");
foreach x,str in split_string(a,"}"){
	matcher m2=create_matcher( "\"value\": (\\d+)", str );
	matcher m3=create_matcher( "\"volume\": (\\d+)", str );
	if (find(m2) && find(m3))
		return new salez(to_int(m2.group(1)), to_int(m3.group(1)));
	}
return new salez(0,0);
}

void main(){

//remove pricegun, stub pricegun functions
/*
if ( !useRealTime && !to_boolean(get_property("_pricegunz")) && usePricegun )
	buildPrices();

buffer page = visit_url();

salez [string] mapi;//map api
if (usePricegun)
	file_to_map("dn_pricegunz", mapi);
*/	
buffer page = visit_url();
salez [string] mapi;//map api
	

//oh boy, last available date. if blank or not found, it's "evergreen" (?)
string LAD=page.group_string("<[^<>]+Last Available Date: (\\w+-\\w+)[^<>]+>")[0][1];
if (LAD=="")
	LAD="Last Available Date: <font style=\"color:black; font-weight:bold;\" title='probably'>Evergreen</font>";
else if (now_to_string('YYYY') <= to_int(format_date_time('YYYY-MM',LAD,'YYYY'))+2)
	LAD="Last Available Date: <font style=\"color:black; font-weight:bold\">"+LAD+"</font>";
else
	LAD="Last Available Date: <font style=\"color:grey; font-weight:bold\">"+LAD+"</font>";

//negative item ids are possible (npc shops)
string itemid=page.group_string("<[^<>]+itemid: (-?\\d+)[^<>]+>")[0][1]; 
if (useRealTime)
	mapi[itemid]=returnPrice(itemid);

item descIt=to_item(itemid); //convert parsed item id to mafia item 

string itemprice="";
if (usePricegun || useRealTime)
	itemprice=(mapi[itemid].price==0 ? (descIt.tradeable ? "<i>0 sold in past 2 weeks</i>" : " ") : "<span title=\"~"+to_string(mapi[itemid].volume/14,"%,d")+" /day\">"+to_string(mapi[itemid].volume,"%,d")+" sold</span>/ "+to_string(mapi[itemid].price,"%,d")+" meat");

	
string wiki="<a href=\"https://wiki.kingdomofloathing.com/"+descIt.name+"\" target=\"_blank\" style=\"float: right;\">[wiki]</a>";
string mall=(descIt.tradeable ? "<a href=\"mall.php?pudnuggler="+url_encode(descIt.name)+"\" target=\"mainpane\" style=\"float: right;\">[mall]</a>": "");

page.replace_string("<body>","<body># "+itemid+wiki+"<br>"+itemprice+mall+"<br>");
page.replace_string("</blockquote>","<br>"+LAD+"</blockquote>");

//add in hint for (base) adv range and adv/full.
if ( descIt.adventures > 0 ){
//bug: Schrödinger's thermos fails because inebriety and fullness are 0, but adventures is not blank. wont fix
	string typeC=(descIt.fullness>=descIt.inebriety ? "Size:" : "Potency:");
	if (descIt.spleen>0) 
		typeC="Toxicity:"; 
	float counter=0;
	//computes the average from size 1 or 2 array. either (0+value)/1 or (value1+value2)/2 depending on the array length
	foreach c,d in split_string(descIt.adventures,"-")
		counter=(counter+to_int(d))/(c+1);
	//actual calculation is the sum of full/drunk/spleen. usually 2 of the 3 are "0"
	counter/=max(1,descIt.fullness+descIt.inebriety+descIt.spleen);//set denominator to 1 if 0 to avoid divide by zero errors
//	print(counter);

	string specialOut; //show mafia's special categories handling as "notes" if keywords are found in the word jumble below
	foreach index,attr in split_string(descIt.notes,", ")
		if ( contains_text("BEANSCANNEDBEERLASAGNAMARTINIPIZZASALADSAUCYTACOWINE",attr) ) //Beans Canned Beer ...
			specialOut+=to_lower_case(attr)+" ";
	//format and display if it isn't all just spaces.
	specialOut=( (length(specialOut)>=4) ? "Category: <b>"+specialOut+"</b><br>" : "" );

	page.replace_string(typeC,specialOut+"Advs: <b>"+descIt.adventures+"</b> ("+to_string(counter,"%.1f")+" adv/full)<br>"+typeC);
	}
	
//kol builds window sizes around the div in the popup (because its fetched in shop mouseovers), but we've added stuff and now the page scrolls. We'll use size of <body> instead
page.replace_string("document.getElementById('description').offsetHeight;","document.body.offsetHeight;");
page.write();
}
