@echo off
set /p pubkey="Enter your Snatcoin address: "
set /p usegpu="Should I use your graphics card to mine? Type either 'true' or 'false': "
set /p VANITYGEN_OPTIONS="Any options (like GPU device, '-D 2') for Vanitygen? Hit enter for none: "
node index.js %pubkey% -g %usegpu%
pause
