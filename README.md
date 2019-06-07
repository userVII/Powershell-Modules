# Event_Logging.psm1
PowerShell module for easier File and Event Viewer logging

Basic ugly call.

Import-Module "\\PATHTOFILE\Event_Logger_Module.psm1" -Force

WriteLog "C:\User\Desktop" "Test log" "Info" $True "This is a test"

More robust and pretty

Import-Module "\\PATHTOFILE\Event_Logger_Module.psm1" -Force

$myargs = @{
  PathToLogFile = "C:\User\Desktop"; 
  EventLogSourceName = "Test log";
  WriteInEventViewer = $True
}

WriteLog @myargs -EventLevel:"Info" -StringToLog:"This is a test"

WriteLog @myargs -EventLevel:"Warn" -StringToLog:"This is a warn test"
