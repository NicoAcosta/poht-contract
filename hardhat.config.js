require('@nomiclabs/hardhat-waffle')
require('@nomiclabs/hardhat-etherscan')
require('hardhat-abi-exporter')

const secret = require('./secret')

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async (taskArgs, hre) => {
	const accounts = await hre.ethers.getSigners()

	for (const account of accounts) {
		console.log(account.address)
	}
})

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
	solidity: '0.8.4',
	networks: {
		rinkeby: {
			url: secret.rinkeby_node_url,
			accounts: [secret.deployer_key],
		},
		kovan: {
			url: secret.kovan_node_url,
			accounts: [secret.deployer_key],
		},
	},
	abiExporter: {
		path: './data/abi',
		clear: true,
		flat: true,
		// only: [':ERC20$'],
		spacing: 2,
	},
	etherscan: {
		// Your API key for Etherscan
		// Obtain one at https://etherscan.io/
		apiKey: secret.etherscan_api_key,
	},
}
