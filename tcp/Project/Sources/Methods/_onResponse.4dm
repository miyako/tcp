//%attributes = {"invisible":true,"preemptive":"capable"}
#DECLARE($worker : 4D:C1709.SystemWorker; $params : Object)

var $text : Text
$text:=$worker.response
var $context : Object
$context:=$params.context

If (OB Instance of:C1731($context.data.output; 4D:C1709.File))
	$context.data.output.setText($text)
End if 

var $json : Collection
$json:=JSON Parse:C1218($text; Is collection:K8:32)
var $port : Integer
$port:=$context.port
var $get : 4D:C1709.Function
$get:=$context.get

var $matches : Collection
$matches:=$get.call(This:C1470; $port; $json)

var $PID : Collection
$PID:=$matches=Null:C1517 ? [] : $matches.extract("PID")

If (OB Instance of:C1731($context.onResponse; 4D:C1709.Function))
	$context.onResponse.call(This:C1470; {success: $matches=Null:C1517; PID: $PID; port: $port}; $context.data)
	//async results are delivered via $worker.response; This is the controller
	This:C1470.clear()
End if 