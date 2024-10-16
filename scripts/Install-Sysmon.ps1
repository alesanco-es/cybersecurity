# Define paths for downloading and extraction
$sysmonZipUrl = "https://download.sysinternals.com/files/Sysmon.zip"
$sysmonConfigUrl = "https://raw.githubusercontent.com/olafhartong/sysmon-modular/master/sysmonconfig-excludes-only.xml"
$downloadPath = "C:\Tools\Sysmon"
$sysmonZipPath = "$downloadPath\Sysmon.zip"
$sysmonConfigPath = "$downloadPath\sysmonconfig.xml"

# Create directory for Sysmon
if (-not (Test-Path -Path $downloadPath)) {
    New-Item -ItemType Directory -Path $downloadPath -Force
}

# Download Sysmon
Write-Output "Downloading Sysmon..."
Invoke-WebRequest -Uri $sysmonZipUrl -OutFile $sysmonZipPath

# Extract Sysmon
Write-Output "Extracting Sysmon..."
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($sysmonZipPath, $downloadPath)

# Check if Sysmon64.exe exists
if (-not (Test-Path "$downloadPath\Sysmon64.exe")) {
    Write-Error "Sysmon64 executable not found after extraction. Please check the downloaded files."
    exit 1
}

# Download Sysmon configuration file
Write-Output "Downloading Sysmon configuration file..."
Invoke-WebRequest -Uri $sysmonConfigUrl -OutFile $sysmonConfigPath

# Install Sysmon with the configuration file
Write-Output "Installing Sysmon with configuration file..."
$sysmonExe = "$downloadPath\Sysmon64.exe"

Start-Process -FilePath $sysmonExe -ArgumentList "-accepteula -i $sysmonConfigPath" -Wait -Verb RunAs

Write-Output "Sysmon installation complete."
