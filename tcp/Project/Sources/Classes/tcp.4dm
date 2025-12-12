Class extends _CLI

Class constructor($controller : 4D:C1709.Class)
	
	If (Not:C34(OB Instance of:C1731($controller; cs:C1710._tcp_Controller)))
		$controller:=cs:C1710._tcp_Controller
	End if 
	
	Super:C1705("procs"; $controller)
	
Function get worker() : 4D:C1709.SystemWorker
	
	return This:C1470.controller.worker
	
Function terminate()
	
	This:C1470.controller.terminate()
	
Function get($port : Integer; $json : Collection) : Collection
	
	If ($json=Null:C1517)
		return 
	End if 
	
	var $filter : 4D:C1709.Function
	$filter:=Formula:C1597($1.result:=(JSON Parse:C1218($1.value.TCP; Is collection:K8:32).includes($2)))
	
	var $matches : Collection
	$matches:=$json.filter($filter; $port)
	
	If ($matches.length=0)
		return Null:C1517
	End if 
	
	return $matches
	
Function check($option : Variant; $formula : 4D:C1709.Function) : Collection
	
	var $stdOut; $isStream; $isAsync : Boolean
	var $options : Collection
	var $results : Collection
	$results:=[]
	
	Case of 
		: (Value type:C1509($option)=Is object:K8:27)
			$options:=[$option]
		: (Value type:C1509($option)=Is collection:K8:32)
			$options:=$option
		Else 
			$options:=[]
	End case 
	
	var $commands : Collection
	$commands:=[]
	
	This:C1470.controller.onResponse:=Formula:C1597(_onResponse)
	
	For each ($option; $options)
		
		If ($option=Null:C1517) || (Value type:C1509($option)#Is object:K8:27)
			continue
		End if 
		
		$stdOut:=Not:C34(OB Instance of:C1731($option.output; 4D:C1709.File))
		
		$command:=This:C1470.escape(This:C1470.executablePath)
		$command+=" --insert port --json"
		
		$option.data:={}
		$option.data.port:=$option.port
		$option.data.get:=This:C1470.get
		
		If (OB Instance of:C1731($formula; 4D:C1709.Function))
			$isAsync:=True:C214
			$option.data.onResponse:=$formula
		End if 
		
		var $worker : 4D:C1709.SystemWorker
		$worker:=This:C1470.controller.execute($command; $isStream ? $option.file : Null:C1517; $option.data).worker
		
		If (Not:C34($isAsync))
			$worker.wait()
		End if 
		
		If (Not:C34($isAsync))
			//%W-550.26
			//%W-550.2
			If ($stdOut)
				$results.push(This:C1470.controller.stdOut)
			Else 
				$results.push(Null:C1517)
			End if 
			This:C1470.controller.clear()
			//%W+550.2
			//%W+550.26
		End if 
		
	End for each 
	
	If (Not:C34($isAsync))
		return $results
	End if 