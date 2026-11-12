//%attributes = {"invisible":true,"preemptive":"capable"}
#DECLARE($worker : 4D:C1709.SystemWorker; $params : Object)

//This is the controller

var $context : Object
$context:=$params.context
var $port : Integer
$port:=$context.port

var $text : Text
$text:=$worker.response

var $json : Collection
//exitCode may not be set yet when onResponse fires
If (Num:C11($worker.exitCode)=0) && (Match regex:C1019("^\\s*\\[[\\s\\S]*\\]\\s*$"; $text; 1))
	$json:=JSON Parse:C1218($text; Is collection:K8:32)
End if 

var $error : Text
If ($json=Null:C1517)
	$error:=String:C10($worker.responseError)
	ARRAY LONGINT:C221($pos; 0)
	ARRAY LONGINT:C221($len; 0)
	If (Match regex:C1019("^\\s*([\\s\\S]*?)\\s*$"; $error; 1; $pos; $len))
		$error:=Substring:C12($error; $pos{1}; $len{1})
	End if 
	If ($error="")
		$error:="procs returned no data"
	End if 
	$context.data.error:=$error
	This:C1470.stdOut:=""
Else 
	//procs only sees processes the current user can inspect; add listeners owned by root, other users or SYSTEM
	If (_merge($json; _listeners()))
		$text:=JSON Stringify:C1217($json)
		This:C1470.stdOut:=$text
	End if 
	If (OB Instance of:C1731($context.data.output; 4D:C1709.File))
		$context.data.output.setText($text)
	End if 
End if 

If (OB Instance of:C1731($context.onResponse; 4D:C1709.Function))
	var $status : Object
	If ($json=Null:C1517)
		$status:={success: False:C215; PID: []; port: $port; error: $error}
		If ($worker.exitCode#Null:C1517)
			$status.exitCode:=$worker.exitCode
		End if 
	Else 
		var $get : 4D:C1709.Function
		$get:=$context.get
		var $matches : Collection
		$matches:=$get.call(Null:C1517; $port; $json)
		$status:={success: $matches=Null:C1517; PID: $matches=Null:C1517 ? [] : $matches.extract("PID"); port: $port}
	End if 
	$context.onResponse.call(This:C1470; $status; $context.data)
	//async results are delivered via $worker.response
	This:C1470.clear()
End if 
