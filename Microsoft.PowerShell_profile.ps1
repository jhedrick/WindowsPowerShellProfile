# POWERSHELL PROFILE SCRIPT
# USEAGE: 1) Open powershell, type $profile.
#         2) Go to location in windows explorer, make a copy of your existing profile (if it exists)
#         3) Overwrite the existing file with this file.
#            The script should display error messages if you do not have the proper software installed or pathed.

## Initializations
#=================

<# Uncomment the following if you have relocated your user directory to another location... You'll need to specify the location manually.
(get-psprovider filesystem).Home = "X:\Users\<user>"
#>

If (-Not (host).version.Major -gt 3) {
    Write-Host "`nPlease download Windows Management Framework 4.0 or greater."  -ForegroundColor Red
    Write-Host "`nDiscontinuing profile installation..." -ForegroundColor Red
    Exit
}

$ProfileDir = Split-Path -Path $profile

## Check if scripts directory is on the path
#============================================

$CheckScriptPath = "$ProfileDir\Scripts"
$Path=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path


# Verify item exists as an EXACT match to
$Verify=$Path.split(';') -contains $CheckScriptPath

If (-Not($Verify)) {
  Write-Host "`nPlease add $CheckScriptPath to your path and restart your powershell terminal."  -ForegroundColor Red
  # Check the active user's path since it is not concatinated onto the registry...
  $Path=[Environment]::GetEnvironmentVariable( "PATH", [System.EnvironmentVariableTarget]::User )
  # Verify item exists as an EXACT match to
  $Verify=$Path.split(';') -contains $CheckScriptPath
  If (-Not($Verify)) {
    Write-Host "`nAlso checked the active users path."  -ForegroundColor Red
    Exit
  }
}


## Check System Execution Policy
# ===============================

$Policy = "RemoteSigned"
If ((get-ExecutionPolicy) -ne $Policy) {
   Set-ExecutionPolicy $Policy -Force
}


# Check If PsGet is installed in the system.
# ===============================

if (Get-Module -ListAvailable -Name PsGet) {
    Write-Host "PsGet is installed" -ForegroundColor Yellow
} else {
    Write-Host "Installing PsGet Module to add shell script / module installation support." -ForegroundColor Green
    (new-object Net.WebClient).DownloadString("http://psget.net/GetPsGet.ps1") | iex
}


## Load Path Modification Support (Not PsGet Based Script)
# ===============================

. Path-Modification-Support

## Improve terminal format
# ========================
. PowerShell-Formatting


# Check If git is installed in the system.
# ==========================================

if ((Get-Command "git.exe" -ErrorAction SilentlyContinue) -eq $null)
{
   Write-Host "Unable to find git.exe in your PATH. Please check installation, or install from git-scm.com/downloads" -ForegroundColor Red
   Write-Host "Powershell profile installation will not complete until git is installed."
   Exit
}


# Check If PsGet is installed in the system.
# ===========================================

if (Get-Module -ListAvailable -Name posh-git) {
    Write-Host "posh-git is installed" -ForegroundColor Yellow
} else {
    Write-Host "Installing posh-git Module to add git support." -ForegroundColor Green
    Install-Module posh-git
}


## Load posh-git example profile
#=================================
# My prompt was modified to include abbreviate long shell paths from http://winterdom.com/2008/08/mypowershellprompt

if (Get-Module -ListAvailable -Name posh-git) {

    Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)

    # Load posh-git module from current directory
    Import-Module posh-git

    # If module is installed in a default location ($env:PSModulePath),
    # use this instead (see about_Modules for more information):
    # Import-Module posh-git

    # Required to shorten.

    function shorten-path([string] $path) {
       $loc = $path.Replace($HOME, '~')
       # remove prefix for UNC paths
       $loc = $loc -replace '^[^:]+::', ''
       # make path shorter like tabs in Vim,
       # handle paths starting with \\ and . correctly
       return ($loc -replace '\\(\.?)([^\\])[^\\]*(?=\\)','\$1$2')
    }

    # Set up a simple prompt, adding the git prompt parts inside git repos
    function global:prompt {
        $realLASTEXITCODE = $LASTEXITCODE

        # Reset color, which can be messed up by Enable-GitColors
        $Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultForegroundColor

        #Write-Host($pwd.ProviderPath) -nonewline # Old git-posh
        # New shorter lines.
        $cdelim = [ConsoleColor]::DarkCyan
        $chost = [ConsoleColor]::Green
        $cloc = [ConsoleColor]::Cyan
        Write-Host "$([char]0x0A7) " -n -f $cloc
        Write-Host ([net.dns]::GetHostName()) -n -f $chost
        Write-Host ' {' -n -f $cdelim
        Write-Host (shorten-path (pwd).Path) -n -f $cloc
        Write-Host '}' -n -f $cdelim

        Write-VcsStatus

        $global:LASTEXITCODE = $realLASTEXITCODE
        return "> "
    }

    Pop-Location

    Start-SshAgent -Quiet

} else {
    Write-Host "Profile installation incomplete. Ensure posh-git is installed to enable prompt update."   -ForegroundColor Red
}


