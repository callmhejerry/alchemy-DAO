// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Voting} from "../src/Voting.sol";
import {Test} from "forge-std/Test.sol";

contract VotingTest is Test {
    event Voting_ProposalCreated(uint256 proposalId);
    event Voting_VoteCast(uint256 proposalId, address voter);

    Voting public votingContract;
    Account PROTOCOL_ADDRESS = makeAccount("Protocol");
    address user1;
    address user2;

    function setUp() public {
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        address[] memory voters = new address[](2);
        voters[0] = user1;
        voters[1] = user2;
        votingContract = new Voting(voters);
    }

    function test_CreateProposal() public {
        uint256 initialAmountOfProposals = votingContract.getProposalsLength();
        bytes memory functionCalldata = abi.encodeWithSignature("add(uint, uint)", 2, 3);

        votingContract.newProposal(PROTOCOL_ADDRESS.addr, functionCalldata);
        uint256 finalAmountOfProposals = votingContract.getProposalsLength();

        assertEq(initialAmountOfProposals + 1, finalAmountOfProposals);
    }

    function test_castVote() public {
        // Arrange
        bytes memory functionCalldata = abi.encodeWithSignature("add(uint256, uint256)", 2, 5);
        votingContract.newProposal(PROTOCOL_ADDRESS.addr, functionCalldata);

        // ACT
        vm.startPrank(user1);
        votingContract.castVote(0, true);

        // Assert
        assertEq(votingContract.getProposalsLength(), 1);
        assertEq(votingContract.getProposalByIndex(0).yesCount, 1);
        assertEq(votingContract.getProposalByIndex(0).noCount, 0);

        // Test double voting
        votingContract.castVote(0, true);
        assertEq(votingContract.getProposalByIndex(0).yesCount, 1);
        assertEq(votingContract.getProposalByIndex(0).noCount, 0);

        votingContract.castVote(0, false);
        assertEq(votingContract.getProposalByIndex(0).noCount, 1);
        assertEq(votingContract.getProposalByIndex(0).yesCount, 0);

        vm.stopPrank();

        vm.prank(user2);
        votingContract.castVote(0, true);
        vm.prank(user1);
        votingContract.castVote(0, true);

        assertEq(votingContract.getProposalByIndex(0).yesCount, 2);
        assertEq(votingContract.getProposalByIndex(0).noCount, 0);
    }

    function test_emitProposalEvent() external {
        bytes memory functionCalldata = abi.encodeWithSignature("add(uint, uint)", 2, 5);

        vm.expectEmit(false, false, false, true);
        emit Voting_ProposalCreated(0);
        votingContract.newProposal(PROTOCOL_ADDRESS.addr, functionCalldata);
    }

    // function test_emitVoteCastEvent() external{
    //     address voter = makeAddr("jerry");

    //     vm.expectEmit(false, false, false, true);
    //              vm.prank(voter);
    //     emit Voting_VoteCast(0, voter);

    //     votingContract.castVote(0, true);
    // }

    function test_preventSybilAttack() external {
        address jerry = makeAddr("jerry");
        vm.expectRevert();
        vm.prank(jerry);
        votingContract.newProposal(PROTOCOL_ADDRESS.addr, abi.encodeWithSignature("add(uint)", 1));
        vm.expectRevert();
        vm.prank(jerry);
        votingContract.castVote(0, true);
    }
}
