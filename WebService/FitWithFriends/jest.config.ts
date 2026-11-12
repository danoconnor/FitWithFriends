// jest.config.ts
import type { Config } from '@jest/types';

const config: Config.InitialOptions = {
    verbose: true,
    transform: {
        '^.+\\.tsx?$': 'ts-jest',
    },
    testPathIgnorePatterns: [
        '/node_modules/',
        '/dist/',
    ],
    moduleNameMapper: {
        // jwks-rsa@4 is ESM-only via jose@6; see test/mocks/jwksRsaStub.ts
        '^jwks-rsa$': '<rootDir>/test/mocks/jwksRsaStub.ts',
    },
};

export default config;
