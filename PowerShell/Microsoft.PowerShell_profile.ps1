$docsFolder = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)
$moduleFolder = Join-Path $docsFolder 'dotfiles/PowerShell/Modules'

# Shortcuts also contains basic functions that other modules have a dependency upon.
Import-Module (Join-Path $moduleFolder 'Shortcuts\Shortcuts.psm1') -Force
Import-Module (Join-Path $moduleFolder 'AutoUpdater\AutoUpdater.psm1') -Force #TODO fix forced imports.. probably need manifests
if(Invoke-AutoUpdate){
    . $PROFILE
}

. (Join-Path $moduleFolder 'Start-MediaPlayer.ps1')
Import-Module (Join-Path $moduleFolder 'AzureShortcuts\AzureShortcuts.psm1') -Force
Import-Module (Join-Path $moduleFolder 'ProjectDepShortcuts\ProjectDepShortcuts.psm1') -Force
Import-Module (Join-Path $moduleFolder 'Emacs\Emacs.psm1') -Force
Import-Module (Join-Path $moduleFolder 'Timer\Timer.psm1') -Force -ArgumentList 'C:\Users\morten.frolich\Music\Number Ones\Earth Song.mp3'
Import-Module (Join-Path $moduleFolder 'FunctionOfTheDay\FunctionOfTheDay.psm1') -Force -ArgumentList (,@('PSReadline', 'posh-git', 'AutoUpdater', 'Microsoft.PowerShell.Utility', 'FunctionOfTheDay', 'Emacs', 'chocolateyProfile', 'EdlPlatform', 'Microsoft.PowerShell.Management'))

#WSL interop methods if running in powershell core
if($PSVersionTable.PSEdition -eq 'Core'){
    Import-WslCommand "awk", "grep", "head", "less", "ls", "man", "sed", "seq", "ssh", "tail", "vim"
}
#Environment settings
$env:FZF_DEFAULT_COMMAND='fd --type f'
$env:DOTNET_CLI_TELEMETRY_OPTOUT = 1
$env:HOME = $HOME #This seems to be needed since it defaults to H: not sure if that is intended
$env:EDITOR = 'nvim'
$env:LC_ALL='C.UTF-8' # This seems to be required to force git to output utf-8 correctly in conemu..

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
Import-Module 'C:\tools\poshgit\dahlbyk-posh-git-9bda399\src\posh-git.psd1'
Set-Theme ModifiedAgnoster

# PowerShell parameter completion shim for the dotnet CLI 
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
