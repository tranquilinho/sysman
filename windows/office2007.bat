:: OPTIONAL: Install Office 2007
@Echo off
:: Reminder: Commands will be executed in reverse order.


:: The MSP includes the key
:: call %Z%\site\keys.bat
:: if %office2k3%==xxxxxxx goto nokey

:: Pro -- todo.pl "%Z%\site\packages\office2007\setup.exe /adminfile %Z%\site\packages\office2007\install.msp"

todo.pl "%Z%\site\packages\office2007-ent-csic\setup.exe /adminfile %Z%\site\packages\office2007-ent-csic\install.msp"

if errorlevel 1 exit 1
exit 0

:nokey
@echo *** Unable to get Office license key
@echo ***  (did you forget to edit %Z%\site\keys.bat?)
exit 2
