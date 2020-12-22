<#
.NOTES
    Name:           Approve-WSUSUpdateDelay.ps1
    Version:        v0.1
    Author:         w21froster (https://w21froster.github.io/)
    Creation Date:  12/21/2021
    Credits:        David Rawling for Info on Accepting EULA https://social.technet.microsoft.com/Forums/en-US/0cc2f3bc-9b03-4a5f-88fe-ec3b7a7c869c/how-to-accept-eula-for-update-with-powershell-4-on-wsus-2012-r2?forum=winserverwsus
#>

#region Import Functions

Import-Module UpdateServices

#endregion

#region Define Variables

$Classifications = 'Critical', 'Security', 'WSUS'
$TargetGroups = 'Windows 10', 'Windows 7', 'Windows Server 2019'
$ApprovalDelay = (Get-Date).AddDays(-30) # Change the -30 as needed 
$UpdateCSV = "C:\logs\UpdateLog_" + (Get-Date -Format "MMddyyyy") + ".csv"
$UpdateTranscript = "C:\logs\UpdateLog_" + (Get-Date -Format "MMddyyyy") + ".txt"

#endregion

Start-Transcript -Path $UpdateTranscript -Force

# Get List of Available Updates Older than ApprovalDelay
$NeededUpdates = $Classifications | ForEach-Object {
    Get-WsusUpdate -Classification $_ -Approval Unapproved `
        | Where-Object {$_.Update.CreationDate -le $ApprovalDelay} 
    
}

# Accept EULA for Updates
$NeededUpdates | ForEach-Object {
    If ($_.Update.RequiresLicenseAgreementAcceptance) {
        $_.Update.AcceptLicenseAgreement()
    }
}

# Approve WSUS Updates for each target group
ForEach ($Update in $NeededUpdates) {
    ForEach ($Group in $TargetGroups) {
        Approve-WsusUpdate -Update $Update -Action Install -TargetGroupName $Group -Verbose
    }
}


#Export CSV File of Approved Updates
$NeededUpdates | Select-Object -ExpandProperty Update | Select-Object LegacyName, ProductTitles, UpdateClassificationTitle, CreationDate `
        | Export-CSV -Path $UpdateCSV 

Stop-Transcript

        



