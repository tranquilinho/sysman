:: OPTIONAL: Install Skype
:: Download it at http://www.skype.com/go/getskype
:: URL|ALL|http://www.skype.com/go/getskype|packages/skype/skype.exe
:: More info:
:: http://forum.skype.com/index.php?showtopic=9783&st=0&gopid=366611&

@Echo off

todo.pl "%Z%\packages\Skype\SkypeSetup.exe /SILENT /NORESTART /NOGOOGLE"
