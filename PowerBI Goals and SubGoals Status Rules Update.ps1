
#USER INPUT Define the variables, list your different goals and properties

$group = 'xxxx-xxxxxx-xxxxxx-xxxxx' #Workspace ID of the scorecard
$scorecard = 'xxxxx-xxxxxx-xxxxxx-xxxxxx' #Scorecard ID
$namequerylike = '*XXXXXXXX*' #Name (or key word) of the goal we want to edit
$urlgoal = 'https://api.powerbi.com/v1.0/myorg/groups/'+ $group +'/scorecards/' + $scorecard +'/goals'


$timerstart = (Get-Date).DateTime

#Run the GET request to obtain all the goals that contain the key word

$GoalsJSON = Invoke-PowerBIRestMethod -Url $urlgoal -Method GET
$Goals = $GoalsJSON | ConvertFrom-Json
$GoalsID = $Goals.value | Where -Property name -like $namequerylike

#Extract the status rule in JSON from the status already created and split into parts excluding any date

$goalstatus = $GoalsID[0].statusRules.rules
$body1 = $goalstatus.Substring(0,($goalstatus.IndexOf('"dateTime":'))+12)
$body2 = $goalstatus.Substring($body1.Length+25,($goalstatus.substring($body1.Length+25, $goalstatus.Length - $body1.Length-25)).IndexOf('"dateTime":')+12)
$body3 = $goalstatus.Substring($body1.Length+25+$body2.Length+25,($goalstatus.substring($body1.Length+25+$body2.Length+25, $goalstatus.Length - $body1.Length-25 - $body2.Length - 25)).IndexOf('"dateTime":')+12)
$body4 = $goalstatus.Substring($body1.Length+25+$body2.Length+25+$body3.length+25,($goalstatus.substring($body1.Length+25+$body2.Length+25+$body3.length+25, $goalstatus.Length - $body1.Length-25 - $body2.Length - 25 -$body3.length-25)).IndexOf('"dateTime":')+12)
$body5 = $goalstatus.Substring($body1.Length+25+$body2.Length+25+$body3.length+25+$body4.length+25, $goalstatus.Length - $body1.Length-25 - $body2.Length - 25 -$body3.length-25 - $body4.Length - 25)


#Run the loop to POST the new status rule, merging the parts of the JSON file with the dates for each goal

$loopStatus = foreach($g in $GoalsID) {
$posturl = $urlgoal+"/"+$g.id+"/statusRules";
$postbody = $body1+$g.completionDate+$body2+$g.completionDate+$body3+$g.completionDate+$body4+$g.startDate+$body5;
Invoke-PowerBIRestMethod -Method POST -Url $posturl -Body $postbody
}

$timerend = (Get-Date).DateTime

clear

[string]$loopStatus.Count + ' Goal Statuses updated in '+ [string](New-TimeSpan -Start $timerstart -End $timerend).Minutes + ' minutes and '+ [string](New-TimeSpan -Start $timerstart -End $timerend).Seconds + ' seconds'
