function Get-DotNetVersion {
    <#
    .SYNOPSIS
        Gets the highest version of .NET framework installed
    .DESCRIPTION
        Outputs an object with properties related the version of .NET framework installed
    .EXAMPLE
        Get-DotNetVersion
    .NOTES
        Modified from gist here: https://gist.github.com/Jaykul/a1e448d982d469e82d9a4244585d85f2

        Author: Sean Quinlan
        Email:  sean@yster.org
    #>
    [CmdletBinding()]
    param(
        # Output all .NET versions found, not just the latest version
        [switch]
        $All
    )

    # .NET versions from v4.5 up are detailed here: https://github.com/dotnet/docs/blob/master/docs/framework/migration-guide/how-to-determine-which-versions-are-installed.md
    $Version_Table = @{
        378389 = [version]'4.5'
        378675 = [version]'4.5.1'
        378758 = [version]'4.5.1'
        379893 = [version]'4.5.2'
        393295 = [version]'4.6'
        393297 = [version]'4.6'
        394254 = [version]'4.6.1'
        394271 = [version]'4.6.1'
        394802 = [version]'4.6.2'
        394806 = [version]'4.6.2'
        460798 = [version]'4.7'
        460805 = [version]'4.7'
        461308 = [version]'4.7.1'
        461310 = [version]'4.7.1'
        461808 = [version]'4.7.2'
        461814 = [version]'4.7.2'
    }

    $DotNet_Framework_RegKey = 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP'
    $All_DotNet_Framework_Keys = Get-ChildItem -Path $DotNet_Framework_RegKey -Recurse | Get-ItemProperty -Name 'Version','Release' -ErrorAction SilentlyContinue

    if ($All) {
        $DotNet_Versions = $All_DotNet_Framework_Keys | Where-Object { $_.PSChildName -match '^(?!S|W)\p{L}' }
    } else {
        $DotNet_Versions = $All_DotNet_Framework_Keys | Where-Object { $_.PSChildName -eq 'Full' }
    }

    $DotNet_Versions | ForEach-Object {
        if ($_.Release) {
            $Release = $Version_Table[$_.Release]
        } elseif ($_.Version -match '^4\.0') {
            $Release = [version]'4.0'
        } else {
            $Release = [version]$_.PSChildName.TrimStart('v')
        }
        [pscustomobject]@{
            'FrameworkType'     = $_.PSChildName
            'Version'           = $Release
            'Release'           = $_.Release
            'SpecificVersion'   = $_.Version
        }
    }
}
