// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {Test} from "forge-std/Test.sol";
import {BinPoolManager} from "@pancakeswap/v4-core/src/pool-bin/BinPoolManager.sol";
import {Vault} from "@pancakeswap/v4-core/src/Vault.sol";
import {Currency} from "@pancakeswap/v4-core/src/types/Currency.sol";
import {SortTokens} from "@pancakeswap/v4-core/test/helpers/SortTokens.sol";
import {PoolKey} from "@pancakeswap/v4-core/src/types/PoolKey.sol";
import {SafeCast} from "@pancakeswap/v4-core/src/pool-bin/libraries/math/SafeCast.sol";
import {BinSwapRouter} from "@pancakeswap/v4-periphery/src/pool-bin/BinSwapRouter.sol";
import {BinFungiblePositionManager} from "@pancakeswap/v4-periphery/src/pool-bin/BinFungiblePositionManager.sol";
import {IBinFungiblePositionManager} from "@pancakeswap/v4-periphery/src/pool-bin/interfaces/IBinFungiblePositionManager.sol";
import {EnglishOrSpanish} from "../src/EnglishOrSpanish.sol";
import {MockOracle} from "../src/MockOracle.sol";
import {PredictionPoolHook} from "../src/PredictionPoolHook.sol";

contract DeployScript is Script {
    Vault vault;
    BinPoolManager poolManager;
    BinFungiblePositionManager positionManager;
    BinSwapRouter swapRouter;
    EnglishOrSpanish englishOrSpanish;
    MockOracle oracle;
    PredictionPoolHook predictionPoolHook;

    function deployContractsWithTokens() internal returns (Currency, Currency) {
        // address[2] memory approvalAddress = [address(positionManager), address(swapRouter)];
        // for (uint256 i; i < approvalAddress.length; i++) {
        //     token0.approve(approvalAddress[i], type(uint256).max);
        //     token1.approve(approvalAddress[i], type(uint256).max);
        // }
        // return SortTokens.sort(token0, token1);
    }

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying contracts...");
        // deployContractsWithTokens();
        vault = new Vault();
        poolManager = new BinPoolManager(vault, 500000);
        vault.registerApp(address(poolManager));

        positionManager = new BinFungiblePositionManager(vault, poolManager, address(0));
        swapRouter = new BinSwapRouter(vault, poolManager, address(0));

        MockERC20 ERC20_SPAIN = new MockERC20("SPAIN", "SPAIN", 18);
        MockERC20 ERC20_ENGLAND = new MockERC20("ENGLAND", "ENGLAND", 18);
        MockERC20 ERC20_DRAW = new MockERC20("DRAW", "DRAW", 18);
        MockERC20 ERC20_USDC = new MockERC20("USDC", "USDC", 18);

        console.log("Vault deployed at:", address(vault));
        console.log("BinPoolManager deployed at:", address(poolManager));
        console.log("BinFungiblePositionManager deployed at:", address(positionManager));
        console.log("BinSwapRouter deployed at:", address(swapRouter));
        console.log("ERC20_SPAIN deployed at:", address(ERC20_SPAIN));
        console.log("ERC20_ENGLAND deployed at:", address(ERC20_ENGLAND));
        console.log("ERC20_DRAW deployed at:", address(ERC20_DRAW));
        console.log("ERC20_USDC deployed at:", address(ERC20_USDC));

        // Deploy MockOracle
        oracle = new MockOracle();

        // Deploy PredictionPoolHook
        predictionPoolHook = new PredictionPoolHook();

        // Deploy EnglishOrSpanish
        englishOrSpanish = new EnglishOrSpanish(
            oracle,
            ERC20_ENGLAND,
            ERC20_SPAIN,
            ERC20_DRAW,
            ERC20_USDC,
            positionManager,
            address(predictionPoolHook)
        );

        console.log("Approving Tokens...");
        address[2] memory approvalAddress = [address(englishOrSpanish), address(swapRouter)];
        for (uint256 i; i < approvalAddress.length; i++) {
            ERC20_SPAIN.approve(approvalAddress[i], type(uint256).max);
            ERC20_ENGLAND.approve(approvalAddress[i], type(uint256).max);
            ERC20_DRAW.approve(approvalAddress[i], type(uint256).max);
            ERC20_USDC.approve(approvalAddress[i], type(uint256).max);
        }

        console.log("All tokens approved to positionManager and swapRouter");

        // Add liquidity

        vm.stopBroadcast();
    }
}
