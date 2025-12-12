//%attributes = {"invisible":true}
#DECLARE($params : Object)

If (Count parameters:C259=0)
	
	//execute in a worker to process callbacks
	CALL WORKER:C1389(1; Current method name:C684; {})
	
Else 
	
	var $tcp : cs:C1710.tcp
	$tcp:=cs:C1710.tcp.new()
	$tcp.check({port: 8080}; Formula:C1597(onResponse))
	
End if 