function Download-File {
    <#
    .SYNOPSIS
        Downloads a file to a temporary location
    .DESCRIPTION
        Downloads a file and returns an object with details about the downloaded file
    .EXAMPLE
        Download-File -URL 'http://www.contoso.com/downloadfile.txt' -Folder 'C:\Temp'
    .NOTES
        Author: Sean Quinlan
        Email:  sean@yster.org
    #>

    [CmdletBinding()]
    param(
        # The URL to the download file
        [Parameter(Mandatory = $true)]
        [String]
        $URL,

        # The download folder. Defaults to TEMP environment variable
        [Parameter(Mandatory = $false)]
        [String]
        $Folder = $env:TEMP
    )

    # Set the allowed security protocols to all versions of TLS
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Tls,Tls11,Tls12'

    $Download_File = Join-Path -Path $Folder -ChildPath (Split-Path -Path $URL -Leaf)
    $Download_Succeeded = $false

    try {
        Write-Verbose ('Downloading file [{0}] to [{1}]' -f $URL, $Download_File)
        Invoke-WebRequest -Uri $URL -OutFile $Download_File
        if (Test-Path -Path $Download_File) {
            $Download_Succeeded = $true
        }
    } catch {
        Write-Verbose ('Failed to download file:')
        Write-Verbose ($_.Exception.Message)
    }

    # Return an object with the download details
    [PSCustomObject]@{
        'Succeeded' = $Download_Succeeded
        'Path'      = $Download_File
    }
}
