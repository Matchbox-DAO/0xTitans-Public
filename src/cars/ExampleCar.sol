// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./../interfaces/ICar.sol";

contract ExampleCar is ICar {
    function takeYourTurn(Monaco monaco, Monaco.CarData[] calldata allCars, uint256[] calldata /*bananas*/, uint256 ourCarIndex) external override {
        Monaco.CarData memory ourCar = allCars[ourCarIndex];

        // If we can afford to accelerate 3 times, let's do it.
        if (ourCar.balance > monaco.getAccelerateCost(3)) ourCar.balance -= uint24(monaco.buyAcceleration(3));

        if(ourCarIndex + 1 == allCars.length && ourCar.balance > monaco.getSuperShellCost(1)){
            // If we are the last and we can afford it, shell everyone.
            monaco.buySuperShell(1); // This will instantly every car in front of us' speed to 1.
        } else if (ourCarIndex != 0 && allCars[ourCarIndex - 1].speed > ourCar.speed && ourCar.balance > monaco.getShellCost(1)) {
            // If we're not in the lead (index 0) + the car ahead of us is going faster + we can afford a shell, smoke em.
            monaco.buyShell(1); // This will instantly set the car in front of us' speed to 1.
        } else if (ourCar.shield == 0){
            // If we are in the lead, are not shielded and we can afford to shield ourselves, just do it.
            if (ourCarIndex == 0 && ourCar.balance > monaco.getShieldCost(1)){
                monaco.buyShield(1);
            }
        }
    }

    function sayMyName() external pure returns (string memory) {
        return "ExampleCar";
    }
}
