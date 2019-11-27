# Some tests to find out the fastest method of iterating through and outputting every value in a hashtable.

$Size = 100000
$TestArray = 1..$Size
$Output = New-Object -TypeName 'System.Collections.ArrayList'

# Create the hashtable
$Hashtable = @{ }
foreach ($i in $TestArray) {
    $Hashtable.Add("Key_$($i)", "Value_$($i)")
}

# Simply iterate through the entire hashtable and output the values of each item.
$Measure_Hashtable = Measure-Command {
    foreach ($Entry in $Hashtable.GetEnumerator()) {
        $Entry.Value
    }
}
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Hashtable iterated using GetEnumerator() method'
        'Time' = $Measure_Hashtable.TotalMilliseconds
    }
)

$Measure_Hashtable = Measure-Command {
    foreach ($Entry in $Hashtable.Keys) {
        $Hashtable[$Entry]
    }
}
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Hashtable iterated using Square Brackets notation'
        'Time' = $Measure_Hashtable.TotalMilliseconds
    }
)

$Measure_Hashtable = Measure-Command {
    foreach ($Entry in $Hashtable.Keys) {
        $Hashtable.$Entry
    }
}
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Hashtable iterated using Dot notation'
        'Time' = $Measure_Hashtable.TotalMilliseconds
    }
)

$Output | Sort-Object Time -Descending
