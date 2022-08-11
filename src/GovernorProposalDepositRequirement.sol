// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/governance/Governor.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

abstract contract GovernorProposalDepositRequirement is Governor {
    struct ProposalDeposit {
        address proposer;
        address tokenAddress;
        uint256 amount;
    }

    address private _defeatWithdrawAddress;
    address private _depositTokenAddress;
    uint256 private _depositAmount;

    mapping(uint256 => ProposalDeposit) private _deposits;

    constructor(address defeatWithdrawAddress_, address depositTokenAddress_, uint256 depositAmount_) {
        _defeatWithdrawAddress = defeatWithdrawAddress_;
        _depositTokenAddress = depositTokenAddress_;
        _depositAmount = depositAmount_;
    }

    function defeatWithdrawAddress() external view returns (address) {
        return _defeatWithdrawAddress;
    }

    function depositTokenAddress() external view returns (address) {
        return _depositTokenAddress;
    }

    function depositAmount() external view returns (uint256) {
        return _depositAmount;
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual override returns (uint256) {
        uint256 proposalId = super.propose(targets, values, calldatas, description);

        require(proposalDepositFulfilled(proposalId), "Governor: proposal deposit requirement not met");

        return proposalId;
    }

    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual override returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);

        // return deposit before arbitrary execution to avoid reentrancy attack
        _returnDeposit(proposalId);

        super.execute(targets, values, calldatas, descriptionHash);

        return proposalId;
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual override returns (uint256) {
        uint256 proposalId = super._cancel(targets, values, calldatas, descriptionHash);

        _returnDeposit(proposalId);

        return proposalId;
    }

    function stakeDeposit(uint256 proposalId) public payable {
        require(_collectDeposit(), "Governor: incorrect proposal deposit");

        ProposalDeposit storage deposit = _deposits[proposalId];
        deposit.proposer = msg.sender;
        deposit.tokenAddress = _depositTokenAddress;
        deposit.amount = _depositAmount;
    }

    function withdrawDeposit(uint256 proposalId) public returns (bool) {
        ProposalState status = state(proposalId);

        require(status == ProposalState.Defeated, "Governor: proposal must be defeated to withdraw deposit");

        return _closeDepositTo(proposalId, _defeatWithdrawAddress);
    }

    function proposalDepositFulfilled(uint256 proposalId) public view returns (bool) {
        ProposalDeposit memory deposit = _deposits[proposalId];

        return deposit.proposer != address(0);
    }

    function _collectDeposit() internal returns (bool) {
        if (_depositTokenAddress == address(0)) {
            // deposit token is ETH
            return msg.value == _depositAmount;
        } else {
            // deposit token is an ERC-20 token
            IERC20 token = IERC20(_depositTokenAddress);
            return token.transferFrom(msg.sender, address(this), _depositAmount);
        }
    }

    function _returnDeposit(uint256 proposalId) private returns (bool) {
        ProposalDeposit memory deposit = _deposits[proposalId];

        // important: deleting deposit before value transfer to avoid reentrancy attack
        delete _deposits[proposalId];

        return _withdrawTokensTo(deposit.tokenAddress, deposit.amount, deposit.proposer);
    }

    function _closeDepositTo(uint256 proposalId, address to) private returns (bool) {
        ProposalDeposit memory deposit = _deposits[proposalId];

        // important: deleting deposit before value transfer to avoid reentrancy attack
        delete _deposits[proposalId];

        return _withdrawTokensTo(deposit.tokenAddress, deposit.amount, to);
    }

    function _withdrawTokensTo(address tokenAddress, uint256 amount, address to) private returns (bool) {
        if (tokenAddress == address(0)) {
            // deposit token is ETH
            (bool success,) = to.call{value: amount}("");

            return success;
        } else {
            // deposit token is an ERC-20 token
            IERC20 token = IERC20(tokenAddress);
            try token.transfer(to, amount) returns (bool success) {
                return success;
            } catch (bytes memory) {
                return false;
            } catch Error (string memory) {
                return false;
            }
        }
    }
}
