# Some tests to find out the fastest method of adding to a file (eg. for logging).

$Size = 10000
$TestArray = 1..$Size
$Output = New-Object -TypeName 'System.Collections.ArrayList'
$OutputFolder = "C:\Temp" # Adjust for different disks.
if (-not (Test-Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory | Out-Null
}

# Using Add-Content
$Measure_Array = Measure-Command {
    $OutputFile = "$OutputFolder\FilePerfTest-AddContent-{0}.txt" -f (Get-Date -Format 'yyyy-MM-dd_HHmmss.fff')
    for ($i = 0; $i -lt $TestArray.Count; $i++) {
        "Test$($i)" | Add-Content -Path $OutputFile
    }
}

[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Using Add-Content'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

# Using Out-File
$Measure_Array = Measure-Command {
    $OutputFile = "$OutputFolder\FilePerfTest-OutFile-{0}.txt" -f (Get-Date -Format 'yyyy-MM-dd_HHmmss.fff')
    for ($i = 0; $i -lt $TestArray.Count; $i++) {
        "Test$($i)" | Out-File -FilePath $OutputFile -Append -Encoding utf8
    }
}

[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Using Out-File'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

# Using StreamWriter
$Measure_Array = Measure-Command {
    $OutputFile = "$OutputFolder\FilePerfTest-StreamWriter-{0}.txt" -f (Get-Date -Format 'yyyy-MM-dd_HHmmss.fff')
    for ($i = 0; $i -lt $TestArray.Count; $i++) {
        $StreamWriter = [System.IO.StreamWriter]::new($OutputFile, $true)
        $StreamWriter.WriteLine("Test$($i)")
        $StreamWriter.Close()
    }
}

[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Using StreamWriter'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

$Output | Sort-Object Time -Descending
