# Some tests to find out the fastest method of randomly accessing values in a hashtable.

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

# Similar to full iteration, here we randomly access a number of items and output the values of these items.
$Measure_Hashtable = Measure-Command {
    foreach ($Number in $Random_Numbers) {
        $Hashtable["Key_$Number"]
    }
}
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Hashtable randomly accessed using Square Brackets notation'
        'Time' = $Measure_Hashtable.TotalMilliseconds
    }
)

$Measure_Hashtable = Measure-Command {
    foreach ($Number in $Random_Numbers) {
        $Hashtable."Key_$Number"
    }
}
[void]$Output.Add(
    [pscustomobject]@{
        'Name' = 'Hashtable randomly accessed using Dot notation'
        'Time' = $Measure_Hashtable.TotalMilliseconds
    }
)

$Output | Sort-Object Time -Descending
