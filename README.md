# CrowdTank — Internship Project (NullClass)

## Summary
This repository contains the `CrowdTank.sol` smart contract, a comprehensive decentralized application (DApp) for crowdfunding fully implemented and tested on the Ethereum Virtual Machine (EVM) via Remix IDE. The contract successfully demonstrates both the core functionality and all complex enhancements required for the internship.

### Repository Structure
- `contracts/`: Contains the final, enhanced `CrowdTank.sol` source code.
- `screenshots/`: Contains all transaction proofs for core logic and enhancements.
- `README.md`: This documentation file.

---

## Demonstrated Functionality

### 1. Core Logic (Success & Failure Proofs Collected)
- **Full Lifecycle:** Demonstrated successful project creation, funding, and creator withdrawal (finalize).
- **Refund Flow:** Demonstrated project failure (did not meet the goal) and successful contributor refund.

### 2. Required Enhancements (All Implemented and Proven)

| Feature | Description |
| :--- | :--- |
| **Admin/Creator Management** | Implemented an `admin` role (set by the contract deployer) with functions (`addCreator`, `removeCreator`) to manage who can create new projects. Project creation is restricted to registered creators. |
| **Over-Funding Refund** | The `fundProject` method now calculates the exact amount needed to meet the goal and immediately refunds any excess Ether to the funder (`ExcessRefunded` event is logged). |
| **Early Commitment Withdrawal** | Added the `withdrawCommitment` function, which allows a funder to retrieve their invested funds before the project deadline passes. |
| **Project Tracking** | Implemented state variables (`successfullyFundedCount`, `failedToFundCount`) and logic within `finalizeProject` to track and count project outcomes. |
| **Funding Percentage View** | The `getFundingPercentage(uint256 id)` view function provides a real-time calculation of the funding raised versus the project's goal. |

---

## Proof / Screenshots

All transaction proofs demonstrating the successful execution of the core logic and all required enhancements are located in the `screenshots/` directory.

| Screenshot File | Functionality Proven |
| :--- | :--- |
| `compilation-sucessful.jpg` | Contract Compilation (v0.8.20). |
| `deploy_contract.png` | Contract Deployment (`Constructor`). |
| `admin_add_creator.png` | **Enhancement:** Admin successfully added a new creator. |
| `refund_excess.png` | **Enhancement:** Over-funding successfully triggered the **`ExcessRefunded`** event. |
| `early_withdraw.png` | **Enhancement:** Funder successfully called **`withdrawCommitment`** before the deadline. |
| `success_create_fund.png` | Project Creation and Funding (Goal Met). |
| `success_finalize.png` | Successful Withdrawal (`finalizeProject` - Success). |
| `failure_finalize.png` | Project Finalized (Failure). |
| `failure_refund.png` | Funder Refund (`refund`). |
| `final_structure.png` | Proof of organized project structure. |

---

## How to Run (Remix Guide)

1.  Open the Remix IDE: `https://remix.ethereum.org`.
2.  Paste the code from **`contracts/CrowdTank.sol`** into a new file.
3.  Compile with **Solidity v0.8.20** (EVM: **London**).
4.  Deploy on **Remix VM (London)** (The deployer is automatically the Admin).
5.  **Test Enhancements:** Verify `addCreator`, `fundProject` (with excess value), and `withdrawCommitment` before submitting.
6.  **Run Full Flows:** Replicate the successful and failed project cycles to verify all events and final logic.