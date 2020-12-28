<#
.SYNOPSIS
    A script to find and optionally fix unquoted service or uninstall paths.
.DESCRIPTION
    This script will look through the registry for service paths and optionally for uninstall strings which contain a space and are not quoted.
    These unquoted paths can be used in certain circumstances to elevate privileges and are generally considered a vector to exploit the computer.

    The script can be used to scan the local machine, or any remote servers.
    Remote servers do require that the "Remote Registry" service is started and that the user running the script has sufficient rights to modify the registry.

    By default, the script will open a gridview output window with the fixes that it intends to make. Selecting one or more of the changes from this list will apply them.
    Additionally the script can be configured to run in non-interactive mode to automatically fix any paths it finds.

    Lastly, the script can be set to save the required fixes to a file for later review. This file can be imported to apply just the specified fixes.
.EXAMPLE
    .\Fix-UnquotedPaths.ps1

    Running the script with no additional parameters will look at the current host and display a gridview of any unquoted paths it finds.
    Selecting any entries from the gridview list will perform the fix for those entries.
.EXAMPLE
    .\Fix-UnquotedPaths.ps1 -ComputerName SERVER1,SERVER2,SERVER3

    This will check the service paths of supplied servers and will present a gridview with any unquoted paths it finds along with the suggested fix for those entries.
    Selecting one or more entries from the list will perform the fix on those entries.
.EXAMPLE
    .\Fix-UnquotedPaths.ps1 -ComputerName SERVER1,SERVER2,SERVER3 -FixUninstall

    This will check the service paths and uninstall paths for the given servers and present the results in a gridview, along with the suggested fixes.
    Selecting one or more entries from the list will perform the fix on those entries.
.EXAMPLE
    .\Fix-UnquotedPaths.ps1 -ComputerName SERVER1,SERVER2,SERVER3 -FixUninstall -ExpandEnvironmentVariables

    This will check the service paths and uninstall paths for the given servers and will additionally expand any environment variables that are found, before presenting the results in a gridview.
    Many service paths or uninstall paths use environment variables like %PROGRAMFILES% without quotes. When these variables are expanded at runtime, they are vulnerable to the same exploit if the expanded path has a space in it.
    The ExpandEnvironmentVariables parameter will first expand the variable before checking to see if it needs to have quotes around it.
    Selecting one or more entries from the gridview will perform the fix on those entries.
.EXAMPLE
    .\Fix-UnquotedPaths.ps1 -ComputerName SERVER1,SERVER2,SERVER3 -NonInteractive -WhatIf

    This will check the service paths for the supplied servers and display the results of what the script would do in the console.
    No changes will be made to any servers.
.EXAMPLE
    .\Fix-UnquotedPaths.ps1 -ComputerName SERVER1,SERVER2,SERVER3 -NonInteractive

    This will check the service paths for the supplied servers and attempt to fix any unquoted paths it finds.
    A prompt will be given for each path it will attempt to fix, and that change can be confirmed or not.
.EXAMPLE
    .\Fix-UnquotedPaths.ps1 -ComputerName localhost -NonInteractive -FixUninstall -Confirm:$false

    This will check the service paths and uninstall paths for the local machine.
    If any unquoted paths are found, they will be fixed automatically with no extra prompts.
.EXAMPLE
    .\Fix-UnquotedPaths.ps1 -ComputerName SERVER1,SERVER2,SERVER3 -FixUninstall -ReportOnly

    This will check the service paths and uninstall paths for the servers in the supplied list.
    The output of the check will be saved to a CSV file in the %TEMP% folder. The path to the file will be output to the console.
    No changes will be made to the servers.
.EXAMPLE
    .\Fix-UnquotedPaths.ps1 -ComputerName localhost -ReportOnly -Path C:\ProgramData\UnquotedPaths.csv

    This will check the service paths for the local machine and output the results to the path specified.
    No changes will be made to the local machine.
