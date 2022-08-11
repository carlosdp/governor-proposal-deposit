// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/governance/utils/IVotes.sol";
import "openzeppelin-contracts/contracts/governance/Governor.sol";
import "openzeppelin-contracts/contracts/governance/extensions/GovernorSettings.sol";
import "openzeppelin-contracts/contracts/governance/extensions/GovernorVotes.sol";
import "openzeppelin-contracts/contracts/governance/extensions/GovernorCountingSimple.sol";
import "openzeppelin-contracts/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";

import "../GovernorProposalDepositRequirement.sol";

contract TestGovernor is Governor, GovernorVotes, GovernorCountingSimple, GovernorVotesQuorumFraction, GovernorSettings, GovernorProposalDepositRequirement {
  constructor(IVotes tokenAddress, address depositTokenAddress, uint256 depositAmount) Governor("TestGovernor") GovernorSettings(0, 100, 0) GovernorVotes(tokenAddress) GovernorVotesQuorumFraction(10) GovernorProposalDepositRequirement(address(this), depositTokenAddress, depositAmount) {
  }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual override(Governor, GovernorProposalDepositRequirement) returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }

    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual override(Governor, GovernorProposalDepositRequirement) returns (uint256) {
        return super.execute(targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual override(Governor, GovernorProposalDepositRequirement) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function proposalThreshold() public view virtual override(Governor, GovernorSettings) returns (uint256) {
        return 0;
    }
}
