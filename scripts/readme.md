### Get-SysmonDNS.ps1 **PowerShell script** step by step

### 1. **Define the Sysmon Event ID for DNS Queries**
   ```powershell
   $eventID = 22
   ```

   - This defines **Event ID 22**, which Sysmon uses to log **DNS query events** (both requests and responses).
   - The script will filter out events in the **Sysmon Operational Log** that correspond to this specific event ID.

### 2. **Retrieve Sysmon DNS Query Events from Event Viewer**
   ```powershell
   $dnsEvents = Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -FilterXPath "*[System[(EventID=$eventID)]]"
   ```

   - **`Get-WinEvent`**: Retrieves Windows Event logs, filtering by the Sysmon **Operational Log** and using **Event ID 22** to select only DNS query events.
   - **`-LogName`**: Specifies the event log from which to retrieve the data.
   - **`-FilterXPath`**: Filters events using XPath to only retrieve entries where the event ID equals 22.

### 3. **Create an Array to Store Parsed Data**
   ```powershell
   $dnsData = @()
   ```

   - This creates an empty array **`$dnsData`** that will store custom objects representing each parsed DNS event. Each object will contain the extracted fields (e.g., `UTCTime`, `ProcessID`, `QueryName`, `QueryStatus`, etc.).

### 4. **Loop Through Each Event and Extract Relevant Information**
   ```powershell
   foreach ($event in $dnsEvents) {
       $eventXml = [xml]$event.ToXml()
   ```

   - **`foreach` loop**: This iterates over all the DNS events retrieved from the event log.
   - **`$event.ToXml()`**: Converts each event into XML format for easier parsing of specific fields.

### 5. **Extract Required Fields**
   For each DNS event, the script extracts the following fields:

   ```powershell
   $utcTime = $event.TimeCreated.ToUniversalTime()
   $processID = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'ProcessId' } | Select-Object -ExpandProperty '#text'
   $queryName = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'QueryName' } | Select-Object -ExpandProperty '#text'
   $queryStatus = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'QueryStatus' } | Select-Object -ExpandProperty '#text'
   $queryResults = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'QueryResults' } | Select-Object -ExpandProperty '#text'
   $image = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'Image' } | Select-Object -ExpandProperty '#text'
   $user = $eventXml.Event.EventData.Data | Where-Object { $_.Name -eq 'User' } | Select-Object -ExpandProperty '#text'
   ```

   - **`$utcTime`**: The time the DNS query was made, converted to UTC.
   - **`$processID`**: The ID of the process that made the DNS request.
   - **`$queryName`**: The DNS domain name being queried.
   - **`$queryStatus`**: The status of the DNS query (e.g., **Success** or **Failure**).
   - **`$queryResults`**: The response from the DNS query, which can contain multiple IP addresses (IPv4, IPv6) and domain names.
   - **`$image`**: The executable (process) that initiated the DNS request, e.g., `chrome.exe` or `svchost.exe`.
   - **`$user`**: The user who executed the process making the DNS request.

### 6. **Extract Only IPv4 Addresses**
   ```powershell
   $ipv4Addresses = $queryResults -split ';' | Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}$' }
   ```

   - **`$queryResults -split ';'`**: Splits the `QueryResults` string into individual entries. The DNS query results typically contain a mixture of IP addresses (both IPv4 and IPv6) and possibly other data separated by semicolons (`;`).
   - **`Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}$' }`**: This filters the split results, only keeping strings that match the regular expression for **IPv4 addresses** (e.g., `192.168.1.1`).

### 7. **Format the IPv4 Addresses**
   ```powershell
   if ($ipv4Addresses) {
       $ipv4AddressesFormatted = $ipv4Addresses -join ', '
   } else {
       $ipv4AddressesFormatted = "None"
   }
   ```

   - If IPv4 addresses are found in `QueryResults`, they are joined into a comma-separated string (`$ipv4AddressesFormatted`), which will be displayed in the output table. If no IPv4 addresses are found, it displays **"None"**.

### 8. **Add the Extracted Data to the Array**
   ```powershell
   $dnsData += [PSCustomObject]@{
       UTCTime        = $utcTime
       ProcessID      = $processID
       QueryName      = $queryName
       QueryStatus    = $queryStatus
       IPv4Addresses  = $ipv4AddressesFormatted
       Image          = $image
       User           = $user
   }
   ```

   - This step creates a **custom object** with the extracted information (`UTCTime`, `ProcessID`, `QueryName`, `QueryStatus`, `IPv4Addresses`, `Image`, `User`) and adds it to the `$dnsData` array. Each DNS event is represented as an object in this array.

### 9. **Display the Data in Table Format**
   ```powershell
   $dnsData | Format-Table -AutoSize
   ```

   - **`Format-Table -AutoSize`**: Displays the collected data in a neatly formatted table, adjusting column sizes automatically to fit the content.

### Example Output:

The script’s output will look something like this:

```plaintext
UTCTime               ProcessID QueryName           QueryStatus IPv4Addresses        Image                          User
--------              --------- ---------           ----------- --------------       -----                          ----
2024-10-05T08:45:32Z  3408      example.com         Success     93.184.216.34        C:\Program Files\chrome.exe    UserA
2024-10-05T08:50:01Z  4120      maliciousdomain.com Success     95.101.36.65, 23.61.199.64 C:\Windows\System32\svchost.exe UserB
```

### What the Script Does:
- **Retrieves all DNS query events (Event ID 22)** from the Sysmon Operational Log.
- **Parses each event** to extract fields such as **time, process ID, query name, status**, and **query results**.
- **Filters the DNS query results** to extract only the **IPv4 addresses** using a regular expression.
- **Displays the filtered IPv4 addresses** along with other relevant information in a structured table.

### Why This Script is Useful:
- **DNS Monitoring**: By focusing on **DNS queries**, you can track network communication patterns and detect suspicious behavior, such as malware trying to resolve command-and-control (C2) domains.
- **IPv4 Address Filtering**: The script filters out **IPv6 addresses**, focusing on **IPv4 addresses**, which are still widely used and easier to monitor for suspicious activity.
- **Process and User Correlation**: It shows which **process** and **user** made the DNS query, allowing for correlation with other activities, such as detecting which application is making suspicious network requests.

This script can be helpful in **incident response** or **threat hunting** by identifying malicious domains, monitoring unexpected network traffic, and understanding which processes/users are initiating DNS queries.
