<#
.SYNOPSIS
    Gets a list of programs installed on a computer. Trying to match what is displayed in Control Panel - Programs
.DESCRIPTION
    Gets a list of programs installed on a computer, directly from the registry, and including some useful registry values
.EXAMPLE
    .\Get-Programs.ps1 | Select-Object Name,Publisher,InstalledOn,Size,Version | Sort-Object Name | Format-Table

    Gets a list of programs installed on the local computer, in a format that matches the output in Control Panel - Programs
.EXAMPLE
    @('server1','server2') | .\Get-Programs.p1

    Gets a list of programs installed on the named servers
.INPUTS
    Array of ComputerNames
.OUTPUTS
    PSCustomObject with relevant properties
.NOTES
    Author: Sean Quinlan
    Email:  sean@yster.org
#>
#Requires -Version 5

[CmdletBinding()]
param(
    # Computer(s) to run against
    [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
    [Alias('Name', 'CN')]
    [String[]]
    $ComputerName = 'localhost',

    # Include programs marked as SystemComponent
    [Parameter(Mandatory = $false)]
    [Switch]
    $SystemComponent
)

begin {
    function Get-FriendlySize {
        <#
        .SYNOPSIS
            Formats a number of bytes into a more human-friendly format
        .DESCRIPTION
            This will format a number of bytes into a human-friendly format. Allows selecting the number of decimal places to return.

            Allows returning of the following special format types:
            - Programs - the size format used in the Control Panel - Programs window
        .EXAMPLE
            Get-FriendlySize -Bytes 1024 -Decimals 3
        .EXAMPLE
            Get-FriendlySize -Bytes (1024*1024) -FormatType 'Programs'
        #>

        [CmdletBinding()]
        param(
            # The bytes to convert from
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            $Bytes,

            # The number of decimal places to return. Default is 2 decimal places
            [Parameter(Mandatory = $false)]
            [ValidateNotNullOrEmpty()]
            [Int]
            $Decimals = 2,

            # The special type of formatting to return
            [Parameter(Mandatory = $false)]
            [ValidateSet('Programs')]
            [String]
            $FormatType
        )

        # All the possible size units
        $Size_Units = @('B', 'KB', 'MB', 'GB', 'TB')
        $Index = 0
        while ($Bytes -gt 1KB) {
            $Bytes = $Bytes / 1KB
            $Index++
        }

        # Return the formatting the same way as it appears in the Control Panel - Programs:
        # - For numbers less than 10, use 2 decimals
        # - For numbers between 10 and 100, use 1 decimal
        # - For numbers greater than 100, use no decimals
        if ($FormatType -eq 'Programs') {
            if ([Math]::Round($Bytes) -ge 100) {
                $Decimals = 0
            } elseif ([Math]::Round($Bytes) -ge 10) {
                $Decimals = 1
            } else {
                $Decimals = 2
            }
        }

        # Return the friendly size with units
        "{0:N$($Decimals)} {1}" -f $Bytes, $Size_Units[$Index]
    }

    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('Arguments: {0} - {1}' -f $_.Key, ($_.Value -join ' ')) }
    $Registry_Locations = @('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall')
    if ($env:PROCESSOR_ARCHITECTURE -eq 'x86') {
        Write-Warning 'Running in PowerShell (x86). Only x86 software will be captured. Run from PowerShell console on x64 machine to capture all software'
    }
    if ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64') {
        $Registry_Locations += 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    }
}

