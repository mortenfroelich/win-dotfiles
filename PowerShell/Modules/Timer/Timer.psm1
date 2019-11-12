#requires -version 4.0
Param(
    # Default path to use to find the audio file that is played upon terminating the timer. If no argument is given nothing is played.
    [Parameter(Position=0, Mandatory=$false)][string]$DefaultMusicPath = $Null
)

function Start-PSCountdown {
    <#
        .SYNOPSIS
            A progress bar based countdown that plays an audio file upon terminating.
        .DESCRIPTION
            Countdown timer that displays a progress bar with a subset of jokes to make the time go by.
            Plays the specified audio file upon completion. Note this only functions in Windows Powershell.

            This is a modified version of:
            https://gist.github.com/jdhitsolutions/2e58d1aa41f684408b64488259bbeed0

            That was originally inspired by code published at:
            https://github.com/Windos/powershell-depot/blob/master/livecoding.tv/StreamCountdown/StreamCountdown.psm1
        .EXAMPLE
            Start-PSCountdown

            Start a 20 minute timer with the default progress color and audio file.
    #>
    [cmdletbinding()]
    [OutputType("None")]
    Param(
        #Enter the number of minutes to countdown. The default is 20.
        [int32]$Minutes = 20,
        #Enter the text for the progress bar title.
        [ValidateNotNullorEmpty()]
        [string]$Title = "Counting Down ",
        #Enter a primary message to display in the parent window.
        [ValidateNotNullorEmpty()]
        [string]$Message = "Timer",
        #Use this parameter to clear the screen prior to starting the countdown.
        [switch]$ClearHost = $true,
        #Select a progress bar style. This only applies when using the PowerShell console or ISE.
        #
        #Default - use the current value of `$host.PrivateData.ProgressBarBackgroundColor
        #Transparent - set the progress bar background color to the same as the console
        #Random - randomly cycle through a list of console colors
        [ValidateSet("Default", "Random", "Transparent")]
        [alias("style")]
        [string]$ProgressStyle = "Default",
        #Path to music to play at end of timer
        [string]$PathToMusic = $DefaultMusicPath
    )
    Begin {
        if ($ClearHost) {
            Clear-Host
        }
        $PSBoundParameters | out-string | Write-Verbose
        if ($ProgressStyle -ne 'Default')
        {
            $saved = $host.PrivateData.ProgressBackgroundColor 
        }
        if ($ProgressStyle -eq 'Transparent')
        {
            $host.PrivateData.progressBackgroundColor = $host.ui.RawUI.BackgroundColor
        }
        $startTime = Get-Date
        $endTime = $startTime.AddMinutes($Minutes)
        $totalSeconds = (New-TimeSpan -Start $startTime -End $endTime).TotalSeconds

        $totalSecondsChild = Get-Random -Minimum 4 -Maximum 30
        $startTimeChild = $startTime
        $endTimeChild = $startTimeChild.AddSeconds($totalSecondsChild)
        $loadingMessage = Get-LoadingJoke


    } #begin
    Process {
        Do {
            $now = Get-Date
            $secondsElapsed = (New-TimeSpan -Start $startTime -End $now).TotalSeconds
            $secondsRemaining = $totalSeconds - $secondsElapsed
            $percentDone = ($secondsElapsed / $totalSeconds) * 100

            Write-Progress -id 0 -Activity $Title -Status $Message -PercentComplete $percentDone -SecondsRemaining $secondsRemaining

            $secondsElapsedChild = (New-TimeSpan -Start $startTimeChild -End $now).TotalSeconds
            $secondsRemainingChild = $totalSecondsChild - $secondsElapsedChild
            $percentDoneChild = ($secondsElapsedChild / $totalSecondsChild) * 100

            if ($percentDoneChild -le 100 -and $totalSecondsChild -ge 0) {
                Write-Progress -id 1 -ParentId 0 -Activity $loadingMessage -PercentComplete $percentDoneChild -SecondsRemaining $secondsRemainingChild
            }

            if ($percentDoneChild -ge 100) {
                if ($ProgressStyle -eq 'Random') {
                    $host.PrivateData.progressBackgroundColor = ($ProgressColors  | Get-Random)
                }
                $secondsRemaningMinusDelta = $secondsRemaining - 0.01
                $minimum = ( @(4, $secondsRemaningMinusDelta) | Measure-Object -Minimum ).Minimum
                Write-Verbose "Minimum: $minimum"
                $maximum = ( @(40, $secondsRemaining) | Measure-Object -Minimum  ).Minimum
                Write-Verbose "Maximum: $maximum "
                $totalSecondsChild = ( @(0, ( Get-Random -Minimum $minimum -Maximum $maximum )) | Measure-Object -Maximum ).Maximum
                $startTimeChild = $now
                $endTimeChild = $startTimeChild.AddSeconds($totalSecondsChild)
                if ($endTimeChild -gt $endTime) {
                    $endTimeChild = $endTime
                }
                $loadingMessage = Get-LoadingJoke
            }

            Start-Sleep 0.2
        } Until ($now -ge $endTime)
    } #progress

    End {
        if ($saved) {
            #restore value if it has been changed
            $host.PrivateData.ProgressBackgroundColor = $saved
        }
        if($PathToMusic){
            Start-MusicAndWait($PathToMusic)
        }
    } #end

} #end function

