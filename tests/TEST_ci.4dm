//%attributes = {"invisible":true}
#DECLARE($params : Object)

//CI test, copied into the project by tests/run.sh; reads ci.json, writes ci_result.json

If (Count parameters:C259#0)
	TEST_ci_log("worker check")
	ON ERR CALL:C155("TEST_ci_err")
	var $worker : cs:C1710.tcp
	$worker:=cs:C1710.tcp.new()
	$worker.check($params.options; Formula:C1597(TEST_ci_cb($1; $2)))
	TEST_ci_log("worker check returned")
	return 
End if 

var $root : 4D:C1709.Folder
$root:=Folder:C1567(fk database folder:K87:14)
var $ci : Object
$ci:=JSON Parse:C1218($root.file("ci.json").getText())

Use (Storage:C1525)
	Storage:C1525.ci:=New shared object:C1526("events"; New shared collection:C1527; "errors"; New shared collection:C1527)
End use 

ON ERR CALL:C155("TEST_ci_err")

var $failures : Collection
$failures:=[]

TEST_ci_log("compile")
//compile (the release build uses the same 4D version)
var $compile : Object
var $target : Text
$target:=Is macOS:C1572 ? "arm64_macOS_lib" : "x86_64_generic"
$compile:=Compile project:C1760({targets: [$target]; generateSymbols: False:C215})
var $e : Object
For each ($e; $compile.errors)
	If ($e.isError)
		$failures.push("compile: "+String:C10($e.message)+" "+String:C10($e.code.path)+":"+String:C10($e.lineInFile))
	End if 
End for each 

var $tcp : cs:C1710.tcp
$tcp:=cs:C1710.tcp.new()

var $options : Collection
var $l : Object
var $i : Integer
var $res; $m : Collection

TEST_ci_log("sync")
//sync: listeners (user + root/SYSTEM) are found, free port is free
$options:=[]
For each ($l; $ci.listeners)
	$options.push({port: $l.port})
End for each 
$options.push({port: $ci.free})
$res:=$tcp.check($options)

For ($i; 0; $ci.listeners.length-1)
	$l:=$ci.listeners[$i]
	If ($res[$i]=Null:C1517)
		$failures.push("sync "+$l.label+": Null result, error="+String:C10($options[$i].error))
	Else 
		$m:=$tcp.get($l.port; JSON Parse:C1218($res[$i]; Is collection:K8:32))
		If ($m=Null:C1517) || (Not:C34($m.extract("PID").includes($l.pid)))
			$failures.push("sync "+$l.label+": PID "+String:C10($l.pid)+" not found on port "+String:C10($l.port))
		End if 
	End if 
End for 

$i:=$ci.listeners.length
If ($res[$i]=Null:C1517)
	$failures.push("sync free: Null result, error="+String:C10($options[$i].error))
Else 
	If ($tcp.get($ci.free; JSON Parse:C1218($res[$i]; Is collection:K8:32))#Null:C1517)
		$failures.push("sync free: port "+String:C10($ci.free)+" reported in use")
	End if 
End if 

TEST_ci_log("output")
//output file
var $file : 4D:C1709.File
$file:=$root.file("ci_out.json")
$l:=$ci.listeners[0]
$tcp.check({port: $l.port; output: $file})
$m:=$file.exists ? $tcp.get($l.port; JSON Parse:C1218($file.getText(); Is collection:K8:32)) : Null:C1517
If ($m=Null:C1517) || (Not:C34($m.extract("PID").includes($l.pid)))
	$failures.push("output: PID "+String:C10($l.pid)+" not found in file")
End if 

TEST_ci_log("async")
//async
var $expected : Integer
$expected:=$options.length
CALL WORKER:C1389("ci"; "TEST_ci"; {options: $options})
TEST_ci_wait($expected)

var $events : Collection
var $event : Object
$events:=Storage:C1525.ci.events.copy()
For each ($l; $ci.listeners)
	$event:=$events.query("port = :1"; $l.port).first()
	If ($event=Null:C1517) || ($event.success) || (Not:C34($event.PID.includes($l.pid)))
		$failures.push("async "+$l.label+": "+JSON Stringify:C1217($event))
	End if 
End for each 
$event:=$events.query("port = :1"; $ci.free).first()
If ($event=Null:C1517) || (Not:C34($event.success))
	$failures.push("async free: "+JSON Stringify:C1217($event))
End if 

TEST_ci_log("error sync")
//procs failure (broken bundled config) is reported, not "free"
var $config : 4D:C1709.File
$config:=$root.file("Resources/procs.toml")
var $saved : Blob
$saved:=$config.getContent()
$config.setText("broken = [")

$options:=[{port: $ci.free}]
$res:=$tcp.check($options)
If ($res[0]#Null:C1517) || ($options[0].error=Null:C1517) || (Num:C11($options[0].exitCode)=0)
	$failures.push("sync error: "+JSON Stringify:C1217({result: $res[0]; option: $options[0]}))
End if 

TEST_ci_log("error async")
$expected+=1
CALL WORKER:C1389("ci"; "TEST_ci"; {options: [{port: $ci.free}]})
TEST_ci_wait($expected)
$event:=Storage:C1525.ci.events.length=$expected ? Storage:C1525.ci.events[$expected-1] : Null:C1517
If ($event=Null:C1517) || ($event.success) || (String:C10($event.error)="")
	$failures.push("async error: "+JSON Stringify:C1217($event))
End if 

TEST_ci_log("restore")
$config.setContent($saved)

var $errors : Collection
$errors:=Storage:C1525.ci.errors.copy()
$root.file("ci_result.json").setText(JSON Stringify:C1217({success: ($failures.length=0) && ($errors.length=0); failures: $failures; errors: $errors; version: Application version:C493(*)}; *))

TEST_ci_log("quit")
QUIT 4D:C291
