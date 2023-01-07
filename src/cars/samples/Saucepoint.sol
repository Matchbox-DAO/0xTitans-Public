// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./../../interfaces/ICar.sol";

struct Action {
    uint256 accelerate;
    uint256 shell;
    uint256 superShell;
    uint256 shield;
}

/// @notice a test car for balancing
/// @author saucepoint
/// @dev borrowed from functions from MadCar.sol
contract Sauce is ICar {
    // starting tages of the race
    uint256 internal constant MID_GAME = 400;
    uint256 internal constant LATE_GAME = 600;
    uint256 internal constant FLAT_OUT = 800;

    uint256 internal constant ACCEL_FLOOR = 10;

    function updateBalance(Monaco.CarData memory ourCar, uint256 cost) internal pure {
        ourCar.balance -= uint24(cost);
    }

    function hasEnoughBalance(Monaco.CarData memory ourCar, uint256 cost) internal pure returns (bool) {
        return ourCar.balance > cost;
    }

    function buyAsMuchAccelerationAsSensible(Monaco monaco, Monaco.CarData memory ourCar) internal {
        uint256 baseCost = 25;
        uint256 speedBoost = ourCar.speed < 5 ? 5 : ourCar.speed < 10 ? 3 : ourCar.speed < 15 ? 2 : 1;
        uint256 yBoost =
            ourCar.y < 100 ? 1 : ourCar.y < 250 ? 2 : ourCar.y < 500 ? 3 : ourCar.y < 750 ? 4 : ourCar.y < 950 ? 5 : 10;
        uint256 costCurve = baseCost * speedBoost * yBoost;
        // uint costCurve = 25 * ((5 / (ourCar.speed + 1))+1) * ((ourCar.y + 1000) / 500);
        uint256 speedCurve = 8 * ((ourCar.y + 500) / 300);

        while (
            hasEnoughBalance(ourCar, monaco.getAccelerateCost(1)) && monaco.getAccelerateCost(1) < costCurve
                && ourCar.speed < speedCurve
        ) updateBalance(ourCar, monaco.buyAcceleration(1));
    }

    function buyAsMuchAccelerationAsPossible(Monaco monaco, Monaco.CarData memory ourCar) internal {
        while (hasEnoughBalance(ourCar, monaco.getAccelerateCost(1))) updateBalance(ourCar, monaco.buyAcceleration(1));
    }

    function buy1ShellIfPriceIsGood(Monaco monaco, Monaco.CarData memory ourCar) internal {
        // Buy a shell if the price is good but keep a small balance just in case we need to accelerate again
        if (monaco.getShellCost(1) < 1500 && hasEnoughBalance(ourCar, monaco.getShellCost(1) + 500)) {
            updateBalance(ourCar, monaco.buyShell(1));
        }
    }

    function buy1ShellIfSensible(Monaco monaco, Monaco.CarData memory ourCar, uint256 speedOfNextCarAhead) internal {
        if (speedOfNextCarAhead < 5) return;

        // Adjust tolerable price to the urgency of the situation
        uint256 costCurve = 500 * ((ourCar.y + 1000) / 500) * ((speedOfNextCarAhead + 5) / 5);

        if (monaco.getShellCost(1) < costCurve && hasEnoughBalance(ourCar, monaco.getShellCost(1))) {
            updateBalance(ourCar, monaco.buyShell(1));
        }
    }

    function buy1ShellWhateverThePrice(Monaco monaco, Monaco.CarData memory ourCar) internal {
        if (hasEnoughBalance(ourCar, monaco.getShellCost(1))) updateBalance(ourCar, monaco.buyShell(1));
    }

    function takeYourTurn(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata, /*bananas*/
        uint256 ourCarIndex
    ) external {
        Monaco.CarData memory ourCar = allCars[ourCarIndex];
        Monaco.CarData memory leadCar;
        Monaco.CarData memory lagCar;

        if (ourCarIndex == 0) {
            lagCar = allCars[1];
        } else if (ourCarIndex == 1) {
            leadCar = allCars[0];
            lagCar = allCars[2];
        } else {
            leadCar = allCars[1];
        }

        // lead metrics -- data about the car in front. not valid if car is front
        uint256 leadSpeedDelta =
            ourCar.speed < leadCar.speed ? leadCar.speed - ourCar.speed : ourCar.speed - leadCar.speed;
        uint256 leadDistance = ourCar.y < leadCar.y ? leadCar.y - ourCar.y : ourCar.y - leadCar.y;

        // lag metrics -- data about the car behind. not valid if car is last
        // uint256 lagSpeedDelta = ourCar.speed < lagCar.speed ? lagCar.speed - ourCar.speed : ourCar.speed - lagCar.speed;
        // uint256 lagDistance = ourCar.y < lagCar.y ? lagCar.y - ourCar.y : ourCar.y - lagCar.y;

        Action memory action;

        if (monaco.getAccelerateCost(1) < ACCEL_FLOOR) {
            action.accelerate++;
        }

        // decisions based on stages of the race:
        uint256 point = (allCars[0].y + allCars[1].y) / 2;
        if (point < MID_GAME) {
            // early game logic
            if (ourCar.speed == 0) {
                action.accelerate++;
            }

            if (ourCarIndex != 0 && leadSpeedDelta > 5) {
                action.accelerate++;
            }

            if (ourCarIndex == 2 && allCars[0].speed < 5) {
                action.superShell++;
            }
        } else if (MID_GAME <= point && point < LATE_GAME) {
            // mid game logic
            if (ourCarIndex == 2) {
                action.accelerate++;

                if (100 < leadDistance) {
                    action.shell++;
                }

                if (allCars[0].speed < 5) {
                    action.superShell++;
                }
            }
        } else if (LATE_GAME <= point && point < FLAT_OUT) {
            // late game logic
            action.shell++;
        } else {
            // flat out logic
            action.shield++;
            buyAsMuchAccelerationAsSensible(monaco, ourCar);
        }

        if (action.accelerate != 0) monaco.buyAcceleration(action.accelerate);
        if (action.shell != 0) {
            if (ourCarIndex != 0) { 
                if (0 < leadCar.shield) {
                    action.shell++;
                }
            }
            monaco.buyShell(action.shell);
        }
        if (action.shield != 0) monaco.buyShield(action.shield);
        if (action.superShell != 0) {
            if (ourCarIndex != 0) { 
                if (0 < leadCar.shield) {
                    action.superShell++;
                }
            }
            monaco.buySuperShell(action.superShell);
        }
    }

    function sayMyName() external pure returns (string memory) {
        return "Sauce";
    }
}
