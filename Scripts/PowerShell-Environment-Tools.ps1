# Invokes a Cmd.exe shell script and updates the environment.
function Invoke-CmdScript($scriptName,$scriptArgs) {
    $cmdLine = """$scriptName"" $scriptArgs & set"
    & $Env:SystemRoot\system32\cmd.exe /c $cmdLine |
    select-string '^([^=]*)=(.*)$' | 
    foreach-object {
        $varName = $_.Matches[0].Groups[1].Value
        $varValue = $_.Matches[0].Groups[2].Value
        set-item Env:$varName $varValue
        #Write-Host $varName ":`n" ($varValue -replace  ";","`n")
    }
}

# Returns the current environment.
function Get-Environment {
    $list = get-childitem Env:
    foreach ($item in $list){
        Write-Host $item.name ":`n`t" ($item.value -replace  ";","`n`t") "`n"
    }
}

# Restores the environment to a previous state.
function Restore-Environment {
 param(
     [parameter(Mandatory=$TRUE)]
     [System.Collections.DictionaryEntry[]] $oldEnv
 )
 # Removes any added variables.
 compare-object $oldEnv $(Get-Environment) -property Key -passthru |
 where-object { $_.SideIndicator -eq "=>" } |
 foreach-object { remove-item Env:$($_.Name) }
 # Reverts any changed variables to original values.
 compare-object $oldEnv $(Get-Environment) -property Value -passthru |
 where-object { $_.SideIndicator -eq "<=" } |
 foreach-object { set-item Env:$($_.Name) $_.Value }
}