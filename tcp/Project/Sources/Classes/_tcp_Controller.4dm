property stdOut : Text
property stdErr : Text

Class extends _CLI_Controller

Class constructor($CLI : cs:C1710._CLI)
	
	Super:C1705($CLI)
	
	//no streaming callbacks: many small onData messages during wait() crash 4D 20.x; _onResponse reads $worker.response
	OB REMOVE:C1226(This:C1470; "onData")
	OB REMOVE:C1226(This:C1470; "onDataError")
	
	This:C1470.clear()
	
Function clear() : cs:C1710._tcp_Controller
	
	This:C1470.stdOut:=""
	This:C1470.stdErr:=""
	
	return This:C1470
	
Function onResponse($worker : 4D:C1709.SystemWorker; $params : Object)
	
Function onError($worker : 4D:C1709.SystemWorker; $params : Object)
	
Function onTerminate($worker : 4D:C1709.SystemWorker; $params : Object)
	