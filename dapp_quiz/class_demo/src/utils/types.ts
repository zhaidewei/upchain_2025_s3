// src/utils/types.ts
export interface Command {
    name: string;
    description: string;
    execute(args: any): Promise<void>;
  }
