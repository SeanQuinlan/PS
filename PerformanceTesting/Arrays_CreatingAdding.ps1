# Some tests to find out the fastest method of creating/adding to an array.

$Size = 10000
$TestArray = 1..$Size
$Output = New-Object -TypeName 'System.Collections.ArrayList'

# Using the traditional += method.
$Measure_Array = Measure-Command {
    $ArrayCreate = @()
    for ($i = 0; $i -lt $TestArray.Count; $i++) {
        $ArrayCreate += $TestArray[$i]
    }
}
Remove-Variable -Name ArrayCreate -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Array created via PlusEquals + for loop'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

$Measure_Array = Measure-Command {
    $ArrayCreate = @()
    foreach ($i in $TestArray) {
        $ArrayCreate += $i
    }
}
Remove-Variable -Name ArrayCreate -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Array created via PlusEquals + foreach loop'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

$Measure_Array = Measure-Command {
    $ArrayCreate = @()
    $TestArray | ForEach-Object {
        $ArrayCreate += $_
    }
}
Remove-Variable -Name ArrayCreate -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Array created via PlusEquals + foreach-object loop'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

# Using an ArrayList.
$Measure_Array = Measure-Command {
    $ArrayCreate = New-Object -TypeName 'System.Collections.ArrayList'
    for ($i = 0; $i -lt $TestArray.Count; $i++) {
        [void]$ArrayCreate.Add($TestArray[$i])
    }
}
Remove-Variable -Name ArrayCreate -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Array created via ArrayList + for loop'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

$Measure_Array = Measure-Command {
    $ArrayCreate = New-Object -TypeName 'System.Collections.ArrayList'
    foreach ($i in $TestArray) {
        [void]$ArrayCreate.Add($i)
    }
}
Remove-Variable -Name ArrayCreate -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Array created via ArrayList + foreach loop'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

$Measure_Array = Measure-Command {
    $ArrayCreate = New-Object -TypeName 'System.Collections.ArrayList'
    $TestArray | ForEach-Object {
        [void]$ArrayCreate.Add($_)
    }
}
Remove-Variable -Name ArrayCreate -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Array created via ArrayList + foreach-object loop'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

# Using a Generic List with generic object typing.
$Measure_Array = Measure-Command {
    $ArrayCreate = New-Object -TypeName 'System.Collections.Generic.List[psobject]'
    for ($i = 0; $i -lt $TestArray.Count; $i++) {
        $ArrayCreate.Add($TestArray[$i])
    }
}
Remove-Variable -Name ArrayCreate -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Array created via GenericList (psobject) + for loop'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

$Measure_Array = Measure-Command {
    $ArrayCreate = New-Object -TypeName 'System.Collections.Generic.List[psobject]'
    foreach ($i in $TestArray) {
        $ArrayCreate.Add($i)
    }
}
Remove-Variable -Name ArrayCreate -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Array created via GenericList (psobject) + foreach loop'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

$Measure_Array = Measure-Command {
    $ArrayCreate = New-Object -TypeName 'System.Collections.Generic.List[psobject]'
    $TestArray | ForEach-Object {
        $ArrayCreate.Add($_)
    }
}
Remove-Variable -Name ArrayCreate -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Array created via GenericList (psobject) + foreach-object loop'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

# Using a Generic List with strict typing.
$Measure_Array = Measure-Command {
    $ArrayCreate = New-Object -TypeName ('System.Collections.Generic.List[{0}]' -f $TestArray[0].GetType().Name)
    for ($i = 0; $i -lt $TestArray.Count; $i++) {
        $ArrayCreate.Add($TestArray[$i])
    }
}
Remove-Variable -Name ArrayCreate -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Array created via GenericList (strict) + for loop'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

$Measure_Array = Measure-Command {
    $ArrayCreate = New-Object -TypeName ('System.Collections.Generic.List[{0}]' -f $TestArray[0].GetType().Name)
    foreach ($i in $TestArray) {
        $ArrayCreate.Add($i)
    }
}
Remove-Variable -Name ArrayCreate -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Array created via GenericList (strict) + foreach loop'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

$Measure_Array = Measure-Command {
    $ArrayCreate = New-Object -TypeName ('System.Collections.Generic.List[{0}]' -f $TestArray[0].GetType().Name)
    $TestArray | ForEach-Object {
        $ArrayCreate.Add($_)
    }
}
Remove-Variable -Name ArrayCreate -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Array created via GenericList (strict) + foreach-object loop'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

# By assigning to a variable.
$Measure_Array = Measure-Command {
    $ArrayCreate = for ($i = 0; $i -lt $TestArray.Count; $i++) {
        $TestArray[$i]
    }
}
Remove-Variable -Name ArrayCreate -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Array created via Variable Assignment + for loop'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

$Measure_Array = Measure-Command {
    $ArrayCreate = foreach ($i in $TestArray) {
        $i
    }
}
Remove-Variable -Name ArrayCreate -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Array created via Variable Assignment + foreach loop'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

$Measure_Array = Measure-Command {
    $ArrayCreate = $TestArray | ForEach-Object {
        $_
    }
}
Remove-Variable -Name ArrayCreate -ErrorAction Ignore
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Array created via Variable Assignment + foreach-object loop'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

$Output | Sort-Object Time -Descending
