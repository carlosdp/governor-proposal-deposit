# GovernorProposalDepositRequirement
:rotating_light: **Not Yet Audited**

This is an extension for the [Open Zeppelin Governor contract](https://docs.openzeppelin.com/contracts/4.x/api/governance#Governor) that adds a staking requirement (in any ERC-20 token) to those that want to make a proposal to governance. If the proposal succeeds, the stake is returned to the proposal on execution. If it is defeated, the stake is slashed and can be withdrawn to an address of the contract's choosing.

This was designed for use by the ENS DAO as a mechanism to allow safely reducing the amount of ENS tokens required to propose, without introducing the risk of spam proposals.

## Running Tests
Install [foundry](https://getfoundry.sh/) and run:

```bash
forge test
```

## Design Notes

- Solidity style strives to remain as close as possible to the way Open Zeppeling likes their contracts
- Revert strings are used to remain consistent with the Open Zeppelin contracts
- Execute **will not** revert in the event the deposit return fails. This is important because there are very straightforward and realistic scenarios in which the return can fail. These include tokens being transfered out of the contract by governance out-of-band, or a broken/malicious ERC-20 implementation. There is another function for manually returning a deposit outside of execution to allow for remediation, if possible, without disrupting core contract functionality.

## License
This repository is dual licensed under both MIT and Apache 2.0.
