//%attributes = {"invisible":true,"preemptive":"capable"}
#DECLARE($json : Collection; $listeners : Collection) : Boolean

//adds listeners missing from the procs result; returns True if $json was modified

If ($json=Null:C1517) || ($listeners=Null:C1517)
	return False:C215
End if 

var $modified : Boolean
var $listener; $entry : Object
var $ports : Collection
var $port : Integer

For each ($listener; $listeners)
	
	$entry:=$json.find(Formula:C1597($1.result:=($1.value.PID=$2)); $listener.PID)
	
	If ($entry=Null:C1517)
		$json.push({PID: $listener.PID; TCP: JSON Stringify:C1217($listener.ports.orderBy()); Command: $listener.name})
		$modified:=True:C214
		continue
	End if 
	
	If (Match regex:C1019("^\\[[\\d, ]*\\]$"; String:C10($entry.TCP); 1))
		$ports:=JSON Parse:C1218($entry.TCP; Is collection:K8:32)
	Else 
		$ports:=[]
	End if 
	
	var $added : Boolean
	$added:=False:C215
	For each ($port; $listener.ports)
		If (Not:C34($ports.includes($port)))
			$ports.push($port)
			$added:=True:C214
		End if 
	End for each 
	
	If ($added)
		$entry.TCP:=JSON Stringify:C1217($ports.orderBy())
		$modified:=True:C214
	End if 
	
End for each 

return $modified
