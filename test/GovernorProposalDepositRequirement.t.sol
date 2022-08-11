// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/utils/TestGovernor.sol";
import "../src/utils/TestToken.sol";

contract GovernorProposalDepositRequirementTest is Test {
    TestToken token;
    TestGovernor governorTokenDeposit;

    function setUp() public {
        token = new TestToken();
        governorTokenDeposit = new TestGovernor(token, address(token), 1 ether);

        token.mint(10 ether);
        token.delegate(address(this));
    }

    function testAllowsProposalIfEnoughTokensProvided() public {
        address[] memory targets = new address[](1);
        targets[0] = address(1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory callDatas = new bytes[](1);
        string memory description = "Test Proposal";

        token.approve(address(governorTokenDeposit), 1 ether);

        governorTokenDeposit.propose(targets, values, callDatas, description);
    }

    function testProposeRevertsIfNotEnoughTokensApproved() public {
        address[] memory targets = new address[](1);
        targets[0] = address(1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory callDatas = new bytes[](1);
        string memory description = "Test Proposal";

        token.approve(address(governorTokenDeposit), 0.9 ether);

        vm.expectRevert("ERC20: insufficient allowance");
        governorTokenDeposit.propose(targets, values, callDatas, description);
    }

    function testProposeRevertsIfNotEnoughTokensInBalance() public {
        address[] memory targets = new address[](1);
        targets[0] = address(1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory callDatas = new bytes[](1);
        string memory description = "Test Proposal";

        token.transfer(address(1), 9.1 ether);
        token.approve(address(governorTokenDeposit), 1 ether);

        vm.expectRevert("ERC20: transfer amount exceeds balance");
        governorTokenDeposit.propose(targets, values, callDatas, description);
    }

    function testDoesNotRevertOnExecuteIfTokenDepositReturnFails() public {
        address[] memory targets = new address[](1);
        targets[0] = address(1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory callDatas = new bytes[](1);
        string memory description = "Test Proposal";

        uint256 proposalId = governorTokenDeposit.hashProposal(targets, values, callDatas, keccak256(bytes(description)));

        token.approve(address(governorTokenDeposit), 1 ether);

        governorTokenDeposit.propose(targets, values, callDatas, description);

        vm.roll(block.number + 1);

        governorTokenDeposit.castVote(proposalId, 1);

        vm.roll(block.number + 100);

        token.burn(address(governorTokenDeposit), 1 ether);

        governorTokenDeposit.execute(targets, values, callDatas, keccak256(bytes(description)));
    }
}
