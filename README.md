# VaneMiner
## a vanitygen-based proof-of-work mining software for Snatcoin

### Installation:
This software is currently only supported on Linux 64-bit and Windows 32/64-bit.

Install Node.js 8.2.1 ("Latest Features").

 - [For Windows](https://nodejs.org/en/)
 - [Unix-like OSes (Linux) should use NVM](https://github.com/creationix/nvm)
 - If neither of the above, you probably already have it installed.
   (MAKE SURE YOU HAVE NODE 7 OR HIGHER!!!!)

### Usage:

#### Windows
Download as .zip from GitHub and extract to a folder.
To install necessary libraries, open `cmd.exe`, and use the command
`cd C:\Users\YOURUSER\path\to\extracted\vaneminer` with the path set
appropriately. Then, use the command `npm install`.

After installing libraries, you may now use the `vaneminer.bat` file to start
mining.

#### Unix-like
Running via command line:
```
index.js [-g] <your snatcoin address> <vanitygen options...>


Options:
  -h, --help       Show help                                           [boolean]
  -g, --gpu        Use OpenCL Vanitygen for faster mining on supported graphics
                   cards                              [boolean] [default: false]
  -p, --prefix     Prefix for Vanitygen to use (e.g. 1snat, 1snats)
                                                     [string] [default: "1snat"]
  -s, --sensitive  Make Vanitygen mine case-sentitively (e.g. mine only for
                   1SNATS, not 1Snats)                [boolean] [default: false]
```

### Contribution:

The source code is in the `_coffee/` folder. `index.js` is compiled by
CoffeeScript 2.0 with gulp. Use `yarn install --dev` to install gulp, etc.

Written by [@tphecca](https://github.com/tphecca) of [Divergent Thinking](http://github.com/DivergentThinking).
Donate Snatcoin here: `1DrhbvTnnz8UdF4QoY5jRwivhZ82uT67YK`. Thanks!
