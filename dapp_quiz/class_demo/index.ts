
// index.ts
import { HashDemoCommand } from './src/commands/hashDemo';
import { RecoverDemoCommand } from './src/commands/recoverDemo';
import { SignDemoCommand } from './src/commands/signDemo';
import { SignEip712Command } from './src/commands/signEip712';

const commands = {
  hash: new HashDemoCommand(),
  sign: new SignDemoCommand(),
  signEip712: new SignEip712Command(),
  recover: new RecoverDemoCommand(),
};

async function main() {
  const commandName = process.argv[2]; // 直接从 process.argv 获取命令
  const command = commands[commandName as keyof typeof commands];

  if (!command) {
    console.error('Unknown command:', commandName);
    console.log('Available commands:', Object.keys(commands).join(', '));
    process.exit(1);
  }

  await command.execute(process.argv);
}

main().catch(console.error);
