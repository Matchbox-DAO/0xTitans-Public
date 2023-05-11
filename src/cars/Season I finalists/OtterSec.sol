// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/* Originally published at 
https://github.com/otter-sec/battle-of-titans/blob/main/src/cars/ExampleCar.sol

Created by Robert Chen from OtterSec

 */

import "./../../interfaces/ICar.sol";

contract OtterSec is ICar {
    function takeYourTurn(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata /*bananas*/,
        uint256 ourCarIndex
    ) external override {
        Monaco.CarData memory ourCar = allCars[ourCarIndex];

        if (allCars[0].y < 700 && ourCar.balance > 10000) {
            uint banCost = monaco.getBananaCost();
            if (banCost < 10) {
                ourCar.balance -= uint24(monaco.buyBanana());
            }

            bool getShell = false;
            bool getSuperShell = false;

            uint256 shellCost = monaco.getShellCost(1);
            uint256 superShellCost = monaco.getSuperShellCost(1);
            if (shellCost <= 50) {
                getShell = true;
            }
            if (superShellCost <= 50) {
                getSuperShell = true;
            }
            if (ourCarIndex != 0 && allCars[ourCarIndex - 1].speed > 20 && shellCost <= 500) {
                getShell = true;
            }
            if (allCars[0].speed > 20 && superShellCost <= 500) {
                getSuperShell = true;
            }
            if (getSuperShell && ourCar.balance > superShellCost) {
                ourCar.balance -= uint24(monaco.buySuperShell(1));
                if (shellCost <= 50) {
                    ourCar.balance -= uint24(monaco.buyShell(1));
                }
            } else if (getShell && ourCar.balance > shellCost) {
                ourCar.balance -= uint24(monaco.buyShell(1));
            }
            return;
        }

        // Win if possible.
        if (
            ourCar.y > 850 &&
            ourCar.balance >=
            monaco.getAccelerateCost(1000 - (ourCar.y + ourCar.speed))
        ) {
            monaco.buyAcceleration(1000 - (ourCar.y + ourCar.speed));
            return;
        }

        bool getShell = false;
        bool getSuperShell = false;

        uint256 shellCost = monaco.getShellCost(1);
        uint256 superShellCost = monaco.getSuperShellCost(1);

        if (shellCost <= 100) {
            getShell = true;
        }
        if (superShellCost <= 100) {
            getSuperShell = true;
        }

        if (ourCarIndex != 0) {
            if (allCars[0].y + allCars[0].speed >= 1000) {
                getShell = allCars[0].shield != 0 && ourCarIndex == 1;
                getSuperShell = true;
            }

            if (
                allCars[ourCarIndex - 1].speed >= 8
            ) {
                if (superShellCost <= 500) getSuperShell = true;
                else if (shellCost <= 500 && allCars[ourCarIndex - 1].shield == 0) getShell = true;
            }
            if (
                ourCar.balance > 3500 && 
                allCars[ourCarIndex - 1].speed >= 25
            ) {
                if (superShellCost <= 1500) getSuperShell = true;
                else if (shellCost <= 1500 && allCars[ourCarIndex - 1].shield == 0) getShell = true;
            }
            if (
                ourCar.balance > 6000 && 
                allCars[ourCarIndex - 1].speed >= 75
            ) {
                if (superShellCost <= 4000) getSuperShell = true;
                else if (shellCost <= 4000 && allCars[ourCarIndex - 1].shield == 0) getShell = true;
            }
        }
        
        if (ourCarIndex == 2) {
            if (
                superShellCost <= 500 && 
                ourCar.balance > 2000 && 
                (allCars[0].speed > 8 || allCars[1].speed > 8)
            ) {
                getSuperShell = true;
            }
            if (
                superShellCost <= 1000 && 
                ourCar.balance > 4000 && 
                (allCars[0].speed > 25 || allCars[1].speed > 25)
            ) {
                getSuperShell = true;
            }
        }

        if (ourCar.balance > 10000 && ourCar.speed > 50) {
            if (superShellCost <= 2000) {
                getSuperShell = true;
            }
            if (shellCost <= 2000) {
                getShell = true;
            }
        }

        if (getSuperShell && ourCar.balance > superShellCost) {
            ourCar.balance -= uint24(monaco.buySuperShell(1));
        } else if (getShell && ourCar.balance > shellCost) {
            ourCar.balance -= uint24(monaco.buyShell(1));
        }

        uint maxCost = 250;
        if (
            (ourCar.balance > 12000) ||
            (ourCar.balance > 8000 && ourCar.y > 600) ||
            (ourCar.balance > 5000 && ourCar.y > 800)
        ) {
            maxCost = 500;
        }
        if (
            (ourCar.balance > 2500 && ourCar.y > 900)
        ) {
            maxCost = 500;
        }

        if (ourCar.balance < 1000) {
            maxCost = 100;
        }

        uint i = 0;
        uint prevI = 0;
        {
            uint cost = 0;
            while (i < 200 && cost < maxCost && cost <= ourCar.balance) {
                prevI = i;
                if (i < 10) i++;
                else if (i < 20) i += 5;
                else i += 50;
                cost = monaco.getAccelerateCost(i);
            }
        }

        if (prevI >= 3) {
            uint cost = monaco.getAccelerateCost(prevI);
            if (ourCar.balance >= cost) {
                ourCar.balance -= uint24(monaco.buyAcceleration(prevI));
                ourCar.speed += uint32(prevI);
            }
        }

        if (ourCar.speed < 3) {
            if (ourCar.balance > 1000 && monaco.getAccelerateCost(1) <= 100) {
                ourCar.balance -= uint24(monaco.buyAcceleration(1));
                ourCar.speed += 1;
            }
        }

        if (ourCar.balance > 1000 && ourCar.shield == 0) {
            bool getShield = false;
            uint shieldCost = monaco.getShieldCost(2);
            if (ourCarIndex == 0) {
                if (shieldCost < 100) getShield = true;
            } else if (ourCarIndex == 1) {
                if (shieldCost < 30) getShield = true;
            } else {
                if (shieldCost < 20) getShield = true;
            }
            if (getShield && ourCar.balance > shieldCost) {
                ourCar.balance -= uint24(monaco.buyShield(2));
            }
        }

    }

    function sayMyName() external pure returns (string memory) {
        return "ExampleCar";
    }
}
