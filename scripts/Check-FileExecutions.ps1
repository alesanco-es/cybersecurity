# Define the Sysmon Event ID for Process Creation (Event ID 1)
$eventID_ProcessCreation = 1

# Get the list of .exe files from the previous script (file creation events)
$exeFiles = @(
    "C:\Program Files\Wireshark\Wireshark.exe",
    "C:\Users\xxx\Downloads\Wireshark-4.4.0-x64.exe"
    # Add more file paths as needed from the previous output
)

# Retrieve Sysmon process creation events from Event Viewer
$processEvents = Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -FilterXPath "*[System[(EventID=$eventID_ProcessCreation)]]"

# Create an array to store the matching process executions
$executedFiles = @()

# Loop through each process creation event and check if the executable was run
foreach ($event in $processEvents) {
    $eventXml = [xml]$event.ToXml()

    # Extract the image (executable) path
    $image = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'Image' } | Select-Object -ExpandProperty '#text'

    # Check if the executable matches one of the created files
    if ($exeFiles -contains $image) {
        $utcTime = $event.TimeCreated.ToUniversalTime()
        $processID = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'ProcessId' } | Select-Object -ExpandProperty '#text'
        $commandLine = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'CommandLine' } | Select-Object -ExpandProperty '#text'
        $user = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'User' } | Select-Object -ExpandProperty '#text'

        # Add the data to the array
        $executedFiles += [PSCustomObject]@{
            UTCTime      = $utcTime
            Executable   = $image
            ProcessID    = $processID
            CommandLine  = $commandLine
            User         = $user
        }
    }
}

# Display the data in a table format
$executedFiles | Format-Table -AutoSize
