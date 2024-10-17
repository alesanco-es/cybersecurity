# Define the Event IDs for logon and logoff
$logonEventID = 4624
$logoffEventID = 4634

# Get logon events (Network Logon Type 3)
# When using Select-Object, properties not selected are removed so they are not accesible via Properties[]
$logonEvents = Get-WinEvent -FilterHashtable @{LogName="Security"; Id=$logonEventID} | 
    Where-Object { ($_.Properties[8].Value -eq 3) } |
    Select-Object @{Name="TimeCreated";Expression={$_.TimeCreated}}, 
                  @{Name="UserName";Expression={$_.Properties[5].Value}}, 
                  @{Name="SessionId";Expression={$_.Properties[7].Value}},
                  @{Name="WorkstationName";Expression={$_.Properties[11].Value}},
                  @{Name="IpAddress";Expression={$_.Properties[18].Value}}

# Get logoff events (Network Logon Type 3)
$logoffEvents = Get-WinEvent -FilterHashtable @{LogName="Security"; Id=$logoffEventID} | 
    Where-Object { ($_.Properties[4].Value -eq 3) } |
    Select-Object @{Name="TimeCreated";Expression={$_.TimeCreated}}, 
                  @{Name="UserName";Expression={$_.Properties[1].Value}}, 
                  @{Name="SessionId";Expression={$_.Properties[3].Value}}

# Create an empty array to hold the timeline data
$timeline = @()

# Match logon and logoff events by Logon ID and calculate session duration
$logonEvents | ForEach-Object {
    $logon = $_
    $logoff = $logoffEvents | Where-Object {
        $_.SessionId -eq $logon.SessionId
    } | Select-Object -First 1

    if ($logoff) {
        $logonTime = $logon.TimeCreated
        $logoffTime = $logoff.TimeCreated
        $sessionDuration = $logoffTime - $logonTime

        # Add the paired event to the timeline array
        $timeline += [pscustomobject]@{
            LogonTime = $logon.TimeCreated
            LogoffTime = $logoff.TimeCreated
            UserName = $logon.UserName
            WorkstationName = $logon.WorkstationName
            IpAddress = $logon.IpAddress
            SessionDuration = $sessionDuration
         }

        # Print the times and session duration on the screen
        # Write-Host "User: $($logon.UserName)"
        # Write-Host "IP address: $($logon.IpAddress)"
        # Write-Host "Workstation Name: $($logon.WorkstationName)"
        # Write-Host "Logon Time: $logonTime"
        # Write-Host "Logoff Time: $logoffTime"
        # Write-Host "Session Duration: $sessionDuration"
        # Write-Host "-------------------------------"
    }
}

# Output the timeline in a table format
$timeline | Format-Table -AutoSize

# Optionally, export the timeline to a CSV file
$timeline | Export-Csv -Path "C:\scripts\timeline_output.csv" -NoTypeInformation
