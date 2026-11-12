/*
    Jest stand-in for jwks-rsa.

    jwks-rsa@4 depends on jose@6, which is ESM-only. Node loads it fine at runtime, but Jest's
    CommonJS loader cannot require() it. Mapping jwks-rsa to this stub keeps modules that merely
    import the Apple helper loadable. Tests that need real signing keys mock 'jwks-rsa' themselves.
*/
export default function jwksRsaStub() {
    return {
        getSigningKey(kid: string | null | undefined, callback: (err: Error) => void) {
            callback(new Error(`jwks-rsa is stubbed in tests (kid '${kid}'); mock it in the test that needs signing keys`));
        },
    };
}
