// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Setup.t.sol";
import "../../../src/libraries/PositionCalculator.sol";

contract CalculateMinMarginTest is TestPositionCalculator {
    DataType.PairStatus pairStatus;

    function setUp() public override {
        TestPositionCalculator.setUp();

        pairStatus = createAssetStatus(1, address(usdc), address(weth), address(uniswapPool));
    }

    function getVault(int256 _amountStable, int256 _amountSquart, int256 _amountUnderlying, int256 _margin)
        internal
        view
        returns (DataType.Vault memory)
    {
        Perp.UserStatus memory openPosition = Perp.createPerpUserStatus(2);

        openPosition.sqrtPerp.amount = _amountSquart;
        openPosition.basePosition.positionAmount = _amountUnderlying;
        openPosition.perp.amount = _amountUnderlying;

        openPosition.perp.entryValue = _amountStable;
        openPosition.sqrtPerp.entryValue = 0;
        openPosition.stablePosition.positionAmount = _amountStable;

        return DataType.Vault(1, address(usdc), address(this), address(this), _margin, openPosition);
    }

    function testCalculateMinDepositZero() public {
        (int256 minDeposit, int256 vaultValue, bool hasPosition,) =
            PositionCalculator.calculateMinMargin(pairStatus, getVault(0, 0, 0, 0), DataType.FeeAmount(0, 0));

        assertEq(minDeposit, 0);
        assertEq(vaultValue, 0);
        assertFalse(hasPosition);
    }

    function testCalculateMinDepositStable(uint256 _amountStable) public {
        int256 amountQuote = int256(bound(_amountStable, 0, 1e36));

        (int256 minDeposit, int256 vaultValue, bool hasPosition,) =
            PositionCalculator.calculateMinMargin(pairStatus, getVault(amountQuote, 0, 0, 0), DataType.FeeAmount(0, 0));

        assertEq(minDeposit, 0);
        assertEq(vaultValue, amountQuote);
        assertFalse(hasPosition);
    }

    function testCalculateMinDepositDeltaLong() public {
        DataType.Vault memory vault = getVault(-1000, 0, 1000, 0);

        (int256 minDeposit, int256 vaultValue, bool hasPosition,) =
            PositionCalculator.calculateMinMargin(pairStatus, vault, DataType.FeeAmount(0, 0));

        assertEq(minDeposit, 1000000);
        assertEq(vaultValue, 0);
        assertTrue(hasPosition);

        (, bool isSafe,) = PositionCalculator.getIsSafe(pairStatus, vault, DataType.FeeAmount(0, 0));

        assertFalse(isSafe);
    }

    function testCalculateMinDepositGammaShort() public {
        DataType.Vault memory vault = getVault(-2 * 1e8, 1e8, 0, 0);
        (int256 minDeposit, int256 vaultValue, bool hasPosition,) =
            PositionCalculator.calculateMinMargin(pairStatus, vault, DataType.FeeAmount(0, 0));

        assertEq(minDeposit, 17425814);
        assertEq(vaultValue, 0);
        assertTrue(hasPosition);

        (, bool isSafe,) = PositionCalculator.getIsSafe(pairStatus, vault, DataType.FeeAmount(0, 0));
        (bool isLiquidatable,,,) = PositionCalculator.isLiquidatable(pairStatus, vault, DataType.FeeAmount(0, 0));

        assertFalse(isSafe);
        assertTrue(isLiquidatable);
    }

    function testCalculateMinDepositGammaShortSafe() public {
        DataType.Vault memory vault = getVault(-2 * 1e8, 1e8, 0, 20000000);
        (int256 minDeposit, int256 vaultValue, bool hasPosition,) =
            PositionCalculator.calculateMinMargin(pairStatus, vault, DataType.FeeAmount(0, 0));

        assertEq(minDeposit, 17425814);
        assertEq(vaultValue, 20000000);
        assertTrue(hasPosition);

        (, bool isSafe,) = PositionCalculator.getIsSafe(pairStatus, vault, DataType.FeeAmount(0, 0));
        assertTrue(isSafe);
    }

    function testCalculateMinDepositGammaLong() public {
        DataType.Vault memory vault = getVault(2 * 1e8, -1e8, 0, 0);
        (int256 minDeposit, int256 vaultValue, bool hasPosition,) =
            PositionCalculator.calculateMinMargin(pairStatus, vault, DataType.FeeAmount(0, 0));

        assertEq(minDeposit, 19489021);
        assertEq(vaultValue, 0);
        assertTrue(hasPosition);

        (, bool isSafe,) = PositionCalculator.getIsSafe(pairStatus, vault, DataType.FeeAmount(0, 0));
        (bool isLiquidatable,,,) = PositionCalculator.isLiquidatable(pairStatus, vault, DataType.FeeAmount(0, 0));

        assertFalse(isSafe);
        assertTrue(isLiquidatable);
    }

    function testCalculateMinDepositGammaLongSafe() public {
        DataType.Vault memory vault = getVault(2 * 1e8, -1e8, 0, 22000000);
        (int256 minDeposit, int256 vaultValue, bool hasPosition,) =
            PositionCalculator.calculateMinMargin(pairStatus, vault, DataType.FeeAmount(0, 0));

        assertEq(minDeposit, 19489021);
        assertEq(vaultValue, 22000000);
        assertTrue(hasPosition);

        (, bool isSafe,) = PositionCalculator.getIsSafe(pairStatus, vault, DataType.FeeAmount(0, 0));
        assertTrue(isSafe);
    }

    function testMarginIsNegative() public {
        DataType.Vault memory vault = getVault(0, 0, 0, -100);

        (, bool isSafe,) = PositionCalculator.getIsSafe(pairStatus, vault, DataType.FeeAmount(0, 0));
        (bool isLiquidatable,,,) = PositionCalculator.isLiquidatable(pairStatus, vault, DataType.FeeAmount(0, 0));

        assertFalse(isSafe);
        assertFalse(isLiquidatable);
    }
}
