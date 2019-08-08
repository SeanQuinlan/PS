# Some tests to find out the fastest method of randomly accessing values in a hashtable.

$Size = 100000
$Output = New-Object -TypeName 'System.Collections.ArrayList'

# Create the hashtable
$Hashtable = @{}
for ($i = 0; $i -lt $Size; $i++) {
    $Hashtable["Key_$i"] = "Value_$i"
}
# Build an array of 25% of the values of the Size, to use as random numbers for checking.
$Random_Numbers = Get-Random -InputObject (0..$Size) -Count ($Size / 4)

$HT_SquareBrackets = Measure-Command {
    foreach ($Number in $Random_Numbers) {
        $Hashtable["Key_$Number"]
    }
}
[void]$Output.Add([pscustomobject]@{
        'Name' = 'Using Square Brackets notation'
        'Time' = $HT_SquareBrackets.TotalMilliseconds
    })

$HT_DotKey = Measure-Command {
    foreach ($Number in $Random_Numbers) {
        $Hashtable."Key_$Number"
    }
}
[void]$Output.Add([pscustomobject]@{
        'Name' = 'Using Dot Notation'
        'Time' = $HT_DotKey.TotalMilliseconds
    })

$Output | Sort-Object Time -Descending
