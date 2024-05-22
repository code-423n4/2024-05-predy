// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Setup.t.sol";

contract ScaledAssetCompoundTest is TestScaledAsset {
    uint256 internal constant ASSET_AMOUNT = 1e18;
    uint256 internal constant DEBT_AMOUNT = 1e17;
    uint256 initialMintAmount;
    uint256 constant MAX_AMOUNT = type(uint128).max;

    function setUp() public override {
        TestScaledAsset.setUp();

        initialMintAmount = ScaledAsset.addAsset(assetStatus, ASSET_AMOUNT);
        ScaledAsset.updatePosition(assetStatus, userStatus0, -int256(DEBT_AMOUNT), 1, false);
    }

    //////////////////
    //   addAsset   //
    //////////////////

    // Supply asset
    function testAddAsset(uint256 _amount) public {
        uint256 amount = bound(_amount, 1, MAX_AMOUNT);

        uint256 claimAmount = ScaledAsset.addAsset(assetStatus, amount);

        assertEq(claimAmount, amount);
    }

    //////////////////
    //  removeAsset //
    //////////////////

    function testRemoveAsset(uint256 _amount) public {
        uint256 amount = bound(_amount, 1, MAX_AMOUNT);

        uint256 mintAmount = ScaledAsset.addAsset(assetStatus, amount);

        (uint256 burntAmount, uint256 finalWithdrawAmount) = ScaledAsset.removeAsset(assetStatus, mintAmount, amount);

        assertEq(burntAmount, amount);
        assertEq(finalWithdrawAmount, amount);
    }

    // Cannot remove asset if there is no enough supply
    function testCannotRemoveAsset() public {
        vm.expectRevert(bytes("S0"));
        ScaledAsset.removeAsset(assetStatus, initialMintAmount, ASSET_AMOUNT);
    }

    function testCannotRemoveAsset_IfSuppliedAmountIsZero() public {
        vm.expectRevert(bytes("S3"));
        ScaledAsset.removeAsset(assetStatus, 0, 1);
    }
}
