# Some tests to find out the fastest method of initialising array variables.

$Size = 1000
$TestArray = 1..$Size
$Output = New-Object -TypeName 'System.Collections.ArrayList'

# Using @()
$Measure_Array = Measure-Command {
    for ($i = 0; $i -lt $TestArray.Count; $i++) {
        New-Variable -Name Array$i -Value @()
    }
}

for ($i = 0; $i -lt $TestArray.Count; $i++) {
    Remove-Variable -Name Array$i -ErrorAction Ignore
}
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Array init via @()'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

# Using New-Object
$Measure_Array = Measure-Command {
    for ($i = 0; $i -lt $TestArray.Count; $i++) {
        New-Variable -Name Array$i -Value (New-Object -TypeName 'System.Collections.ArrayList')
    }
}

for ($i = 0; $i -lt $TestArray.Count; $i++) {
    Remove-Variable -Name Array$i -ErrorAction Ignore
}
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'ArrayList init via New-Object'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

$Measure_Array = Measure-Command {
    for ($i = 0; $i -lt $TestArray.Count; $i++) {
        New-Variable -Name Array$i -Value (New-Object -TypeName 'System.Collections.Generic.List[psobject]')
    }
}

for ($i = 0; $i -lt $TestArray.Count; $i++) {
    Remove-Variable -Name Array$i -ErrorAction Ignore
}
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Generic List init via New-Object'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

# Using ::New() method
$Measure_Array = Measure-Command {
    for ($i = 0; $i -lt $TestArray.Count; $i++) {
        New-Variable -Name Array$i -Value ([System.Collections.ArrayList]::new())
    }
}

for ($i = 0; $i -lt $TestArray.Count; $i++) {
    Remove-Variable -Name Array$i -ErrorAction Ignore
}
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'ArrayList init via New() method'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

$Measure_Array = Measure-Command {
    for ($i = 0; $i -lt $TestArray.Count; $i++) {
        New-Variable -Name Array$i -Value ([System.Collections.Generic.List[psobject]]::new())
    }
}

for ($i = 0; $i -lt $TestArray.Count; $i++) {
    Remove-Variable -Name Array$i -ErrorAction Ignore
}
[System.GC]::Collect()
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Generic List init via New() method'
        'Time' = $Measure_Array.TotalMilliseconds
    }
)

$Output | Sort-Object Time -Descending
