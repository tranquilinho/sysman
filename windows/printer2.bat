echo Installing B13 BW printer...
cscript C:\WINDOWS\system32\Printing_Admin_Scripts\es-ES\prnport.vbs -a -r printer2 -h 123.456.78.11 -q ps -o lpr
rundll32 printui.dll,PrintUIEntry /if /b "printer" /f "%z%\packages\printer_drivers\PS\sml371.inf" /r "printer" /m "Samsung ML-371x Series PS" 

