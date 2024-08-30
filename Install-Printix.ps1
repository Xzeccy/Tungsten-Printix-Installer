# Define the path to the MSI, the wrapped arguments, and the .NET installer script
$msiPath = "$PSScriptRoot\CLIENT_{<YOURCOMPANY>.printix.net}_{<TENANTID>}.MSI" # REPLACE WITH YOUR PRINTIX MSI FROM SOFTWARE DROPDOWN IN PRINTIX ADMIN CONSOLE
$wrappedArgs = "WRAPPED_ARGUMENTS=/id:<YOURTENANTID>"
$dotNetInstaller = "$PSScriptRoot\install-dotnet.ps1"

# Function to check if the script is running as administrator
function Test-IsAdmin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Restart script with elevated privileges if not already running as admin
if (-not (Test-IsAdmin)) {
    Start-Process powershell "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Setup logging
$logDirectory = "C:/IntuneLogs"
$logFile = "$logDirectory/PrintixLog$(Get-Date -Format 'yyyyMMddHHmmss').txt"

if (-not (Test-Path $logDirectory)) {
    New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
}

function Log-Message {
    param (
        [string]$message
    )
    Add-Content -Path $logFile -Value $message
}

# Define the registry path and value name
$regPath = "HKLM:\SOFTWARE\printix.net\Printix Client\CurrentVersion"
$parentRegPath = "HKLM:\SOFTWARE\printix.net"

# Function to compare version numbers
function Compare-Version {
    param (
        [string]$v1,
        [string]$v2
    )
    $ver1 = [System.Version]$v1
    $ver2 = [System.Version]$v2
    return $ver1.CompareTo($ver2)
}

# Function to install Printix Client
function Install-PrintixClient {
    param (
        [string]$msiPath,
        [string]$wrappedArgs
    )
    Log-Message "Installing Printix Client..."
    $installProcess = Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" $wrappedArgs /qn /norestart" -PassThru -Wait

    if ($installProcess.ExitCode -eq 0) {
        Log-Message "Printix Client installation completed successfully."
        Start-Sleep -Seconds 60
        Log-Message "Printix Client installation script completed successfully."
        exit 0
    } elseif ($installProcess.ExitCode -eq 1618) {
        Log-Message "Another installation is already in progress. Waiting before retrying..."
        Start-Sleep -Seconds 120
        Install-PrintixClient -msiPath $msiPath -wrappedArgs $wrappedArgs
    } else {
        Log-Message "Printix Client installation failed with exit code $($installProcess.ExitCode)."
        exit $installProcess.ExitCode
    }
}

# Check if any .NET Runtime 6 version is installed by looking for the specific folders
function Check-DotNetRuntime {
    $dotnetFolders = @(
        "C:\Program Files\dotnet\shared\Microsoft.AspNetCore.App\",
        "C:\Program Files\dotnet\shared\Microsoft.NETCore.App\",
        "C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App\"
    )

    foreach ($folder in $dotnetFolders) {
        if (-not (Get-ChildItem -Path $folder -Directory | Where-Object { $_.Name -like "6*" })) {
            Log-Message "Required .NET 6.x folder not found in: $folder"
            return $false
        }
    }

    Log-Message ".NET Runtime 6.x is installed in all required folders."
    return $true
}

# Function to install .NET Runtimes
function Install-DotNetRuntimes {
    $dotnetInstallScript = "$dotNetInstaller"
    
    if (-not (Test-Path $dotnetInstallScript)) {
        Log-Message "The dotnet-install.ps1 script was not found."
        exit 1
    }

    Log-Message "Installing .NET Desktop Runtime 6.0.32..."
    & powershell -File $dotnetInstallScript -Runtime windowsdesktop -Channel 6.0 -Version 6.0.32
    Log-Message ".NET Desktop Runtime 6.0.32 installation completed."

    Log-Message "Installing .NET ASP.NET Core Runtime 6.0.32..."
    & powershell -File $dotnetInstallScript -Runtime aspnetcore -Channel 6.0 -Version 6.0.32
    Log-Message ".NET ASP.NET Core Runtime 6.0.32 installation completed."

    # Update PATH globally
    $dotnetPath = "C:\Program Files\dotnet"
    $existingPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")

    if ($existingPath -notlike "*$dotnetPath*") {
        [System.Environment]::SetEnvironmentVariable("Path", "$existingPath;$dotnetPath", "Machine")
        Log-Message "PATH environment variable updated to include $dotnetPath."

        # Refresh the current session to recognize the updated PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    } else {
        Log-Message "PATH environment variable already includes $dotnetPath."
    }
}

# Main logic
if (Check-DotNetRuntime) {
    Log-Message ".NET Runtime 6.x is already installed in all required folders."
} else {
    Install-DotNetRuntimes
}

# Proceed with Printix installation only if .NET Runtime is confirmed to be present in all required folders
if (Check-DotNetRuntime) {
    # Check if the full registry entry exists
    if (Test-Path $regPath) {
        $currentVersion = (Get-ItemProperty -Path $regPath -Name "CurrentVersion").CurrentVersion
        $minVersion = "2.3.0.211"
        $comparison = Compare-Version $currentVersion $minVersion

        if ($comparison -lt 0) {
            $uninstallerPath = "C:\Program Files\printix.net\Printix Client\unins000.exe"
            if (Test-Path $uninstallerPath) {
                Log-Message "Uninstalling existing Printix Client version $currentVersion..."
                Start-Process -FilePath $uninstallerPath -ArgumentList "/verysilent" -Wait
                Log-Message "Printix Client uninstalled successfully."
            }

            Install-PrintixClient -msiPath $msiPath -wrappedArgs $wrappedArgs
        } elseif ($comparison -ge 0) {
            Log-Message "Current Printix Client version ($currentVersion) is up-to-date. No action required."
            exit 0
        }
    } else {
        if (Test-Path $parentRegPath) {
            Log-Message "Printix would be installed."
            Install-PrintixClient -msiPath $msiPath -wrappedArgs $wrappedArgs
        } else {
            Log-Message "Registry path $parentRegPath does not exist. Installing Printix Client."
            Install-PrintixClient -msiPath $msiPath -wrappedArgs $wrappedArgs
        }
    }
} else {
    Log-Message "Skipping Printix Client installation due to missing .NET Runtime 6 in one or more required folders."
    exit 0
}