## Set environment variables for Visual Studio Command Prompt
#=================================
. PowerShell-Environment-Tools
if ($Env:VS140COMNTOOLS) {
  if (Test-Path "$Env:VS140COMNTOOLS..\..\VC") {
    Invoke-CmdScript "$Env:VS140COMNTOOLS..\..\VC\vcvarsall.bat" "x64"
    Write-Host "`nVisual Studio 2015 (MSVC14) Command Prompt variables set." -ForegroundColor Yellow
  }
} Else {
  Write-Host "`nPlease install Visual Studio 2015 (MSVC14)." -ForegroundColor Red
}


## Set environment variables for Intel XE 2016 Library Command Prompt
#====================================================================
$ProgramFilesx86 = "${Env:ProgramFiles(x86)}"
if (Test-Path "$ProgramFilesx86\IntelSWTools\compilers_and_libraries_2016.1.146") {
    Invoke-CmdScript "C:\Program Files (x86)\IntelSWTools\compilers_and_libraries_2016.1.146\windows\bin\ipsxe-comp-vars.bat" "intel64 vc2015"
    Write-Host "`n ... Variables superseded by Intel Compilers and Libraries." -ForegroundColor Yellow
    Invoke-CmdScript "C:\Program Files (x86)\IntelSWTools\compilers_and_libraries_2016.1.146\windows\mkl\bin\mklvars.bat" "intel64 vc2015"
    Write-Host "`n ... including Intel MKL." -ForegroundColor Yellow
}


## Clean up environment variables by removing duplicates
#=======================================================

$d = ';' # Separate paths by delimiter
$list = (Get-Childitem Env:)
foreach ($item in $list) {
  Try {
    #Write-Host "`n Processed:" $item.name
    #Write-Host "Value:" $item.value
    $new_value = (( $item.value -split $d | select -Unique ) -join $d)
    #(Set-Item env:$item.name $new_value) # This does not work in V4
    [Environment]::SetEnvironmentVariable($item.name,$new_value) # This does?
    #Write-Host "`n Processed:" $item.name
    #Write-Host "Value:" $item.value
  } Catch {
    Write-Host ("Failed to process: " + $item.name)
  }
}


