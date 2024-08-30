# Function to check if the script is running as administrator
function Test-IsAdmin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Restart script with elevated privileges if not already running as admin
if (-not (Test-IsAdmin)) {
    Write-Host "Script is not running as administrator. Restarting with elevated privileges..."
    Start-Process powershell "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Path to the dotnet-install.ps1 script
$dotnetInstallScript = "$PSScriptRoot\dotnet-install.ps1"

# Ensure the dotnet-install script is available
if (-not (Test-Path $dotnetInstallScript)) {
    Write-Host "The dotnet-install.ps1 script was not found at $dotnetInstallScript"
    exit 1
}

# Install .NET Desktop Runtime 6.0.32
Write-Host "Installing .NET Desktop Runtime 6.0.32..."
powershell -File $dotnetInstallScript -Runtime windowsdesktop -Channel 6.0 -Version 6.0.32

# Install .NET ASP.NET Core Runtime 6.0.32
Write-Host "Installing .NET ASP.NET Core Runtime 6.0.32..."
powershell -File $dotnetInstallScript -Runtime aspnetcore -Channel 6.0 -Version 6.0.32

Write-Host ".NET Desktop Runtime and ASP.NET Core Runtime 6.0.32 installation completed."

# Copy additional files to their respective locations
$sourceDir = "$PSScriptRoot"

# Define file destinations
$hostfxrDest = "C:\Program Files\dotnet\host\fxr\6.0.32\hostfxr.dll"
$swidtagDest = "C:\Program Files\dotnet\swidtag\Microsoft Windows Desktop Runtime - 6.0.32 (x64).swidtag"
$dotnetExeDest = "C:\Program Files\dotnet\dotnet.exe"

# Ensure destination directories exist
$destDirs = @("C:\Program Files\dotnet\host\fxr\6.0.32", "C:\Program Files\dotnet\swidtag")
foreach ($dir in $destDirs) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
}

# Copy files if they do not already exist
if (-not (Test-Path $hostfxrDest)) {
    Copy-Item -Path "$sourceDir\hostfxr.dll" -Destination $hostfxrDest -Force
}
if (-not (Test-Path $swidtagDest)) {
    Copy-Item -Path "$sourceDir\Microsoft Windows Desktop Runtime - 6.0.32 (x64).swidtag" -Destination $swidtagDest -Force
}
if (-not (Test-Path $dotnetExeDest)) {
    Copy-Item -Path "$sourceDir\dotnet.exe" -Destination $dotnetExeDest -Force
}

# Set the PATH environment variable
$dotnetPath = "C:\Program Files\dotnet"
$existingPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")

if ($existingPath -notlike "*$dotnetPath*") {
    [System.Environment]::SetEnvironmentVariable("Path", "$existingPath;$dotnetPath", "Machine")
    Write-Host "PATH environment variable updated to include $dotnetPath."
} else {
    Write-Host "PATH environment variable already includes $dotnetPath."
}

# Refresh environment variables
$null = [System.Environment]::SetEnvironmentVariable("Path", $existingPath, [System.EnvironmentVariableTarget]::Machine)
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)

# Registry path for InstalledVersions
$installedVersionsRegPath = "HKLM:\SOFTWARE\dotnet\Setup\InstalledVersions\x64\sharedhost"

# Create registry key and set values
if (-not (Test-Path $installedVersionsRegPath)) {
    New-Item -Path $installedVersionsRegPath -Force | Out-Null
}
Set-ItemProperty -Path $installedVersionsRegPath -Name "Version" -Value "6.0.32"
Set-ItemProperty -Path $installedVersionsRegPath -Name "Path" -Value "C:\Program Files\dotnet\"

# Registry path for Uninstall entry
$uninstallRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{885F1CFB-4EAC-4C60-97B8-394BD65ED91E}"

# Create uninstall registry key and set values
if (-not (Test-Path $uninstallRegPath)) {
    New-Item -Path $uninstallRegPath -Force | Out-Null
}

Set-ItemProperty -Path $uninstallRegPath -Name "AuthorizedCDFPrefix" -Value ""
Set-ItemProperty -Path $uninstallRegPath -Name "Comments" -Value ""
Set-ItemProperty -Path $uninstallRegPath -Name "Contact" -Value ""
Set-ItemProperty -Path $uninstallRegPath -Name "DisplayName" -Value "Microsoft Windows Desktop Runtime - 6.0.32 (x64)"
Set-ItemProperty -Path $uninstallRegPath -Name "DisplayVersion" -Value "48.128.16742"
Set-ItemProperty -Path $uninstallRegPath -Name "HelpLink" -Value ""
Set-ItemProperty -Path $uninstallRegPath -Name "HelpTelephone" -Value ""
Set-ItemProperty -Path $uninstallRegPath -Name "InstallDate" -Value "20240805"
Set-ItemProperty -Path $uninstallRegPath -Name "InstallLocation" -Value ""
Set-ItemProperty -Path $uninstallRegPath -Name "InstallSource" -Value "C:\ProgramData\Package Cache\{885F1CFB-4EAC-4C60-97B8-394BD65ED91E}v48.128.16742\"
Set-ItemProperty -Path $uninstallRegPath -Name "ModifyPath" -Value "MsiExec.exe /X{885F1CFB-4EAC-4C60-97B8-394BD65ED91E}"
Set-ItemProperty -Path $uninstallRegPath -Name "NoModify" -Value 1 -Type DWord
Set-ItemProperty -Path $uninstallRegPath -Name "Publisher" -Value "Microsoft Corporation"
Set-ItemProperty -Path $uninstallRegPath -Name "Readme" -Value ""
Set-ItemProperty -Path $uninstallRegPath -Name "Size" -Value ""
Set-ItemProperty -Path $uninstallRegPath -Name "EstimatedSize" -Value 88752 -Type DWord
Set-ItemProperty -Path $uninstallRegPath -Name "SystemComponent" -Value 1 -Type DWord
Set-ItemProperty -Path $uninstallRegPath -Name "UninstallString" -Value "MsiExec.exe /X{885F1CFB-4EAC-4C60-97B8-394BD65ED91E}"
Set-ItemProperty -Path $uninstallRegPath -Name "URLInfoAbout" -Value ""
Set-ItemProperty -Path $uninstallRegPath -Name "URLUpdateInfo" -Value ""
Set-ItemProperty -Path $uninstallRegPath -Name "VersionMajor" -Value 48 -Type DWord
Set-ItemProperty -Path $uninstallRegPath -Name "VersionMinor" -Value 128 -Type DWord
Set-ItemProperty -Path $uninstallRegPath -Name "WindowsInstaller" -Value 1 -Type DWord
Set-ItemProperty -Path $uninstallRegPath -Name "Version" -Value 30804166 -Type DWord
Set-ItemProperty -Path $uninstallRegPath -Name "Language" -Value 1033 -Type DWord

Write-Host "Registry keys created successfully."
Write-Host "Files copied to their respective locations successfully."
Write-Host "Environment variables set successfully."

# Refresh the registry view
$null = [System.Runtime.InteropServices.Marshal]::GetTypeFromCLSID([guid]'{00000000-0000-0000-C000-000000000046}')
$null = [System.Runtime.InteropServices.Marshal]::GetTypeFromCLSID([guid]'{8B2B0E50-C6E8-4425-A273-9F2A2384C047}')
Write-Host "Registry refreshed successfully."
