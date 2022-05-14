#// This is the parameter block. It defines the parameters that can be passed to the script.
param(
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $false)]
    [string] $minSize = 149GB,

    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $false)]
    [string] $hosts = $null,

    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $false)]
    $volumes = $null
)

# A separator for the `` parameter.
$sep = ":";

# // If the `` variable is not set, then it will be set to the current computer name.
if (!$hosts) { $hosts = $env:computername; }

# This is a loop that iterates through the list of hosts that are passed to the script. If the host is
# an IP address, then it will be converted to a hostname.
foreach ($cur_host in $hosts.split($sep)) {
    if (($cur_host -As [IPAddress]) -As [Bool]) {
        $cur_host = [System.Net.Dns]::GetHostEntry($cur_host).HostName
    }

    Write-Host ("----------------------------------------------");
    Write-Host ($cur_host + " is running the script");
    Write-Host ("----------------------------------------------");
# // Creating an empty array.
    $drives_to_check = @();

# // This is a conditional statement that checks if the  variable is null. If it is, then it will
# // set the  variable to the output of the Get-WMIObject win32_volume command. If the 
# // variable is not equal to the :computername variable, then it will set the  variable to
# // the output of the Invoke-Command -ComputerName  -ScriptBlock { Get-WMIObject win32_volume }
# // command.
    if ($null -eq $volumes) {
   	    $volArr = 
        If ($cur_host -eq $env:computername) { Get-WMIObject win32_volume }
        Else { Invoke-Command -ComputerName $cur_host -ScriptBlock { Get-WMIObject win32_volume } }

# // This is a loop that iterates through the list of volumes that are passed to the script. If the
# // volume is an IP address, then it will be converted to a hostname.
        $drives_to_check = @();
        foreach ($vol in $volArr | Sort-Object -Property DriveLetter) {
            if ($vol.DriveType -eq 3 -And $null -ne $vol.DriveLetter ) {
                $drives_to_check += $vol.DriveLetter[0];
            }
        }
    }
# // This is a conditional statement that checks if the  variable is null. If it is, then it will
# // set the  variable to the output of the Get-WMIObject win32_volume command. If the
# //  variable is not equal to the :computername variable, then it will set the
# //  variable to the output of the Invoke-Command -ComputerName  -ScriptBlock { Get-WMIObject win32_volume } command.
    Else { 
        $drives_to_check = $volumes.split($sep) 
    }
# // This is a loop that iterates through the list of drives that are passed to the script. If the drive
# // is an IP address, then it will be converted to a hostname.

    foreach ($d in $drives_to_check) {
        $disk = If ($cur_host -eq $env:computername) { Get-PSDrive $d }
        Else { Invoke-Command -ComputerName $cur_host -ScriptBlock { Get-PSDrive $using:d } }

# // This is the part of the script that sends the message to Slack.
        if ($disk.Free -lt $minSize) {
            $uriSlack = "slackURL"
            $body = ConvertTo-Json @{
                pretext = "Low Disk Space!" 
                text    = ("Drive " + $d + " has less than " + ($minSize / 1GB) `
                        + " GB (" + "Current free space in drive $d - " + ($disk.Free / 1GB).ToString(".00") + " GB)")
            }
        
# This is a try/catch block. It is used to catch errors that may occur during the execution of the script.
            try {
                Invoke-RestMethod -uri $uriSlack -Method Post -body $body -ContentType 'application/json' | Out-Null
            }
            catch {
                Write-Error (Get-Date) ": Update to Slack went wrong..."
            }
        }
        Else {
            Write-Host "  - [" -noNewLine
            Write-Host "OK" -noNewLine -ForegroundColor Green
            Write-Host "] " -noNewLine
            Write-Host ("Drive " + $d + " has more than " + ($minSize / 1GB).ToString(".00") + " GB")
            
        }
    }

}