## Color the dir and ls commands.
#=================================
  try {
  New-CommandWrapper Out-Default -Process {
    $regex_opts = ([System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $compressed = New-Object System.Text.RegularExpressions.Regex(
      '\.(zip|tar|gz|rar|jar|war|mat)$', $regex_opts)
    $executable = New-Object System.Text.RegularExpressions.Regex(
      '\.(exe|bat|cmd|py|msi|ps1|psm1|vbs|reg|m)$', $regex_opts)
    $doc = New-Object System.Text.RegularExpressions.Regex(
      '\.(doc|docx|xls|xlsx|pdf|ppt|pptx)$', $regex_opts)
     $text_docs = New-Object System.Text.RegularExpressions.Regex(
          '\.(txt|tex|cfg|conf|ini|csv|log|xml|java|c|cpp|cs|asv)$', $regex_opts)

    if(($_ -is [System.IO.DirectoryInfo]) -or ($_ -is [System.IO.FileInfo]))
    {
      if(-not ($notfirst))
      {
        Write-Host "`n    Directory: " -noNewLine
        Write-Host "$(pwd)`n" -foregroundcolor "Cyan"
        Write-Host "Mode        Last Write Time       Length   Name"
        Write-Host "----        ---------------       ------   ----"
        $notfirst=$true
      }

      if ($_ -is [System.IO.DirectoryInfo])
      {
        Write-Host ("{0}   {1}                {2}" -f $_.mode, ([String]::Format("{0,10} {1,8}", $_.LastWriteTime.ToString("d"), $_.LastWriteTime.ToString("t"))), $_.name) -ForegroundColor "Cyan"
      }
      else
      {
        if ($compressed.IsMatch($_.Name))
        {
          $color = "Red"
        }
        elseif ($executable.IsMatch($_.Name))
        {
          $color =  "Magenta"
        }
        elseif ($doc.IsMatch($_.Name))
        {
          $color =  "Yellow"
        }
        elseif ($text_docs.IsMatch($_.Name))
        {
          $color =  "Green"
        }
        else
        {
          $color = "White"
        }
        Write-Host ("{0}   {1}   {2,10}   {3}" -f $_.mode, ([String]::Format("{0,10} {1,8}", $_.LastWriteTime.ToString("d"), $_.LastWriteTime.ToString("t"))), $_.length, $_.name) -ForegroundColor $color
      }

      $_ = $null
    }
  } -end {
    Write-Host
  }

  function Get-DirSize
  {
    param ($dir)
    $bytes = 0
    $count = 0

    Get-Childitem $dir | Foreach-Object {
      if ($_ -is [System.IO.FileInfo])
      {
        $bytes += $_.Length
        $count++
      }
    }

    Write-Host "`n    " -NoNewline

    if ($bytes -ge 1KB -and $bytes -lt 1MB)
    {
      Write-Host ("" + [Math]::Round(($bytes / 1KB), 2) + " KB") -ForegroundColor "White" -NoNewLine
    }
    elseif ($bytes -ge 1MB -and $bytes -lt 1GB)
    {
      Write-Host ("" + [Math]::Round(($bytes / 1MB), 2) + " MB") -ForegroundColor "White" -NoNewLine
    }
    elseif ($bytes -ge 1GB)
    {
      Write-Host ("" + [Math]::Round(($bytes / 1GB), 2) + " GB") -ForegroundColor "White" -NoNewLine
    }
    else
    {
      Write-Host ("" + $bytes + " bytes") -ForegroundColor "White" -NoNewLine
    }
    Write-Host " in " -NoNewline
    Write-Host $count -ForegroundColor "White" -NoNewline
    Write-Host " files"

  }

  function Get-DirWithSize
  {
    param ($dir)
    Get-Childitem $dir
    Get-DirSize $dir
  }

  Remove-Item alias:dir
  Remove-Item alias:ls
  Set-Alias dir Get-DirWithSize
  Set-Alias ls Get-DirWithSize
  Set-Alias la Get-DirWithSize

  Write-Host "`ndir and ls output will now be colored." -ForegroundColor Yellow
} catch  {
  Write-Host "`nCould not set dir and ls..." -ForegroundColor Red
}

## Set BASH aliases (makes PS more unix user friendly)
#=====================================================

Write-Host "`nSetting some bash like aliases..." -ForegroundColor Yellow

function which
{
get-command $args -All | Format-Table CommandType, Name, Definition -AutoSize
}


## Configure vim
#================

if (Test-Path "$ProgramFilesx86\Vim\vim74") {

  set-alias vim "C:/Program Files (x86)/Vim/vim74/vim.exe"

  # To edit the Powershell Profile
  # (Not that I'll remember this)
  Function Edit-Profile
  {
      vim $profile
  }

  # To edit Vim settings
  Function Edit-Vimrc
  {
      vim $HOME\_vimrc
  }

  Write-Host "`nVim has been initialized!" -ForegroundColor Yellow
} Else {
  Write-Host "`nInstall Vim for windows if you would like a syntax highlighting text editor in terminal." -ForegroundColor Red
  Write-Host "`nhttp://www.vim.org/download.php#pc" -ForegroundColor White

}

## Confirm Status
# ===============

$continue = Read-Host "Clear prompt? (y/n)"
If ($continue -eq "y") {
  Clear-Host
} Else {
  Write-Host "Welcome back!"
}

# Load posh-git example profile
. 'C:\Users\jhedrick\Documents\WindowsPowerShell\Modules\posh-git\profile.example.ps1'
