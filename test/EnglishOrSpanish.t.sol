// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {EnglishOrSpanish} from "../src/EnglishOrSpanish.sol";
import {MockOracle} from "../src/MockOracle.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {IBinFungiblePositionManager} from "@pancakeswap/v4-periphery/src/pool-bin/interfaces/IBinFungiblePositionManager.sol";
import {BinPoolManager} from "@pancakeswap/v4-core/src/pool-bin/BinPoolManager.sol";
import {Vault} from "@pancakeswap/v4-core/src/Vault.sol";

contract EnglishOrSpanishTest is Test {
    EnglishOrSpanish public englishOrSpanish;
    MockOracle public oracle;
    MockERC20 public englandToken;
    MockERC20 public spainToken;
    MockERC20 public drawToken;
    MockERC20 public usdc;
    IBinFungiblePositionManager public binFungiblePositionManager;
    BinPoolManager public binPoolManager;
    Vault vault;

    address public predictionPoolHook;

    function setUp() public {
        oracle = new MockOracle();
        englandToken = new MockERC20("England Token", "ENG", 18);
        spainToken = new MockERC20("Spain Token", "SPA", 18);
        drawToken = new MockERC20("Draw Token", "DRAW", 18);
        usdc = new MockERC20("USD Coin", "USDC", 18);
        binFungiblePositionManager = IBinFungiblePositionManager(address(0x123)); // Mock address
        vault = new Vault();
        binPoolManager = new BinPoolManager(vault, 500000);
        predictionPoolHook = address(0x456); // Mock address

        englishOrSpanish = new EnglishOrSpanish(
            oracle,
            englandToken,
            spainToken,
            drawToken,
            usdc,
            binFungiblePositionManager,
            binPoolManager,
            predictionPoolHook
        );
    }

    function testInitializePools() public {
        englishOrSpanish.initializePools();

        // Add assertions to verify the state after initialization
        // For example, check if tokens were minted correctly
        assertEq(usdc.balanceOf(address(englishOrSpanish)), 3000 ether);
        assertEq(englandToken.balanceOf(address(englishOrSpanish)), 1000 ether);
        assertEq(spainToken.balanceOf(address(englishOrSpanish)), 1000 ether);
        assertEq(drawToken.balanceOf(address(englishOrSpanish)), 1000 ether);
    }

    function testDripUSDCTokens() public {
        englishOrSpanish.dripUSDCTokens();

        // Check if the tokens were minted to the caller
        assertEq(usdc.balanceOf(address(this)), 100 ether);
    }

    // Add more tests as needed
}
