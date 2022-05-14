#PI.ps1
Write-Host
Write-Host "####################################################################" -ForegroundColor DarkBlue
Write-Host "          WELCOME!!! I'LL BE CHECKING YOUR DISK DRIVE USAGE         "
Write-Host "####################################################################" -ForegroundColor DarkBlue
Write-Host
Start-Sleep -Seconds 1

$selectedDrive = Read-Host -Prompt "Enter a drive letter to check disk usage"




$driveLetters = (Get-Volume).DriveLetter
If ($driveLetters -contains $selectedDrive){
    Write-Host "$selectedDrive Drive found!"
    Write-Host "Checking Disk..."
    Start-Sleep -Seconds 2
    Write-Host

} Else {
    Write-Host "The specified drive doesn't exist" -ForegroundColor DarkRed
    Start-Sleep -Seconds 2
    Write-Host "Terminating program..."
    Write-Host
    Start-Sleep -Seconds 1
    Exit
}

$dsk = Get-Volume -DriveLetter $selectedDrive | Select-Object HealthStatus, OperationalStatus, SizeRemaining, Size
$usagePercent = 79
# $size = [Math]::Round($dsk.Size /1Gb, 2)
# $sizeRemaining = [Math]::Round($dsk.SizeRemaining /1Gb, 2)
# $usagePercent = [Math]::Round(($size - $sizeRemaining) / $size * 100) 
$healthStatus = $dsk.HealthStatus
$operationalStatus =  $dsk.OperationalStatus

function Get-DiskDetails($percent, $health, $operation) {
    Write-Host "$percent% of this disk has been used"
    Start-Sleep -Seconds 1
    Write-Host "HealthStatus: $health"
    Start-Sleep -Seconds 1
    Write-Host "OperationalStatus: $operation"
    Write-Host
}

If ($usagePercent -ge 80){
    Get-DiskDetails $usagePercent $healthStatus $operationalStatus
    # Write-Host "Disk $selectedDrive is almost full"
    $uriSlack = "slackURL"
    $body = ConvertTo-Json @{
        pretext = "Low Disk Space!" 
        text = "Disk $selectedDrive is almost full. $usagePercent% of the $selectedDrive have been used"
    }

    try {
        Invoke-RestMethod -uri $uriSlack -Method Post -body $body -ContentType 'application/json' | Out-Null
    }
    catch {
        Write-Error (Get-Date) ": Update to Slack went wrong..."
    }
}
# } ElseIf ($usagePercent -ge 40){
#     Get-DiskDetails $usagePercent $healthStatus $operationalStatus
#     Write-Host "Disk usage is is within limit"
Else {
    Get-DiskDetails $usagePercent $healthStatus $operationalStatus
    Write-Host "Disk usage is within limit"
}
