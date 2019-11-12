# TODO add requirements, Shortcuts for 7z .. maybe more?
# Helper module to wrap emacs and integrate it with PS etc.
$emacsbin = 'C:\tools\emax64\bin'
$emaxDL = 'https://github.com/m-parashar/emax64/releases/download/emax64-26.2-20190417/emax64-bin-26.2.7z'
$installDir = 'C:\tools'
if(-Not (Test-Path $emacsbin)){
  Write-Error "Cannot locate $emacsbin please install it."
}
# Overrides the general-utils function since its implementation does not support
# complex editor assignment.
function e
{
  if([string]$args -match '^(.+?)(:\d+)?:?$') # skip line numbers after file name
  {
    $args = $matches[1]
  }
  & "$emacsbin\emacsclientw.exe" -c --alternate-editor C:\tools\emax64\bin\runemacs.exe $args
}

function Install-Emacs{
    if(Test-Path $emacsbin){
      throw 'Emacs already installed aborting.'
    }

    New-Item -Type "directory" $installDir -ErrorAction SilentlyContinue
    Push-Location $installDir
    $fileName = Split-Path $emaxDL -Leaf
    (New-Object System.Net.WebClient).DownloadFile($emaxDL, (Join-Path $installDir $fileName))
    7z x $fileName
    Pop-Location
    $dotemacs = Join-Path $HOME .emacs.d
    if(Test-Path $dotemacs){
      Write-Host '.emacs.d found in home folder skipping spacemacs download.'
    }
    else{
      git clone https://github.com/syl20bnr/spacemacs $dotemacs
    }
  }
