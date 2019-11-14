#Auto update manager to help keep packages updated.

$updateFileIndicator = Join-Path $env:LOCALAPPDATA '.autoUpdaterIndicator'
$updateFrequency = 7

function Test-IsOutOfDate([string]$file, [datetime]$date)
{
  $item = get-item -ErrorAction SilentlyContinue $file
  return !$item -or ($item.LastWriteTime.Date -lt $date.Date)
}

function Invoke-AutoUpdate(){
  if(Test-IsOutOfDate $updateFileIndicator (Get-Date).AddDays($updateFrequency * -1)){
      $dotfilesRepo = Join-Path $docsFolder 'dotfiles'
      Push-Location $dotfilesRepo
      if(Update-Profile){
          return $True
      }
      Pop-Location
      Set-TouchItem $updateFileIndicator
      Find-AutoUpdates
  }
  return $False
}

function Find-AutoUpdates(){
    Write-Host 'Checking for updates:'
    Write-Host 'Checking for atom package updates'
    Invoke-Expression 'apm upgrade --list'
    Write-Host 'Checking for choco package updates'
    Invoke-Expression 'choco outdated -r' | %{
        $name, $current, $newest, $stuff = $_.Split('|')
        Write-Host "$name ($current => $newest)" -ForegroundColor Cyan
        }
    Write-Host 'Run Install-AutoUpdates to install updates.'
}

function Update-Profile(){
    Write-Host 'Checking for profile updates:'
    git fetch
    $upstream= git rev-parse '@{u}'
    $local = git rev-parse '@'
    $base = git merge-base "$local" "$upstream"
    if($local -eq $upstream){
        Write-Host 'Nothing to update.'
        return $False
    }
    if($base -eq $upstream){
        Write-Warning 'Local profile is ahead of upstream, you need to push'
        return $False
    }
    git diff --exit-code --quiet
    if(-not $?){
        Write-Warning 'Unstaged changes found in dotfile repo aborting update.'
        return $False
    }
    git diff --exit-code --cached --quiet
    if(-not $?){
        Write-Warning 'Staged changes found in dotfile repo aborting update.'
        return $False
    }
    git pull --rebase --stat origin/master
    if(-not $?){
        Write-Error 'Error rebasing changes from origin/master aborting update.'
        return $False
    }
    Write-Host 'Profile updated reloading.'
    return $True
}

function Install-AutoUpdates(){
  Write-Host 'Installing atom package updates:'
  Invoke-Expression 'apm upgrade --no-confirm'
  Write-Host 'Installing choco package updates:'
  Invoke-Expression 'choco upgrade all -y'
  Set-TouchItem $updateFileIndicator
}

Export-ModuleMember -Function Find-AutoUpdates, Install-AutoUpdates, Invoke-AutoUpdate
