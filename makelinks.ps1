param([switch]$WhatIf,[switch]$Verbose)

$here =  Split-Path -Parent $MyInvocation.MyCommand.Path

function New-SymLink
{
  [cmdletbinding(SupportsShouldProcess=$True)]
  param($target, $link)
  New-Item -Path $link -ItemType SymbolicLink -Value $target >$null
  return
}

function New-DotFile($InstallPath, $Files){
  $object = New-Object PSCustomObject
  Add-Member -InputObject $object -MemberType NoteProperty -Name InstallPath -Value $null
  Add-Member -InputObject $object -MemberType NoteProperty -Name Files -Value $null
  return $object
}

function CreateLinks{
  [cmdletbinding(SupportsShouldProcess=$True)]
  param([PSCustomObject]$dotfile)
  Foreach ($file in $dotfile.Files)
  {
    if(-Not (Test-Path $dotfile.InstallPath)){
    	Write-Verbose "$($dotfile.InstallPath) doesn't exist, creating"
	New-Item -ItemType "directory" -Path $dotfile.InstallPath -Force
    }
    $link = (Join-Path $dotfile.InstallPath $file.Name)
    if(Test-Path $link){
      if(Test-IsLink $link){
        Write-Verbose "$link is already linked skipping."
        continue
      }
      Write-Verbose "$link exists but is not linked, moving to .backup."
      Move-Item $link ($link + '.backup') -Force
    }
    Write-Verbose "Creating SymbolicLink to $link"
    New-SymLink -target $file.FullName -link $link
  }
}

function Test-IsLink($path){
  return (Get-Item $path).LinkType -eq 'SymbolicLink'
}

function GetAllDotFilesFromDir([string]$dirName){
  return Get-ChildItem (Join-Path $here $dirName) -File
}

$dotfiles = @()

$atom = New-DotFile
$atom.InstallPath = Join-Path $HOME '.atom'
$atom.Files = GetAllDotFilesFromDir 'atom'
$dotfiles += $atom

$neovim = New-DotFile
$neovim.InstallPath = Join-Path $env:LOCALAPPDATA 'nvim'
$neovim.Files = GetAllDotFilesFromDir 'nvim'
$dotfiles += $neovim

$ideavimrc = New-DotFile
$ideavimrc.InstallPath = $HOME
$ideavimrc.Files = GetAllDotFilesFromDir 'ideavimrc'
$dotfiles += $ideavimrc

$ps = New-DotFile
$ps.InstallPath = Split-Path $profile
$ps.Files = GetAllDotFilesFromDir 'PowerShell'
$dotfiles += $ps

$poshthemes = New-DotFile
$poshthemes.InstallPath = Join-Path $ps.InstallPath "PoshThemes"
$poshthemes.Files = GetAllDotFilesFromDir 'PowerShell/PoshThemes'
$dotfiles += $poshthemes

$hg = New-DotFile
$hg.InstallPath = $HOME
$hg.Files = GetAllDotFilesFromDir 'mercurial'
$dotfiles += $hg

$git = New-DotFile
$git.InstallPath = $HOME
$git.Files = GetAllDotFilesFromDir 'git'
$dotfiles += $git

Foreach ($File in $dotfiles)
{
  CreateLinks $File -WhatIf:$WhatIf -Verbose:$Verbose
}
