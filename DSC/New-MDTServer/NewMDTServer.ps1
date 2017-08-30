Configuration NewMDTServer
{ 
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Servers,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $InitPath
    )
  
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
 
   Node $Servers
   { 
        xRemoteFile DownloadMDT2013
        {
            URI = "https://download.microsoft.com/download/3/0/1/3012B93D-C445-44A9-8BFB-F28EB937B060/MicrosoftDeploymentToolkit2013_x64.msi"
            DestinationPath = "$InitPath\MicrosoftDeploymentToolkit2013_x64.msi"
            MatchSource = $False
        }

        xRemoteFile DownloadWinADK
        {
            URI = "https://go.microsoft.com/fwlink/p/?LinkId=526740"
            DestinationPath = "$InitPath\adksetup.exe"
            MatchSource = $False
        }

        xRemoteFile Server2016ISO
        {
            URI = "http://care.dlservice.microsoft.com/dl/download/1/4/9/149D5452-9B29-4274-B6B3-5361DBDA30BC/14393.0.161119-1705.RS1_REFRESH_SERVER_EVAL_X64FRE_EN-US.ISO"
            DestinationPath = "$InitPath\Server2016-Eval.iso"
            MatchSource = $False
        }

        Package InstallMDT2013
        {

            DependsOn = "[xRemoteFile]DownloadMDT2013"
            Name = "Microsoft Deployment Toolkit 2013 Update 2 (6.3.8330.1000)"
            Path =  "$InitPath\MicrosoftDeploymentToolkit2013_x64.msi"
            ProductId = '{F172B6C7-45DD-4C22-A5BF-1B2C084CADEF}'
            Arguments = "/qn"
            Ensure = "Present"

        }

        Package InstallWinADK
        {
            DependsOn = "[xRemoteFile]DownloadWinADK"
            Name = "Windows Deployment Tools"
            Path =  "$InitPath\adksetup.exe"
            ProductId = '{52EA560E-E50F-DC8F-146D-1B631548BA29}'
            Arguments = "/Quiet /NoRestart /ceip off /Features OptionId.DeploymentTools OptionId.WindowsPreinstallationEnvironment OptionId.UserStateMigrationTool"
            Ensure = "Present"
        }
    }
}