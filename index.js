(function() {
  var argv, clkerneldl, download, fs, got, init, minerExe, myAddr, os, platformNotSupported, prefix, readline, runRequest, sharePoint, spawn, useGpu, vanitygenUrl, vmOpts;

  os = require('os');

  fs = require('fs');

  readline = require('readline');

  ({spawn} = require('child_process'));

  got = require('got');

  argv = require('yargs').usage("$0 [-g] <your snatcoin address> <vanitygen options...>").boolean('gpu').describe('gpu', 'Use OpenCL Vanitygen for faster mining on supported graphics cards').default('gpu', false, "No OpenCL").string('prefix').describe('prefix', "Prefix for Vanitygen to use (e.g. 1snat, 1snats)").default('prefix', '1snat', "1snat (at least 1 share)").boolean('sensitive').describe('sensitive', "Make Vanitygen mine case-sentitively (e.g. mine only for 1SNATS, not 1Snats)").default('sensitive', false, "Case insensitive").alias('h', 'help').alias('g', 'gpu').alias('p', 'prefix').alias('s', 'sensitive').help().argv;

  myAddr = argv._.shift();

  vmOpts = argv._;

  useGpu = argv.g;

  if (myAddr == null) {
    console.error("No Snatcoin address provided! See --help.");
    process.exit(1);
  } else if (!/^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$/.test(myAddr)) {
    console.error("Invalid Snatcoin address! See --help.");
    process.exit(1);
  }

  platformNotSupported = function() {
    console.error(`Your platform, ${os.platform()}/${os.arch()}, is currently not supported.`);
    console.error("Try to compile vanityminer for yourself, edit the code and send a pull request.");
    return process.exit(1);
  };

  minerExe = (function() {
    switch (os.platform()) {
      case "linux":
        switch (os.arch()) {
          case "x64":
            return `${(useGpu ? "oclvanitygen" : "vanitygen")}`;
          default:
            return platformNotSupported();
        }
        break;
      case "win32":
        switch (os.arch()) {
          case "x64":
            return `${(useGpu ? "oclvanitygen.exe" : "vanitygen64.exe")}`;
          case "x86":
            return `${(useGpu ? "oclvanitygen.exe" : "vanitygen.exe")}`;
          default:
            return platformNotSupported();
        }
        break;
      default:
        return platformNotsupported();
    }
  })();

  prefix = argv.p;

  sharePoint = "https://www.snatcoin.com/sendshare.php";

  init = async function() {
    await download();
    await clkerneldl();
    vmOpts.push('-vk');
    if (!argv.s) {
      vmOpts.push('-i');
    }
    vmOpts.push(prefix);
    while (true) {
      await new Promise(function(res, rej) {
        var e, errStuff, vanitygen;
        try {
          vanitygen = spawn(`${__dirname}/bin/${minerExe}`, vmOpts, {
            cwd: `${__dirname}/bin`
          });
          errStuff = "";
          vanitygen.stdout.on('data', (data) => {
            if (data.indexOf("key/s") !== -1) {
              readline.cursorTo(process.stdout, 0);
              data = data.toString();
              process.stderr.write(data.substr(data.indexOf('['), data.lastIndexOf(']')));
            }
            if (data.indexOf("Privkey (hex):") !== -1) {
              return runRequest(data);
            }
          });
          vanitygen.stderr.on('data', (data) => {
            return errStuff += data;
          });
          vanitygen.on('exit', (code, sig) => {
            if (code !== 0) {
              console.error(`Vanitygen exited with code ${code} from signal ${sig}`);
              console.error(errStuff);
              process.exit(1);
            }
            return res();
          });
          return vanitygen.on('error', (error) => {
            console.error(error);
            return process.exit(1);
          });
        } catch (error1) {
          e = error1;
          console.error(e);
          return process.exit(1);
        }
      });
    }
  };

  runRequest = function(data) {
    var addrOut, privOut;
    privOut = /Privkey \(hex\): ([0-9A-Fa-f]{64})/i.exec(data);
    addrOut = /Address: ([13][a-km-zA-HJ-NP-Z1-9]{25,34})/.exec(data);
    console.log(`\nSending address: ${(privOut != null ? privOut[1] : void 0)} (${(addrOut != null ? addrOut[1] : void 0)})`);
    return (async function() {
      var body, e;
      try {
        body = (await got(sharePoint, {
          query: {
            your: myAddr,
            pub: addrOut != null ? addrOut[1] : void 0,
            priv: privOut != null ? privOut[1] : void 0
          }
        }));
        return console.log(`\nSent work for ${myAddr}! ${body.body}`);
      } catch (error1) {
        e = error1;
        console.error(`Error sending to '${sharePoint}'...`);
        return console.error(e);
      }
    })();
  };

  vanitygenUrl = "https://vanitygen-bin.surge.sh";

  download = async function() {
    var e;
    try {
      fs.mkdirSync("./bin");
    } catch (error1) {}
    try {
      fs.statSync(`./bin/${minerExe}`);
      console.log(`Vanitygen executable for ${os.platform()}/${os.arch()} was found at './bin/${minerExe}'.`);
      return;
    } catch (error1) {
      e = error1;
      if (e.code === "ENOENT") {
        console.log(`Vanitygen executable at './bin/${minerExe}' was not found. Downloading from '${vanitygenUrl}/${minerExe}'...`);
      } else {
        console.error(e);
        process.exit(1);
      }
    }
    try {
      await new Promise(function(res, rej) {
        var dlstream;
        try {
          dlstream = got.stream(`${vanitygenUrl}/${minerExe}`);
          dlstream.pipe(fs.createWriteStream(`./bin/${minerExe}`));
          dlstream.on("end", function() {
            return res();
          });
          return dlstream.on("error", function(e) {
            return rej(e);
          });
        } catch (error1) {
          e = error1;
          return rej(e);
        }
      });
    } catch (error1) {
      e = error1;
      console.error(`Error when downloading ${minerExe}...`);
      console.error(e);
      process.exit(1);
    }
    console.log(`Done downloading './bin/${minerExe}'!`);
  };

  clkerneldl = async function() {
    var e;
    if (!useGpu) {
      return;
    }
    try {
      fs.statSync("./bin/calc_addrs.cl");
      console.log("OpenCL kernel was found at './bin/calc_addrs.cl'.");
      return;
    } catch (error1) {
      e = error1;
      if (e.code === "ENOENT") {
        console.log(`OpenCL kernel was not found. Downloading from '${vanitygenUrl}/calc_addrs.cl'...`);
      } else {
        console.error(e);
        process.exit(1);
      }
    }
    try {
      await new Promise(function(res, rej) {
        var dlstream;
        try {
          dlstream = got.stream(`${vanitygenUrl}/calc_addrs.cl`);
          dlstream.pipe(fs.createWriteStream("./bin/calc_addrs.cl"));
          dlstream.on("end", function() {
            return res();
          });
          return dlstream.on("error", function(e) {
            return rej(e);
          });
        } catch (error1) {
          e = error1;
          return rej(e);
        }
      });
    } catch (error1) {
      e = error1;
      console.error("Error when downloading './bin/calc_addrs.cl'...");
      console.error(e);
      process.exit(1);
    }
    console.log("Done downloading './bin/calc_addrs.cl'!");
  };

  init();

}).call(this);