#define an optional alias
Set-Alias -Name spc -Value Start-PSCountdown

function Start-MusicAndWait([string]$PathToMusic){
    Add-Type -AssemblyName PresentationCore
    $mediaPlayer = New-Object System.Windows.Media.Mediaplayer
    $mediaPlayer.Open($PathToMusic)
    $mediaPlayer.Play()
    Write-Host -NoNewLine 'Press any key to stop music.';
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
    $mediaPlayer.Stop()
}

function Get-LoadingJoke(){
    return $LoadingJokes[(Get-Random -Minimum 0 -Maximum ($LoadingJokes.Length - 1))]
}

$LoadingJokes = @(
    'Waiting for someone to hit enter',
    'Warming up processors',
    'Downloading the Internet',
    'Trying common passwords',
    'Commencing infinite loop',
    'Injecting double negatives',
    'Breeding bits',
    'Capturing escaped bits',
    'Dreaming of electric sheep',
    'Calculating gravitational constant',
    'Adding Hidden Agendas',
    'Adjusting Bell Curves',
    'Aligning Covariance Matrices',
    'Attempting to Lock Back-Buffer',
    'Building Data Trees',
    'Calculating Inverse Probability Matrices',
    'Calculating Llama Expectoration Trajectory',
    'Compounding Inert Tessellations',
    'Concatenating Sub-Contractors',
    'Containing Existential Buffer',
    'Deciding What Message to Display Next',
    'Increasing Accuracy of RCI Simulators',
    'Perturbing Matrices',
    'Initializing flux capacitors',
    'Brushing up on my Dothraki',
    'Preparing second breakfast',
    'Preparing the jump to lightspeed',
    'Initiating self-destruct sequence',
    'Mining cryptocurrency',
    'Aligning Heisenberg compensators',
    'Setting phasers to stun',
    'Deciding...blue pill or yellow?',
    'Bringing Skynet online',
    'Learning PowerShell',
    'On hold with Comcast customer service',
    'Waiting for Godot',
    'Folding proteins',
    'Searching for infinity stones',
    'Restarting the ARC reactor',
    'Learning regular expressions',
    'Trying to quit vi',
    'Waiting for the last Game_of_Thrones book',
    'Watching paint dry',
    'Aligning warp coils'
)

$ProgressColors = "black", "darkgreen", "magenta", "blue", "darkgray"

Export-ModuleMember -Function Start-PSCountDown -Alias spc
