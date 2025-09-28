// adds expire date to skill descriptions, taken from other desc_ relay scripts.

void main(){

buffer page = visit_url();

string skil=page.group_string("<b>(.*?)<\/b>")[0][1]; //skill name (matching text between <b> tag)
string out=" <a href=\"https://wiki.kingdomofloathing.com/"+skil+"\" target='_blank' title='thekolwiki' style='float: right;'>[wiki]</a><br>";

string JSSSS="<script>document.write(new URL(window.location.href).searchParams.get(\"whichskill\") || '???');</script>";
page.replace_string("description\">","description\"># "+JSSSS+out);

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

page.replace_string("</blockquote>","<p>"+LAD+"</blockquote>");

//kol builds window sizes around the div in the popup (because its fetched in shop mouseovers), but we've added stuff and now the page scrolls. We'll using the size of <body> instead.
page.replace_string("document.getElementById('description').offsetHeight;","document.body.offsetHeight;");

page.write();
}
