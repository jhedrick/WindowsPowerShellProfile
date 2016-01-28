# POWERSHELL PROFILE SCRIPT
# USEAGE: 1) Open powershell, type $profile.
#         2) Go to location in windows explorer, make a copy of your existing profile
#         3) Overwrite the existing file with this file. 
#            The script should display error messages if you do not have the proper software installed or pathed.

## Check if scripts directory is on the path
#============================================

$CheckScriptPath = "$home\Documents\WindowsPowerShell\Scripts"
$Path=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path 
 
# Verify item exists as an EXACT match to 
$Verify=$Path.split(';') -contains $CheckScriptPath 
 
If (-Not($Verify)) {
  Write-Host "`nPlease add $CheckScriptPath to your path and restart your powershell terminal."  -ForegroundColor Red
  Exit
} 


## Load Path Modification Support

. .\Path-Modification-Support.ps1


## Load posh-git example profile 
#=================================
# My prompt was modified to include abbreviate long shell paths from http://winterdom.com/2008/08/mypowershellprompt

if (Get-Module -ListAvailable -Name posh-git) {
  . "$home\Documents\WindowsPowerShell\Modules\posh-git\profile.example.ps1"
} else {
  if (-Not(Get-Command git)) {Write-Host "Please download git from http://git-scm.com ... then ..."}
  Write-Host "`nPlease visit : "   -ForegroundColor Red
  Write-Host "http://haacked.com/archive/2011/12/13/better-git-with-powershell.aspx/"   -ForegroundColor White
  Write-Host "Follow instructions for installing Posh-Git."   -ForegroundColor Red
  Write-Host "See $profile\..\Modules\posh-git\profile.example.ps1 in the gist for a better profile with shorter path."   -ForegroundColor Red
}


## Set environment variables for Visual Studio Command Prompt 
#=================================

$ProgramFilesx86 = "${Env:ProgramFiles(x86)}"  
if (Test-Path "$ProgramFilesx86\Microsoft Visual Studio 14.0\VC") { 
  pushd 'c:\Program Files (x86)\Microsoft Visual Studio 14.0\VC'
  cmd /c "vcvarsall.bat intel64 & set" |
  foreach {
    if ($_ -match "=") {
      $v = $_.split("="); set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
    }
  }
  popd
  write-host "`nVisual Studio 2015 (MSVC14) Command Prompt variables set." -ForegroundColor Yellow
} Else {
  write-host "`nPlease install Visual Studio 2015 (MSVC14)." -ForegroundColor Red
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

  write-host "`ndir and ls output will now be colored." -ForegroundColor Yellow
} catch  { 
  write-host "`nCould not set dir and ls..." -ForegroundColor Red
}

## Set BASH aliases (makes PS more unix user friendly)
#=====================================================

write-host "`nSetting some bash like aliases..." -ForegroundColor Yellow

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

  write-host "`nVim has been initialized!" -ForegroundColor Yellow
} Else { 
  write-host "`nInstall Vim for windows if you would like a syntax highlighting text editor in terminal." -ForegroundColor Red
  write-host "`nhttp://www.vim.org/download.php#pc" -ForegroundColor White
  
}