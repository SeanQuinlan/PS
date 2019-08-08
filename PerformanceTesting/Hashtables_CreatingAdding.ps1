# Some tests to find out the fastest method of creating/adding to a hashtable.

$Size = 10000
$Output = New-Object -TypeName 'System.Collections.ArrayList'

$HT_PlusEquals = Measure-Command {
    $Hashtable_PlusEquals = @{}
    for ($i = 0; $i -lt $Size; $i++) {
        $Hashtable_PlusEquals += @{
            "Key_$i" = "Value_$i"
        }
    }
}
[void]$Output.Add([pscustomobject]@{
        'Name' = 'Hashtable created via PlusEquals'
        'Time' = $HT_PlusEquals.TotalMilliseconds
    })

$HT_KeyAssignment = Measure-Command {
    $Hashtable_KeyAssignment = @{}
    for ($i = 0; $i -lt $Size; $i++) {
        $Hashtable_KeyAssignment["Key_$i"] = "Value_$i"
    }
}
[void]$Output.Add([pscustomobject]@{
        'Name' = 'Hashtable created via Key Assignment'
        'Time' = $HT_KeyAssignment.TotalMilliseconds
    })

$HT_Add = Measure-Command {
    $Hashtable_Add = @{}
    for ($i = 0; $i -lt $Size; $i++) {
        $Hashtable_Add.Add("Key_$i", "Value_$i")
    }
}
[void]$Output.Add([pscustomobject]@{
        'Name' = 'Hashtable created via .Add() method'
        'Time' = $HT_Add.TotalMilliseconds
    })

$Output | Sort-Object Time -Descending
