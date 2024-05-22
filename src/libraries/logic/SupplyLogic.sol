// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

import {SafeTransferLib} from "@solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "@solmate/src/tokens/ERC20.sol";
import {IPredyPool} from "../../interfaces/IPredyPool.sol";
import {ISupplyToken} from "../../interfaces/ISupplyToken.sol";
import {DataType} from "../DataType.sol";
import {Perp} from "../Perp.sol";
import {ScaledAsset} from "../ScaledAsset.sol";
import {ApplyInterestLib} from "../ApplyInterestLib.sol";
import {GlobalDataLibrary} from "../../types/GlobalData.sol";

library SupplyLogic {
    using ScaledAsset for ScaledAsset.AssetStatus;
    using GlobalDataLibrary for GlobalDataLibrary.GlobalData;
    using SafeTransferLib for ERC20;

    event TokenSupplied(address indexed account, uint256 pairId, bool isStable, uint256 suppliedAmount);
    event TokenWithdrawn(address indexed account, uint256 pairId, bool isStable, uint256 finalWithdrawnAmount);

    function supply(GlobalDataLibrary.GlobalData storage globalData, uint256 _pairId, uint256 _amount, bool _isStable)
        external
        returns (uint256 mintAmount)
    {
        // Checks pair exists
        globalData.validate(_pairId);
        // Checks amount is not 0
        if (_amount <= 0) {
            revert IPredyPool.InvalidAmount();
        }
        // Updates interest rate related to the pair
        ApplyInterestLib.applyInterestForToken(globalData.pairs, _pairId);

        DataType.PairStatus storage pair = globalData.pairs[_pairId];

        if (_isStable) {
            mintAmount = receiveTokenAndMintBond(pair.quotePool, _amount);
        } else {
            mintAmount = receiveTokenAndMintBond(pair.basePool, _amount);
        }

        emit TokenSupplied(msg.sender, pair.id, _isStable, _amount);
    }

    function receiveTokenAndMintBond(Perp.AssetPoolStatus storage _pool, uint256 _amount)
        internal
        returns (uint256 mintAmount)
    {
        mintAmount = _pool.tokenStatus.addAsset(_amount);

        ERC20(_pool.token).safeTransferFrom(msg.sender, address(this), _amount);

        ISupplyToken(_pool.supplyTokenAddress).mint(msg.sender, mintAmount);
    }

    function withdraw(GlobalDataLibrary.GlobalData storage globalData, uint256 _pairId, uint256 _amount, bool _isStable)
        external
        returns (uint256 finalburntAmount, uint256 finalWithdrawalAmount)
    {
        // Checks pair exists
        globalData.validate(_pairId);
        // Checks amount is not 0
        require(_amount > 0, "AZ");
        // Updates interest rate related to the pair
        ApplyInterestLib.applyInterestForToken(globalData.pairs, _pairId);

        DataType.PairStatus storage pair = globalData.pairs[_pairId];

        if (_isStable) {
            (finalburntAmount, finalWithdrawalAmount) = burnBondAndTransferToken(pair.quotePool, _amount);
        } else {
            (finalburntAmount, finalWithdrawalAmount) = burnBondAndTransferToken(pair.basePool, _amount);
        }

        emit TokenWithdrawn(msg.sender, pair.id, _isStable, finalWithdrawalAmount);
    }

    function burnBondAndTransferToken(Perp.AssetPoolStatus storage _pool, uint256 _amount)
        internal
        returns (uint256 finalburntAmount, uint256 finalWithdrawalAmount)
    {
        address supplyTokenAddress = _pool.supplyTokenAddress;

        (finalburntAmount, finalWithdrawalAmount) =
            _pool.tokenStatus.removeAsset(ERC20(supplyTokenAddress).balanceOf(msg.sender), _amount);

        ISupplyToken(supplyTokenAddress).burn(msg.sender, finalburntAmount);

        ERC20(_pool.token).safeTransfer(msg.sender, finalWithdrawalAmount);
    }
}
