module.exports = {
    skipFiles: ['test', 'utils/MockAxelarGateway.sol'],
    mocha: {
        grep: '@skip-on-coverage', // Add to test description to skip coverage from being run some tests, such as bytecode checks
        invert: true,
    },
};
