<#
    .SYNOPSIS
    Creates a shortcut, with a default location of the current user's desktop.
    .DESCRIPTION
        Create a shortcut, to a file or URL, with options for all the relevant properties for a shortcut.

        Defaults to creating the shortcut on the current user's desktop. Default icon is the first icon in target file.
    .EXAMPLE
    .\New-Shortcut.ps1 -Name 'Notepad' -Target 'C:\Windows\notepad.exe' -Comment 'Shortcut to Notepad on the Desktop'

    Creates a shortcut to Notepad on the desktop.
    .EXAMPLE
    .\New-Shortcut.ps1 -Name 'Notepad' -Target 'C:\Windows\notepad.exe' -Arguments 'C:\Windows\WindowsUpdate.log' -Force

    Creates a shortcut to Notepad on the desktop, which opens the WindowsUpate.log. Overwrites an existing shortcut if it exists.
    .EXAMPLE
    .\New-Shortcut.ps1 -Name 'Registry Editor' -Target 'C:\Windows\regedit.exe' -Folder 'C:\Users\Public\Desktop' -RunAsAdmin -Comment 'Shortcut to RegEdit which opens as Admin'

    Creates a shortcut to Registry Editor, which opens as Administrator, on the All User's desktop.
    .NOTES
        Author: Sean Quinlan
        Email:  sean@yster.org
#>

[CmdletBinding()]
param(
    # Name of the shortcut.
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $Name,

    # The folder to create the shortcut in. Default is the user's desktop.
    [ValidateScript( {
            if (-not (Test-Path -Path $_)) {
                throw ('Folder "{0}" not found!' -f $_)
            } elseif (-not (Test-Path -Path $_ -PathType Container)) {
                throw ('"{0}" is not a folder!' -f $_)
            } else {
                $true
            }
        })]
    [String]
    $Folder = (Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders' -Name 'Desktop').Desktop,

    # The path to the target of the shortcut.
    [Parameter(Mandatory = $true)]
    [ValidateScript( {
            if (-not (Test-Path -Path $_)) {
                throw ('Target "{0}" not found!' -f $_)
            } else {
                $true
            }
        })]
    [String]
    $Target,

    # The folder to start in. Default is to the same folder as the shortcut is in.
    [Parameter(Mandatory = $false)]
    [ValidateScript( {
            if (-not (Test-Path -Path $_)) {
                throw ('Start In folder "{0}" not found!' -f $_)
            } elseif (-not (Test-Path -Path $_ -PathType Container)) {
                throw ('"{0}" is not a folder!' -f $_)
            } else {
                $true
            }
        })]
    [Alias('WorkingDir', 'WorkingDirectory')]
    [String]
    $StartIn = $Folder,

    # The arguments for the target line.
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String]
    $Arguments,

    # The description for the shortcut.
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [Alias('Description')]
    [String]
    $Comment,

    # The path to the icon file. Defaults to the first icon in the Target file.
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String]
    $IconPath,

    # The index of the icon within the IconPath file. Note: Starts at 0.
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String]
    $IconIndex = '0',

    # The type of window for the shortcut.
    [Parameter(Mandatory = $false)]
    [ValidateSet('Default', 'Maximized', 'Minimized')]
    [String]
    $WindowStyle = 'Default',

    # Set the "Run as Administrator" checkbox.
    [Parameter(Mandatory = $false)]
    [Alias('Admin', 'Administrator', 'Elevated')]
    [Switch]
    $RunAsAdmin,

    # Overwrite any existing shortcut.
    [Parameter(Mandatory = $false)]
    [Switch]
    $Force
)

$PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('- Arguments: {0} - {1}' -f $_.Key, ($_.Value -join ' ')) }

Write-Verbose ('Checking shortcut file name: {0}' -f $Name)
$Name_Extension = $Name.Substring($Name.Length - 4)
if (($Name_Extension -ne '.lnk') -and ($Name_Extension -ne '.url')) {
    Write-Verbose ('- Adding .lnk extension')
    $Name = '{0}.lnk' -f $Name
}
Write-Verbose ('Shortcut name: {0}' -f $Name)

