@echo off
set /p pubkey="Enter your Snatcoin address: "
set /p usegpu="Should I use your graphics card to mine? Type either 'true' or 'false': "
set /p VANITYGEN_OPTIONS="Any options (like GPU device, '-D 1:1') for Vanitygen? Hit enter for none: "
:again
node index.js %pubkey% -g %usegpu%
taskkill /F /IM oclvanitygen.exe
taskkill /F /IM vanitygen.exe
taskkill /F /IM vanitygen64.exe
echo "It appears Vaneminer has stopped unexpectedly. Please wait 5 seconds or press any key to restart, or close the window to stop."
timeout /t 5
goto again
