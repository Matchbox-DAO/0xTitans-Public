// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./../../interfaces/ICar.sol";

contract MadCar is ICar {
    function updateBalance(Monaco.CarData memory ourCar, uint cost) pure internal {
        ourCar.balance -= uint24(cost);
    }

    function hasEnoughBalance(Monaco.CarData memory ourCar, uint cost) pure internal returns (bool) {
        return ourCar.balance > cost;
    }

    function buyAsMuchAccelerationAsSensible(Monaco monaco, Monaco.CarData memory ourCar) internal {
        uint baseCost = 25;
        uint speedBoost = ourCar.speed < 5 ? 5 : ourCar.speed < 10 ? 3 : ourCar.speed < 15 ? 2 : 1;
        uint yBoost = ourCar.y < 100 ? 1 : ourCar.y < 250 ? 2 : ourCar.y < 500 ? 3 : ourCar.y < 750 ? 4 : ourCar.y < 950 ? 5 : 10;
        uint costCurve = baseCost * speedBoost * yBoost;
        // uint costCurve = 25 * ((5 / (ourCar.speed + 1))+1) * ((ourCar.y + 1000) / 500);
        uint speedCurve = 8 * ((ourCar.y + 500) / 300);

        while(hasEnoughBalance(ourCar, monaco.getAccelerateCost(1)) && monaco.getAccelerateCost(1) < costCurve && ourCar.speed < speedCurve) updateBalance(ourCar, monaco.buyAcceleration(1));
    }

    function buyAsMuchAccelerationAsPossible(Monaco monaco, Monaco.CarData memory ourCar) internal {
        while(hasEnoughBalance(ourCar, monaco.getAccelerateCost(1))) updateBalance(ourCar, monaco.buyAcceleration(1));
    }

    function buy1ShellIfPriceIsGood(Monaco monaco, Monaco.CarData memory ourCar) internal {
        // Buy a shell if the price is good but keep a small balance just in case we need to accelerate again
        if(monaco.getShellCost(1) < 1500 && hasEnoughBalance(ourCar, monaco.getShellCost(1) + 500)) updateBalance(ourCar, monaco.buyShell(1));
    }

    function buy1ShellIfSensible(Monaco monaco, Monaco.CarData memory ourCar, uint speedOfNextCarAhead) internal {
        if(speedOfNextCarAhead < 5) return;

        // Adjust tolerable price to the urgency of the situation
        uint costCurve = 500 * ((ourCar.y + 1000) / 500) * ((speedOfNextCarAhead + 5) / 5);

        if(monaco.getShellCost(1) < costCurve && hasEnoughBalance(ourCar, monaco.getShellCost(1))) updateBalance(ourCar, monaco.buyShell(1));
    }

    function buy1ShellWhateverThePrice(Monaco monaco, Monaco.CarData memory ourCar) internal {
        if(hasEnoughBalance(ourCar, monaco.getShellCost(1))) updateBalance(ourCar, monaco.buyShell(1));
    }

    function takeYourTurn(Monaco monaco, Monaco.CarData[] calldata allCars, uint256[] calldata /*bananas*/,uint256 ourCarIndex) external {
        Monaco.CarData memory ourCar = allCars[ourCarIndex];
        Monaco.CarData memory otherCar1 = allCars[ourCarIndex == 0 ? 1 : 0];
        Monaco.CarData memory otherCar2 = allCars[ourCarIndex == 2 ? 1 : 2];

        bool isCar1Ahead = otherCar1.y > ourCar.y;
        bool isCar2Ahead = otherCar2.y > ourCar.y;
        bool hasCarAhead = isCar1Ahead || isCar2Ahead;
        // bool hasCarBehind = !isCar1Ahead || !isCar2Ahead;
        // bool isLastPosition = !hasCarBehind;
        // bool is2ndPosition = (isCar1Ahead && !isCar2Ahead) || (isCar2Ahead && !isCar1Ahead);
        bool is1stPosition = !isCar1Ahead && !isCar2Ahead;
        // bool isCar1NextAhead = isCar1Ahead && !isCar2Ahead;
        // bool isCar2NextAhead = isCar2Ahead && !isCar1Ahead;
        // uint distanceToCar1 = isCar1Ahead ? otherCar1.y - ourCar.y : ourCar.y - otherCar1.y;
        // uint distanceToCar2 = isCar2Ahead ? otherCar2.y - ourCar.y : ourCar.y - otherCar2.y;
        // uint distanceToNextCarAhead = is1stPosition ? 0 : isCar1Ahead ? distanceToCar1 : distanceToCar2;
        // uint distanceToNextCarBehind = isLastPosition ? 0 : isCar1NextAhead ? distanceToCar2 : distanceToCar1;
        Monaco.CarData memory nextCarAhead = is1stPosition ? ourCar : isCar1Ahead ? otherCar1 : otherCar2;

        if(hasCarAhead) buy1ShellIfSensible(monaco, ourCar, nextCarAhead.speed);
        buy1ShellIfPriceIsGood(monaco, ourCar);
        buyAsMuchAccelerationAsSensible(monaco, ourCar);
    }

    function sayMyName() external pure returns (string memory) {
        return "MadCar";
    }
}