Write-Verbose ('Unwrapping paths...')
$Folder = (Get-Item -Path $Folder -Force).FullName
Write-Verbose ('- $Folder: {0}' -f $Folder)
$StartIn = (Get-Item -Path $StartIn -Force).FullName
Write-Verbose ('- $StartIn: {0}' -f $StartIn)

Write-Verbose ('Checking if shortcut already exists')
$Shortcut_Path = Join-Path -Path $Folder -ChildPath $Name
if ((Test-Path -Path $Shortcut_Path) -and (-not $Force)) {
    Write-Error ('Shortcut already exists: {0}. Use -Force to overwrite.' -f $Shortcut_Path) -ErrorAction Stop
}
# Set the default IconPath to the Target file.
if (-not $IconPath) { $IconPath = $Target }

# Convert the WindowStyle to an integer.
switch ($WindowStyle) {
    'Default' { $WindowStyleInt = 1 }
    'Maximized' { $WindowStyleInt = 3 }
    'Minimized' { $WindowStyleInt = 7 }
}
Write-Verbose ('Window Style: {0} [{1}]' -f $WindowStyle, $WindowStyleInt)

Write-Verbose ('Creating shortcut with path: {0}' -f $Shortcut_Path)
$Shell_Object = New-Object -ComObject Wscript.Shell
$Shortcut_Object = $Shell_Object.CreateShortcut($Shortcut_Path)

Write-Verbose ('Adding properties for shortcut:')
Write-Verbose ('- TargetPath: {0}' -f $Target)
Write-Verbose ('- Arguments: {0}' -f $Arguments)
Write-Verbose ('- Start In: {0}' -f $StartIn)
Write-Verbose ('- Comment: {0}' -f $Comment)
Write-Verbose ('- IconPath: {0}' -f $IconPath)
Write-Verbose ('- Icon Index: {0}' -f $IconIndex)
Write-Verbose ('- WindowStyle: {0} ({1})' -f $WindowStyle, $WindowStyleInt)

$Shortcut_Object.TargetPath = $Target
$Shortcut_Object.Arguments = $Arguments
$Shortcut_Object.WorkingDirectory = $StartIn
$Shortcut_Object.Description = $Comment
$Shortcut_Object.IconLocation = '{0},{1}' -f $IconPath, $IconIndex
$Shortcut_Object.WindowStyle = $WindowStyleInt

Write-Verbose ('Saving shortcut')
try {
    $Shortcut_Object.Save()
} catch [System.UnauthorizedAccessException] {
    Write-Error ('Unable to save shortcut: {0}. Check permissions on destination location.' -f $Shortcut_Path) -ErrorAction Stop
}

$global:Shortcut_All_Bytes = [System.IO.File]::ReadAllBytes($Shortcut_Path)
# Check the "Run as Administrator" checkbox involves setting byte 21 (0x15), bit 5 (0x20) to ON.
$global:RunAsAdmin_Bit = 0x20
if ($RunAsAdmin) {
    Write-Verbose ('Setting "Run as Administrator" checkbox')
    $Shortcut_All_Bytes[0x15] = $Shortcut_All_Bytes[0x15] -bor $RunAsAdmin_Bit
    [System.IO.File]::WriteAllBytes($Shortcut_Path, $Shortcut_All_Bytes)
} else {
    # Overwriting an existing shortcut link with "Run as Administrator" set does not remove that checkbox, so here it is removed if required.
    if (($Shortcut_All_Bytes[0x15] -band $RunAsAdmin_Bit) -eq $RunAsAdmin_Bit) {
        Write-Verbose ('Removing "Run as Administrator" checkbox')
        $Shortcut_All_Bytes[0x15] = $Shortcut_All_Bytes[0x15] -bxor $RunAsAdmin_Bit
        [System.IO.File]::WriteAllBytes($Shortcut_Path, $Shortcut_All_Bytes)
    }
}
