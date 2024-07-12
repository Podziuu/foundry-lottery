// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {console} from "forge-std/Script.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";

contract InteractionsTest is Test, CodeConstants {
    event SubscriptionFunded(uint256 indexed subId, uint256 oldBalance, uint256 newBalance);
    event SubscriptionConsumerAdded(uint256 indexed subId, address consumer);

    CreateSubscription createSubscription;
    HelperConfig.NetworkConfig config;
    FundSubscription fundSubscription;

    modifier skipFork() {
        if (block.chainid != LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

    function setUp() external {
        createSubscription = new CreateSubscription();
        HelperConfig helperConfig = new HelperConfig();
        config = helperConfig.getConfig();
        fundSubscription = new FundSubscription();
    }

    function testCreateSubscription() public skipFork {
        (uint256 subId, address coordinator) = createSubscription.createSubscriptionUsingConfig();
        assert(subId != 0);
        assert(coordinator != address(0));
    }

    function testFundSubscription() public skipFork {
        (config.subscriptionId, config.vrfCoordinator) = createSubscription.createSubscriptionUsingConfig();

        vm.expectEmit(address(config.vrfCoordinator));
        emit SubscriptionFunded(config.subscriptionId, address(config.vrfCoordinator).balance, 300 ether);
        fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link, config.account);
    }

    function testAddConsumer() public skipFork {
        (config.subscriptionId, config.vrfCoordinator) = createSubscription.createSubscriptionUsingConfig();
        fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link, config.account);
        AddConsumer addConsumer = new AddConsumer();
        vm.expectEmit();
        emit SubscriptionConsumerAdded(config.subscriptionId, address(this));
        addConsumer.addConsumer(address(this), config.vrfCoordinator, config.subscriptionId, config.account);
    }
}
