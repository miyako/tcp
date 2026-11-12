//%attributes = {"invisible":true}
#DECLARE($count : Integer)

var $start : Integer
$start:=Milliseconds:C459
While (Storage:C1525.ci.events.length<$count) && ((Milliseconds:C459-$start)<30000)
	DELAY PROCESS:C323(Current process:C322; 10)
End while 
