//%attributes = {"invisible":true,"preemptive":"capable"}
#DECLARE() : Collection

//TCP listeners from netstat, which also sees sockets owned by root, other users and SYSTEM
//returns [{PID: Integer; ports: Collection; name: Text}], or Null if netstat failed

var $command; $pattern : Text
Case of 
	: (Is macOS:C1572)
		$command:="/usr/sbin/netstat -anv -p tcp"
		//tcp4 0 0 127.0.0.1.8080 *.* LISTEN ...; the port is the last dot-separated field
		$pattern:="^tcp\\S*\\s+\\d+\\s+\\d+\\s+\\S+\\.(\\d+)\\s+\\S+\\s+LISTEN\\s+(.*)$"
	: (Is Windows:C1573)
		$command:="netstat -ano"
		//TCP 0.0.0.0:80 0.0.0.0:0 LISTENING 4; listeners have foreign port 0 (state is localised)
		$pattern:="^\\s*TCP\\s+\\S+:(\\d+)\\s+\\S+:0\\s+\\S+\\s+(\\d+)\\s*$"
	Else 
		return Null:C1517
End case 

//runs inside onResponse: a nested SystemWorker.wait() there can crash 4D, LAUNCH EXTERNAL PROCESS doesn't pump messages
var $stdIn; $stdOut; $stdErr : Text
SET ENVIRONMENT VARIABLE:C812("_4D_OPTION_BLOCKING_EXTERNAL_PROCESS"; "true")
SET ENVIRONMENT VARIABLE:C812("_4D_OPTION_HIDE_CONSOLE"; "true")
LAUNCH EXTERNAL PROCESS:C811($command; $stdIn; $stdOut; $stdErr)

If (OK=0) || ($stdOut="")
	return Null:C1517
End if 

var $byPID : Object
$byPID:={}

ARRAY LONGINT:C221($pos; 0)
ARRAY LONGINT:C221($len; 0)

var $line; $rest; $name; $key : Text
var $port; $PID : Integer

For each ($line; Split string:C1554(Replace string:C233($stdOut; "\r"; ""; *); "\n"))
	
	If (Not:C34(Match regex:C1019($pattern; $line; 1; $pos; $len)))
		continue
	End if 
	
	$port:=Num:C11(Substring:C12($line; $pos{1}; $len{1}))
	$rest:=Substring:C12($line; $pos{2}; $len{2})
	$name:=""
	
	If (Is macOS:C1572)
		Case of 
			: (Match regex:C1019("^(?:\\d+\\s+)*(\\S.*?):(\\d+)\\s"; $rest; 1; $pos; $len))
				//rxbytes txbytes rhiwat shiwat process:pid ...
				$name:=Substring:C12($rest; $pos{1}; $len{1})
				$PID:=Num:C11(Substring:C12($rest; $pos{2}; $len{2}))
			: (Match regex:C1019("^\\d+\\s+\\d+\\s+(\\d+)\\s"; $rest; 1; $pos; $len))
				//older macOS: rhiwat shiwat pid epid ...
				$PID:=Num:C11(Substring:C12($rest; $pos{1}; $len{1}))
			Else 
				continue
		End case 
	Else 
		$PID:=Num:C11($rest)
	End if 
	
	$key:=String:C10($PID)
	If ($byPID[$key]=Null:C1517)
		$byPID[$key]:={PID: $PID; ports: []; name: $name}
	End if 
	If (Not:C34($byPID[$key].ports.includes($port)))
		$byPID[$key].ports.push($port)
	End if 
	
End for each 

return OB Values:C1718($byPID)
