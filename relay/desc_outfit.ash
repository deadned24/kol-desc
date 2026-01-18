//fancies up outfit display by showing ID and parts (through mafia) as well as a wiki link
buffer page = visit_url();

page.replace_string("</head>","\n<script src=\"https://code.jquery.com/jquery-3.6.4.min.js\"></script>\n</head>");
page.replace_string("</head>","<link rel=\"stylesheet\" type=\"text/css\" href=\"desc.css\"></head>");

string outFit=page.group_string("<br><b>([^\\<]+)</b>")[0][1];

string [string] DIP={
//	"pricegun (<b>unsupported</b>)":"dnUsePricegun",
//	"consumable helper":"dnShowAdvs",
	"show outfit parts":"dnShowDrops",
//	"show Standard dates":"dnShowLAD",
	};
string mbox="<form id=\"descMenu\"><div id=menuBox>";
foreach str,P in DIP
	mbox+="<label><input type=\"checkbox\" "+(get_property(P)=="true"?"checked":"")+" id=\""+P+"\">"+str+"</label><br>";	
mbox+="</div></form>";

string outID= form_field("whichoutfit");
string wiki="<a href=\"https://wiki.kingdomofloathing.com/"+outFit+"\" target=\"_blank\" style=\"float: right;\">[wiki]</a><br>";
page.replace_string("description\">","description\"><div id=icon>☰</div> "+mbox+outID+wiki);

if (to_boolean(get_property("dnShowDrops"))){
string out="<br></center><dl><dt><center>Outfit Parts:</center></dt>";
foreach _,it in outfit_pieces(outFit) 
	out+="<dd>• <a style=\"text-decoration: none;\" href=desc_item.php?whichitem="+it.descid+">"+it+"</a></dd>";
out+="</dl><center>";

page.replace_string("<p>Outfit Bonus",out+"<p>Outfit Bonus");
}

page.replace_string("document.getElementById('description').offsetHeight;","document.body.offsetHeight;");
page.replace_string("</body>","<script src=desc.js></script></body>");
page.write();
