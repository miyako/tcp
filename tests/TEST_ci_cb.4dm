//%attributes = {"invisible":true}
#DECLARE($status : Object; $option : Object)

Use (Storage:C1525.ci.events)
	Storage:C1525.ci.events.push(OB Copy:C1225($status; ck shared:K85:29; Storage:C1525.ci.events))
End use 
