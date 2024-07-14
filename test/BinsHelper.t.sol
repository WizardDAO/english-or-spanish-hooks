// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {PriceToActiveIdHelper} from "../src/BinsHelper.sol";
import {console} from "forge-std/console.sol";

contract BinsHelperTest is Test {
    PriceToActiveIdHelper helper;

    function setUp() public {
        helper = new PriceToActiveIdHelper();
    }

    function testGetActiveIdFromPrice() public {
        uint256 price = 1 * 10 ** 18; // Example price
        uint256 expectedActiveId = 8388608; // Expected activeId for price 1e18

        uint256 activeId = helper.getActiveIdFromPrice(price);
        console.log("Active ID:", activeId);
        console.log("Expected Active ID:", expectedActiveId);
        assertEq(activeId, expectedActiveId, "Active ID does not match the expected value");
    }

    function testGetActiveIdFromPriceDifferentValue() public {
        uint256 price = 2 * 10 ** 18; // Example price
        uint256 expectedActiveId = 8388677; // Expected activeId for price 2e18

        uint256 activeId = helper.getActiveIdFromPrice(price);

        console.log("Active ID:", activeId);
        console.log("Expected Active ID:", expectedActiveId);
        assertEq(activeId, expectedActiveId, "Active ID does not match the expected value");
    }
}
