# Define the Sysmon Event ID for File Creation
$eventID = 11

# Define the date range for filtering
$startDate = Get-Date "2024-10-04"
$endDate = Get-Date "2024-10-06"

# Retrieve Sysmon file creation events from Event Viewer
$fileEvents = Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -FilterXPath "*[System[(EventID=$eventID)]]"

# Create an array to store the parsed data
$fileData = @()

# Loop through each event and extract relevant information
foreach ($event in $fileEvents) {
    $eventXml = [xml]$event.ToXml()

    # Extract required fields
    $utcTime = $event.TimeCreated.ToUniversalTime()
    
    # Filter by date range
    if ($utcTime -ge $startDate -and $utcTime -le $endDate) {
        $filePath = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'TargetFilename' } | Select-Object -ExpandProperty '#text'
        
        # Filter for .exe files only
        if ($filePath -like "*.exe") {
            $processID = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'ProcessId' } | Select-Object -ExpandProperty '#text'
            $image = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'Image' } | Select-Object -ExpandProperty '#text'
            $user = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'User' } | Select-Object -ExpandProperty '#text'

            # Add the data to the array
            $fileData += [PSCustomObject]@{
                UTCTime      = $utcTime
                FilePath     = $filePath
                ProcessID    = $processID
                Image        = $image
                User         = $user
            }
        }
    }
}

# Display the data in a table format
$fileData | Format-Table -AutoSize
