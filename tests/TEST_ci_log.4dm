//%attributes = {"invisible":true}
#DECLARE($step : Text)

//append a progress line, so a crash or hang shows the last step reached
var $file : 4D.File
$file:=Folder(fk database folder).file("ci_trace.txt")
$file.setText(($file.exists ? $file.getText() : "")+String(Milliseconds)+" "+Current process name+" "+$step+"\n")
