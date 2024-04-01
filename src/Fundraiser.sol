// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MyERC20} from "./MyERC20.sol";

error Fundraiser__GoalGreaterThanZero(string message);
error Fundraiser__DeadlineInTheFuture(string message);
error Fundraiser__InvalidCampaignID(string message);
error Fundraiser__CampaignDeadlinePassed(string message);
error Fundraiser__DonationAmountGreaterThanZero(string message);
error Fundraiser__OnlyCampaignCreator(string message);
error Fundraiser__TokenNotAccepted(string message);
error Fundraiser__DonationFailed(string message);
error Fundraiser__UnfinishedCampaign(string message);
error Fundraiser__TokenTransferFailed(string message);
error Fundraiser__NoDonationMade(string message);

contract Fundraiser {
    struct Campaign {
        address creator;
        uint256 goal;
        uint256 deadline;
        uint256 totalDonated;
        address token;
        mapping(address => uint256) donations;
        mapping(address => bool) donatedToCampaign;
    }

    mapping(uint256 => Campaign) public s_campaigns;
    uint256 public s_campaignCount;

    event CampaignCreated(
        uint256 indexed id,
        address indexed creator,
        address token,
        uint256 goal,
        uint256 deadline
    );
    event Donation(
        address indexed donor,
        uint256 indexed campaignId,
        uint256 amount,
        address token
    );
    event Withdrawal(
        address indexed withdrawer,
        uint256 indexed campaignId,
        uint256 totalDonated,
        address token
    );

    modifier validCampaignId(uint256 _campaignId) {
        if (_campaignId <= 0 || _campaignId > s_campaignCount) {
            revert Fundraiser__InvalidCampaignID("Invalid campaign ID");
        }
        _;
    }

    function createFundraiser(
        uint256 _goal,
        address _token,
        uint256 _deadline
    ) external {
        if (_goal <= 0) {
            revert Fundraiser__GoalGreaterThanZero(
                "Goal must be greater than zero"
            );
        }
        if (_deadline <= block.timestamp) {
            revert Fundraiser__DeadlineInTheFuture(
                "Deadline must be in the future"
            );
        }

        uint8 decimals = MyERC20(_token).decimals();
        s_campaignCount++;
        s_campaigns[s_campaignCount].creator = msg.sender;
        s_campaigns[s_campaignCount].goal = _multiplyByDecimals(
            decimals,
            _goal
        );
        s_campaigns[s_campaignCount].token = _token;
        s_campaigns[s_campaignCount].deadline = _deadline;
        emit CampaignCreated(
            s_campaignCount,
            msg.sender,
            _token,
            _goal,
            _deadline
        );
    }

    function donate(
        uint256 _campaignId,
        address _token,
        uint256 _amount
    ) external payable validCampaignId(_campaignId) {
        if (block.timestamp >= s_campaigns[_campaignId].deadline) {
            revert Fundraiser__CampaignDeadlinePassed(
                "Campaign deadline passed"
            );
        }
        if (_amount <= 0) {
            revert Fundraiser__DonationAmountGreaterThanZero(
                "Donation amount must be greater than zero"
            );
        }
        if (_token != s_campaigns[_campaignId].token) {
            revert Fundraiser__TokenNotAccepted(
                "Token not accepted for this campaign"
            );
        }

        bool ok = transferMoney(msg.sender, address(this), _amount, _token);

        if (!ok) {
            revert Fundraiser__DonationFailed("Donation failed");
        }
        uint8 decimals = MyERC20(_token).decimals();
        s_campaigns[_campaignId].totalDonated += _multiplyByDecimals(
            decimals,
            _amount
        );
        s_campaigns[_campaignId].donations[msg.sender] += _multiplyByDecimals(
            decimals,
            _amount
        );
        s_campaigns[_campaignId].donatedToCampaign[msg.sender] = true;

        emit Donation(msg.sender, _campaignId, _amount, _token);
    }

    function withdraw(
        uint256 _campaignId
    ) external validCampaignId(_campaignId) {
        if (msg.sender != s_campaigns[_campaignId].creator) {
            revert Fundraiser__OnlyCampaignCreator(
                "Only campaign creator can withdraw"
            );
        }

        Campaign storage campaign = s_campaigns[_campaignId];

        if (block.timestamp < campaign.deadline) {
            revert Fundraiser__UnfinishedCampaign("Unfinished campaign");
        }

        if (campaign.totalDonated >= campaign.goal) {
            uint8 decimals = MyERC20(campaign.token).decimals();
            MyERC20(campaign.token).approve(
                address(this),
                campaign.totalDonated
            );
            bool ok = transferMoney(
                address(this),
                msg.sender,
                _divideByDecimals(decimals, campaign.totalDonated),
                campaign.token
            );

            if (!ok) {
                revert Fundraiser__TokenTransferFailed("Token transfer failed");
            }
            campaign.totalDonated = 0;

            emit Withdrawal(
                msg.sender,
                _campaignId,
                _divideByDecimals(decimals, campaign.totalDonated),
                campaign.token
            );
        }
    }

    function withdrawExcess(
        uint256 _campaignId
    ) external validCampaignId(_campaignId) {
        Campaign storage campaign = s_campaigns[_campaignId];
        if (block.timestamp < campaign.deadline) {
            revert Fundraiser__UnfinishedCampaign("Unfinished campaign");
        }
        if (campaign.donations[msg.sender] == 0) {
            revert Fundraiser__NoDonationMade("No donation made by this user");
        }
        if (!campaign.donatedToCampaign[msg.sender]) {
            revert Fundraiser__NoDonationMade("No donation made by this user");
        }

        if (campaign.totalDonated < campaign.goal) {
            uint256 excessAmount = campaign.donations[msg.sender];

            uint8 decimals = MyERC20(campaign.token).decimals();
            bool ok = transferMoney(
                address(this),
                msg.sender,
                _divideByDecimals(decimals, excessAmount),
                campaign.token
            );

            if (!ok) {
                revert Fundraiser__TokenTransferFailed("Token Transfer failed");
            }
            campaign.donations[msg.sender] = 0;

            emit Withdrawal(
                msg.sender,
                _campaignId,
                _divideByDecimals(decimals, excessAmount),
                campaign.token
            );
        }
    }

    function transferMoney(
        address _from,
        address _to,
        uint256 _amountToWithdraw,
        address _token
    ) private returns (bool ok) {
        try IERC20(_token).transferFrom(_from, _to, _amountToWithdraw) returns (
            bool
        ) {
            return true;
        } catch {
            return false;
        }
    }

    function _multiplyByDecimals(
        uint8 _decimals,
        uint256 _amount
    ) internal pure returns (uint256) {
        return _amount * (10 ** _decimals);
    }

    function _divideByDecimals(
        uint8 _decimals,
        uint256 _amount
    ) internal pure returns (uint256) {
        return _amount / (10 ** _decimals);
    }
}
