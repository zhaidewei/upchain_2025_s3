// src/parse.ts
import yargs from 'yargs';

export async function getArgv() {
  return await yargs(process.argv.slice(2))
    .command('hash', 'Run hash demo')
    .command('sign', 'Run signature demo')
    .command('signEip712', 'Run signEip712 demo')
    .command('transfer', 'Run transfer demo')
    .command('balance', 'Check balance')
    .demandCommand(1, 'You need to specify a command')
    .help()
    .argv;
}
