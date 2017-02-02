:: OPTIONAL: Install Printers 0.60
@Echo off

echo Installing printer 32 bits...
cscript C:\WINDOWS\system32\Printing_Admin_Scripts\es-ES\prnport.vbs -a -r printer -h 123.456.78.123 -q pcl -o lpr
rundll32 printui.dll,PrintUIEntry /if /b "printer color" /f "%z%\packages\printer_drivers\pcl-i386\x28560L.inf" /r "printer" /m "Xerox Phaser 8560DN" 
