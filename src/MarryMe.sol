// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ISP } from "@ethsign/sign-protocol-evm/src/interfaces/ISP.sol";
import { Attestation } from "@ethsign/sign-protocol-evm/src/models/Attestation.sol";
import { DataLocation } from "@ethsign/sign-protocol-evm/src/models/DataLocation.sol";

contract MarryMe is Ownable {
    ISP public spInstance;
    uint64 public schemaId;

    mapping(address => address) public proposalMapping;
    mapping(address => string) public proposalInfo;

    error ConfirmationAddressMismatch();

    event DidSignProposal(address addressA, address addressB, uint64 attestationId);

    constructor() Ownable(_msgSender()) { }

    function setSPInstance(address instance) external onlyOwner {
        spInstance = ISP(instance);
    }

    function setSchemaID(uint64 schemaId_) external onlyOwner {
        schemaId = schemaId_;
    }

    function submitProposal(address addressB, string memory infoA) external {
        proposalMapping[_msgSender()] = addressB;
        proposalInfo[_msgSender()] = infoA;
    }

    function confirmProposal(address addressA, string memory infoB) external returns (uint64) {
        address addressB = _msgSender();
        string memory infoA = proposalInfo[addressA];
        string memory infoB = proposalInfo[addressB];

        bytes memory data = abi.encode(infoA, infoB);

        if (proposalMapping[addressA] == addressB) {
            // B has confirm A's marriage proposal
            bytes[] memory recipients = new bytes[](2);
            recipients[0] = abi.encode(addressA);
            recipients[1] = abi.encode(addressB);
            Attestation memory a = Attestation({
                schemaId: schemaId,
                linkedAttestationId: 0,
                attestTimestamp: 0,
                revokeTimestamp: 0,
                attester: address(this),
                validUntil: 0,
                dataLocation: DataLocation.ONCHAIN,
                revoked: false,
                recipients: recipients,
                data: data
            });
            uint64 attestationId = spInstance.attest(a, "", "", "");
            emit DidSignProposal(addressA, addressB, attestationId);
            return attestationId;
        } else {
            revert ConfirmationAddressMismatch();
        }
    }
}
