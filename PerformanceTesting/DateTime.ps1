# Some tests to find out the fastest method of outputting the date and time.

$Size = 10000
$TestArray = 1..$Size
$Output = New-Object -TypeName 'System.Collections.ArrayList'
$DateFormat = 'yyyy-MM-dd HH:mm:ss'

# Using Get-Date
$Measure_Array = Measure-Command {
    for ($i = 0; $i -lt $TestArray.Count; $i++) {
        Get-Date -Format $DateFormat
    }
}

[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Using Get-Date'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

# Using DateTime::Now
$Measure_Array = Measure-Command {
    for ($i = 0; $i -lt $TestArray.Count; $i++) {
        [DateTime]::Now.ToString($DateFormat)
    }
}

[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'DateTime::Now'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

$Output | Sort-Object Time -Descending
