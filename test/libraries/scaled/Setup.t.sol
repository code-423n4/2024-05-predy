// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../../src/libraries/ScaledAsset.sol";

contract TestScaledAsset is Test {
    ScaledAsset.AssetStatus internal assetStatus;
    ScaledAsset.UserStatus internal userStatus0;
    ScaledAsset.UserStatus internal userStatus1;
    ScaledAsset.UserStatus internal userStatus2;

    function setUp() public virtual {
        assetStatus = ScaledAsset.createAssetStatus();
        userStatus0 = ScaledAsset.createUserStatus();
        userStatus1 = ScaledAsset.createUserStatus();
        userStatus2 = ScaledAsset.createUserStatus();
    }
}
