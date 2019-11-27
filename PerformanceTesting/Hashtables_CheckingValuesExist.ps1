# Some tests to find out the fastest method of checking whether values exist in a hashtable.

$Size = 100000
$TestArray = 1..$Size
$Output = New-Object -TypeName 'System.Collections.ArrayList'

# Create the hashtable
$Hashtable = @{ }
foreach ($i in $TestArray) {
    $Hashtable.Add("Key_$($i)", "Value_$($i)")
}
# Build an array of 25% of the values of the Size, to use as random numbers for checking.
$Random_Numbers = Get-Random -InputObject $TestArray -Count ($Size / 4)

# NOTE: We just test to see if the key exists, but don't do anything with a match.
$Measure_Hashtable = Measure-Command {
    foreach ($Number in $Random_Numbers) {
        if ($Hashtable.ContainsKey("Key_$Number")) {
        }
    }
}
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Hashtable accessed via ContainsKey'
        'Time' = $Measure_Hashtable.TotalMilliseconds
    }
)

$Measure_Hashtable = Measure-Command {
    foreach ($Number in $Random_Numbers) {
        if ($Hashtable["Key_$Number"]) {
        }
    }
}
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Hashtable accessed via Square Brackets notation'
        'Time' = $Measure_Hashtable.TotalMilliseconds
    }
)

$Measure_Hashtable = Measure-Command {
    foreach ($Number in $Random_Numbers) {
        if ($Hashtable."Key_$Number") {
        }
    }
}
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Hashtable accessed via Dot notation'
        'Time' = $Measure_Hashtable.TotalMilliseconds
    }
)

$Output | Sort-Object Time -Descending
