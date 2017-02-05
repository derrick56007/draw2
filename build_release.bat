:start

cls

:: build dart files
call "C:\Program Files\Dart\dart-sdk\bin\pub.bat" build --mode=release --output=build

pause

goto start