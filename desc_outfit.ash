//fancies up outfit display by showing ID (via javascript) and parts (through mafia) as well as a wiki link
buffer page = visit_url();

string outFit=page.group_string("<br><b>([^\\<]+)</b>")[0][1];

string JSSSS="<script>document.write(new URL(window.location.href).searchParams.get(\"whichoutfit\") || '???');</script>";
string wiki="<a href=\"https://wiki.kingdomofloathing.com/"+outFit+"\" target=\"_blank\" style=\"float: right;\">[wiki]</a><br>";
page.replace_string("description\">","description\"># "+JSSSS+wiki);

string out="<br></center><dl><dt><center>Outfit Parts:</center></dt>";
foreach _,it in outfit_pieces(outFit) out+="<dd><a style=\"text-decoration: none;\" href=desc_item.php?whichitem="+it.descid+">"+it+"</a></dd>";
out+="</dl><center>";

page.replace_string("<p>Outfit Bonus",out+"<p>Outfit Bonus");

page.replace_string("document.getElementById('description').offsetHeight;","document.body.offsetHeight;");
page.write();
