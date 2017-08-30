# Initialize Variables
$ISOPath = "$env:SystemDrive\DSCINIT\MDTISOs"

# Install DSC Dependencies 
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
$DSCModules = "PowerShellModule","xPSDesiredStateConfiguration"
$DSCModules | ForEach-Object {
    If (!(Get-Module -ListAvailable -Name $_)) {
            Install-Module $_ -Verbose -Confirm:$false
    }
}

Configuration NewMDTServer
{ 
 
  param(
    [Parameter(Mandatory=$true)]
    [String[]]$Servers,
    [String]$ISOPath
  )
 
 Import-DscResource -ModuleName PSDesiredStateConfiguration
 Import-DscResource -ModuleName xPSDesiredStateConfiguration
 Import-DscResource -ModuleName PowerShellModule

 Configuration NewMDTServer
 { 
  
   param(
     [Parameter(Mandatory=$true)]
     [String[]]$Servers,
     [String]$ISOPath
   )
  
  Import-DscResource -ModuleName PSDesiredStateConfiguration
  Import-DscResource -ModuleName xPSDesiredStateConfiguration
  Import-DscResource -ModuleName PowerShellModule
 
   Node $Servers
   { 
     
    PSModuleResource PSWindowsUpdate
    {
        Ensure = 'Present'
        Module_Name = 'PSWindowsUpdate'
    }
 
    xRemoteFile DownloadMDT2013
    {
        URI = "https://download.microsoft.com/download/3/0/1/3012B93D-C445-44A9-8BFB-F28EB937B060/MicrosoftDeploymentToolkit2013_x64.msi"
        DestinationPath = "$ISOPath\MicrosoftDeploymentToolkit2013_x64.msi"
        MatchSource = $False
    }
 
    xRemoteFile DownloadWinADK
    {
        URI = "https://go.microsoft.com/fwlink/p/?LinkId=526740"
        DestinationPath = "$ISOPath\adksetup.exe"
        MatchSource = $False
    }
 
    xRemoteFile Server2016ISO
    {
        URI = "http://care.dlservice.microsoft.com/dl/download/1/4/9/149D5452-9B29-4274-B6B3-5361DBDA30BC/14393.0.161119-1705.RS1_REFRESH_SERVER_EVAL_X64FRE_EN-US.ISO"
        DestinationPath = "$ISOPath\Server2016-Eval.iso"
        MatchSource = $False
    }
 
    Package InstallMDT2013
    {
 
        DependsOn = "[xRemoteFile]DownloadMDT2013"
        Name = "Microsoft Deployment Toolkit 2013 Update 2 (6.3.8330.1000)"
        Path =  "$ISOPath\MicrosoftDeploymentToolkit2013_x64.msi"
        ProductId = '{F172B6C7-45DD-4C22-A5BF-1B2C084CADEF}'
        Arguments = "/qn"
        Ensure = "Present"
 
    }
    
    Package InstallWinADK
    {
        DependsOn = "[xRemoteFile]DownloadWinADK"
        Name = "Windows Deployment Tools"
        Path =  "$ISOPath\adksetup.exe"
        ProductId = '{52EA560E-E50F-DC8F-146D-1B631548BA29}'
        Arguments = "/Quiet /NoRestart /ceip off /Features OptionId.DeploymentTools OptionId.WindowsPreinstallationEnvironment OptionId.UserStateMigrationTool"
        Ensure = "Present"
    } 
}

NewMDTServer -Servers localhost -OutputPath $ISOPath -ISOPath $ISOPath
Start-DscConfiguration -Path $ISOPath -Wait -Verbose -Force

#Create S Drive 
#Create MDT Deployment share on S drive

#region Extracting ISOs and importing into MDT
#Import MDT Module
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
#Mount ISO for Server 2016
$MountedISO = Mount-DiskImage -ImagePath $ISOPath\Server2016-Eval.iso -PassThru
$DriveLetter = $MountedISO | Get-Volume
#Create Deployment Share
New-Item -Path "C:\DeploymentShare" -ItemType directory
New-SmbShare -Name "DeploymentShare$" -Path "C:\DeploymentShare" -FullAccess Administrators
New-PSDrive -Name "DS001" -PSProvider "MDTProvider" -Root "C:\DeploymentShare" -Description "MDT Deployment Share" -NetworkPath "\\$Env:COMPUTERNAME\DeploymentShare$" -Verbose | Add-MDTPersistentDrive -Verbose
#Scaffold Operating Systems folder and import Server 2016
New-Item -Path "DS001:\Operating Systems" -enable "True" -Name "ISO No Updates" -Comments "This folder holds WIM files created from the ISOs. These have no Windows updates installed and no 3rd party software." -ItemType "folder" -Verbose
Import-MdtOperatingSystem -Path "DS001:\Operating Systems\ISO No Updates" -SourcePath "$DriveLetter" -DestinationFolder "Windows Server 2016" -Verbose

#endregion

#WinPE Settings
@'
[Settings]
Priority=Default
Properties=MyCustomProperty

[Default]
' // Credentials for connecting to network share
UserID=
UserDomain=
UserPassword=

' // Wizard Pages
SkipWizard=NO
SkipAppsOnUpgrade=NO
SkipDeploymentType=NO

SkipComputerName=NO
SkipDomainMembership=NO
' // OSDComputerName = 
' // and
' // JoinWorkgroup = 
' // or
' // JoinDomain = 
' // DomainAdmin = 

SkipUserData=NO
' // UDDir = 
' // UDShare = 
' // UserDataLocation = 

SkipComputerBackup=NO
' // BackupDir = 
' // BackupShare = 
' // ComputerBackupLocation = 

SkipTaskSequence=NO
' // TaskSequenceID="Task Sequence ID Here"

SkipProductKey=NO
' // ProductKey = 
' // Or
' // OverrideProductKey = 
' // Or
' // If using Volume license, no Property is required

SkipPackageDisplay=NO
' // LanguagePacks = 

SkipLocaleSelection=NO
' // KeyboardLocale = 
' // UserLocale = 
' // UILanguage = 

SkipTimeZone=NO
' // TimeZone = 
' // TimeZoneName = 

SkipApplications=NO
' // Applications

SkipAdminPassword=NO
' // AdminPassword

SkipCapture=NO
' // ComputerBackupLocation = 

SkipBitLocker=NO
' // BDEDriveLetter = 
' // BDEDriveSize = 
' // BDEInstall = 
' // BDEInstallSuppress = 
' // BDERecoveryKey = 
' // TPMOwnerPassword = 
' // OSDBitLockerStartupKeyDrive = 
' // OSDBitLockerWaitForEncryption = 

SkipSummary=NO
SkipFinalSummary=NO
SkipCredentials=NO

SkipRoles=NO
' // OSRoles
' // OSRoleServices
' // OSFeatures

SkipBDDWelcome=NO
SkipAdminAccounts=NO
' // Administrators = 

'@ | Out-File C:\DeploymentShare\Control\CustomSettings.ini -Encoding ASCII

Update-MDTDeploymentShare -path "DS001:" -Verbose

#region MDT Folders

    New-Item -path "DS001:\Operating Systems" `
        -enable "True" `
        -Name "Base OS" `
        -Comments "This will hold base WIM images. Fully patched but no scripts embedded or software installed" `
        -ItemType "folder" -Verbose

    New-Item -path "DS001:\Operating Systems" `
        -enable "True" `
        -Name "Custom OS" `
        -Comments "This will hold customized WIM images. They may contain special software or scripts" `
        -ItemType "folder" -Verbose

    New-Item -path "DS001:\Task Sequences" `
        -enable "True" `
        -Name "Server 2016" `
        -Comments "This is intended to hold the various task sequences for Windows 7 images" `
        -ItemType "folder" -Verbose


Import-MDTTaskSequence -path "DS001:\Task Sequences\Server 2016" `
    -Name "Server 2016 - Create Reference Image" `
    -Template "Client.xml" `
    -Comments "This task sequence will create a fully patched Server 2016 .WIM" `
    -ID "SRVR2016REF" `
    -Version "1.0" `
    -OperatingSystemPath "DS001:\Operating Systems\ISO No Updates\Server2016.wim" `
    -FullName "w21froster" `
    -OrgName "w21froster.GitHub.IO" `
    -HomePage "https://www.google.com/" `
    -AdminPassword "L0ca1!" -Verbose

Function Enable-TaskSequenceStep
{
    [CmdletBinding()]
    param(

        [String]$TaskSequenceID,
        [String]$GroupName,
        [String]$StepName

    )

    Write-Verbose "Enabling $StepName in $GroupName of $TaskSequenceID"

    $GroupTypes = @{

        "Initialization" = 0
        "Validation" = 1
        "State Capture" = 2
        "Preinstall" = 3
        "Install" = 4
        "PostInstall" = 5
        "StateRestore" = 6

    }
    
    [String]$LogPath = "C:\DeploymentShare\Control\$TaskSequenceID\ts.xml"
    
    [xml]$TaskSequence = Get-Content $LogPath -Raw -Encoding ASCII

    $Steps = $TaskSequence.sequence.group[$GroupTypes[$GroupName]].step

    ($Steps | where {$_.Name -eq $StepName}).Disable = "false"

    $TaskSequence.Save("C:\DeploymentShare\Control\$TaskSequenceID\ts.xml")

}

@(

    "Win7Update",
    "Win81Update",
    "Win10Update"

) | foreach {
                Enable-TaskSequenceStep -TaskSequenceID $_ `
                    -GroupName "StateRestore" `
                    -StepName "Windows Update (Pre-Application Installation)" `
                    -Verbose

                Enable-TaskSequenceStep -TaskSequenceID $_ `
                    -GroupName "StateRestore" `
                    -StepName "Windows Update (Post-Application Installation)" `
                    -Verbose
            }


#endregion

