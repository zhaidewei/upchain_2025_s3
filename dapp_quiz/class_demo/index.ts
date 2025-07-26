
// src/index.ts
import { HashDemoCommand } from './src/commands/hashDemo';
import { argv } from './src/parse';

const commands = {
  hash: new HashDemoCommand(),
//   sign: new SignDemoCommand(),
//   transfer: new TransferDemoCommand(),
//   balance: new BalanceDemoCommand(),
};

async function main() {
  const command = commands[argv.command];
  if (!command) {
    console.error('Unknown command:', argv.command);
    console.log('Available commands:', Object.keys(commands).join(', '));
    process.exit(1);
  }

  await command.execute(argv);
}

main().catch(console.error);
