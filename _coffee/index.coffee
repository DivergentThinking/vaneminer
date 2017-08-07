os = require('os')
fs = require('fs')
readline = require('readline')
{spawn} = require('child_process')
got = require('got')
argv = require('yargs')
  .usage("$0 [-g] <your snatcoin address> <vanitygen options...>")
  .boolean('gpu')
  .describe('gpu', 'Use OpenCL Vanitygen for faster mining on supported graphics cards')
  .default('gpu', false, "No OpenCL")
  .string('prefix')
  .describe('prefix', "Prefix for Vanitygen to use (e.g. 1snat, 1snats)")
  .default('prefix', '1snat', "1snat (at least 1 share)")
  .boolean('sensitive')
  .describe('sensitive', "Make Vanitygen mine case-sentitively (e.g. mine only for 1SNATS, not 1Snats)")
  .default('sensitive', false, "Case insensitive")
  .alias('h', 'help')
  .alias('g', 'gpu')
  .alias('p', 'prefix')
  .alias('s', 'sensitive')
  .help()
  .argv;

myAddr = argv._.shift();
vmOpts = argv._;
useGpu = argv.g;
if not myAddr?
  console.error "No Snatcoin address provided! See --help."
  process.exit 1
else if not /^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$/.test(myAddr)
  console.error "Invalid Snatcoin address! See --help."
  process.exit 1

platformNotSupported = ->
  console.error("Your platform, #{os.platform()}/#{os.arch()}, is currently not supported.")
  console.error("Try to compile vanityminer for yourself, edit the code and send a pull request.")
  process.exit(1)

minerExe = switch os.platform()
  when "linux" then switch os.arch()
    when "x64" then "#{if useGpu then "oclvanitygen" else "vanitygen"}"
    else platformNotSupported()
  when "win32" then switch os.arch()
    when "x64" then "#{if useGpu then "oclvanitygen.exe" else "vanitygen64.exe"}"
    when "x86" then "#{if useGpu then "oclvanitygen.exe" else "vanitygen.exe"}"
    else platformNotSupported()
  else platformNotsupported()

prefix = argv.p
sharePoint = "https://www.snatcoin.com/sendshare.php"
init = ->
  await download()
  await clkerneldl()
  vmOpts.push('-vk')
  unless argv.s then vmOpts.push('-i')
  vmOpts.push(prefix)
  while true then await new Promise (res, rej) ->
    try
      vanitygen = spawn("#{__dirname}/bin/#{minerExe}", vmOpts, { cwd: "#{__dirname}/bin" })
      errStuff = ""
      vanitygen.stdout.on 'data', (data) =>
        unless data.indexOf("key/s") is -1
          readline.cursorTo(process.stdout, 0)
          data = data.toString()
          process.stderr.write(data.substr(data.indexOf('['), data.lastIndexOf(']')))
        unless data.indexOf("Privkey (hex):") is -1
          runRequest(data)
      vanitygen.stderr.on 'data', (data) =>
        errStuff += data
      vanitygen.on 'exit', (code, sig) =>
        unless code is 0
          console.error("Vanitygen exited with code #{code} from signal #{sig}")
          console.error(errStuff)
          process.exit 1
        res()
      vanitygen.on 'error', (error) => console.error(error); process.exit 1
    catch e
      console.error(e)
      process.exit 1

  await return

runRequest = (data) ->
  privOut = /Privkey \(hex\): ([0-9A-Fa-f]{64})/i.exec(data)
  addrOut = /Address: ([13][a-km-zA-HJ-NP-Z1-9]{25,34})/.exec(data)
  console.log("\nSending address: #{privOut?[1]} (#{addrOut?[1]})")
  do ->
    try
      body = await got(sharePoint, { query: { your: myAddr, pub: addrOut?[1], priv: privOut?[1] } })
      console.log("\nSent work for #{myAddr}! #{body.body}")
    catch e
      console.error("Error sending to '#{sharePoint}'...")
      console.error(e)

vanitygenUrl = "https://vanitygen-bin.surge.sh"
download = ->
  try fs.mkdirSync("./bin")
  try
    fs.statSync("./bin/#{minerExe}")
    console.log("Vanitygen executable for #{os.platform()}/#{os.arch()} was found at './bin/#{minerExe}'.")
    return
  catch e
    if e.code is "ENOENT"
      console.log("Vanitygen executable at './bin/#{minerExe}' was not found. Downloading from '#{vanitygenUrl}/#{minerExe}'...")
    else
      console.error(e)
      process.exit 1
  try await new Promise (res, rej) ->
    try
      dlstream = got.stream("#{vanitygenUrl}/#{minerExe}")
      dlstream.pipe(fs.createWriteStream("./bin/#{minerExe}"))
      dlstream.on "end", -> res()
      dlstream.on "error", (e) -> rej(e)
    catch e
      rej e
  catch e
    console.error("Error when downloading #{minerExe}...")
    console.error(e)
    process.exit 1
  console.log("Done downloading './bin/#{minerExe}'!")
  await return

clkerneldl = ->
  unless useGpu then return
  try
    fs.statSync("./bin/calc_addrs.cl")
    console.log("OpenCL kernel was found at './bin/calc_addrs.cl'.")
    return
  catch e
    if e.code is "ENOENT"
      console.log("OpenCL kernel was not found. Downloading from '#{vanitygenUrl}/calc_addrs.cl'...")
    else
      console.error(e)
      process.exit 1
  try await new Promise (res, rej) ->
    try
      dlstream = got.stream("#{vanitygenUrl}/calc_addrs.cl")
      dlstream.pipe(fs.createWriteStream("./bin/calc_addrs.cl"))
      dlstream.on "end", -> res()
      dlstream.on "error", (e) -> rej(e)
    catch e
      rej e
  catch e
    console.error("Error when downloading './bin/calc_addrs.cl'...")
    console.error(e)
    process.exit 1
  console.log("Done downloading './bin/calc_addrs.cl'!")
  await return

init();
