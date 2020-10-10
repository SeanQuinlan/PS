function Write-Log {
    <#
    .SYNOPSIS
        Writes a string or array or object to a log file, in addition to other stream(s), if specified
    .DESCRIPTION
        Writes string/array/object to a log file.
        Log file can be specified on the command line, or via the $WriteLogPath script scope variable.
        If no log file is given, it will log to a text file with the same name as the script, with the current yyyyMMdd appended.
        In addition, can log to one or more of the other output streams: Debug, Error, Host, Information, Progress, Verbose, Warning

        The following script scope variables can be declared in order to set defaults for the function to use, without needing to pass them to every call
            * $script:WriteLogPath - Path to the log file
            * $script:WriteLogDatePrefix - The date format to use
    .EXAMPLE
        Write-Log -Message 'This is a test log line' -Path 'c:\windows\temp\log.txt' -OutHost
    .EXAMPLE
        $WriteLogPath = 'C:\Windows\Temp\Log1.txt'
        Write-Log 'This is a test log line'
    .EXAMPLE
        'This is test log line' | Write-Log
    .NOTES
        This is mostly designed for single text strings or an array of text strings
        Outputting objects to this function will most likely not result in the desired formatting in the log file
        Objects should be formatted into strings first, and then sent to the function

        For some stream output to work (eg. Verbose), requires [cmdletbinding()] at the top of the script in order to pass the VerbosePreference to the function

        Author: Sean Quinlan
        Email:  sean@yster.org
    #>
    [CmdletBinding()]
    param(
        # The text, or array of text to output to the log file
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('LogText', 'InputObject', 'Object', 'MessageData')]
        [Array]
        $Message,

        # The path to the log file
        [Parameter(
            Mandatory = $false,
            Position = 1
        )]
        [Alias('Log', 'LogFile', 'LogPath')]
        [String]
        $Path = $(if ($script:WriteLogPath) { $script:WriteLogPath } else { (Join-Path -Path $PSScriptRoot -ChildPath ('{0}-{1}.log' -f ([io.fileinfo]$PSCommandPath).BaseName, (Get-Date -Format yyyyMMdd))) } ),

        # The DateFormat to prefix each line with
        [Alias('DateFormat')]
        [String]
        $DatePrefix = $(if ($script:WriteLogDatePrefix) { $script:WriteLogDatePrefix } else { Get-Date -Format 'yyyy-MM-dd HH:mm:ss' } ),

        # Output to Debug stream
        [Switch]
        $OutDebug,

        # Output to Error stream
        [Alias('OutErr')]
        [Switch]
        $OutError,

        # Output to Host/Console stream
        [Alias('OutConsole')]
        [Switch]
        $OutHost,

        # Output to Information stream
        [Alias('OutInfo')]
        [Switch]
        $OutInformation,

        # Output to Progress stream
        [Switch]
        $OutProgress,

        # Output to Verbose stream
        [Switch]
        $OutVerbose,

        # Output to Warning stream
        [Switch]
        $OutWarning
    )

    process {
        foreach ($Line in $Message) {
            '{0} {1}' -f $DatePrefix, $Line | Out-File -FilePath $Path -Append
            switch ($true) {
                $OutDebug { Write-Debug $Line }
                $OutError { Write-Error $Line }
                $OutHost { Write-Host $Line }
                $OutInformation { Write-Information $Line }
                $OutProgress { Write-Progress $Line }
                $OutVerbose { Write-Verbose $Line }
                $OutWarning { Write-Warning $Line }
            }
        }
    }
}
