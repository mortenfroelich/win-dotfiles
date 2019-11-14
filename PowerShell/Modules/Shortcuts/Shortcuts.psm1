Set-Alias 7z 'C:\Program Files\7-Zip\7z.exe'
Set-Alias sshagent Start-SshAgent
Set-Alias which Get-Command

function Invoke-QuitOnError{
    <#
    .SYNOPSIS
    Invoke commands but wrap them in a test that throws a powershell exception if git outputs an error.
    Also supports what-if
    #>
    [Cmdletbinding(SupportsShouldProcess=$True)]
    Param([string]$command)
    If($PSCmdlet.ShouldProcess("$command")){
        $ExprWithCatch = "$command" + ';$?'
        Write-Verbose "Executing command $command"
        $Success = Invoke-Expression $ExprWithCatch
        if (-not $Success) { throw "An error occured executing $command"}
    }
}

function Set-Dotfiles{
    <#
      .SYNOPSIS
        Change folder to the dotfiles root
    #>
    [alias("dotfiles")]
    [Cmdletbinding()]
    Param()
    Set-Location (Join-Path $HOME "Documents\dotfiles")
}

function Edit-Dotfiles{
    <#
       .SYNOPSIS
         Change folder to the dotfiles root
    #>
    [alias("edots")]
    [Cmdletbinding()]
    Param()
    Push-Location (Join-Path $HOME "Documents\dotfiles")
    e .
    Pop-Location
}

function Set-TouchItem{
    <#
      .SYNOPSIS
      Reimplenation of unixy touch function
    #>
    [alias("touch")]
    [Cmdletbinding()]
    Param(
       [Parameter(Mandatory=$True)]
       [String]$file)
        if(Test-Path $file){
	   (Get-ChildItem $file).LastWriteTime = Get-Date
	   return
        }
        echo $null > $file
}

function Find-RepoRoot{
    <#
.SYNOPSIS
     Find the root of the current repository of the given type. defaults to .git
#>
    [Cmdletbinding()]
    Param([string]$path = $(Get-Location),
         [string]$type = ".git")
    while ($path){
        Write-Verbose $path
        if (Test-Path -Path:(Join-Path $path $type)){
            return $path
        }
        $path = Split-Path $path
    }
    return $Null
}

function src{
    <#
      .SYNOPSIS
      Quickly change directory to C:\src
    #>
    [cmdletbinding()]
    Param()
  cd 'C:\src'
}

function nview{
    <#
      .SYNOPSIS
      Start NUnitResultViewer, loads the test result from the current solution if no arguments are given.
    #>
    [cmdletbinding()]
    Param(
        # Path to open.
        [alias("p")]
        [string]$Path,
        # Output list of failed test.
        [alias("f")]
        [switch]$Fail,
        # Output path for the list of failed tests defaults to: YYYY-MM-DD-[Solution]-failed.txt
        [string]$FailedOutputPath,
        # Output rerun script for failed tests.
        [alias("r")]
        [switch]$Rerun,
        # Output path for the rerun script. Defaults to YYYY-MM-DD-[Solution]-rerun.ps1
        [string]$RerunOutputPath
    )
    # TODO default the path to the current solution.
    if(-not $Path){
        $Path = Join-Path (Find-Root) 'Debug\.test'
    }
    $arguments = $Path
    if($Fail){
        if(-not $FailedOutputPath){
            $solution = Split-Path (Find-Root) -Leaf
            $FailedOutputPath = (Get-Date -format yyyy-MM-dd\THHmmss) + "-$solution-failed.txt"
        }
        $arguments += " -fail $FailedOutputPath"
    }
    if($Rerun){
        if(-not $RerunOutputPath){
            $solution = Split-Path (Find-Root) -Leaf
            $RerunOutputPath = (Get-Date -format yyyy-MM-dd\THHmmss) + "-$solution-rerun.ps1"
        }
        $arguments += " -rerun $RerunOutputPath"
    }
    $command = "NUnitResultViewer.exe $arguments"
    Write-Verbose $command
    Invoke-Expression $command
}

function fopen{
    <#
      .SYNOPSIS
         Use fzf to find a file and open with the given command.
    #>
    [cmdletbinding()]
    Param(
        # The command to execute.
        [alias("c")]
        [string]$command)
  if (Get-Command $command -errorAction SilentlyContinue){
    $temp = fzf
      if([String]::IsNullOrEmpty($temp))
      {
          Write-Output 'You must select a file'
          return
      }
    & $command $args $temp
  }
  else{
    Write-Error "Cannot find command: $command."
  }
}

function fann(){
    <#
      .SYNOPSIS
       Use fzf to find a file and annotate it.
    #>
    [cmdletbinding()]
    Param()
  fopen 'thg' 'ann'
}

