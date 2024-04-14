// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ISP } from "@ethsign/sign-protocol-evm/src/interfaces/ISP.sol";
import { Attestation } from "@ethsign/sign-protocol-evm/src/models/Attestation.sol";
import { DataLocation } from "@ethsign/sign-protocol-evm/src/models/DataLocation.sol";
import "hardhat/console.sol";

contract MarryMe is Ownable {
    ISP public spInstance;
    uint64 public schemaId;

    struct Proposal {
        string info;
        bool exists;
    }

    // Mapping from proposer to the proposee to their proposal info
    mapping(address => mapping(address => Proposal)) public proposals;
    // Mapping from proposer to an array of all proposees
    mapping(address => address[]) private proposersToProposees;
    // Mapping from proposee to an array of all proposers
    mapping(address => address[]) private proposeesToProposers;

    // marry result info, get attestationId by address
    mapping(address => uint64) public attestationIdMapping;

    event DidSignProposal(address addressA, address addressB, uint64 attestationId);

    constructor() Ownable(_msgSender()) { }

    function setSPInstance(address instance) external onlyOwner {
        spInstance = ISP(instance);
    }

    function setSchemaID(uint64 schemaId_) external onlyOwner {
        schemaId = schemaId_;
    }

    function submitProposal(address addressB, string memory infoA) external {
        address addressA = _msgSender();
        require(attestationIdMapping[addressA] == 0, "You have already married");

        proposals[addressA][addressB] = Proposal({ info: infoA, exists: true });

        proposersToProposees[addressA].push(addressB);
        proposeesToProposers[addressB].push(addressA); // Store each proposer for the proposee
    }

    function cancelProposal(address addressB) external {
        address addressA = _msgSender();
        require(proposals[addressA][addressB].exists, "Proposal not found");

        delete proposals[addressA][addressB];

        // Remove proposee from proposer's array
        for (uint256 i = 0; i < proposersToProposees[addressA].length; i++) {
            if (proposersToProposees[addressA][i] == addressB) {
                proposersToProposees[addressA][i] =
                    proposersToProposees[addressA][proposersToProposees[addressA].length - 1];
                proposersToProposees[addressA].pop();
                break;
            }
        }

        // Remove proposer from proposee's array
        for (uint256 i = 0; i < proposeesToProposers[addressB].length; i++) {
            if (proposeesToProposers[addressB][i] == addressA) {
                proposeesToProposers[addressB][i] =
                    proposeesToProposers[addressB][proposeesToProposers[addressB].length - 1];
                proposeesToProposers[addressB].pop();
                break;
            }
        }
    }

    function getProposalsSentBy(address proposer) external view returns (address[] memory, string[] memory) {
        address[] memory proposees = proposersToProposees[proposer];
        string[] memory infos = new string[](proposees.length);

        for (uint256 i = 0; i < proposees.length; i++) {
            infos[i] = proposals[proposer][proposees[i]].info;
        }

        return (proposees, infos);
    }

    function getProposalsReceivedBy(address proposee) external view returns (address[] memory, string[] memory) {
        address[] memory proposers = proposeesToProposers[proposee];
        string[] memory infos = new string[](proposers.length);

        for (uint256 i = 0; i < proposers.length; i++) {
            infos[i] = proposals[proposers[i]][proposee].info;
        }

        return (proposers, infos);
    }

    function getMarryAttestationId(address addr) external view returns (uint64) {
        return attestationIdMapping[addr];
    }

    function getMarryAttestation(address addr) external view returns (Attestation memory) {
        uint64 attestationId = attestationIdMapping[addr];
        return spInstance.getAttestation(attestationId);
    }

    function checkMarried(address addr) external view returns (bool) {
        return attestationIdMapping[addr] > 0;
    }

    function confirmProposal(address addressA, string memory infoB) external returns (uint64) {
        address addressB = _msgSender();

        if (attestationIdMapping[addressA] > 0 || attestationIdMapping[addressB] > 0) {
            revert("you have already married");
        }

        require(proposals[addressA][addressB].exists, "Proposal not found");

        string memory infoA = proposals[addressA][addressB].info;

        bytes memory data = abi.encode(addressA, addressB, infoA, infoB);
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

        // mapping(address => uint64) public attestationIdMapping;
        attestationIdMapping[addressA] = attestationId;
        attestationIdMapping[addressB] = attestationId;

        emit DidSignProposal(addressA, addressB, attestationId);

        return attestationId;
    }
}
