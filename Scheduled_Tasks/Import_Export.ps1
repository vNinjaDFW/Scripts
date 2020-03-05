$task_path = "D:\SchedTasks\*.xml"
$task_user = "XXX"
$task_pass = "XXX"

$sch = New-Object -ComObject("Schedule.Service")
$sch.connect("localhost")
$folder = $sch.GetFolder("\Reclaims")

Get-Item $task_path | %{
	$task_name = $_.Name.Replace('.xml', '')
	$task_xml = Get-Content $_.FullName
	$task = $sch.NewTask($null)
	$task.XmlText = $task_xml
	$folder.RegisterTaskDefinition($task_name, $task, 6, $task_user, $task_pass, 1, $null)
}




# Run PowerShell with administrator permissions.
If(!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) 
{ 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit 
}
Else
{
    $STS = New-Object -ComObject("Schedule.Service")
    $STS.connect("localhost")
    $rootFolder = $STS.GetFolder("\")

    $ImportPath = "D:\SchedTasks\*.xml" # Set import path, you need to have access to it.
    $tUser      = "XXX"                # Set username
    $tPassword  = "XXX"           # Set password
    $NameFolder = "\Reclaims"                    # Set folder name

    # If folder does not exist, create it
    $rootFolder.CreateFolder("$NameFolder") | Out-Null

    # Set folder
    $Folder = $STS.GetFolder("\$($NameFolder)")

    # Import task
    Get-Item $ImportPath | %{$tName = $_.Name.Replace('.xml', '')
                            [String]$tXml = Get-Content $_.FullName
 	                        $Task = $STS.NewTask($null)
 	                        $Task.XmlText = $tXml
                            $Folder.RegisterTaskDefinition($tName, $Task, 6, $tUser, $tPassword, 1, $null)}
    #>





    #<############################################## Export Scheduled Task ##############################################
    $ExportPath = "E:\Backups\SchedTasks\"           # Set export path, you need to have access to it.
    $Tasks = Get-ScheduledTask –TaskPath "\VM_Admin\" # Set task path (folder name) as it have in Task Scheduler or leave it as "\" if it placed in root.

    # Create path if not exist
    If((Test-Path $ExportPath) -ne $True){New-Item -ItemType directory -Path $ExportPath}

    Foreach($Task in $Tasks) 
    {
        Export-ScheduledTask -TaskName $Task.TaskName -TaskPath $Task.TaskPath | Out-File (Join-Path $ExportPath "$($Task.TaskName).xml")
    }
    #>





    <######### Example: Change command line in all XML files at same time. This is only example, edit as you need #########

    $Path = "E:\Backups\SchedTasks\"
    $XMLFiles = $Null
    $XMLFiles = Get-ChildItem $Path -Filter *.xml

    Foreach($File in $XMLFiles) 
    {
        $myXML = $Null
        [xml]$myXML = Get-Content $File.FullName
    
        Write-Host ""
        Write-Host "File: " $File.Name
        Write-Host "Command: " $myXML.Task.Actions.Exec.Command
        Write-Host "Arguments: " $myXML.Task.Actions.Exec.Arguments
        Write-Host ""

        # Set to use powershell 32-bit version
        #$myXML.Task.Actions.Exec.Command = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
        #$myXML.Save($File.FullName)
    
        # Set to use powershell 64-bit version
        #$myXML.Task.Actions.Exec.Command = "C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe"
        #$myXML.Save($File.FullName)
    }
    #>

}
