#requires -Version 2 -Modules posh-git

$confPath = (Join-Path (Split-Path $profile) "promptconf.json")
if(-not (Test-Path $confPath)){
    Write-Warning "Cannot find prompt configuration solutions wont be mapped."
}
$conf = Get-Content $confPath | ConvertFrom-Json

function Get-SolutionPrompt($root){
  if($root){
    $solution = Split-Path $root -Leaf
      return $conf."$solution"
  }
  return $null
}

function Get-ModulePrompt($path, $root){
  if($root -And $path -ne $root){
      return ($path.Substring($root.Length + 1)).Split('\')[0]
  }
  return $null
}

function Get-HgPrompt{
    if(Find-Root -type ".hg"){
        Invoke-Expression 'hg summary' | foreach {
  		      switch -regex ($_) {
  			        'branch: ([\S ]*)' { $branch = $matches[1] }
  			        'commit: (.*)' { $clean = $matches[1].Contains('(clean)')}
  			    }
        }
    }
    $result = New-Object PSObject -Property @{
        Branch = $branch
        Clean = $clean
    }
    return $result
}

function Write-Theme {

    param(
        [bool]
        $lastCommandFailed,
        [string]
        $with
    )

    # Print a memory boosting function of the day at set intervals.
    Get-TipPrompt

    $lastColor = $sl.Colors.PromptBackgroundColor

    $prompt = Write-Prompt -Object $sl.PromptSymbols.StartSymbol -ForegroundColor $sl.Colors.SessionInfoForegroundColor -BackgroundColor $sl.Colors.SessionInfoBackgroundColor

    #check the last command state and indicate if failed
    If ($lastCommandFailed) {
        $prompt += Write-Prompt -Object "$($sl.PromptSymbols.FailedCommandSymbol) " -ForegroundColor $sl.Colors.CommandFailedIconForegroundColor -BackgroundColor $sl.Colors.SessionInfoBackgroundColor
    }

    #check for elevated prompt
    If (Test-Administrator) {
        $prompt += Write-Prompt -Object "$($sl.PromptSymbols.ElevatedSymbol) " -ForegroundColor $sl.Colors.AdminIconForegroundColor -BackgroundColor $sl.Colors.SessionInfoBackgroundColor
    }

    if (Test-VirtualEnv) {
        $prompt += Write-Prompt -Object "$($sl.PromptSymbols.SegmentForwardSymbol) " -ForegroundColor $sl.Colors.SessionInfoBackgroundColor -BackgroundColor $sl.Colors.VirtualEnvBackgroundColor
        $prompt += Write-Prompt -Object "$($sl.PromptSymbols.VirtualEnvSymbol) $(Get-VirtualEnvName) " -ForegroundColor $sl.Colors.VirtualEnvForegroundColor -BackgroundColor $sl.Colors.VirtualEnvBackgroundColor
        $prompt += Write-Prompt -Object "$($sl.PromptSymbols.SegmentForwardSymbol) " -ForegroundColor $sl.Colors.VirtualEnvBackgroundColor -BackgroundColor $sl.Colors.PromptBackgroundColor
    }
    else {
        $prompt += Write-Prompt -Object "$($sl.PromptSymbols.SegmentForwardSymbol)" -ForegroundColor $sl.Colors.SessionInfoBackgroundColor -BackgroundColor $sl.Colors.PromptBackgroundColor
    }

    # Writes the drive portion
    $path = (Get-Location).Path
    if($path -eq $HOME){
        $prompt += Write-Prompt -Object "~" -ForegroundColor $sl.Colors.PromptForegroundColor -BackgroundColor $sl.Colors.PromptBackgroundColor
    }
    else{
        $clone = Get-ClonePrompt($path)
        if($clone){
            $prompt += Write-Prompt -Object $clone -ForegroundColor $sl.Colors.PromptForegroundColor -BackgroundColor $sl.Colors.PromptBackgroundColor
            $prompt += Write-Prompt -Object $sl.PromptSymbols.SegmentForwardSymbol -ForegroundColor $sl.Colors.SessionInfoBackgroundColor -BackgroundColor $sl.Colors.PromptBackgroundColor
        }
        $root = Find-Root -type ".repo"
        $solution = Get-SolutionPrompt($root)
        if($solution){
            $prompt += Write-Prompt -Object $solution -ForegroundColor $sl.Colors.PromptForegroundColor -BackgroundColor $sl.Colors.PromptBackgroundColor
            $prompt += Write-Prompt -Object $sl.PromptSymbols.SegmentForwardSymbol -ForegroundColor $sl.Colors.SessionInfoBackgroundColor -BackgroundColor $sl.Colors.PromptBackgroundColor
        }
        $module = Get-ModulePrompt($path, $root)
        if($module){
            $prompt += Write-Prompt -Object $module -ForegroundColor $sl.Colors.PromptForegroundColor -BackgroundColor $sl.Colors.PromptBackgroundColor
            $prompt += Write-Prompt -Object $sl.PromptSymbols.SegmentForwardSymbol -ForegroundColor $sl.Colors.SessionInfoBackgroundColor -BackgroundColor $sl.Colors.PromptBackgroundColor
        }
        #$prompt += Write-Prompt -Object ' ' -ForegroundColor $sl.Colors.PromptForegroundColor -BackgroundColor $sl.Colors.PromptBackgroundColor
        $leaf = Split-Path $path -Leaf
        if($path -ne $root -And ($leaf -ne $module)){
            $prompt += Write-Prompt -Object $leaf -ForegroundColor $sl.Colors.PromptForegroundColor -BackgroundColor $sl.Colors.PromptBackgroundColor
        }
    }


    $status = Get-VCSStatus
    if ($status) {
        $themeInfo = Get-VcsInfo -status ($status)
        $lastColor = $themeInfo.BackgroundColor
        $prompt += Write-Prompt -Object $sl.PromptSymbols.SegmentForwardSymbol -ForegroundColor $sl.Colors.PromptBackgroundColor -BackgroundColor $lastColor
        $prompt += Write-Prompt -Object " $($themeInfo.VcInfo) " -BackgroundColor $lastColor -ForegroundColor $sl.Colors.GitForegroundColor
    }
    $hg = Get-HgPrompt 2>&1

    if($hg.Branch){
        if(-not $hg.Clean){
            $lastColor = $sl.Colors.GitLocalChangesColor
        }else{
            $lastColor = $sl.Colors.GitDefaultColor
        }
        $prompt += Write-Prompt -Object $sl.PromptSymbols.SegmentForwardSymbol -ForegroundColor $sl.Colors.PromptBackgroundColor -BackgroundColor $lastColor
        Write-Prompt -Object $sl.GitSymbols.BranchSymbol -ForegroundColor $sl.Colors.GitForegroundColor -BackgroundColor $lastColor
        Write-Prompt -Object "$($hg.Branch) " -ForegroundColor $sl.Colors.GitForegroundColor -BackgroundColor $lastColor
        if(-not $hg.Clean){
            Write-Prompt -Object $sl.PromptSymbols.GitDirtyIndicator -ForegroundColor $sl.Colors.GitForegroundColor -BackgroundColor $lastColor
        }
    }

    if ($with) {
        $prompt += Write-Prompt -Object $sl.PromptSymbols.SegmentForwardSymbol -ForegroundColor $lastColor -BackgroundColor $sl.Colors.WithBackgroundColor
        $prompt += Write-Prompt -Object " $($with.ToUpper()) " -BackgroundColor $sl.Colors.WithBackgroundColor -ForegroundColor $sl.Colors.WithForegroundColor
        $lastColor = $sl.Colors.WithBackgroundColor
    }

    # Writes the postfix to the prompt
    $prompt += Write-Prompt -Object $sl.PromptSymbols.SegmentForwardSymbol -ForegroundColor $lastColor
    $prompt += ' '
    $prompt

    # If run in ConEmu run hooks to set titles.
    if ($env:ConEmuANSI -eq "ON") {
        & "$env:ConEmuBaseDir\ConEmuC.exe" "/GUIMACRO", 'Rename(0,@"'$path''$name'")' > $null
        & "$env:ConEmuBaseDir\ConEmuC.exe" "/GUIMACRO", 'Status(1,@"'$path''$name'")' > $null
    }
}

$sl = $global:ThemeSettings #local settings
$sl.PromptSymbols.SegmentForwardSymbol = [char]::ConvertFromUtf32(0xE0B0)
$sl.PromptSymbols.GitDirtyIndicator = [char]::ConvertFromUtf32(10007)
$sl.Colors.PromptForegroundColor = [ConsoleColor]::White
$sl.Colors.PromptSymbolColor = [ConsoleColor]::White
$sl.Colors.PromptHighlightColor = [ConsoleColor]::DarkBlue
$sl.Colors.GitForegroundColor = [ConsoleColor]::Black
$sl.Colors.WithForegroundColor = [ConsoleColor]::White
$sl.Colors.WithBackgroundColor = [ConsoleColor]::DarkRed
$sl.Colors.VirtualEnvBackgroundColor = [System.ConsoleColor]::Red
$sl.Colors.VirtualEnvForegroundColor = [System.ConsoleColor]::White
