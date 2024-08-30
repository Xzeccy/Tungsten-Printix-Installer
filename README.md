# Printix Deployment with .NET 6.x Runtime Check

## Project Overview

This project contains scripts and resources for deploying the Printix Client using Microsoft Intune while ensuring the necessary .NET 6.x runtimes are installed. This is necessary for deploying the new Printix client since the Tungsten Automation acquisition of Printix. .NET 6 is required prior to Printix install.
The scripts are designed to handle cases where multiple versions of .NET may already be installed, and they ensure the Printix Client installation only proceeds if the required .NET 6.x runtimes are present in specific folders.

## Project Structure

```
Project Folder/
│
├── CLIENT_{<YOURCOMPANY>.printix.net}_{<TENANTID>}.MSI
├── dotnet-install.ps1
├── dotnet.exe
├── hostfxr.dll
├── install-dotnet.ps1
├── Install-Printix.ps1
├── Microsoft Windows Desktop Runtime - 6.0.32 (x64).swidtag
└── README.md
```

### Files Description

- **CLIENT_{<YOURCOMPANY>.printix.net}_{<TENANTID>}.MSI**  
  The MSI installer for the Printix Client. You should replace this with your organization's Printix installer (MSI), which can be obtained from the Software dropdown in the Printix admin panel.

- **dotnet-install.ps1**  
  A script provided by Microsoft for installing various versions of .NET runtimes. This script is utilized to install the required .NET 6.x runtimes if they are not already present on the target system.

- **dotnet.exe**  
  The .NET executable file that will be placed in the appropriate directory as part of the installation process. (Can be found in a normal dotnet install at `C:/Program Files/dotnet/`).

- **hostfxr.dll**  
  A required DLL for .NET runtimes that will be copied to the target system as part of the installation process. (Can be found in a normal dotnet install at `C:/Program Files/dotnet/`).

- **install-dotnet.ps1**  
  This script checks the system for the presence of .NET 6.x runtimes in the specified folders. If the runtimes are missing, it uses `dotnet-install.ps1` to install them.

- **Install-Printix.ps1**  
  The main script that performs the installation of the Printix Client. This script checks for the presence of .NET 6.x runtimes before proceeding with the Printix installation. If .NET 6.x is missing, it installs it first.

- **Microsoft Windows Desktop Runtime - 6.0.32 (x64).swidtag**  
  A software identification tag file that will be copied to the appropriate directory on the target system. (Can be found in a normal dotnet install at `C:/Program Files/dotnet/`).

## How to Use

### Pre-Requisites

- **Microsoft Intune**: Ensure that your environment has Microsoft Intune set up for application deployment.
- **Administrator Privileges**: The scripts need to be run with administrator privileges to install software and modify system paths.

### Steps to Deploy

1. **Prepare Your Own Printix Installer:**
   - Replace the provided `CLIENT_{<YOURCOMPANY>.printix.net}_{<TENANTID>}.MSI` with your organization's Printix MSI installer.

2. **Modify the Scripts:**
   - Update any hardcoded paths or variables in the scripts if your environment requires different paths.

3. **Create an Intune Application Package:**
   - Package all the files in this project (except the `README.md`) into a `.intunewin` file using the IntuneWinAppUtil tool.
   - Create a new Windows app (Win32) deployment in Intune and upload the `.intunewin` file.

4. **Configure Detection Rules:**
   - In Intune, set up detection rules for the Printix Client. You can use a registry path like:

     ```
     Path: HKEY_LOCAL_MACHINE\SOFTWARE\printix.net\Printix Client\CurrentVersion
     Value name: CurrentVersion
     Detection method: String comparison
     Operator: Equals
     Value: <expected Printix version>
     ```

     This ensures that Intune can verify if the Printix Client is already installed.

5. **Deploy to Devices:**
   - Assign the application to the target devices or groups in Intune.
   - The script will ensure that .NET 6.x runtimes are installed before attempting to install the Printix Client.

## What Happens During Execution

1. **Check for .NET 6.x Runtimes:**
   - The script `Install-Printix.ps1` checks if any version of .NET 6.x is installed by verifying the existence of folders that start with "6" in the following directories:
     - `C:\Program Files\dotnet\shared\Microsoft.AspNetCore.App\`
     - `C:\Program Files\dotnet\shared\Microsoft.NETCore.App\`
     - `C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App\`

2. **Install .NET 6.x if Required:**
   - If any of the required folders do not contain a 6.x version, the script installs .NET 6.0.32 using the `install-dotnet.ps1` script.

3. **Check for Existing Printix Client Version:**
   - The script then checks if the Printix Client is already installed by looking for the registry key:
     - `HKEY_LOCAL_MACHINE\SOFTWARE\printix.net\Printix Client\CurrentVersion`
   - If the registry key exists, the script retrieves the current version of the Printix Client.

4. **Compare Printix Client Version:**
   - The script compares the current installed version of Printix with the minimum required version `2.3.0.211`.
   - If the installed version is **less than** `2.3.0.211`:
     - The script locates the Printix Client uninstaller at `C:\Program Files\printix.net\Printix Client\unins000.exe` and runs it silently to remove the outdated version.
     - The uninstallation is performed silently (`/verysilent`), and a log entry is made to confirm the successful uninstallation.
   - If the installed version is **equal to or greater than** `2.3.0.211`:
     - No further action is required, and the script exits, as the installed Printix version meets the requirements.

5. **Install Printix Client:**
   - If the Printix Client was uninstalled, or if the registry path does not exist (indicating Printix is not installed), the script proceeds to install the Printix Client using the provided MSI installer.

6. **Logging:**
   - The script logs all actions and results in the `C:/IntuneLogs` directory, which can be useful for troubleshooting.

## Modifications Required

1. **Update Printix Installer:**
   - Replace the `CLIENT_{<YOURCOMPANY>.printix.net}_{<TENANTID>}.MSI` with your organization's MSI file.

2. **Update Detection Rules:**
   - Ensure the detection rules in Intune match the version of Printix that you are deploying.

3. **Optional Script Modifications:**
   - If your environment has different paths or requires additional configurations, modify the scripts accordingly.

## Conclusion

This project provides a robust solution for deploying the Printix Client with the necessary .NET 6.x runtimes in environments managed by Microsoft Intune. By following the steps outlined in this README, you can ensure that the deployment is successful even in environments with multiple versions of .NET installed.
