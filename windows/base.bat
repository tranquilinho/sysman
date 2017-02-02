:: MASTER: Perform a basic workstation installation
@Echo off

:: Set Automatic Updates to download and install automatically every Tue (SP2 behavior)
todo.pl "auconfig.pl --day 3 --time 12 --wait 10 4 --noautoreboot"

:: Update windows and turn off annoying stuff.
todo.pl %%WINVER%%-updates.bat %%WINVER%%-notips.pl .reboot

:: Defragment the drive to collect the free space.
todo.pl defrag.bat

:: Set IIS startup type to manual and ignore if not installed.
todo.pl ".ignore-err 255 startup-type.pl Manual IISADMIN" ".ignore-err 255 startup-type.pl Manual W3SVC"

:: Turn off Windows Messenger service
todo.pl "startup-type.pl Disabled Messenger"
