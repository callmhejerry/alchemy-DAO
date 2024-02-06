// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract Voting {
    constructor(address[] memory _allowedVoters) {
        for (uint256 i = 0; i < _allowedVoters.length; i++) {
            s_allowedVoters[_allowedVoters[i]] = true;
        }
        s_allowedVoters[msg.sender] = true;
    }

    event Voting_ProposalCreated(uint256 proposalId);
    event Voting_VoteCast(uint256 proposalId, address voter);

    struct Proposal {
        address target;
        bytes data;
        uint256 yesCount;
        uint256 noCount;
    }

    Proposal[] public s_proposals;
    uint256 MINIMUM_VOTING_THRESHOLD = 10;

    /// a mapping of already voted voters
    mapping(address => bool) public s_voters;
    /// a mapping from the voter's address to what vote they
    /// casted (true/fasle)
    mapping(address => bool) public s_votersVote;
    /// a mapping of allowed voters
    mapping(address => bool) public s_allowedVoters;
    /// a mapping of already executed proposal
    mapping(uint256 => bool) public s_executedProposal;

    function newProposal(address _targetAddress, bytes calldata _data) external validateVoter {
        Proposal memory newlyCreatedProposal = Proposal({target: _targetAddress, data: _data, yesCount: 0, noCount: 0});

        s_proposals.push(newlyCreatedProposal);
        emit Voting_ProposalCreated(s_proposals.length - 1);
    }

    function castVote(uint256 _proposalId, bool _voteForProposal) external validateVoter {
        // check if voter has voted before to prevent double voting
        if (!s_voters[msg.sender]) {
            if (_voteForProposal) {
                s_proposals[_proposalId].yesCount += 1;
            } else {
                s_proposals[_proposalId].noCount += 1;
            }
            s_voters[msg.sender] = true;
            s_votersVote[msg.sender] = _voteForProposal;
        } else {
            // check if the previous vote is different from the
            // current vote and update it
            if (s_votersVote[msg.sender] != _voteForProposal) {
                if (_voteForProposal) {
                    s_proposals[_proposalId].noCount -= 1;
                    s_proposals[_proposalId].yesCount += 1;
                } else {
                    s_proposals[_proposalId].yesCount -= 1;
                    s_proposals[_proposalId].noCount += 1;
                }
                s_votersVote[msg.sender] = _voteForProposal;
            }
        }
        if (s_proposals[_proposalId].yesCount == MINIMUM_VOTING_THRESHOLD) {
            executeProposal(_proposalId, s_proposals[_proposalId].target, s_proposals[_proposalId].data);
        }
        emit Voting_VoteCast(_proposalId, msg.sender);
    }

    function executeProposal(uint256 proposalId, address _targetProposal, bytes memory _data) internal returns (bool) {
        require(!s_executedProposal[proposalId], "Proposal already executed");
        (bool success,) = _targetProposal.call(_data);
        if (success) {
            s_executedProposal[proposalId] = success;
        }
        return success;
    }

    modifier validateVoter() {
        require(s_allowedVoters[msg.sender], "Not eligible to vote");
        _;
    }

    //GETTERS
    function getProposalsLength() external view returns (uint256) {
        return s_proposals.length;
    }

    function getProposalByIndex(uint256 index) external view returns (Proposal memory) {
        return s_proposals[index];
    }
}
