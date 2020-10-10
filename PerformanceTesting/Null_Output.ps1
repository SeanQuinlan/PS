# Some tests to find out the fastest method of suppressing output.

$Size = 1000
$TestArray = 1..$Size
$Output = New-Object -TypeName 'System.Collections.ArrayList'

# Using [void]
$Measure_Array = Measure-Command {
    for ($i = 0; $i -lt $TestArray.Count; $i++) {
        [void]'Test String'
    }
}

[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Using [void]'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

# Using Out-Null
$Measure_Array = Measure-Command {
    for ($i = 0; $i -lt $TestArray.Count; $i++) {
        'Test String' | Out-Null
    }
}

[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Using Out-Null'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

# Using $null =
$Measure_Array = Measure-Command {
    for ($i = 0; $i -lt $TestArray.Count; $i++) {
        $null = 'Test String'
    }
}

[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Using $null ='
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

$Output | Sort-Object Time -Descending
