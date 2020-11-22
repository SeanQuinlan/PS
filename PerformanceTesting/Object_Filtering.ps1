# Testing different methods to filter an array

$Size = 10000
$TestArray = 1..$Size
$Output = New-Object -TypeName 'System.Collections.ArrayList'

# Using good old Where-Object
$Measure_Array = Measure-Command {
    $OutArray = $TestArray | Where-Object { $_ % 2 -eq 0 }
}

Remove-Variable -Name OutArray -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Simple filter using Where-Object'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

# Using the newwer .Where() method
$Measure_Array = Measure-Command {
    $OutArray = $TestArray.Where( { $_ % 2 -eq 0 })
}

Remove-Variable -Name OutArray -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Simple filter using Where() method'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

# Split into 2 arrays using Where-Object
$Measure_Array = Measure-Command {
    $OutArray = $TestArray | Where-Object { $_ % 2 -eq 0 }
    $OutArrayNot = $TestArray | Where-Object { $_ % 2 -ne 0 }
}

Remove-Variable -Name OutArray -ErrorAction Ignore
Remove-Variable -Name OutArrayNot -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Split into 2 using Where-Object'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

# Split into 2 arrays using the .Where() method
$Measure_Array = Measure-Command {
    $OutArray, $OutArrayNot = $TestArray.Where( { $_ % 2 -eq 0 }, 'Split')
}

Remove-Variable -Name OutArray -ErrorAction Ignore
Remove-Variable -Name OutArrayNot -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Split into 2 using Where() method'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

# Split into 2 arrays using Foreach-Object
$Measure_Array = Measure-Command {
    $OutArray = New-Object -TypeName 'System.Collections.Generic.List[psobject]'
    $OutArrayNot = New-Object -TypeName 'System.Collections.Generic.List[psobject]'
    $TestArray | ForEach-Object {
        if ($_ % 2 -eq 0) {
            $OutArray.Add($_)
        } else {
            $OutArrayNot.Add($_)
        }
    }
}

Remove-Variable -Name OutArray -ErrorAction Ignore
Remove-Variable -Name OutArrayNot -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Split into 2 using Foreach-Object'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)


$Output | Sort-Object Time -Descending
