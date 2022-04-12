

#USER INPUT Define the variables, list your different goals and properties

$Goal = 'Revenue vs Budget v2' #KPI Name
$Period = '2019' #Period (Year) for the KPI
$group = '0a8163db-27b6-46ca-9d61-c04873c531ec' #Workspace ID of the scorecard
$scorecard = '0af2c4bb-9751-42de-b9c2-bfe4b44a57f8' #Scorecard ID


#USER INPUT Define variables for the segments the goal will be scaled

$dataset = '110683dd-f71a-4c9e-ac8b-73ddf65a2fb2' #Dataset where your table is located
$Table = 'DimProduct'  #Table where your segments are located (usually a Dim table)
$Column = 'BrandName'   #Column where the segments are (specific dimension)



$timerstart = (Get-Date).DateTime

# Query the segments

$url = 'https://api.powerbi.com/v1.0/myorg/datasets/'+$dataset+'/executeQueries'

$body = '{
  "queries": [
    {
      "query": "EVALUATE VALUES('+$Table+'['+$Column+'])"
    }
  ],
  "serializerSettings": {
    "includeNulls": true
  }
}'    #DAX query to extract values from the tables in your dataset

$datasetquery = Invoke-PowerBIRestMethod -Url $url -Method POST -Body $body
$queryJSON = $datasetquery | ConvertFrom-Json
$segmentlist = $queryJSON.results.tables.rows


#Create the list of the 12 months

$Months = (Get-Culture).DateTimeFormat.AbbreviatedMonthNames
$MonthNames = $Months | select -SkipLast 1
$NextPeriod = [string]([int]$Period + 1) #will be used for the due dates
$GoalName = $Goal+' '+$Period


#Create the relation of each Segment for each month

$SegmentGoals = foreach( $s in $segmentlist) { $GoalName +' '+ $s.psobject.Properties.value }
$SegmentMonths = foreach($Seg in $segmentlist) { foreach($m in $MonthNames) { $Goal + ' ' + $m + ' '+$Period + ' '+$seg.psobject.Properties.value}}


#Create new goals per segment

$StartDate = $Period+'-01-01T00:00:00Z'
$EndDate = $NextPeriod+'-01-01T00:00:00Z'
$urlgoal = 'https://api.powerbi.com/v1.0/myorg/groups/'+ $group +'/scorecards/' + $scorecard +'/goals'
$loopgoal = foreach($s in $SegmentGoals) { $newbody = '{"name":"'+ $s +'","startDate":"'+$StartDate + '","completionDate":"'+$EndDate +'"}' ; Invoke-PowerBIRestMethod -Url $urlgoal -Method POST -Body $newbody}


#SubGoals Creation (one goal per month per segment)

$GoalsJSON = Invoke-PowerBIRestMethod -Url $urlgoal -Method GET
$Goals = $GoalsJSON | ConvertFrom-Json
$GoalsID = $Goals.value
$from = ($GoalsID.Count - $SegmentGoals.Count) ; $to = ($GoalsID.Count - 1)
$IDlastgoals = $GoalsID[$from..$to]
$loopsubgoals = foreach($ID in $IDlastgoals) { $i=1; $j=2  ; foreach($m in $MonthNames) { $m2 = $i++; $m3 = $j++ ; $stdate = $Period+'-'+$m2.ToString("00")+'-01T00:00:00Z' ;  $enDate = $Period+'-'+$m3.ToString("00")+'-01T00:00:00Z'; $subgoalbody = '{"name":"'+$ID.name.replace('2019',$m) +'","startDate":"'+ $stdate +'","completionDate":"'+ $enDate.Replace($Period+'-13',$NextPeriod+'-01')  +'","parentId":"'+$ID.id +'"}'; Invoke-PowerBIRestMethod -Url $urlgoal -Method POST -Body $subgoalbody }} 

$timerend = (Get-Date).DateTime

clear

[string]$loopgoal.Count + ' Goals and ' + [string]$loopsubgoals.Count +' subgoals loaded in '+ [string](New-TimeSpan -Start $timerstart -End $timerend).Minutes + ' minutes and '+ [string](New-TimeSpan -Start $timerstart -End $timerend).Seconds + ' seconds'