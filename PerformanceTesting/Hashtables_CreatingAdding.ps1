# Some tests to find out the fastest method of creating/adding to a hashtable.

$Size = 10000
$TestArray = 1..$Size
$Output = New-Object -TypeName 'System.Collections.ArrayList'

# Using the traditional += method.
$Measure_Hashtable = Measure-Command {
    $Hashtable = @{ }
    for ($i = 0; $i -lt $TestArray.Count; $i++) {
        $Hashtable += @{
            "Key_$($TestArray[$i])" = "Value_$($TestArray[$i])"
        }
    }
}
Remove-Variable -Name Hashtable -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Hashtable created via PlusEquals + for loop'
        'Time' = $Measure_Hashtable.TotalMilliseconds
    }
)

$Measure_Hashtable = Measure-Command {
    $Hashtable = @{ }
    foreach ($i in $TestArray) {
        $Hashtable += @{
            "Key_$($i)" = "Value_$($i)"
        }
    }
}
Remove-Variable -Name Hashtable -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Hashtable created via PlusEquals + foreach loop'
        'Time' = $Measure_Hashtable.TotalMilliseconds
    }
)

$Measure_Hashtable = Measure-Command {
    $Hashtable = @{ }
    $TestArray | ForEach-Object {
        $Hashtable += @{
            "Key_$($_)" = "Value_$($_)"
        }
    }
}
Remove-Variable -Name Hashtable -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Hashtable created via PlusEquals + foreach-object loop'
        'Time' = $Measure_Hashtable.TotalMilliseconds
    }
)

# Using direct key assignment.
$Measure_Hashtable = Measure-Command {
    $Hashtable = @{ }
    for ($i = 0; $i -lt $TestArray.Count; $i++) {
        $Hashtable["Key_$($TestArray[$i])"] = "Value_$($TestArray[$i])"
    }
}
Remove-Variable -Name Hashtable -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Hashtable created via Key Assignment + for loop'
        'Time' = $Measure_Hashtable.TotalMilliseconds
    }
)

$Measure_Hashtable = Measure-Command {
    $Hashtable = @{ }
    foreach ($i in $TestArray) {
        $Hashtable["Key_$($i)"] = "Value_$($i)"
    }
}
Remove-Variable -Name Hashtable -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Hashtabe created via Key Assignment + foreach loop'
        'Time' = $Measure_Hashtable.TotalMilliseconds
    }
)

$Measure_Hashtable = Measure-Command {
    $Hashtable = @{ }
    $TestArray | ForEach-Object {
        $Hashtable["Key_$($_)"] = "Value_$($_)"
    }
}
Remove-Variable -Name Hashtable -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Hashtable created via Key Assignment + foreach-object loop'
        'Time' = $Measure_Hashtable.TotalMilliseconds
    }
)

# Using the .Add() method.
$Measure_Hashtable = Measure-Command {
    $Hashtable = @{ }
    for ($i = 0; $i -lt $TestArray.Count; $i++) {
        $Hashtable.Add("Key_$($TestArray[$i])", "Value_$($TestArray[$i])")
    }
}
Remove-Variable -Name Hashtable -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Hashtable created via .Add() method + for loop'
        'Time' = $Measure_Hashtable.TotalMilliseconds
    }
)

$Measure_Hashtable = Measure-Command {
    $Hashtable = @{ }
    foreach ($i in $TestArray) {
        $Hashtable.Add("Key_$($i)", "Value_$($i)")
    }
}
Remove-Variable -Name Hashtable -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Hashtabe created via .Add() method + foreach loop'
        'Time' = $Measure_Hashtable.TotalMilliseconds
    }
)

$Measure_Hashtable = Measure-Command {
    $Hashtable = @{ }
    $TestArray | ForEach-Object {
        $Hashtable.Add("Key_$($_)", "Value_$($_)")
    }
}
Remove-Variable -Name Hashtable -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Hashtable created via .Add() method + foreach-object loop'
        'Time' = $Measure_Hashtable.TotalMilliseconds
    }
)

$Output | Sort-Object Time -Descending
