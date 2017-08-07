# VaneMiner
## a vanitygen-based proof-of-work mining software for Snatcoin

### Usage:
```
index.js [-g] <your snatcoin address> <vanitygen options...>

Options:
  -h, --help  Show help                                                [boolean]
  -g, --gpu   Use OpenCL Vanitygen for faster mining on supported graphics cards
                                                      [boolean] [default: false]
```

### Contribution:

The source code is in the `_coffee/` folder. `index.js` is compiled by
CoffeeScript 2.0 with gulp. Use `yarn install --dev` to install gulp, etc.

Written by @tphecca of Divergent Thinking.
