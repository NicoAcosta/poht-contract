const {BigNumber} = require('ethers')
const hre = require('hardhat')

const networks = require('../networks')
const kovan = networks.kovan
const rinkeby = networks.rinkeby

const network = kovan

async function main() {
	// const _poHAddress = network.poh
	// const _linkAddress = network.link
	// const _oracleAddress = network.oracle
	// // const _jobIdentifier = 'c637797f3e9a468489e88d5441a16a3e'
	// // const _fee = new BigNumber.from(10).pow(17)
	// const _fee = 10
	// const _feePower = 17
	// const _apiAddressURL =
	// 	'https://us-central1-pohtwitter.cloudfunctions.net/api/tweet-address-hash/'
	// const _apiAuthorURL =
	// 	'https://us-central1-pohtwitter.cloudfunctions.net/api/tweet-author/'

	// We get the contract to deploy
	const PoHTwitterV5 = await hre.ethers.getContractFactory('PoHTwitterV5')
	const contract = await PoHTwitterV5
		.deploy
		// _poHAddress,
		// _linkAddress,
		// _oracleAddress,
		// // _jobIdentifier,
		// _fee,
		// _feePower,
		// _apiAddressURL,
		// _apiAuthorURL
		()

	await contract.deployed()

	console.log('PoHTwitterV5 deployed to: ', contract.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error)
		process.exit(1)
	})
