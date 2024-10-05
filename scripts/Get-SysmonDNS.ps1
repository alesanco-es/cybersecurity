# Define the Sysmon Event ID for DNS Queries
$eventID = 22

# Retrieve Sysmon DNS query events from Event Viewer
$dnsEvents = Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -FilterXPath "*[System[(EventID=$eventID)]]"

# Create an array to store the parsed data
$dnsData = @()

# Loop through each event and extract relevant information
foreach ($event in $dnsEvents) {
    $eventXml = [xml]$event.ToXml()

    # Extract required fields
    $utcTime = $event.TimeCreated.ToUniversalTime()
    $processID = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'ProcessId' } | Select-Object -ExpandProperty '#text'
    $queryName = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'QueryName' } | Select-Object -ExpandProperty '#text'
    $queryStatus = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'QueryStatus' } | Select-Object -ExpandProperty '#text'
    $queryResults = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'QueryResults' } | Select-Object -ExpandProperty '#text'
    $image = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'Image' } | Select-Object -ExpandProperty '#text'
    $user = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'User' } | Select-Object -ExpandProperty '#text'

    # Extract only IPv4 addresses from QueryResults using a regular expression
    $ipv4Addresses = $queryResults -split ';' | Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}$' }

    # If there are any IPv4 addresses, format them as a comma-separated list
    if ($ipv4Addresses) {
        $ipv4AddressesFormatted = $ipv4Addresses -join ', '
    } else {
        $ipv4AddressesFormatted = "None"
    }

    # Add the data to the array, displaying the new field 'IPv4Addresses' instead of 'QueryResults'
    $dnsData += [PSCustomObject]@{
        UTCTime        = $utcTime
        ProcessID      = $processID
        QueryName      = $queryName
        QueryStatus    = $queryStatus
        IPv4Addresses  = $ipv4AddressesFormatted
        Image          = $image
        User           = $user
    }
}

# Display the data in a table format
$dnsData | Format-Table -AutoSize
