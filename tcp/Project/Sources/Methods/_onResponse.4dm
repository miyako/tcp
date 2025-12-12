//%attributes = {"invisible":true,"preemptive":"capable"}
#DECLARE($worker : 4D:C1709.SystemWorker; $params : Object)

var $text : Text
$text:=$worker.response
var $json : Collection
$json:=JSON Parse:C1218($text; Is collection:K8:32)
var $context : Object
$context:=$params.context
var $port : Integer
$port:=$context.port
var $get : 4D:C1709.Function
$get:=$context.get

var $matches : Collection
$matches:=$get.call(This:C1470; $port; $json)

var $PID : Collection
$PID:=$matches=Null:C1517 ? [] : $matches.extract("PID")

$context.onResponse.call(This:C1470; {success: $matches=Null:C1517; PID: $PID})