process {
    foreach ($Current_ComputerName in $ComputerName) {
        # Access HKLM in all cases, but only open HKCU for local machine
        $Registry_Hives = @('LocalMachine')
        if (($Current_ComputerName -eq 'localhost') -or ($Current_ComputerName -eq $env:COMPUTERNAME)) {
            $Registry_Hives += 'CurrentUser'
        }

        foreach ($Current_Registry_Hive in $Registry_Hives) {
            try {
                Write-Verbose ('Opening {0} hive on: {1}' -f $Current_Registry_Hive, $Current_ComputerName)
                if ($Registry_Hives -contains 'CurrentUser') {
                    $Open_Registry_Hive = [Microsoft.Win32.RegistryKey]::OpenBaseKey($Current_Registry_Hive, 'Default')
                } else {
                    $Open_Registry_Hive = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Current_Registry_Hive, $Current_ComputerName, 'Default')
                }
            } catch {
                Write-Warning ('Unable to open registry on: {0}' -f $Current_ComputerName)
                continue
            }

            foreach ($Registry_Location in $Registry_Locations) {
                Write-Verbose ('{0}: [{1}] Opening key: {2}' -f $Current_ComputerName, $Current_Registry_Hive, $Registry_Location)
                $Current_Reg_Key = $Open_Registry_Hive.OpenSubKey($Registry_Location)

                # Sometimes the registry keys don't exist, so catch any errors here and set the subkeys variable to $null
                try {
                    $Current_Reg_Key_Subkeys = $Current_Reg_Key.GetSubKeyNames()
                    Write-Verbose ('Found subkeys: {0}' -f $Current_Reg_Key_Subkeys -join ',')
                } catch {
                    $Current_Reg_Key_Subkeys = $null
                    Write-Verbose ('No subkeys found')
                }

                if ($Current_Reg_Key_Subkeys) {
                    $Current_Reg_Key_Subkeys | ForEach-Object {
                        $Current_SubKey = Join-Path -Path $Registry_Location -ChildPath $_
                        Write-Verbose ('Getting DisplayName from SubKey: {0}' -f $Current_SubKey)
                        $Current_SubKey_DisplayName = ($Open_Registry_Hive.OpenSubKey($Current_SubKey)).GetValue('DisplayName')
                        $Current_SubKey_SystemComponent = ($Open_Registry_Hive.OpenSubKey($Current_SubKey)).GetValue('SystemComponent')
                        $Current_Subkey_ParentKeyName = ($Open_Registry_Hive.OpenSubKey($Current_SubKey)).GetValue('ParentKeyName')
                        if (-not $Current_SubKey_DisplayName) {
                            Write-Verbose ('- No DisplayName found, ignoring...')
                        } elseif (($Current_SubKey_SystemComponent -eq '1') -and (-not $SystemComponent)) {
                            Write-Verbose ('- DisplayName: {0}' -f $Current_SubKey_DisplayName)
                            Write-Verbose ('- SystemComponent flag set to 1, ignoring...')
                        } elseif ($Current_Subkey_ParentKeyName -and (-not $SystemComponent)) {
                            Write-Verbose ('- DisplayName: {0}' -f $Current_SubKey_DisplayName)
                            Write-Verbose ('- ParentKeyName: {0}' -f $Current_Subkey_ParentKeyName)
                            Write-Verbose ('- ParentKeyName found, ignoring...')
                        } else {
                            Write-Verbose ('- DisplayName: {0}' -f $Current_SubKey_DisplayName)
                            $Current_SubKey_InstallDate = ($Open_Registry_Hive.OpenSubKey($Current_SubKey)).GetValue('InstallDate')
                            if ($Current_SubKey_InstallDate -match '\d{8}') {
                                # Sometimes the InstallDate is 8 digits but not a proper date (Discord does this)
                                # So if we encounter an error in the date parsing, simply set the date to $null as a fall-back
                                try {
                                    $Current_SubKey_InstallDate = '{0:d}' -f [DateTime]::ParseExact($Current_SubKey_InstallDate, "yyyyMMdd", $null)
                                } catch {
                                    $Current_SubKey_InstallDate = $null
                                }
                            }
                            $Current_SubKey_EstimatedSize = ($Open_Registry_Hive.OpenSubKey($Current_SubKey)).GetValue('EstimatedSize')
                            $Raw_Size = [int]$Current_SubKey_EstimatedSize
                            $Calculated_Size = $null
                            if ($Raw_Size) {
                                $Calculated_Size = Get-FriendlySize -Bytes ($Raw_Size * 1024) -FormatType 'Programs'
                            }

                            [PSCustomObject]@{
                                'Computer'        = $Current_ComputerName
                                'Name'            = $Current_SubKey_DisplayName
                                'Publisher'       = ($Open_Registry_Hive.OpenSubKey($Current_SubKey)).GetValue('Publisher')
                                'InstalledOn'     = $Current_SubKey_InstallDate
                                'Size'            = $Calculated_Size
                                'SizeInKB'        = $Current_SubKey_EstimatedSize
                                'Version'         = ($Open_Registry_Hive.OpenSubKey($Current_SubKey)).GetValue('DisplayVersion')
                                'Path'            = '{0}:\{1}' -f $Current_Registry_Hive, $Current_SubKey
                                'UninstallString' = ($Open_Registry_Hive.OpenSubKey($Current_SubKey)).GetValue('UninstallString')
                                'InstallLocation' = ($Open_Registry_Hive.OpenSubKey($Current_SubKey)).GetValue('InstallLocation')
                            }
                        }
                    }
                }
            }
        }
    }
}
