function New-ISOFile {
    <#
    .SYNOPSIS
        Creates an ISO file from a list of paths.
    .DESCRIPTION
        Creates an ISO file based on a specified path or list of paths.
    .EXAMPLE
        New-ISOFile -Path C:\ISOs\Boot -DestinationPath C:\boot.iso
    .EXAMPLE
        New-ISOFile -Path C:\ISOs\Boot,C:\ISOs\Tools -DestinationPath C:\boot-tools.iso -MediaType 'DVDROM' -VolumeName 'Boot Tools'
    .EXAMPLE
        @('C:\ISOs\Tools','C:\ISOs\Readme.txt') | New-ISOFile -DestinationPath C:\Remote1.iso -MediaType 'DVDRW' -FileSystem 'UDF'
    .INPUTS
        [String[]]
        A list of paths that will be added to the ISO file.
    .NOTES
        Author: Sean Quinlan
        Email: sean@yster.org
    #>

    [CmdletBinding()]
    param(
        # Specifies the path or paths to the files that you want to add to the ISO file.
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [String[]]
        $Path,

        # Specifies the path to the ISO output file.
        [Parameter(Mandatory = $true)]
        [String]
        $DestinationPath,

        # The media type for the ISO file.
        # Taken from https://docs.microsoft.com/en-gb/windows/desktop/api/imapi2/ne-imapi2-_imapi_media_physical_type
        [Parameter(Mandatory = $false)]
        [ValidateSet(
            'UNKNOWN',
            'CDROM',
            'CDR',
            'CDRW',
            'DVDROM',
            'DVDRAM',
            'DVDPLUSR',
            'DVDPLUSRW',
            'DVDPLUSR_DUALLAYER',
            'DVDDASHR',
            'DVDDASHRW',
            'DVDDASHR_DUALLAYER',
            'DISK',
            'DVDPLUSRW_DUALLAYER',
            'HDDVDROM',
            'HDDVDR',
            'HDDVDRAM',
            'BDROM',
            'BDR',
            'BDRE',
            'MAX'
        )]
        [String]
        $MediaType = 'DVDPLUSR',

        # The volume name for the ISO file.
        [Parameter(Mandatory = $false)]
        [String]
        $VolumeName,

        # The file system(s) to support.
        # From http://msdn.microsoft.com/en-us/library/windows/desktop/aa364840.aspx
        [Parameter(Mandatory = $false)]
        [ValidateSet(
            'ISO9660',
            'Joliet',
            'UDF'
        )]
        [String[]]
        $FileSystem = @('ISO9660', 'Joliet', 'UDF'),

        # Overwrite the DestinationPath if it already exists
        [Parameter(Mandatory = $false)]
        [Switch]
        $Force
    )

    begin {
        Write-Verbose ('Function: {0} [begin]' -f (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name)
        $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('- Arguments: {0} - {1}' -f $_.Key, ($_.Value -join ' ')) }

        # List of all possible media types
        $Possible_MediaTypes = @(
            'UNKNOWN',
            'CDROM',
            'CDR',
            'CDRW',
            'DVDROM',
            'DVDRAM',
            'DVDPLUSR',
            'DVDPLUSRW',
            'DVDPLUSR_DUALLAYER',
            'DVDDASHR',
            'DVDDASHRW',
            'DVDDASHR_DUALLAYER',
            'DISK',
            'DVDPLUSRW_DUALLAYER',
            'HDDVDROM',
            'HDDVDR',
            'HDDVDRAM',
            'BDROM',
            'BDR',
            'BDRE',
            'MAX'
        )

        # Joliet is an extension to ISO9660, so cannot be specified without it
        if (($FileSystem -contains 'Joliet') -and ($FileSystem -notcontains 'ISO9660')) {
            throw ('Must include "ISO9660" filesystem if specifying "Joliet" filesystem')
        }

        $FileSystem | ForEach-Object {
            switch ($_) {
                'ISO9660' { $FileSystems_ToCreate += 1 }
                'Joliet' { $FileSystems_ToCreate += 2 }
                'UDF' { $FileSystems_ToCreate += 4 }
            }
        }
        Write-Verbose ('FileSystems_ToCreate: {0}' -f $FileSystems_ToCreate)

        $Input_Paths = New-Object -TypeName System.Collections.ArrayList

        $DestinationPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationPath)
        # Add the extension .iso if not already supplied
        if ($DestinationPath -notmatch '.*\.iso$') {
            $DestinationPath = '{0}.iso' -f $DestinationPath
        }
        Write-Verbose ('Full DestinationPath: {0}' -f $DestinationPath)

        if ((Test-Path -Path $DestinationPath) -and (-not $Force)) {
            throw ('The ISO file "{0}" already exists. Use the -Force parameter to overwrite the existing file' -f $DestinationPath)
        }
    }

    process {
        Write-Verbose ('Function: {0} [process]' -f (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name)

        if (-not $PSBoundParameters.ContainsKey('Path')) {
            $Path = $_
        }

        Write-Verbose ('Validating paths...')
        $Path | ForEach-Object {
            # For any wildcards in the Path value, use Resolve-Path to convert them into an array of paths
            if ($_ -match '\*') {
                $Resolved_Paths = $_ | Resolve-Path
                if (-not $Resolved_Paths) {
                    throw ('Path "{0}" resolves to an empty set' -f $_)
                }

                try {
                    $Resolved_Paths | ForEach-Object {
                        Write-Verbose ('- Adding path: {0}' -f $_.Path)
                        [void]$Input_Paths.Add($_.Path)
                    }
                } catch {
                    throw ('Cannot find path "{0}" because it does not exist' -f $_.Path)
                }
            } else {
                # The Write-IStreamToFile function requires absolute paths, so expand any relative paths to absolute paths here
                if (-not (Test-Path -Path $_)) {
                    throw ('Cannot find path "{0}" because it does not exist' -f $_)
                } else {
                    $Expanded_Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($_)
                    Write-Verbose ('- Adding path: {0}' -f $Expanded_Path)
                    [void]$Input_Paths.Add($Expanded_Path)
                }
            }
        }
        Write-Verbose ('Finished validating paths')
    }

    end {
        Write-Verbose ('Function: {0} [end]' -f (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name)

        Write-Verbose ('Creating ISO filesystem...')
        $ISO_FileSystem = New-Object -ComObject IMAPI2FS.MsftFileSystemImage
        $ISO_FileSystem.FileSystemsToCreate = $FileSystems_ToCreate
        $ISO_FileSystem.ChooseImageDefaultsForMediaType($Possible_MediaTypes.IndexOf($MediaType))
        $Input_Paths | ForEach-Object {
            try {
                Write-Verbose ('- Adding: {0}' -f $_)
                $ISO_FileSystem.Root.AddTree($_, $false)
            } catch {
                # Break out if there are any errors adding files/folders to the file system
                throw $_.Exception.Message
                break
            }
        }

        try {
            if ($VolumeName) {
                Write-Verbose ('Setting VolumeName to: {0}' -f $VolumeName)
                if ($VolumeName.Length -gt 32) { Write-Warning 'VolumeName is greater than 32 characters. Any characters after the 32nd will be ignored.' }
                $ISO_FileSystem.VolumeName = $VolumeName
            }
        } catch {
            # Break out if there are any problems setting the VolumeName
            throw $_.Exception.Message
            break
        }
        Write-Verbose ('Finished creating ISO filesystem')

        Write-Verbose ('Writing ISO filesystem to file: {0}' -f $DestinationPath)
        Write-IStreamToFile -IStream $ISO_FileSystem.CreateResultImage().ImageStream -Path $DestinationPath
        Write-Verbose ('Finished writing ISO filesystem to file')
    }
}

function Write-IStreamToFile {
    <#
    .SYNOPSIS
        Writes a COM object to a file.
    .DESCRIPTION
        This takes a COM object and casts it to an IStream, which can then be written to a file.
    .EXAMPLE
        $ISO = New-Object -ComObject IMAPI2FS.MsftFileSystemImage
        $ISO.FileSystemsToCreate = 7
        $ISO.Root.AddTree("C:\Boot", $false)
        Write-IStreamToFile -IStream $ISO.CreateResultImage().ImageStream -Path C:\boot.iso

        This writes the $ISO COM object with the "IMAPI2FS.MsftFileSystemImage" filesystem, to an ISO file.
    .NOTES
        Author: Marnix Klooster (original)
        Modified by: Sean Quinlan

        Taken from https://gist.github.com/marnix/3944688 and modified style
    #>

    [CmdletBinding()]
    param(
        # The IStream COM object that will be written to file.
        [Parameter(Mandatory = $true)]
        [__ComObject]
        $IStream,

        # The path to the ISO file.
        [Parameter(Mandatory = $true)]
        [String]
        $Path
    )

    Write-Verbose ('Entering function: {0}' -f (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Name)
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Verbose ('- Arguments: {0} - {1}' -f $_.Key, ($_.Value -join ' ')) }

    # NOTE: We cannot use [System.Runtime.InteropServices.ComTypes.IStream],
    # since PowerShell apparently cannot convert an IStream COM object to this
    # Powershell type.  (See http://stackoverflow.com/a/9037299/223837 for
    # details.)
    #
    # It turns out that .NET/CLR _can_ do this conversion.
    #
    # That is the reason why method FileUtil.WriteIStreamToFile(), below,
    # takes an object, and casts it to an IStream, instead of directly
    # taking an IStream inputStream argument.

    $Compiler_Parameters = New-Object CodeDom.Compiler.CompilerParameters
    $Compiler_Parameters.CompilerOptions = "/unsafe"
    $Compiler_Parameters.WarningLevel = 4
    $Compiler_Parameters.TreatWarningsAsErrors = $true

    Add-Type -CompilerParameters $Compiler_Parameters -TypeDefinition @"
		using System;
		using System.IO;
		using System.Runtime.InteropServices.ComTypes;
		namespace My
		{
			public static class FileUtil {
				public static void WriteIStreamToFile(object i, string fileName) {
					IStream inputStream = i as IStream;
					FileStream outputFileStream = File.OpenWrite(fileName);
					int bytesRead = 0;
					int offset = 0;
					byte[] data;
					do {
						data = Read(inputStream, 2048, out bytesRead);
						outputFileStream.Write(data, 0, bytesRead);
						offset += bytesRead;
					} while (bytesRead == 2048);
					outputFileStream.Flush();
					outputFileStream.Close();
				}
				unsafe static private byte[] Read(IStream stream, int toRead, out int read) {
				    byte[] buffer = new byte[toRead];
				    int bytesRead = 0;
				    int* ptr = &bytesRead;
				    stream.Read(buffer, toRead, (IntPtr)ptr);
				    read = bytesRead;
				    return buffer;
				}
			}
		}
"@

    [My.FileUtil]::WriteIStreamToFile($IStream, $Path)
}
