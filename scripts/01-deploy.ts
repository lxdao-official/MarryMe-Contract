/* eslint-disable no-console */
import { ethers } from 'hardhat'

async function main() {

    const [deployer, addressB] = await ethers.getSigners()

    const Factory = await ethers.getContractFactory('MarryMe')
    const instance = await Factory.deploy()
    const contract = await instance.waitForDeployment()
    console.log(await contract.getAddress())

    console.log('addressA:', deployer.getAddress())
    console.log('addressB:', addressB.getAddress())

    await contract.setSPInstance('0x878c92FD89d8E0B93Dc0a3c907A2adc7577e39c5')

    console.log('setSPInstance done')

    await contract.setSchemaID('0x7')

    console.log('setSchemaID done')

    // submitProposal

    await contract.submitProposal(addressB.getAddress(), 'hello world B')

    console.log('submitProposal done')

    // acceptProposal

    // switch to addressB to accept the proposal
    await contract.connect(addressB).confirmProposal(deployer.getAddress(), 'hello world A')

    console.log('acceptProposal done')




}

void main()