.EXAMPLE
    .\Fix-UnquotedPaths.ps1 -ReportInput C:\ProgramData\UnquotedPaths.csv

    This will import the list of changes in the provided file and will apply the fixes. No further confirmation will be required.
.LINK
    https://cwe.mitre.org/data/definitions/428.html
    https://isc.sans.edu/diary/Help+eliminate+unquoted+path+vulnerabilities/14464
    https://www.tenable.com/plugins/nessus/63155
.NOTES
    Author: Sean Quinlan
    Email:  sean@yster.org
#>
#Requires -Version 5

[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Default')]
param(
    # Computer(s) to run against.
    [Parameter(Mandatory = $false, ValueFromPipeline = $true, ParameterSetName = ('Default', 'ReportOut'))]
    [Alias('Name', 'CN')]
    [String[]]
    $ComputerName = $env:COMPUTERNAME,

    # Set this switch in order to check and/or fix the Uninstall keys in the registry as well.
    [Parameter(Mandatory = $false, ParameterSetName = ('Default', 'ReportOut'))]
    [Switch]
    $FixUninstall,

    # Set this switch in order to expand environment variables found in the registry keys.
    # For example, %PROGRAMFILES% will be expanded to 'C:\Program Files', and will thus require quotes around it.
    [Parameter(Mandatory = $false, ParameterSetName = ('Default', 'ReportOut'))]
    [Switch]
    $ExpandEnvironmentVariables,

    # By default, the script will run in interactive mode and show you a GridView list of changes to make.
    # To run this without the interactive prompt, specify this switch.
    [Parameter(Mandatory = $false, ParameterSetName = ('Default', 'NonInteractive'))]
    [Switch]
    $NonInteractive,

    # Set this switch to produce a report only, and not attempt any fixes.
    [Parameter(Mandatory = $false, ParameterSetName = 'ReportOut')]
    [Switch]
    $ReportOnly,

    # Provide a path for the report file. If no path is given, a temporary file will be created for the report.
    [Parameter(Mandatory = $false, ParameterSetName = 'ReportOut')]
    [String]
    $Path = (Join-Path -Path $env:TEMP -ChildPath ('{0}.csv' -f [System.IO.Path]::GetRandomFileName())),

    # Provide the path for an input file.
    [Parameter(Mandatory = $false, ParameterSetName = 'ReportInput')]
    [String]
    $ReportInput
)

begin {
    function Get-UnquotedPaths {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [String[]]
            $ComputerName,

            [Parameter(Mandatory = $true)]
            [String[]]
            $Locations,

            [Parameter(Mandatory = $true)]
            [String[]]
            $Values,

            [Parameter(Mandatory = $true)]
            [String]
            $EnvironmentVariablesOption
        )
        $Unquoted_Value_Regex = '(?<Command>^(?!\u0022).*\s.*\.exe(?<!\u0022))(?<Arguments>.*$)'

        foreach ($Current_ComputerName in $ComputerName) {
            try {
                if (($Current_ComputerName -eq $env:COMPUTERNAME) -or ($Current_ComputerName -eq 'localhost')) {
                    $Registry_Hive = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Default')
                } else {
                    $Registry_Hive = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Current_ComputerName, 'Default')
                }
            } catch {
                Write-Warning ('Unable to open remote registry on: {0}' -f $Current_ComputerName)
                continue
            }

            foreach ($Registry_Location in $Locations) {
                # Certain registry keys may not exist on certain target computers (eg. 64-bit Uninstall key not existing on 32-bit version of Windows).
                Write-Verbose ('{0}: Opening key: {1}' -f $Current_ComputerName, $Registry_Location)
                try {
                    $Current_Root_Registry_Key = $Registry_Hive.OpenSubKey($Registry_Location)
                    $Root_Registry_SubKeys = $Current_Root_Registry_Key.GetSubKeyNames()
                } catch {
                    $Root_Registry_SubKeys = $null
                    Write-Verbose ('{0}: No subkeys found for: {1}' -f $Current_ComputerName, $Registry_Location)
                }

                if ($Root_Registry_SubKeys) {
                    $Root_Registry_SubKeys | ForEach-Object {
                        $Current_SubKey_Path = Join-Path -Path $Registry_Location -ChildPath $_
                        $Current_Reg_SubKey = $Registry_Hive.OpenSubKey($Current_SubKey_Path)
                        foreach ($Unquoted_Registry_Value in $Values) {
                            $Registry_Value_To_Check = ($Current_Reg_SubKey).GetValue($Unquoted_Registry_Value, $null, [Microsoft.Win32.RegistryValueOptions]::$EnvironmentVariablesOption)
                            if ($Registry_Value_To_Check) {
                                if ($Registry_Value_To_Check -match $Unquoted_Value_Regex) {
                                    Write-Verbose ('{0}: Found unquoted value at: {1}\{2}' -f $Current_ComputerName, $Current_SubKey_Path, $Unquoted_Registry_Value)
                                    Write-Verbose ('{0}: Unquoted Value: {1}' -f $Current_ComputerName, $Registry_Value_To_Check)
                                    $Correctly_Quoted_Value = '"{0}"{1}' -f $Matches.Command, $Matches.Arguments
                                    Write-Verbose ('{0}: Quoted Value:  {1}' -f $Current_ComputerName, $Correctly_Quoted_Value)
                                    [pscustomobject]@{
                                        'ComputerName'  = $Current_ComputerName
                                        'RegistryKey'   = $Current_SubKey_Path
                                        'RegistryValue' = $Unquoted_Registry_Value
                                        'OriginalValue' = $Registry_Value_To_Check
                                        'FixedValue'    = $Correctly_Quoted_Value
                                    }
                                }
                                break
                            }
                        }
                    }
                }
            }
        }
    }

    function Set-UnquotedPaths {
        [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
        param(
            [Parameter(Mandatory = $true)]
            [Object]
            $InputObject,

            [Parameter(Mandatory = $true)]
            [String]
            $EnvironmentVariablesOption
        )
        Write-Verbose ('Set-UnquotedPaths starting')

        $Grouped_By_ComputerName = $InputObject | Group-Object 'ComputerName'
        $Grouped_By_ComputerName | ForEach-Object {
            $Confirm_Header = New-Object -TypeName 'System.Text.StringBuilder'
            [void]$Confirm_Header.AppendLine('Confirm')
            [void]$Confirm_Header.AppendLine('Are you sure you want to perform this action?')

            $Current_ComputerName = $_.Name
            try {
                Write-Verbose ('Opening registry on: {0}' -f $Current_ComputerName)
                if (($Current_ComputerName -eq $env:COMPUTERNAME) -or ($Current_ComputerName -eq 'localhost')) {
                    $Registry_Hive = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Default')
                } else {
                    $Registry_Hive = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Current_ComputerName, 'Default')
                }
            } catch {
                Write-Warning ('Unable to open remote registry on: {0}' -f $Current_ComputerName)
                continue
            }

            foreach ($Registry_Entry in $_.Group) {
                Write-Verbose ('{0}: Opening key: {1}' -f $Current_ComputerName, $Registry_Entry.RegistryKey)
                $Current_Registry_Key = $Registry_Hive.OpenSubKey($Registry_Entry.RegistryKey, $true)

                try {
                    $Current_Registry_Value = $Current_Registry_Key.GetValue($Registry_Entry.RegistryValue, $null, [Microsoft.Win32.RegistryValueOptions]::$EnvironmentVariablesOption)
                    if ($Current_Registry_Value -eq $Registry_Entry.OriginalValue) {
                        $Current_Registry_ValueKind = $Current_Registry_Key.GetValueKind($Registry_Entry.RegistryValue)
                        Write-Verbose ('{0}: Registry value [{1}] matches: {2}' -f $Current_ComputerName, $Registry_Entry.RegistryValue, $Registry_Entry.OriginalValue)
                        Write-Verbose ('{0}: Setting fixed value of [{1}]' -f $Current_ComputerName, $Registry_Entry.FixedValue)
                        $WhatIf_Statement = 'Setting registry key "{0}" on {1} to: {2}' -f "$($Registry_Entry.RegistryKey)\$($Registry_Entry.RegistryValue)", $Current_ComputerName, $Registry_Entry.FixedValue

                        $Confirm_Statement = $WhatIf_Statement
                        if ($PSCmdlet.ShouldProcess($WhatIf_Statement, $Confirm_Statement, $Confirm_Header.ToString())) {
                            try {
                                $Current_Registry_Key.SetValue($Registry_Entry.RegistryValue, $Registry_Entry.FixedValue, [Microsoft.Win32.RegistryValueKind]::$Current_Registry_ValueKind)
                            } catch {
                                throw $_
                            }
                        }
                    } else {
                        Write-Warning ('{0}: Current registry value of [{1}] does not match OriginalValue of [{2}]' -f $Current_ComputerName, $Current_Registry_Value, $Registry_Entry.OriginalValue)
                    }
                } catch {
                    Write-Warning ('{0}: Unable to get registry value from: {1}' -f $Current_ComputerName, "$($Registry_Entry.RegistryKey)\$($Registry_Entry.RegistryValue)")
                }
            }
        }
    }

    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('Arguments: {0} - {1}' -f $_.Key, ($_.Value -join ' ')) }
    $Registry_Locations = @('SYSTEM\CurrentControlSet\Services')
    $Unquoted_Registry_Values = @('ImagePath')

    if ($FixUninstall) {
        $Registry_Locations += 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
        $Registry_Locations += 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
        $Unquoted_Registry_Values += 'UninstallString'
    }

    if ($ExpandEnvironmentVariables) {
        $EnvironmentVariablesOption = 'None'
    } else {
        $EnvironmentVariablesOption = 'DoNotExpandEnvironmentNames'
    }
}
process {
    if ($ReportInput) {
        $Set_Parameters = @{
            'InputObject'                = Import-Csv -Path $ReportInput
            'EnvironmentVariablesOption' = $EnvironmentVariablesOption
            'Confirm'                    = $false
        }
        Set-UnquotedPaths @Set_Parameters

    } else {
        $Get_Parameters = @{
            'ComputerName'               = $ComputerName
            'Locations'                  = $Registry_Locations
            'Values'                     = $Unquoted_Registry_Values
            'EnvironmentVariablesOption' = $EnvironmentVariablesOption
        }
        $Unquoted_Paths = Get-UnquotedPaths @Get_Parameters
        if (-not $Unquoted_Paths) {
            Write-Host ('No unquoted paths found')
        }

        if ($ReportOnly) {
            try {
                $Unquoted_Paths | Export-Csv -NoTypeInformation -Path $Path -ErrorAction Stop
                Write-Host ('Report saved to file: {0}' -f $Path)
            } catch {
                throw $_
            }
        } elseif ($NonInteractive) {
            $Set_Parameters = @{
                'InputObject'                = $Unquoted_Paths
                'EnvironmentVariablesOption' = $EnvironmentVariablesOption
            }
            Set-UnquotedPaths @Set_Parameters
        } else {
            $Selected_Unquoted_Paths = $Unquoted_Paths | Out-GridView -Title "Select all paths to fix, then click OK. Press Cancel to abort all changes" -PassThru
            if ($Selected_Unquoted_Paths) {
                $Set_Parameters = @{
                    'InputObject'                = $Selected_Unquoted_Paths
                    'EnvironmentVariablesOption' = $EnvironmentVariablesOption
                    'Confirm'                    = $false
                }
                Set-UnquotedPaths @Set_Parameters
            } else {
                Write-Verbose ('No paths selected')
            }
        }
    }
}
