pragma solidity ^0.8.0;

import {MockOracle} from "./MockOracle.sol";
import {PoolKey} from "@pancakeswap/v4-core/src/types/PoolKey.sol";
import {PoolId} from "@pancakeswap/v4-core/src/types/PoolId.sol";

import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {BinPoolManager} from "@pancakeswap/v4-core/src/pool-bin/BinPoolManager.sol";
import {IHooks} from "@pancakeswap/v4-core/src/interfaces/IHooks.sol";
import {PoolIdLibrary} from "@pancakeswap/v4-core/src/types/PoolId.sol";
import {BinPoolParametersHelper} from "@pancakeswap/v4-core/src/pool-bin/libraries/BinPoolParametersHelper.sol";
import {Currency} from "@pancakeswap/v4-core/src/types/Currency.sol";
import {IBinFungiblePositionManager} from "@pancakeswap/v4-periphery/src/pool-bin/interfaces/IBinFungiblePositionManager.sol";
import {SortTokens} from "@pancakeswap/v4-core/test/helpers/SortTokens.sol";
import {BinsHelper} from "./BinsHelper.sol";
import {ImpliedOddsHelper} from "./ImpliedOddsHelper.sol";

/**
 * @title EnglishOrSpanish
 * @author 2manslkh
 * @notice This contract will help to initialize the match and mint the mock tokens
 */
contract EnglishOrSpanish is BinsHelper, ImpliedOddsHelper {
    using PoolIdLibrary for PoolKey;
    using BinPoolParametersHelper for bytes32;
    BinPoolManager public poolManager;

    MockERC20 public ENGLAND_TOKEN;
    MockERC20 public SPAIN_TOKEN;
    MockERC20 public DRAW_TOKEN;
    MockERC20 public USDC;

    PoolKey public ENGLAND_USDC_POOL_KEY;
    PoolKey public SPAIN_USDC_POOL_KEY;
    PoolKey public DRAW_USDC_POOL_KEY;

    uint24 ACTIVE_ID = 2 ** 23;

    uint24[3] public ACTIVE_IDS = [ACTIVE_ID, ACTIVE_ID, ACTIVE_ID];

    IHooks public PREDICTION_POOL_HOOK;

    uint24 ZERO_BIN = 8387608; // = 0ish
    uint24 STARTER_BIN = 8388497; // = 0.33
    uint24 MAX_BIN = 8388608; // = 1 = ACTIVE_ID

    // Keep track of rounds

    constructor(
        MockOracle _oracle,
        MockERC20 _englandToken,
        MockERC20 _spainToken,
        MockERC20 _drawToken,
        MockERC20 _usdc,
        IBinFungiblePositionManager _positionManager,
        BinPoolManager _poolManager,
        IHooks _predictionPoolHook
    ) BinsHelper(_positionManager) ImpliedOddsHelper(_oracle) {
        ENGLAND_TOKEN = _englandToken;
        SPAIN_TOKEN = _spainToken;
        DRAW_TOKEN = _drawToken;
        USDC = _usdc;
        positionManager = _positionManager;
        poolManager = _poolManager;
        PREDICTION_POOL_HOOK = _predictionPoolHook;

        SPAIN_TOKEN.approve(address(positionManager), type(uint256).max);
        ENGLAND_TOKEN.approve(address(positionManager), type(uint256).max);
        DRAW_TOKEN.approve(address(positionManager), type(uint256).max);
        USDC.approve(address(positionManager), type(uint256).max);
    }

    function initPool(Currency _currency0, Currency _currency1) internal returns (PoolKey memory key) {
        // create the pool key
        key = PoolKey({
            currency0: _currency0,
            currency1: _currency1,
            hooks: PREDICTION_POOL_HOOK,
            poolManager: poolManager,
            fee: 0,
            // binstep: 10 = 0.1% price jump per bin
            parameters: bytes32(uint256(PREDICTION_POOL_HOOK.getHooksRegistrationBitmap())).setBinStep(1)
        });

        // initialize pool at 1:1 price point (assume stablecoin pair)
        positionManager.initialize(key, ACTIVE_ID, new bytes(0));
        // add liquidity
    }

    // Initialize Pool function
    function initializePools() external {
        // Initialize all 3 pools using 3000 USDC
        mintUSDCTokens();
        mintEnglandTokens();
        mintSpainTokens();
        mintDrawTokens();

        // start oracle
        oracle.startMatch();

        // Initialize Pools with PredictionPoolHook
        (Currency token0, Currency token1) = SortTokens.sort(ENGLAND_TOKEN, USDC);
        ENGLAND_USDC_POOL_KEY = initPool(token0, token1);
        addLiquidity(ENGLAND_USDC_POOL_KEY, 1000 ether, 0 ether, ACTIVE_ID, 1);

        (token0, token1) = SortTokens.sort(SPAIN_TOKEN, USDC);
        SPAIN_USDC_POOL_KEY = initPool(token0, token1);
        addLiquidity(SPAIN_USDC_POOL_KEY, 0 ether, 1000 ether, ACTIVE_ID, 1);

        (token0, token1) = SortTokens.sort(DRAW_TOKEN, USDC);
        DRAW_USDC_POOL_KEY = initPool(token0, token1);
        addLiquidity(DRAW_USDC_POOL_KEY, 1000 ether, 0 ether, ACTIVE_ID, 1);
    }

    // Rebalance all Pools
    function rebalanceAllPools() external {
        // Calculate Liquidity for each pool
        (uint24 englandBin, uint24 spainBin, uint24 drawBin) = calculateNewBins();
        // Calculate new active id
        // Rebalance all pools
        // a. Remove all Liquidity from each pool
        removeLiquidity(ENGLAND_USDC_POOL_KEY, 1000 ether, 0 ether, ACTIVE_ID, 1);
        removeLiquidity(SPAIN_USDC_POOL_KEY, 0 ether, 1000 ether, ACTIVE_ID, 1);
        removeLiquidity(DRAW_USDC_POOL_KEY, 1000 ether, 0 ether, ACTIVE_ID, 1);
        // b. Add liquidity in new range
        addLiquidity(ENGLAND_USDC_POOL_KEY, 1000 ether, 0 ether, englandBin, 1);
        addLiquidity(SPAIN_USDC_POOL_KEY, 0 ether, 1000 ether, spainBin, 1);
        addLiquidity(DRAW_USDC_POOL_KEY, 1000 ether, 0 ether, drawBin, 1);
    }

    function dripUSDCTokens() external {
        // Mint 3000 Tokens
        USDC.mint(msg.sender, 100 ether);
    }

    function mintUSDCTokens() internal {
        // Mint 3000 Tokens
        USDC.mint(address(this), 3000 ether);
    }

    function mintEnglandTokens() internal {
        // Mint 1000 USDC to England Pool
        ENGLAND_TOKEN.mint(address(this), 1000 ether);
    }

    function mintSpainTokens() internal {
        // Mint 1000 USDC to Spain Pool
        SPAIN_TOKEN.mint(address(this), 1000 ether);
    }

    function mintDrawTokens() internal {
        // Mint 1000 USDC to Draw Pool
        DRAW_TOKEN.mint(address(this), 1000 ether);
    }

    function getEnglandPoolId() external view returns (PoolId) {
        return ENGLAND_USDC_POOL_KEY.toId();
    }

    function getSpainPoolId() external view returns (PoolId) {
        return SPAIN_USDC_POOL_KEY.toId();
    }

    function getDrawPoolId() external view returns (PoolId) {
        return DRAW_USDC_POOL_KEY.toId();
    }
}
