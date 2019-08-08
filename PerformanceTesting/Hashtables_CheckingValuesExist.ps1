# Some tests to find out the fastest method of checking whether values exist in a hashtable.

$Size = 100000
$Output = New-Object -TypeName 'System.Collections.ArrayList'

# Create the hashtable
$Hashtable = @{}
for ($i = 0; $i -lt $Size; $i++) {
    $Hashtable["Key_$i"] = "Value_$i"
}
# Build an array of 25% of the values of the Size, to use as random numbers for checking.
$Random_Numbers = Get-Random -InputObject (0..$Size) -Count ($Size / 4)

# We just test to see if the key exists, but don't do anything with a match.
$HT_ContainsKey = Measure-Command {
    foreach ($Number in $Random_Numbers) {
        if ($Hashtable.ContainsKey("Key_$Number")) {
        }
    }
}
[void]$Output.Add([pscustomobject]@{
        'Name' = 'Using .ContainsKey'
        'Time' = $HT_ContainsKey.TotalMilliseconds
    })

$HT_SquareBrackets = Measure-Command {
    foreach ($Number in $Random_Numbers) {
        if ($Hashtable["Key_$Number"]) {
        }
    }
}
[void]$Output.Add([pscustomobject]@{
        'Name' = 'Using Square Brackets notation'
        'Time' = $HT_SquareBrackets.TotalMilliseconds
    })

$HT_DotKey = Measure-Command {
    foreach ($Number in $Random_Numbers) {
        if ($Hashtable."Key_$Number") {
        }
    }
}
[void]$Output.Add([pscustomobject]@{
        'Name' = 'Using Dot Notation'
        'Time' = $HT_DotKey.TotalMilliseconds
    })

$Output | Sort-Object Time -Descending
