param([switch]$WhatIf, [switch]$Verbose, [switch]$SkipChocoInstall, [switch]$SkipAPMInstall)

$here =  Split-Path -Parent $MyInvocation.MyCommand.Path

function Invoke-ExpressionVerbose{
  [cmdletbinding(SupportsShouldProcess=$True)]
  param([string]$command)
  Write-Verbose "Invoking: $command"
  Invoke-Expression $command
}

function ChocoInstall
{
  [cmdletbinding(SupportsShouldProcess=$True)]
  param()

  if(-Not (Get-Command 'choco' -errorAction SilentlyContinue)){ throw 'Install chocolatey before running install script' }

  if($WhatIf){
    Write-Host 'What if: Performing operation "Disable choco showNonElevatedWarnings"'
  }else{
    Invoke-ExpressionVerbose 'choco feature disable -n=showNonElevatedWarnings'
  }

  $chocoArgs = ''
  if($WhatIf){$chocoArgs += '--what-if'}
  $chocoPackages = Join-Path $here 'chocopackages.config'
  $chocoCommand = "choco install $chocoArgs $chocoPackages -y"
  Invoke-ExpressionVerbose $chocoCommand
}

function InstallAtomPackages
{
  [cmdletbinding(SupportsShouldProcess=$True)]
  param()
  if($WhatIf){
    Write-Host 'What if: Performing the operation "Install atom packages using apm"'
  }
  else{
    $packages = Join-Path $here 'atom\atompackages.txt'
    Invoke-ExpressionVerbose "apm install --packages-file $packages"
  }
}

function Install-VSSetupModule
{
  [cmdletbinding(SupportsShouldProcess=$True)]
  param()

  if($WhatIf){
    Write-Host 'What if: Performing the operation "Install-Module VSSetup"'
  }
  else{
    Install-Module VSSetup -Scope AllUsers
  }
}

function main
{
  [cmdletbinding(SupportsShouldProcess=$True)]
  param([switch]$SkipChocoInstall,[switch]$SkipAPMInstall)

  Write-Host 'Running new pc initial setup'

  if(-Not $SkipChocoInstall) { ChocoInstall } else { Write-Verbose 'Skipping chocolatey package installation' }
  if(-Not $SkipAPMInstall) { InstallAtomPackages } else { Write-Verbose 'Skipping apm package installation' }

  #Touch mercurial.ini to make repo auth token get stored in that instead of the versioned .hgrc
  New-Item -Type File (Join-Path $HOME 'mercurial.ini')

  Install-VSSetupModule
}

main -WhatIf:$WhatIf -Verbose:$Verbose -SkipChocoInstall:$SkipChocoInstall -SkipAPMInstall:$SkipAPMInstall
