Param(
    [Parameter(Position=0,Mandatory=$False)][switch]$Verbose
)
$confPath = (Join-Path (Split-Path $profile) "projectconf.json")
if(-not (Test-Path $confPath)){
    Write-Warning "Cannot find project configuration aborting project dependant module load, use the projectconf.json template to define needed configuration."
    return
}
$conf = Get-Content $confPath | ConvertFrom-Json

if($Verbose){
    Write-Host "defaultSolution: $($conf.defaultSolution)"
    Write-Host "solutionPatterns: $($conf.solutionPatterns)"
    Write-Host "mainProject: $($conf.mainProject)"
}
function ol([switch]$a){
    open $conf.mainProject $conf.defaultSolution -a:$a
}

function Get-ClonePrompt($fullloc){
    if($fullloc -match 'C:\\src\\(\d).*'){
        return $matches[1]
    }
    return ""
}

function sbs{
    <#
    .SYNOPSIS
    Stop, Build, Start the current solution.
    #>
    [cmdletbinding()]
    Param($s)
    edlstop
    build
    edlstart $s
}

function mpul{
    <#
    .SYNOPSIS
    Run repo pul in the master clone, will throw if not in a solution.
    #>
    [cmdletbinding()]
    Param()
    Push-Location (Join-Path (Split-Path (getSolutionRoot)) MASTER)
    repo pul
    Pop-Location
}

function mpus{
    Push-Location (Join-Path (Split-Path (getSolutionRoot)) MASTER)
    repo pus
    Pop-Location
}

function mreb($module){
    Push-Location (Join-Path (Join-Path (Split-Path (getSolutionRoot)) MASTER) $module)
    hg rebase
    Pop-Location
}

function mst{
    Push-Location (Join-Path (Split-Path (getSolutionRoot)) MASTER)
    repo st
    Pop-Location
}

function min{
    <#
      .SYNOPSIS
        Run repo in, in the master clone, will throw if not in a solution.
    #>
    Push-Location (Join-Path (Split-Path (getSolutionRoot)) MASTER)
    repo in
    Pop-Location
}

function drafts{
    <#
      .SYNOPSIS
        Fetch drafts from the root of the solution, throws if not in a solution
    #>
    [cmdletbinding()]
    Param()
    Push-Location (Find-Root -type ".repo")
    Get-ChildItem -Directory | %{
        if(Test-Path (Join-Path $_.FullName '.hg')){
            Push-Location $_.FullName
            Write-Output (Split-Path $_.FullName -Leaf)
            hg log -r 'draft()'
            Pop-Location
        }
    }
    Pop-Location
}

function unbundle([string]$searchpattern){
    Push-Location 'C:\src\bundles'
    $files = Get-ChildItem ('*' + $searchpattern + '*')
    Pop-Location
    if ($files.Count -eq 0){
        throw "Cannot find bundle matching $searchpattern"
    }
    if ($files.Count -gt 1){
        Write-Warning 'Found multiple matches:'
        foreach ($file in $files){
            Write-Warning $file.Name
        }
        throw "Ambigious pattern $searchpattern" 
    }
    repo pul $files.FullName
}

function cts{
    <#
.SYNOPSIS
Change to solution, used to quickly jump between standardized solutions in 1, 2 and core
#>
    [Cmdletbinding()]
    Param(
        [string]$s)

    $root = Find-Root -type ".repo"
    if ($s -Match '.*(\d).*')
    {
        $cloneRoot = "C:\src\$Matches[1]"
        Write-Verbose "$s matches a clone, setting cloneRoot to $cloneRoot"
    }else{
        Write-Verbose "Root not specified, found root: $root"
        if($root) {$cloneRoot = Split-Path $root}
        Write-Verbose "Cloneroot set to : $cloneRoot"
      if(!$root){
        $cloneRoot = 'C:\src\1\'
          Write-Verbose "No cloneRoot found defaulting to cloneRoot: $cloneRoot"
      }
    }
    $solution = Get-FullSolutionName($s) -ErrorAction SilentlyContinue
    if(-not $solution){
        if($root){
            $solution = Split-Path -Leaf $root
            Write-Verbose "No solution given, setting to solution in current root: $solution."
        }
        else{
            throw "Not currently in a solution and no solution given in: $s"
        }
    }
    $path = (Get-Location).Path
    $solutionRoot = Join-Path $cloneRoot $solution
    if($root -And $path -ne $root){ # If root is $Null then we are not in a solution and finding the rest is meaningless
        $rest = $path.Substring($root.Length + 1)
        Write-Verbose "Not currently at root of solution saving 'rest' $rest"
    }
    $goto = Join-Path $solutionRoot $rest
  if(Test-Path $goto){
      Write-Verbose "Changing to $goto"
    cd $goto
  }else
  {
      Write-Verbose "Cannot find folder in solution going to root: $solutionRoot"
      if(-not (Test-Path $solutionRoot)){throw 'Cannot find solution root, did you forget to create the default clones?'}
      cd $solutionRoot
  }
}

function Get-FullSolutionName{
    <#
.SYNOPSIS
Map shorthand solution names to full solutions.
#>
    [Cmdletbinding()]
    Param([string]$s,[switch]$allowMaster)
    Process {
        Foreach ($solutionPattern in $conf.solutionPatterns){
            Write-Verbose "Trying to match pattern: .*$($solutionPattern.pattern).*"
            If($s -Match ".*$($solutionPattern.pattern).*"){
                Write-Verbose "Matched $($solutionPattern.pattern) returning $($solutionPattern.solution)"
                return $solutionPattern.solution
            }
        }
        Write-Verbose "No matching solution found."
        if($ErrorAction -ne 'SilentlyContinue')
        {
            throw "Unknown solution: " + $s
        }
    }
}

function Get-SolutionPath($solution){
    $root = Find-Root -type ".repo"
    return (Join-Path (Split-Path ($root)) $solution)
}

function fors{
    param(
        [string] $command,
        [string] $selectedSolutions = 'lnp'
    )
    $solutions = New-Object System.Collections.Generic.List[System.Object]
    Foreach ($s in $selectedSolutions.ToCharArray())
    {
        $solutions += Get-FullSolutionName($s)
    }
    Foreach ($solution in $solutions)
    {
        Push-Location (Get-SolutionPath $solution)
        Write-Host "Running '$command' for: " (pwd)
        Invoke-Expression "& $command"
        Pop-Location
    }
}

function bundle($name){
    if(!(pwd | Out-String) -Match 'MASTER|MAIN'){
        throw "Current folder is not part of master or main clone"
    }
    if(!$name){
        $name = "temp"
    }
    $name = (Get-Date -format yyyy-MM-dd\THHmmss) + "-" + $name + ".bundle"
    $path = Join-Path 'C:\src\bundles\' $name
    Write-Host "Bundling to : $path"
    repo bundle $path $args
}
