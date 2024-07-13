pragma solidity ^0.8.0;

import {MockOracle} from "./MockOracle.sol";
import {PoolKey} from "@pancakeswap/v4-core/src/types/PoolKey.sol";

import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {BinPoolManager} from "@pancakeswap/v4-core/src/pool-bin/BinPoolManager.sol";
import {IHooks} from "@pancakeswap/v4-core/src/interfaces/IHooks.sol";
import {PoolIdLibrary} from "@pancakeswap/v4-core/src/types/PoolId.sol";
import {BinPoolParametersHelper} from "@pancakeswap/v4-core/src/pool-bin/libraries/BinPoolParametersHelper.sol";
import {Currency} from "@pancakeswap/v4-core/src/types/Currency.sol";
import {IBinFungiblePositionManager} from "@pancakeswap/v4-periphery/src/pool-bin/interfaces/IBinFungiblePositionManager.sol";
import {SortTokens} from "@pancakeswap/v4-core/test/helpers/SortTokens.sol";

/**
 * @title EnglishOrSpanish
 * @author 2manslkh
 * @notice This contract will help to initialize the match and mint the mock tokens
 */
contract EnglishOrSpanish {
    using PoolIdLibrary for PoolKey;
    using BinPoolParametersHelper for bytes32;
    MockOracle public oracle;
    IBinFungiblePositionManager public binFungiblePositionManager;

    MockERC20 public ENGLAND_TOKEN;
    MockERC20 public SPAIN_TOKEN;
    MockERC20 public DRAW_TOKEN;
    MockERC20 public USDC;

    PoolKey public ENGLAND_USDC_POOL_KEY;
    PoolKey public SPAIN_USDC_POOL_KEY;
    PoolKey public DRAW_USDC_POOL_KEY;

    uint24 ACTIVE_ID = 2 ** 23;

    address public PREDICTION_POOL_HOOK;

    // Keep track of rounds

    constructor(
        MockOracle _oracle,
        MockERC20 _englandToken,
        MockERC20 _spainToken,
        MockERC20 _drawToken,
        MockERC20 _usdc,
        IBinFungiblePositionManager _binFungiblePositionManager,
        address _predictionPoolHook
    ) {
        oracle = _oracle;
        ENGLAND_TOKEN = _englandToken;
        SPAIN_TOKEN = _spainToken;
        DRAW_TOKEN = _drawToken;
        USDC = _usdc;
        binFungiblePositionManager = _binFungiblePositionManager;
        PREDICTION_POOL_HOOK = _predictionPoolHook;

        SPAIN_TOKEN.approve(address(binFungiblePositionManager), type(uint256).max);
        ENGLAND_TOKEN.approve(address(binFungiblePositionManager), type(uint256).max);
        DRAW_TOKEN.approve(address(binFungiblePositionManager), type(uint256).max);
        USDC.approve(address(binFungiblePositionManager), type(uint256).max);
    }

    function initPool(
        IBinFungiblePositionManager _poolManager,
        IHooks _hook,
        Currency _currency0,
        Currency _currency1
    ) internal returns (PoolKey memory key) {
        // create the pool key
        key = PoolKey({
            currency0: _currency0,
            currency1: _currency1,
            hooks: _hook,
            poolManager: _poolManager,
            fee: uint24(3000),
            // binstep: 10 = 0.1% price jump per bin
            parameters: bytes32(uint256(_hook.getHooksRegistrationBitmap())).setBinStep(10)
        });

        // initialize pool at 1:1 price point (assume stablecoin pair)
        _poolManager.initialize(key, ACTIVE_ID, new bytes(0));
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
        SortTokens.sort(ENGLAND_TOKEN, USDC);
        SortTokens.sort(SPAIN_TOKEN, USDC);
        SortTokens.sort(DRAW_TOKEN, USDC);
        initPool(binFungiblePositionManager, IHooks(PREDICTION_POOL_HOOK), SortTokens.sort(ENGLAND_TOKEN, USDC));
        initPool(
            binFungiblePositionManager,
            IHooks(PREDICTION_POOL_HOOK),
            Currency(address(SPAIN_TOKEN)),
            Currency(address(USDC))
        );
        initPool(
            binFungiblePositionManager,
            IHooks(PREDICTION_POOL_HOOK),
            Currency(address(DRAW_TOKEN)),
            Currency(address(USDC))
        );
    }

    // Rebalance all Pools
    function rebalanceAllPools() external {
        // Rebalance all 3 pools
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
}
