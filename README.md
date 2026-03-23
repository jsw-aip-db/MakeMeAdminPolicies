# MakeMeAdminPolicies

This repository contains policies and configuration scripts for [@pseymour/MakeMeAdmin](https://github.com/pseymour/MakeMeAdmin), designed to apply restrictive policies that limit MakeMeAdmin usage to the current user only.

## Overview

MakeMeAdmin is a Windows application that allows standard users to temporarily elevate their privileges to install software or perform administrative tasks without permanently granting them administrator rights. This repository provides a PowerShell script to configure restrictive policies that ensure MakeMeAdmin can only be used by the current user.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Installing MakeMeAdmin](#installing-makemeadmin)
  - [Applying Restrictive Policies](#applying-restrictive-policies)
- [Policy Configuration Details](#policy-configuration-details)
- [Verification and Testing](#verification-and-testing)
- [Troubleshooting](#troubleshooting)
- [Resources](#resources)
- [License](#license)

## Prerequisites

Before proceeding, ensure you have the following:

1. **Windows Operating System**: Windows 10/11 or Windows Server 2016 or later
2. **Administrator Rights**: Required for installing MakeMeAdmin and applying policies
3. **PowerShell 5.1 or later**: Check your version by running:
   ```powershell
   $PSVersionTable.PSVersion
   ```
4. **Internet Connection**: For downloading MakeMeAdmin installer (if not already available)

## Installation

### Installing MakeMeAdmin

MakeMeAdmin can be installed using several methods:

#### Method 1: Using winget (Recommended)

```powershell
# Install MakeMeAdmin using Windows Package Manager
winget install --id=Sinclair.MakeMeAdmin -e
```

#### Method 2: Using Chocolatey

```powershell
# Install MakeMeAdmin using Chocolatey
choco install MakeMeAdmin
```

#### Method 3: Manual Installation

1. Download the latest installer from the [MakeMeAdmin Releases page](https://github.com/pseymour/MakeMeAdmin/releases)
2. Run the installer with administrator privileges
3. Follow the installation wizard prompts
4. Complete the installation

#### Verify Installation

After installation, verify that MakeMeAdmin is running:

```powershell
# Check if MakeMeAdmin service is running
Get-Service -Name "Make Me Admin" | Select-Object Status, DisplayName
```

The service status should show as "Running".

### Applying Restrictive Policies

The `SetMakeMeAdminPolicy.ps1` script in this repository configures MakeMeAdmin to:

- Restrict usage to the current user only
- Automatically remove admin rights on logout
- Log all elevated processes
- Prompt for a reason when requesting elevation
- Provide canned reasons for elevation requests

#### Step 1: Download the Policy Script

Download or clone this repository:

```powershell
# Clone the repository
git clone https://github.com/jsw-aip-db/MakeMeAdminPolicies.git

# Navigate to the repository directory
cd MakeMeAdminPolicies
```

Or download the script directly from GitHub.

#### Step 2: Set PowerShell Execution Policy (if needed)

Check your current execution policy:

```powershell
Get-ExecutionPolicy
```

If the policy is too restrictive (e.g., `Restricted`), you may need to temporarily allow script execution:

```powershell
# Allow local scripts to run (requires Administrator)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Note**: Always review scripts before running them. You can view the script content with:

```powershell
Get-Content .\SetMakeMeAdminPolicy.ps1
```

#### Step 3: Run the Policy Script

Execute the script as an administrator. The script will automatically request elevation if needed:

```powershell
# Run the policy configuration script
.\SetMakeMeAdminPolicy.ps1
```

Alternatively, you can explicitly run it with administrator privileges:

```powershell
# Run as Administrator explicitly
Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PWD\SetMakeMeAdminPolicy.ps1`"" -Verb RunAs
```

#### What the Script Does

The script will:

1. **Auto-elevate**: Request administrator privileges if not already running as admin
2. **Detect Current User**: Automatically identify the logged-in user in `DOMAIN\username` format
3. **Create Registry Keys**: Set up the policy registry path at:
   ```
   HKLM:\SOFTWARE\Policies\Sinclair Community College\Make Me Admin
   ```
4. **Configure Policies**: Apply the following settings:
   - **Allowed Entities**: Restricts MakeMeAdmin to the current user only
   - **Remote Allowed Entities**: Mirrors the local allowed entities
   - **Remove Admin Rights On Logout**: Enabled (automatic cleanup)
   - **Log Elevated Processes**: Enabled (audit trail)
   - **Prompt For Reason**: Required (accountability)
   - **Canned Reasons**: Predefined options:
     - Software installation
     - System update or configuration
     - Driver or hardware issue

#### Step 4: Restart MakeMeAdmin Service (Optional)

For policies to take immediate effect, restart the MakeMeAdmin service:

```powershell
# Restart the Make Me Admin service
Restart-Service -Name "Make Me Admin"

The script configures the following registry values:

| Setting | Type | Value | Description |
|---------|------|-------|-------------|
| Allowed Entities | REG_MULTI_SZ | Current User | Users/groups permitted to use MakeMeAdmin |
| Remote Allowed Entities | REG_MULTI_SZ | Current User | Users/groups permitted for remote elevation |
| Remove Admin Rights On Logout | DWORD | 1 (Enabled) | Automatically revokes admin rights when user logs out |
| Log Elevated Processes | DWORD | 1 (Enabled) | Logs all processes run with elevated privileges |
| Prompt For Reason | DWORD | 2 (Required) | Forces user to provide a reason for elevation |
| Canned Reasons | REG_MULTI_SZ | Multiple | Pre-defined reasons for quick selection |

## Verification and Testing

### 1. Verify Registry Settings

Check that the policies were applied correctly:

```powershell
# View all MakeMeAdmin policy settings
Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Sinclair Community College\Make Me Admin' | Format-List
```

### 2. Verify Current User Configuration

Confirm that only your user account is allowed:

```powershell
# Check the allowed entities
$regPath = 'HKLM:\SOFTWARE\Policies\Sinclair Community College\Make Me Admin'
(Get-ItemProperty -Path $regPath).'Allowed Entities'
```

This should display your username in `DOMAIN\username` format.

### 3. Test MakeMeAdmin Functionality

1. **Open MakeMeAdmin**: Launch the MakeMeAdmin application from the Start menu or system tray
2. **Request Admin Rights**: Click "Make Me Admin" or use the configured hotkey
3. **Verify Prompt**: You should see a prompt asking for a reason
4. **Select Reason**: Choose one of the canned reasons or enter a custom one
5. **Perform Admin Task**: Try performing an administrative action (e.g., installing software)
6. **Check Logs**: Review the event logs for elevated process records

### 4. Check Event Logs

View MakeMeAdmin activity in the Event Viewer:

```powershell
# View MakeMeAdmin events from the last 24 hours
Get-WinEvent -FilterHashtable @{
    LogName = 'Application'
    ProviderName = 'Make Me Admin'
    StartTime = (Get-Date).AddDays(-1)
} | Select-Object TimeCreated, Message | Format-Table -AutoSize
```

### 5. Test Logout Behavior

1. Request admin privileges using MakeMeAdmin
2. Log out of Windows
3. Log back in
4. Verify that admin rights were automatically removed

## Troubleshooting

### Script Won't Run - Execution Policy Error

**Error**: "cannot be loaded because running scripts is disabled on this system"

**Solution**:
```powershell
# Temporarily bypass execution policy for this script
powershell.exe -ExecutionPolicy Bypass -File .\SetMakeMeAdminPolicy.ps1
```

For more information, see [About Execution Policies](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies).

### MakeMeAdmin Service Not Found

**Error**: Service "Make Me Admin" not found

**Solution**:
1. Verify MakeMeAdmin is installed:
   ```powershell
   Get-Service | Where-Object { $_.DisplayName -like "*Make Me Admin*" }
   ```
2. If not found, reinstall MakeMeAdmin using one of the installation methods above

### Policies Not Taking Effect

**Issue**: Changes don't seem to apply after running the script

**Solution**:
1. Verify the registry keys were created:
   ```powershell
   Test-Path 'HKLM:\SOFTWARE\Policies\Sinclair Community College\Make Me Admin'
   ```
2. Restart the MakeMeAdmin service:
   ```powershell
   Restart-Service -Name "Make Me Admin"
   ```
3. If still not working, try restarting your computer

### Access Denied When Running Script

**Error**: "Access to the registry path is denied"

**Solution**:
- Ensure you're running PowerShell as Administrator
- Right-click PowerShell and select "Run as administrator"
- Or allow the script to auto-elevate when prompted

### Wrong User Configured

**Issue**: The script configured a different user than intended

**Solution**:
The script uses the currently logged-in user. To configure for a different user:
1. Edit the script and replace line 19:
   ```powershell
   # Original
   $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
   
   # Modified (replace with actual username)
   $currentUser = "DOMAIN\username"
   ```
2. Run the script again

### Registry Path Not Standard

**Note**: MakeMeAdmin uses the registry path:
```
HKLM:\SOFTWARE\Policies\Sinclair Community College\Make Me Admin
```

This is the standard path for the official MakeMeAdmin distribution. If your installation uses a different path, you'll need to modify line 23 in the script accordingly.

## Resources

### Official Documentation
- **MakeMeAdmin Repository**: [https://github.com/pseymour/MakeMeAdmin](https://github.com/pseymour/MakeMeAdmin)
- **MakeMeAdmin Documentation**: Configuration and usage guides available in the repository

### Microsoft Documentation
- **PowerShell Execution Policies**: [About Execution Policies](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies)
- **Group Policy Overview**: [Group Policy Overview](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/hh831791(v=ws.11))
- **Windows Registry**: [Registry Reference](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry)

### Security Best Practices
- **Principle of Least Privilege**: [Microsoft Security Best Practices](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/security-best-practices/implementing-least-privilege-administrative-models)
- **Privileged Access Management**: [Microsoft PAM Documentation](https://learn.microsoft.com/en-us/microsoft-identity-manager/pam/privileged-identity-management-for-active-directory-domain-services)

### Community Support
- **MakeMeAdmin Issues**: Report bugs or request features at [MakeMeAdmin Issues](https://github.com/pseymour/MakeMeAdmin/issues)

## License

This project is licensed under the MIT License.

Copyright (c) 2026 Jugendsozialwerk (AIP plus - Stiftung Jugendsozialwerk)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

**Note**: MakeMeAdmin itself is a separate project with its own license. This repository only contains policy configuration scripts for use with MakeMeAdmin. Please refer to the [MakeMeAdmin repository](https://github.com/pseymour/MakeMeAdmin) for its licensing information.
