// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./../../interfaces/ICar.sol";

contract Floor is ICar {

    uint256 internal constant ACCEL_FLOOR = 15;
    uint256 internal constant SHELL_FLOOR = 200;
    uint256 internal constant SUPER_SHELL_FLOOR = 300;
    uint256 internal constant SHIELD_FLOOR = 400;

    function takeYourTurn(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata, /*bananas*/
        uint256 ourCarIndex
    ) external {
        if (monaco.getAccelerateCost(1) < ACCEL_FLOOR) monaco.buyAcceleration(1);
        if (monaco.getShellCost(1) < SHELL_FLOOR) monaco.buyShell(1);
        if (ourCarIndex == 2 && monaco.getSuperShellCost(1) < SUPER_SHELL_FLOOR) monaco.buySuperShell(1);
        if (ourCarIndex != 2 && monaco.getShieldCost(1) < SHIELD_FLOOR) monaco.buyShield(1);
    }

    function sayMyName() external pure returns (string memory) {
        return "Floor";
    }
}
