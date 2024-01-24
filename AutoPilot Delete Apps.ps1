Powershell Script 1

$64BitProgramsList = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty
$32BitProgramsList = Get-ChildItem "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty
$CurrentUserProgramsList = Get-ChildItem "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty
# These are the uninstall registry keys which correspond to currently installed programs and contain the uninstall command.


$ProgramName = "Lenovo Vantage Service", "Microsoft OneNote -en-us", "Microsoft 365 -en-us", "Microsoft Visual C++ *"
# Program name strings to search for, you can specify multiple by separating them with a comma.
# Don't use wildcard characters unless the application name contains the wild card character, as these will will be used in a regular expressions match.


$SearchList = $32BitProgramsList + $64BitProgramsList
# Program lists to search in, you can specify multiple by adding them together.


$Programs = $SearchList | ?{$_.DisplayName -match ($ProgramName -join "|")}
Write-Output "Programs Found: $($Programs.DisplayName -join ", ")`n`n"

Foreach ($Program in $Programs)
{
If (Test-Path $Program.PSPath)
{
Write-Output "Registry Path: $($Program.PSPath | Convert-Path)"
Write-Output "Installed Location: $($Program.InstallLocation)"
Write-Output "Program: $($Program.DisplayName)"
Write-Output "Uninstall Command: $($Program.UninstallString)"

$Uninstall = (Start-Process cmd.exe -ArgumentList '/c', $Program.UninstallString -Wait -PassThru)
# Runs the uninstall command located in the uninstall string of the program's uninstall registry key, this is the command that is ran when you uninstall from Control Panel.
# If the uninstall string doesn't contain the correct command and parameters for silent uninstallation, then when PDQ Deploy runs it, it may hang, most likely due to a popup.

Write-Output "Exit Code: $($Uninstall.ExitCode)`n"
If ($Uninstall.ExitCode -ne 0)
{
Exit $Uninstall.ExitCode
}
# This is the exit code after running the uninstall command, by default 0 means successful, any other number may indicate a failure, so if the exit code is not 0, it will cause the script to exit.
# The exit code is dependent on the software vendor, they decide what exit code to use for success and failure, most of the time they use 0 as success, but sometimes they don't.
}
Else {Write-Output "Registry key for ($($Program.DisplayName)) no longer found, it may have been removed by a previous uninstallation.`n"}
}

If (!$Programs)
{
Write-Output "No Program found!"
}