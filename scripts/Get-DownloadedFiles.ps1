# Define the Sysmon Event ID for File Creation (Event ID 11)
$eventID = 11

# Define the date range for filtering
$startDate = Get-Date "2024-10-04"
$endDate = Get-Date "2024-10-06"

# Define common processes used for downloading files
$downloadProcesses = @(
    "chrome.exe",
    "msedge.exe",
    "firefox.exe",
    "iexplore.exe",
    "wget.exe",
    "curl.exe",
    "powershell.exe"
    # Add any other processes you expect to be used for downloads
)

# Retrieve Sysmon file creation events from Event Viewer
$fileEvents = Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -FilterXPath "*[System[(EventID=$eventID)]]"

# Create an array to store the parsed data
$downloadedFiles = @()

# Loop through each event and extract relevant information
foreach ($event in $fileEvents) {
    $eventXml = [xml]$event.ToXml()

    # Extract the time the file was created
    $utcTime = $event.TimeCreated.ToUniversalTime()
    
    # Filter by date range
    if ($utcTime -ge $startDate -and $utcTime -le $endDate) {
        $filePath = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'TargetFilename' } | Select-Object -ExpandProperty '#text'
        $processID = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'ProcessId' } | Select-Object -ExpandProperty '#text'
        $image = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'Image' } | Select-Object -ExpandProperty '#text'
        $user = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'User' } | Select-Object -ExpandProperty '#text'

        # Extract the executable name from the full path (e.g., "chrome.exe" from "C:\Program Files\chrome.exe")
        $exeName = [System.IO.Path]::GetFileName($image)

        # Filter files created by download-related processes
        if ($downloadProcesses -contains $exeName) {
            # Add the data to the array
            $downloadedFiles += [PSCustomObject]@{
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
$downloadedFiles | Format-Table -AutoSize
