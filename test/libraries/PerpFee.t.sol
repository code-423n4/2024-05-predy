// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/libraries/PerpFee.sol";
import {PairStatusUtils} from "../utils/PairStatusUtils.sol";

contract PerpFeeTest is Test, PairStatusUtils {
    DataType.PairStatus pairStatus;
    ScaledAsset.AssetStatus stableAssetStatus;
    Perp.UserStatus perpUserStatus;

    function setUp() public {
        pairStatus = createAssetStatus(1, address(0), address(0), address(0));
        stableAssetStatus = ScaledAsset.createAssetStatus();
        perpUserStatus = Perp.createPerpUserStatus(1);

        pairStatus.sqrtAssetStatus.borrowPremium0Growth = 1 * Constants.Q128 / 1e2;
        pairStatus.sqrtAssetStatus.borrowPremium1Growth = 2 * Constants.Q128 / 1e2;
        pairStatus.sqrtAssetStatus.fee0Growth = 200 * Constants.Q128 / 1e6;
        pairStatus.sqrtAssetStatus.fee1Growth = 5 * Constants.Q128 / 1e6;
    }

    function testComputeTradeFeeForLong() public {
        perpUserStatus.sqrtPerp.amount = 10000000000;

        (int256 feeUnderlying, int256 feeStable) = PerpFee.computePremium(pairStatus, perpUserStatus.sqrtPerp);

        assertEq(feeUnderlying, 1999999);
        assertEq(feeStable, 49999);
    }

    function testComputeTradeFeeForShort() public {
        perpUserStatus.sqrtPerp.amount = -10000000000;

        (int256 feeUnderlying, int256 feeStable) = PerpFee.computePremium(pairStatus, perpUserStatus.sqrtPerp);

        assertEq(feeUnderlying, -100000000);
        assertEq(feeStable, -200000000);
    }

    function testSettleTradeFeeForLong() public {
        perpUserStatus.sqrtPerp.amount = 10000000000;

        (int256 feeUnderlying, int256 feeStable) = PerpFee.settlePremium(pairStatus, perpUserStatus.sqrtPerp);

        assertEq(feeUnderlying, 1999999);
        assertEq(feeStable, 49999);
        assertEq(perpUserStatus.sqrtPerp.entryTradeFee0, pairStatus.sqrtAssetStatus.fee0Growth);
        assertEq(perpUserStatus.sqrtPerp.entryTradeFee1, pairStatus.sqrtAssetStatus.fee1Growth);
    }

    function testSettleTradeFeeForShort() public {
        perpUserStatus.sqrtPerp.amount = -10000000000;

        (int256 feeUnderlying, int256 feeStable) = PerpFee.settlePremium(pairStatus, perpUserStatus.sqrtPerp);

        assertEq(feeUnderlying, -100000000);
        assertEq(feeStable, -200000000);
        assertEq(perpUserStatus.sqrtPerp.entryTradeFee0, pairStatus.sqrtAssetStatus.borrowPremium0Growth);
        assertEq(perpUserStatus.sqrtPerp.entryTradeFee1, pairStatus.sqrtAssetStatus.borrowPremium1Growth);
    }
}
