/* eslint-disable no-console */
import { ethers } from 'hardhat'

async function main() {

    const [deployer, deployer2] = await ethers.getSigners()

    const Factory = await ethers.getContractFactory('MarryMe')
    const instance = await Factory.deploy()
    const contract = await instance.waitForDeployment()
    console.log(await contract.getAddress())

    console.log('addressA:', deployer.getAddress())
    console.log('addressB:', deployer2.getAddress())

    const addressA = await deployer.getAddress();
    const addressB = await deployer2.getAddress();

    await contract.setSPInstance('0x878c92FD89d8E0B93Dc0a3c907A2adc7577e39c5')

    console.log('setSPInstance done')

    await contract.setSchemaID('0x7')

    console.log('setSchemaID done')

    // submitProposal
    await (await contract.submitProposal(addressB, 'hello world B')).wait()

    console.log('submitProposal done')

    // 查询某个地址发送的所有求婚信息
    const proposalSubmitted = await contract.getProposalsSentBy(addressA)
    console.log('proposal submit by addressA:', JSON.stringify(proposalSubmitted, null, 2))

    // 查询某个地址收到的所有求婚信息
    const info = await contract.getProposalsReceivedBy(addressB);
    console.log('proposal received by addressB:', JSON.stringify(info, null, 2))

    // switch to addressB to accept the proposal
    const confirm = await contract.connect(deployer2).confirmProposal(addressA, 'hello world A')
    await confirm.wait()
    console.log('acceptProposal done:')

    // 查询某个地址的婚姻状态，返回 attestationId
    const attestationId = await contract.getMarryAttestationId(addressA)
    console.log('attestationID:', attestationId);

    // 查询某个地址的婚姻状态，返回 attestation 详细信息
    const attestation = await contract.getMarryAttestation(addressA);
    console.log('attestation:', attestation)

    // 查询某个地址的婚姻状态，返回 true/false
    const isMarried = await contract.checkMarried(addressA)
    console.log('isMarried:', isMarried)

    /**
     * output example:
     * 
0xE0B870ffbA7f73d5F757552F3a428DFE73431944
addressA: Promise { '0x9713093e7d93Eb303257c466e37440F9B5BE29f4' }
addressB: Promise { '0x5c1A1A6A86118820C58faF385291Ea9E83c1721C' }
setSPInstance done
setSchemaID done
submitProposal done
proposal submit by addressA: [
  [
    "0x5c1A1A6A86118820C58faF385291Ea9E83c1721C", "0x..."
  ],
  [
    "hello world B", "info for address 2"
  ]
]
proposal received by addressB: [
  [
    "0x9713093e7d93Eb303257c466e37440F9B5BE29f4"
  ],
  [
    "hello world B"
  ]
]
acceptProposal done:
attestationID: 55n
attestation: Result(10) [
  7n,
  0n,
  1713090780n,
  0n,
  '0xE0B870ffbA7f73d5F757552F3a428DFE73431944',
  0n,
  0n,
  false,
  Result(2) [
    '0x0000000000000000000000009713093e7d93eb303257c466e37440f9b5be29f4',
    '0x0000000000000000000000005c1a1a6a86118820c58faf385291ea9e83c1721c'
  ],
  '0x0000000000000000000000009713093e7d93eb303257c466e37440f9b5be29f40000000000000000000000005c1a1a6a86118820c58faf385291ea9e83c1721c000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000d68656c6c6f20776f726c64204200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d68656c6c6f20776f726c64204100000000000000000000000000000000000000'
]
isMarried: true
     */

}

void main()
