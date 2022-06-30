const fs = require('fs');
const {argv} = require('yargs');
const readline = require('readline');
const { validate } = require('jsonschema');
const tenderSchema = require('./schemas/tender.schema.json');
const status = require('node-status')
let execSync = require('child_process').execSync;

async function validateDataset() {
    const fileStream = fs.createReadStream(argv.f);
    const errorsFileName = `logs/errors-${argv.f.split('/').slice(-1)[0]}-${Date.now()}.json`
    let tenders = status.addItem('tender', {
        max: parseInt(execSync(`wc -l < ${argv.f}`).toString().trim())
    })

    status.start({
        pattern: `Validating ${argv.f}: {tender.percentage} ({uptime})`
    })
    errorsUnique = []

    const rl = readline.createInterface({
        input: fileStream,
        crlfDelay: Infinity
    });

    for await (const line of rl) {
        tenders.inc()
        const v = validate(JSON.parse(line), tenderSchema);

        if (v.errors.length) {

            errorObj = {
                tender:  JSON.parse(line),
                errors: v.errors
            }
            fs.appendFileSync(errorsFileName, JSON.stringify(errorObj, null, 2))

            v.errors.forEach(error => {
                errorMsg = error.stack.replace(/\d/g, '')
                    .replace('instance', 'tender')

                if (errorsUnique.indexOf(errorMsg) === -1) {
                    errorsUnique.push(errorMsg)
                    console.log(errorMsg + '                                                        ') //  quick fix for a better output
                }
            })
        }
    }

    status.stop();

    if (errorsUnique.length === 0) {
      console.log('Dataset is valid!                                                        ')
    }
    else {
        console.log('Dataset is NOT valid!                                                         \n' +
                    `Full errors list check here: ${errorsFileName}\n`
        )
    }
}

validateDataset().then(null, error => { console.log('caught', error.message); });

