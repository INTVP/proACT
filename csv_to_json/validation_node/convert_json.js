const status = require('node-status');
const {argv} = require('yargs');
const fs = require('fs');
const JSONStream = require('JSONStream');

const _docs = status.addItem('docs');

async function main() {
  if (!argv.i || !argv.o) {
    process.exit(1);
  }

  status.start({
    pattern: 'Doing work: {uptime} {spinner.cyan} | {docs} items'
  });

  const in_file = fs.createReadStream(argv.i);
  const out_file = fs.createWriteStream(argv.o);

  const parse = JSONStream.parse('*');

  parse.on('data', (ch) => {
    out_file.write(JSON.stringify(ch) + '\n');

    _docs.inc();
  });

  in_file.pipe(parse);

  parse.on('end', () => {
    out_file.end(() => {
      process.exit();
    });
  });

  in_file.on('error', (err) => {
    console.log(err);

    out_file.end(() => {
      process.exit(1);
    });
  });
}

main();
