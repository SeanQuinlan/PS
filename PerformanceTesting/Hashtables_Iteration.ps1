# Some tests to find out the fastest method of iterating through and outputting every value in a hashtable.

$Size = 100000
$Output = New-Object -TypeName 'System.Collections.ArrayList'

# Create the hashtable
$Hashtable = @{}
for ($i = 0; $i -lt $Size; $i++) {
    $Hashtable["Key_$i"] = "Value_$i"
}

# Simply iterate through the entire hashtable and output the values of each item.
$HT_GetEnumerator = Measure-Command {
    foreach ($Entry in $Hashtable.GetEnumerator()) {
        $Entry.Value
    }
}
[void]$Output.Add([pscustomobject]@{
        'Name' = 'Using GetEnumerator() method'
        'Time' = $HT_GetEnumerator.TotalMilliseconds
    })

$HT_SquareBrackets = Measure-Command {
    foreach ($Entry in $Hashtable.Keys) {
        $Hashtable[$Entry]
    }
}
[void]$Output.Add([pscustomobject]@{
        'Name' = 'Using Square Brackets notation'
        'Time' = $HT_SquareBrackets.TotalMilliseconds
    })

$HT_DotKey = Measure-Command {
    foreach ($Entry in $Hashtable.Keys) {
        $Hashtable.$Entry
    }
}
[void]$Output.Add([pscustomobject]@{
        'Name' = 'Using Dot Notation'
        'Time' = $HT_DotKey.TotalMilliseconds
    })

$Output | Sort-Object Time -Descending
