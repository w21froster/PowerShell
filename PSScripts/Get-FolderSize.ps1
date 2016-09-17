#requires -Version 3.0
[CmdletBinding()]
Param (
    [Parameter(ValueFromPipeline)]
	[string[]]$Paths = "c:\dropbox\test",
	[string]$ReportPath = "c:\dropbox\test",
    [ValidateSet("Folder","Folders","Size","Created","Changed","Owner")]
    [string]$Sort = "Folder",
    [switch]$Descending,
    [switch]$Recurse
)

Begin {
    Function AddObject {
    	Param ( 
    		$FileObject
    	)
        $RawSize = (Get-ChildItem $FileObject.FullName -Recurse | Measure-Object Length -Sum).Sum

    	If ($RawSize)
    	{	$Size = CalculateSize $RawSize
    	}
    	Else
    	{	$Size = "0.00 MB"
    	}
    	$Object = New-Object PSObject -Property @{
    		'Folder Name' = $FileObject.FullName
    		'Created on' = $FileObject.CreationTime
    		'Last Updated' = $FileObject.LastWriteTime
    		Size = $Size
    		Owner = (Get-Acl $FileObject.FullName).Owner
            RawSize = $RawSize
    	}
        Return $Object
    }

    Function CalculateSize {
    	Param (
    		[double]$Size
    	)
    	If ($Size -gt 1000000000)
    	{	$ReturnSize = "{0:N2} GB" -f ($Size / 1GB)
    	}
    	Else
    	{	$ReturnSize = "{0:N2} MB" -f ($Size / 1MB)
    	}
    	Return $ReturnSize
    }

    Function Set-AlternatingRows {
        [CmdletBinding()]
       	Param(
           	[Parameter(Mandatory=$True,ValueFromPipeline=$True)]
            [object[]]$Lines,
           
       	    [Parameter(Mandatory=$True)]
           	[string]$CSSEvenClass,
           
            [Parameter(Mandatory=$True)]
       	    [string]$CSSOddClass
       	)
    	Begin {
    		$ClassName = $CSSEvenClass
    	}
    	Process {
            ForEach ($Line in $Lines)
            {	$Line = $Line.Replace("<tr>","<tr class=""$ClassName"">")
        		If ($ClassName -eq $CSSEvenClass)
        		{	$ClassName = $CSSOddClass
        		}
        		Else
        		{	$ClassName = $CSSEvenClass
        		}
        		Return $Line
            }
    	}
    }

    #Validate sort parameter
    Switch -regex ($Sort)
    {   "^folder.?$" { $SortBy = "Folder Name";Break }
        "created" { $SortBy = "Created On";Break }
        "changed" { $SortBy = "Last Updated";Break }
        default { $SortBy = $Sort }
    }
            
    $Report = @()
    $TotalSize = 0
    $NumDirs = 0
    $Title = @()
    Write-Verbose "$(Get-Date): Script begins!"
}

Process {
    ForEach ($Path in $Paths)
    {   #Test if path exists
        If (-not (Test-Path $Path))
        {   $Result += $Object = New-Object PSObject -Property @{
        		'Folder Name' = $Path
        		'Created on' = ""
        		'Last Updated' = ""
        		Size = ""
        		Owner = "Path not found"
                RawSize = 0
        	}
            $Title += $Path
            Continue
        }
            
        #First get the properties of the starting path
        $NumDirs ++
        Write-Verbose "$(Get-Date): Now working on $Path..."
        $Root = Get-Item -Path $Path 
        $Result = AddObject $Root
        $TotalSize += $Result.RawSize
        $Report += $Result
        $Title += $Path

        #Now loop through all the subfolders
        $ParamSplat = @{
            Path = $Path
            Recurse = $Recurse
        }
        ForEach ($Folder in (Get-ChildItem @ParamSplat | Where { $_.PSisContainer }))
        {	$Report += AddObject $Folder
            $NumDirs ++
        }
    }
}

End {
    #Create the HTML for our report
    $Header = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}
TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
.odd  { background-color:#ffffff; }
.even { background-color:#dddddd; }
</style>
<Title>
Folder Sizes for "$Path"
</Title>
"@

    $TotalSize = CalculateSize $TotalSize

    $Pre = "<h1>Folder Sizes Report</h1><h3>Folders processed: ""$($Title -join ", ")""</h3>"
    $Post = "<h2><p>Total Folders Processed: $NumDirs<br>Total Space Used:  $TotalSize</p></h2>Run on $(Get-Date -f 'MM/dd/yyyy hh:mm:ss tt')</body></html>"

    #Create the report and save it to a file
    #$HTML = $Report | Select 'Folder Name',Owner,'Created On','Last Updated',Size | Sort $SortBy -Descending:$Descending | ConvertTo-Html -PreContent $Pre -PostContent $Post -Head $Header | Set-AlternatingRows -CSSEvenClass even -CSSOddClass odd | Out-File $ReportPath\FolderSizes.html

    #Display the report in your default browser
    #& $ReportPath\FolderSizes.html
    
	#Write text file with calculated total size in GB.
    $TotalSize | out-file $ReportPath\total_backup_size.txt
    
	Write-Verbose "$(Get-Date): $NumDirs folders processed"
    Write-Verbose "$(Get-Date): Script completed!"
}
