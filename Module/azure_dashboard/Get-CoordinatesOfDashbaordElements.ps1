# # terrafrom data null_resoruce requirements
$userInput = [Console]::In.ReadLine()
$input = ConvertFrom-Json $userInput
[int]$Length = $input.ElementCount
[int]$Height= $input.ElementHeight
[int]$Weight = $input.ElementWeight

if ($Length -eq 0) {
    throw "User does not provided elements."
    exit 2
}
if ($Height * $Weight -eq 0) {
    $Weight = 5
    $Height = 3
}
# calculate dashboard size 
$dashboardSize = [math]::Ceiling($Length / 2) 
$elementPosition = @()

$i = 0
for ($x = 0; $x -lt $Length; $x++) {
    
    for ($y = 0; $y -lt $Length; $y++) {

        $x1 = ($x * $Weight )
        $y1 = ($y * $Height)
        if ( ($x1 -gt $dashboardSize) -or ($y1 -gt $dashboardSize) ) {
            break
        }
        if (($x1+$Weight) -gt ($Weight * $Length)/2)  {
            break
        }
        if (($y1+$Hight) -gt ($Height* $Length)/2)  {
            break
        }
        if ($elementPosition.count -eq $Length) {
            break
        }
        $elementPosition += "$x1;$y1"
        $i++      
    }
}
$result = @"
{
    "positions":"$($elementPosition -join ',')",
    "user":"$input"
}
"@
return $result




