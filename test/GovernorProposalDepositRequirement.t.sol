// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/utils/TestGovernor.sol";
import "../src/utils/TestToken.sol";

contract GovernorProposalDepositRequirementTest is Test {
    TestToken token;
    TestGovernor governorETHDeposit;
    TestGovernor governorTokenDeposit;

    function setUp() public {
        token = new TestToken();
        governorETHDeposit = new TestGovernor(token, address(0), 1 ether);
        governorTokenDeposit = new TestGovernor(token, address(token), 1 ether);

        token.mint(10 ether);
        token.delegate(address(this));
    }

    function testAllowsProposalIfEnoughETHProvided() public {
        address[] memory targets = new address[](1);
        targets[0] = address(1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory callDatas = new bytes[](1);
        string memory description = "Test Proposal";

        uint256 proposalId = governorETHDeposit.hashProposal(targets, values, callDatas, keccak256(bytes(description)));

        governorETHDeposit.stakeDeposit{value: 1 ether}(proposalId);

        governorETHDeposit.propose(targets, values, callDatas, description);
    }

    function testAllowsProposalIfEnoughTokensProvided() public {
        address[] memory targets = new address[](1);
        targets[0] = address(1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory callDatas = new bytes[](1);
        string memory description = "Test Proposal";

        uint256 proposalId = governorTokenDeposit.hashProposal(targets, values, callDatas, keccak256(bytes(description)));

        token.approve(address(governorTokenDeposit), 1 ether);

        governorTokenDeposit.stakeDeposit(proposalId);

        governorTokenDeposit.propose(targets, values, callDatas, description);
    }

    function testStakeRevertsIfNotEnoughtETHProvided() public {
        address[] memory targets = new address[](1);
        targets[0] = address(1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory callDatas = new bytes[](1);
        string memory description = "Test Proposal";

        uint256 proposalId = governorETHDeposit.hashProposal(targets, values, callDatas, keccak256(bytes(description)));

        vm.expectRevert("Governor: incorrect proposal deposit");
        governorETHDeposit.stakeDeposit{value: 0.9 ether}(proposalId);
    }

    function testStakeRevertsIfNotEnoughtTokensApproved() public {
        address[] memory targets = new address[](1);
        targets[0] = address(1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory callDatas = new bytes[](1);
        string memory description = "Test Proposal";

        uint256 proposalId = governorTokenDeposit.hashProposal(targets, values, callDatas, keccak256(bytes(description)));

        token.approve(address(governorTokenDeposit), 0.9 ether);

        vm.expectRevert("ERC20: insufficient allowance");
        governorTokenDeposit.stakeDeposit(proposalId);
    }

    function testStakeRevertsIfNotEnoughtTokensInBalance() public {
        address[] memory targets = new address[](1);
        targets[0] = address(1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory callDatas = new bytes[](1);
        string memory description = "Test Proposal";

        uint256 proposalId = governorTokenDeposit.hashProposal(targets, values, callDatas, keccak256(bytes(description)));

        token.transfer(address(1), 9.1 ether);
        token.approve(address(governorTokenDeposit), 1 ether);

        vm.expectRevert("ERC20: transfer amount exceeds balance");
        governorTokenDeposit.stakeDeposit(proposalId);
    }

    function testDoesNotRevertOnExecuteIfDepositReturnFails() public {
        address[] memory targets = new address[](1);
        targets[0] = address(1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory callDatas = new bytes[](1);
        string memory description = "Test Proposal";

        uint256 proposalId = governorETHDeposit.hashProposal(targets, values, callDatas, keccak256(bytes(description)));

        governorETHDeposit.stakeDeposit{value: 1 ether}(proposalId);
        governorETHDeposit.propose(targets, values, callDatas, description);

        vm.roll(block.number + 1);

        governorETHDeposit.castVote(proposalId, 1);

        vm.roll(block.number + 100);

        // set the governor's ETH balance to 0, so it fails to pay back the deposit to proposer
        vm.deal(address(governorETHDeposit), 0);

        governorETHDeposit.execute(targets, values, callDatas, keccak256(bytes(description)));
    }
}
