// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./../interfaces/ICar.sol";

contract ExampleCar is ICar {
    function takeYourTurn(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata /*bananas*/,
        uint256 ourCarIndex
    ) external override {
        Monaco.CarData memory ourCar = allCars[ourCarIndex];
        // If we can afford to accelerate 3 times, let's do it.
        if (ourCar.balance > monaco.getAccelerateCost(3))
            ourCar.balance -= uint24(monaco.buyAcceleration(3));

        if (
            ourCarIndex + 1 == allCars.length &&
            ourCar.balance > monaco.getSuperShellCost(1)
        ) {
            // If we are the last and we can afford it, shell everyone.
            monaco.buySuperShell(1); // This will instantly set every car in front of us' speed to 1 and destroys bananas.
        } else if (
            ourCarIndex != 0 &&
            allCars[ourCarIndex - 1].speed > ourCar.speed &&
            ourCar.balance > monaco.getShellCost(1)
        ) {
            // If we're not in the lead (index 0) + the car ahead of us is going faster + we can afford a shell, smoke em.
            monaco.buyShell(1); // This will instantly set the car in front of us' speed to 1 or hit a banana.
        } else if (ourCarIndex == 0) {
            // If we are in the lead, either shield or spawn a banana.
            uint256 bananaCost = monaco.getBananaCost();
            uint256 shieldCost = monaco.getShieldCost(2);
            bool useBanana = shieldCost > bananaCost;

            if (ourCar.balance >= min(bananaCost, shieldCost)) {
                if (useBanana) {
                    monaco.buyBanana();
                } else {
                    monaco.buyShield(2);
                }
            }
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }

    function sayMyName() external pure returns (string memory) {
        return "ExampleCar";
    }
}
