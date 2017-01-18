
set ymd=%date:~-10,4%%date:~-5,2%%date:~-2,2%

powershell.exe  .\mainconverter.ps1 >> log\mainlog%ymd%.txt 

pause
