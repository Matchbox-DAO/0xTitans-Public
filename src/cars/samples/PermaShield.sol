// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./../../interfaces/ICar.sol";

contract PermaShield is ICar {
    function takeYourTurn(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata, /*bananas*/
        uint256 ourCarIndex
    ) external {
        if (monaco.getShieldCost(1) < 500) { 
            monaco.buyShield(1);
        }
        if (monaco.getAccelerateCost(1) < 800) {
            monaco.buyAcceleration(1);
        }
        if (allCars[ourCarIndex].speed == 0) {
            monaco.buyAcceleration(1);
        }
    }

    function sayMyName() external pure returns (string memory) {
        return "PermaShield";
    }
}
