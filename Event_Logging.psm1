<#
    .Synopsis
        Allows for Event Viewer and local file logging

    .Description
         Allows for multiple levels of Event Viewer logging. Also, there is built in file logging
         which can be written to without adding to the Event Viewer; usually for mundane tasks

    .Parameter PathToLogFile
        The disc location to write the log file. Usually in the current users library somewhere.

    .Parameter EventLogSourceName
        What to name the log in the Event Viewer.

    .Parameter EventLevel
        The level of the event. Currently supports Info, Warn, Error

    .Parameter WriteInEventViewer
        A boolean (true, false) value for whether or not to write to the Event Viewer

    .Parameter WriteFileLog
        A boolean (true, false) value for whether or not to write a file log

    .Parameter StringToLog
        The string to write to the Event Viewer and/or the log file

    .Example
         # Basic ugly call.
         Import-Module "\\SOMELOCATION\Event_Logger_Module.psm1" -Force
         WriteLog "C:\User\Desktop" "Test log" "Info" $True "This is a test"

    .Example
         # More robust and pretty
         Import-Module "\\SOMELOCATION\Event_Logger_Module.psm1" -Force
         $myargs = @{
             PathToLogFile = "C:\User\Desktop"; 
             EventLogSourceName = "Test log";
             WriteInEventViewer = $True
         }
         WriteLog @myargs -EventLevel:"Info" -StringToLog:"This is a test"
         WriteLog @myargs -EventLevel:"Warn" -StringToLog:"This is a warn test"

    .Notes
        Version:  3
        Author:  userVII
        Creation Date:  02-15-2017
        Last Update:  06-07-2019

        Can use -Verbose with Import-Module to verify it gets imported. Sometime script permissions interfere
        Needs to run with Administrator rights on pc 
#>

function Setup_FileLogging($logFilePath){
    #Deletes log file if it gets too big
    if (Test-Path $logFilePath){
        $SizeMin = 10 #MB
        if($logFilePath -Like "*.log" -Or $logFilePath -Like "*.txt"){            
            Get-ChildItem -Path $logFilePath | Where-Object { $_.Length / 1MB -gt $SizeMin } | Remove-Item -Force
        }        
    }

    #Create log file if doesn't exist
    if (Test-Path $logFilePath){
        Write-Verbose "Log file exists, writing output to that"
    }elseif(!(Test-Path $logFilePath)) {
        Write-Verbose "Creating log file"
        New-Item $logFilePath -Force -ItemType File
    }else{
        Write-Warning "Something went wrong creating the log file"
    }
}

function Setup_EventLogging($eventLogName, $eventSourceName){
    #Create event log source if it doesn't exist
    if (! ([System.Diagnostics.EventLog]::SourceExists($eventSourceName))){
        New-EventLog –LogName $eventLogName –Source $eventSourceName
    } 
}

function Write_FileLog($logFilePath, $dateFormatted, $errorLevelString, $messageString){
    if (Test-Path $logFilePath){
        Add-content $logFilePath "($dateFormatted): $errorLevelString $messageString"
        Add-content $logFilePath ""
    }else{
        Write-Warning "Could not write to log file"
    }
}

function Write_EventViewerLog($eventLogName, $eventSourceName, $levelEntryTypeString, $levelValueInt, $errorLevelString, $messageString){
    if (([System.Diagnostics.EventLog]::SourceExists($eventSourceName))){
        Write-EventLog -LogName $eventLogName –Source $eventSourceName –EntryType $levelEntryTypeString –EventID $levelValueInt –Message “$errorLevelString $messageString”
    }else{
        Write-Warning "Could not write to Event Viewer"
    }
}

function WriteLog(){
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$PathToLogFile = "C:\General.Log",
    
    [Parameter(Mandatory=$false)]   
    [string]$EventLogSourceName = "General Log",
    
    [Parameter(Mandatory=$false)] 
    [string]$EventLevel = "Info",       

    [Parameter(Mandatory=$false)] 
    [switch]$WriteInEventViewer = $True,

    [Parameter(Mandatory=$false)] 
    [switch]$WriteFileLog = $True,

    [Parameter(Mandatory=$true)] 
    [string]$StringToLog
    )

    $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"    
    $LogName = "Custom Logs"

    $LevelText = ""
    $LevelValue = 0
    $LevelEntryType = ""
    
    switch ($EventLevel){ 
    "Error" { 
        Write-Warning $StringToLog 
        $LevelText = "ERROR:"
        $LevelValue = 3
        $LevelEntryType = "Error"
        break
        } 
    "Warn" { 
        Write-Warning $StringToLog
        $LevelText = "WARNING:"
        $LevelValue = 2
        $LevelEntryType = "Warning"
        break
        } 
    "Info" { 
        Write-Verbose $StringToLog 
        $LevelText = "INFO:"
        $LevelValue = 1
        $LevelEntryType = "Information"
        break
        }
    }

    if($WriteFileLog){
        Setup_FileLogging $PathToLogFile
        Write_FileLog $PathToLogFile $FormattedDate $LevelText $StringToLog
    }

    if($WriteInEventViewer){
        Setup_EventLogging $LogName $EventLogSourceName
        Write_EventViewerLog $LogName $EventLogSourceName $LevelEntryType $LevelValue $LevelText $StringToLog
    }
}

Export-ModuleMember -function WriteLog
