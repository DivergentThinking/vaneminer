@echo off
set /p pubkey="Enter your Snatcoin address: "
set /p usegpu="Should I use your graphics card to mine? Type either 'true' or 'false': "
node index.js %pubkey% -g %usegpu%
