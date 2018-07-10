function Get-WindowsVersion {
    <#
    .SYNOPSIS
        Gets the version of Windows installed
    .DESCRIPTION
        Outputs an object with properties related the version of Windows installed
    .EXAMPLE
        Get-WindowsVersion
    .NOTES
        Author: Sean Quinlan
        Email:  sean@yster.org
    #>
    [CmdletBinding()]
    param()

    # Use Get-CimInstance if possible
    if ($PSVersionTable.PSVersion.Major -ge 3) {
        $WMICIMDetails = Get-CimInstance -ClassName Win32_OperatingSystem
    } else {
        $WMICIMDetails = Get-WmiObject -Class Win32_OperatingSystem
    }

    # Split the Version string into Major, Minor and Build
    $VersionMajor,$VersionMinor,$VersionBuild = $WMICIMDetails.Version.Split('.')

    # Output the WindowsVersion object
    [pscustomobject]@{
        'Caption'       = $WMICIMDetails.Caption
        'Version'       = $WMICIMDetails.Version
        'VersionMajor'  = $VersionMajor
        'VersionMinor'  = $VersionMinor
        'VerisonBuild'  = $VersionBuild
        'Architecture'  = $WMICIMDetails.OSArchitecture
    }
}
