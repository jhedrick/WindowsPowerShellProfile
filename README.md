# Powershell Profile

Your powershell profile is stored in `$profile` environment variable. You can read this variable in powershell.

The purpose of this file should be as simple as 

1. cloning this repository into a Download location (or unzipping it), 
2. backing up your existing profile in the directory $profile is stored in (should if you already use powershell), and
3. overwriting the primary profile, including extra scripts and modules that enable the desired functionality.

## Functions:

+ posh-git : Adds annotation to the shell when in a git folder. `C:\..\*.git [master +3 ~0 -0 !] >`
+ shorten-path: Creates a visually short representation of the current directory. `§ computerName {~\D\WindowsPowerShell}`
+ Visual Studio Command Prompt : Enables access to cl.exe and other VS compilers you have installed.
+ `ls, dir` commands: 
    * are colored, similar to ls on linux systems. This is configurable under `New-CommandWrapper()`
    * show human readable sizes
+ adds bash like syntax: `which`,`pwd`
+ If vim is installed, adds `vim` aliasing