//%attributes = {"invisible":true,"preemptive":"capable"}
#DECLARE($status : Object; $port)

If ($status.success)
	
	ALERT:C41("OK!")
	
Else 
	
	ALERT:C41("port is already used by process "+$status.PID.join(","))
	
End if 