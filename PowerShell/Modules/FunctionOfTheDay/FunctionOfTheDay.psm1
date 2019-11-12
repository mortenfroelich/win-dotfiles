Param(
    # Sources of functions and alias to ignore
    [Parameter(Position=0, Mandatory=$false)][string[]]$IgnoredSources = @()
)

$tipOfTheDayIndicator = Join-Path $env:LOCALAPPDATA '.tipOfTheDayIndicator'
$updateFrequencyInMinutes = 30

function Get-FunctionOfTheDay {
    <#
        .SYNOPSIS
            Fetch the help documentation from a random user defined function.
        .DESCRIPTION
            Get the help documentation from a random user defined function to help with recall of user defined functions.
    #>
    [cmdletbinding()]
    [OutputType("None")]
    Param()
    $functions = Get-ChildItem function: | where {$_.source -ne [string]::Empty -and $IgnoredSources -NotContains $_.source}
    $alias = Get-ChildItem alias: | where {$_.source -ne [string]::Empty -and $IgnoredSources -NotContains $_.source}
    $item = ($functions + $alias) | Get-Random
    if($item.CommandType -eq 'Function'){
        $help = Get-Help $item
        Write-Host "Function of the day: $($help.Name)"
        Write-Host "Synopsis: $($help.Synopsis)"
    }
    else{
        Write-Host "Todays function is an alias:"
        Write-Host "$($item.Name) -> $(which $item)"
    }
}

function Test-IsOutOfDate([string]$file, [datetime]$date)
{
    $item = get-item -ErrorAction SilentlyContinue $file
    Write-Verbose "Last write time: $($item.LastWriteTime)"
    Write-Verbose "Out of date at: $date"
    return !$item -or ($item.LastWriteTime -lt $date)
}

function Get-TipPrompt(){
    [cmdletbinding()]
    [OutputType("None")]
    Param()
    if(Test-IsOutOfDate $tipOfTheDayIndicator (Get-Date).AddMinutes($updateFrequencyInMinutes * -1)){
        Set-TouchItem $tipOfTheDayIndicator
        Write-Host "------"
        Get-FunctionOfTheDay
        Write-Host "------"
    }
}

#define an optional alias
Set-Alias -Name gfotd -Value Get-FunctionOfTheDay


Export-ModuleMember -Function Get-FunctionOfTheDay, Get-TipPrompt -Alias gfotd
