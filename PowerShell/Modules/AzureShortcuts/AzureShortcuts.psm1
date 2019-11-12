$confPath = (Join-Path (Split-Path $profile) "azureconf.json")
if(-not (Test-Path $confPath)){
    Write-Warning "Cannot find azure configuration aborting project dependant module load, use the azureconf.json template to define needed configuration."
    return
}
$conf = Get-Content $confPath | ConvertFrom-Json

function New-GitSolution{
    <#
    .SYNOPSIS
    Create a new solution from the given git repo and setup
    Mono solutions and upstream. Alias: ngs
    #>
    [Alias("ngs")]
    [Cmdletbinding()]
    Param(
        # The destination of the solution
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [alias("d")]
        [string]$destination,
        # The repository to clone
        [alias("r")]
        [string]$repo = $conf.DefaultRepo,
        # The repository to use as upstream, defaults to conf upstream repo.
        [alias("u")]
        [string]$upstream = $conf.UpstreamRepo,
        # The name of the master branch in the upstream repo
        [alias("m")]
        [string]$branch = $conf.DefaultMasterBranch)
    if ( -not (Get-Command git -errorAction SilentlyContinue)){
        throw 'Cannot find git, git is required to clone.'
    }
    $repoDestDir = Split-Path -Leaf $repo
    New-Item -ItemType "directory" -Path "$destination" -Force
    Push-Location "$destination"
    git clone $repo
    Push-Location $repoDestDir
    git remote add upstream $upstream
    git checkout $branch
    Pop-Location
    Pop-Location
}

function Invoke-GitSync{
    <#
    .SYNOPSIS
    Syncronize the fork master branch with upstream
    #>
    [Alias("sync")]
    [Cmdletbinding()]
    Param(
    # The name of the master branch
        [alias("m")]
        [string]$master = $conf.DefaultMasterBranch)
    Invoke-QuitOnError("git checkout $master")
    Invoke-QuitOnError("git pull upstream $master")
    Invoke-QuitOnError("git push origin $master")
}

function Invoke-GitRebase{
    <#
    .SYNOPSIS
    Rebase the current topic branch on top of master after syncing master with upstream.
    #>
    [alias("rebase")]
    [Cmdletbinding(SupportsShouldProcess=$True)]
    Param(
    # The name of the master branch
        [alias("m")]
        [string]$master = $conf.DefaultMasterBranch)
    $topicBranch = Get-GitBranch
    if($topicBranch -eq $master){
        throw 'Cannot automatically rebase master branch: $master, you risk wrecking your fork'
    }
    Invoke-GitSync -master $master
    Invoke-QuitOnError("git checkout $topicBranch")
    Invoke-QuitOnError("git rebase $master")
}
