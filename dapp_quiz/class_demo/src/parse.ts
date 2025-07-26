// src/parse.ts
import yargs from 'yargs';

export const argv = yargs(process.argv.slice(2))
  .command('hash', 'Run hash demo')
  .command('sign', 'Run signature demo')
  .command('transfer', 'Run transfer demo')
  .command('balance', 'Check balance')
  .demandCommand(1, 'You need to specify a command')
  .help()
  .argv;
