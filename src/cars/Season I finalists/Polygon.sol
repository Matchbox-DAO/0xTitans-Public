// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./../interfaces/ICar.sol";

enum Status {
    EARLY_GAME,
    LATE_GAME
}

contract PolygonCarV31 is ICar {
    uint256 internal constant BANANA_MAX = 400;
    uint256 ACCEL_MAX = 50;
    uint256 SUPER_SHELL_MAX = 300;
    uint256 SHELL_MAX = 150;
    uint256 SHIELD_MAX = 100;

    uint256 internal constant LATE_GAME = 900;

    Status status = Status.EARLY_GAME;
    uint256 bananasAhead;
    Monaco.CarData[] cars;
    uint256 aheadIndex;
    uint256 remainingBalance;
    uint256 speed = 0;
    bool bananaBought = false;
    bool superShellBought = false;
    uint256 shields = 0;

    modifier setUp(
        Monaco.CarData[] calldata allCars,
        uint256[] calldata bananas,
        uint256 ourCarIndex
    ) {
        {
            speed = allCars[ourCarIndex].speed;
            shields = allCars[ourCarIndex].shield;
            remainingBalance = allCars[ourCarIndex].balance;
            bananasAhead = 0;
            // setup cars in order
            (uint256 firstIndex, uint256 secondIndex) = (
                (ourCarIndex + 1) % 3,
                (ourCarIndex + 2) % 3
            );
            (
                Monaco.CarData memory firstCar,
                Monaco.CarData memory secondCar
            ) = allCars[firstIndex].y > allCars[secondIndex].y
                    ? (allCars[firstIndex], allCars[secondIndex])
                    : (allCars[secondIndex], allCars[firstIndex]);
            cars.push(secondCar);
            cars.push(firstCar);

            uint256 maxY = allCars[ourCarIndex].y > firstCar.y
                ? allCars[ourCarIndex].y
                : firstCar.y;
            if (maxY > LATE_GAME) {
                ACCEL_MAX = 1000;
                SUPER_SHELL_MAX = 1200;
                SHELL_MAX = 900;
                SHIELD_MAX = 600;
                status = Status.LATE_GAME;
            } else {
                status = Status.EARLY_GAME;
            }

            // get all bananas in our way
            if (ourCarIndex != 0) {
                // we are not in first place
                if (ourCarIndex == 1) {
                    aheadIndex = 1;
                }
                uint256 ourCarPosition = allCars[ourCarIndex].y;
                uint256 nextCarPosition = ourCarIndex == 1
                    ? firstCar.y
                    : secondCar.y;
                for (uint256 i = 0; i < bananas.length; i++) {
                    if (bananas[i] > ourCarPosition) {
                        ++bananasAhead;
                    }
                    if (bananas[i] > nextCarPosition) {
                        break;
                    }
                }
            } else {
                aheadIndex = 2;
            }
        }
        _;
        delete cars;
        aheadIndex = 0;
        remainingBalance = 0;
        speed = 0;
        shields = 0;
        bananaBought = false;
        superShellBought = false;
        ACCEL_MAX = 50;
        SUPER_SHELL_MAX = 300;
        SHELL_MAX = 150;
        SHIELD_MAX = 150;
    }

    function takeYourTurn(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata bananas,
        uint256 ourCarIndex
    ) external override setUp(allCars, bananas, ourCarIndex) {
        Monaco.CarData memory ourCar = allCars[ourCarIndex];

        getBananasOutOfTheWay(monaco);

        // Win if possible.
        if (
            ourCar.y > 850 &&
            remainingBalance >=
            monaco.getAccelerateCost((1000 - (ourCar.y + speed)))
        ) {
            monaco.buyAcceleration((1000 - (ourCar.y + speed)));
            return;
        }

        // spend it all in the end
        if ((ourCar.y > 985 || cars[1].y > 985) && remainingBalance > 300) {
            buyAccelerationFor(monaco, remainingBalance / 2);
        } else {
            buyAcceleration(monaco);
        }

        if (status == Status.LATE_GAME) {
            lateGameStrat(monaco, ourCarIndex);
        }

        if (shields == 0) buyShield(monaco, 1);
    }

    function buyFreeStuff(Monaco monaco) private {
        if (monaco.getAccelerateCost(1) == 0) {
            monaco.buyAcceleration(1);
            speed += 1;
        }
        if (monaco.getShieldCost(1) == 0) {
            monaco.buyShield(1);
            shields += 1;
        }
        if (monaco.getBananaCost() == 0) {
            monaco.buyBanana();
            bananaBought = true;
        }
        if (monaco.getSuperShellCost(1) == 0) {
            monaco.buySuperShell(1);
            superShellBought = true;
        }
        if (monaco.getShellCost(1) == 0) {
            monaco.buyShell(1);
            if (bananasAhead > 0) {
                --bananasAhead;
                return;
            }
            if (aheadIndex != 2) {
                if (cars[aheadIndex].shield > 0) {
                    --cars[aheadIndex].shield;
                    return;
                }
                cars[aheadIndex].speed = 1;
                return;
            }
        }
    }

    function buyAccelerationFor(Monaco monaco, uint256 target) private {
        buyFreeStuff(monaco);
        uint256 price = 0;
        uint256 i = 0;
        while (price <= target) {
            ++i;
            price = monaco.getAccelerateCost(i);
            if (gasleft() < 1_000_000) break;
        }
        --i;
        if (i > 0) {
            remainingBalance -= monaco.buyAcceleration(i);
            speed += i;
        }
    }

    function buyAcceleration(Monaco monaco) private {
        uint256 targetPurchase;
        if (status == Status.EARLY_GAME) {
            targetPurchase = 60;
        } else {
            targetPurchase = 500;
        }
        if (remainingBalance < targetPurchase) {
            buyFreeStuff(monaco);
            return;
        }
        buyAccelerationFor(monaco, targetPurchase);
    }

    function getBananasOutOfTheWay(Monaco monaco) private {
        uint256 remainingBananas = bananasAhead;
        if (remainingBananas == 0) return;
        uint256 shellCost = monaco.getShellCost(remainingBananas);
        uint256 superShellCost = monaco.getSuperShellCost(1);
        if (shellCost > superShellCost) {
            // buy super shell
            buySuperShell(monaco);
        } else {
            // buy shells
            buyShell(monaco, remainingBananas);
        }
    }

    function lateGameStrat(Monaco monaco, uint256 ourCarIndex) private {
        Monaco.CarData storage first = cars[1];
        Monaco.CarData storage second = cars[0];

        uint256 maxSpeed = first.speed > second.speed
            ? first.speed
            : second.speed;

        // Handle cases where speed is too low and we are in last
        if (maxSpeed >= speed && aheadIndex == 0) {
            if (!buyAcceleration(monaco, maxSpeed + 1 - speed)) {
                buyAcceleration(monaco, 3);
            }
        }

        if (ourCarIndex != 0) {
            // handle cases when we are second or last
            uint256 shellCost = monaco.getShellCost(1);
            uint256 superShellCost = monaco.getSuperShellCost(1);

            if (first.y >= 990) {
                SHELL_MAX = remainingBalance / 2;
                SUPER_SHELL_MAX = remainingBalance / 2;
            }

            if (
                first.shield != 0 ||
                shellCost >= superShellCost ||
                ourCarIndex == 2
            ) {
                buySuperShell(monaco);
            } else {
                buyShell(monaco, 1);
            }
        }
    }

    function buyAcceleration(
        Monaco monaco,
        uint256 amount
    ) private returns (bool) {
        uint256 cost = monaco.getAccelerateCost(amount);
        // don't buy if price exceeds maximum
        if (cost > (ACCEL_MAX * amount)) return false;
        if (cost < remainingBalance) {
            remainingBalance -= monaco.buyAcceleration(amount);
            speed += amount;
            return true;
        }
        return false;
    }

    function buyShield(Monaco monaco, uint256 amount) private returns (bool) {
        if (shields >= 5) return false;
        uint cost = monaco.getShieldCost(amount);
        if (cost > (SHIELD_MAX * amount)) return false;
        if (cost < remainingBalance) {
            remainingBalance -= monaco.buyShield(amount);
            shields += amount;
            return true;
        }
        return false;
    }

    function buyBanana(Monaco monaco) private returns (bool) {
        if (aheadIndex == 0 || bananaBought) return false;
        uint cost = monaco.getBananaCost();
        if (cost > BANANA_MAX) return false;
        if (cost < remainingBalance) {
            remainingBalance -= monaco.buyBanana();
            bananaBought = true;
            return true;
        }
        return false;
    }

    function buyShell(Monaco monaco, uint256 amount) private returns (bool) {
        if (aheadIndex == 2) return false;
        uint remainingBanananas = bananasAhead;
        uint carAheadSpeed = cars[aheadIndex].speed;
        uint remainingShields = cars[aheadIndex].shield;
        if (
            carAheadSpeed == 1 &&
            remainingBanananas == 0 &&
            remainingShields == 0
        ) return false;
        uint cost = monaco.getShellCost(amount);
        if (cost > (SHELL_MAX * amount)) return false;
        if (cost < remainingBalance) {
            remainingBalance -= monaco.buyShell(amount);
            if (remainingBanananas > 0) {
                if (remainingBanananas >= amount) {
                    bananasAhead -= amount;
                    return true;
                } else {
                    amount -= remainingBanananas;
                    bananasAhead = 0;
                }
            }
            if (remainingShields > 0) {
                if (remainingShields >= amount) {
                    cars[aheadIndex].shield -= uint32(amount);
                    return true;
                } else {
                    amount -= remainingShields;
                    cars[aheadIndex].shield = 0;
                }
            }
            cars[aheadIndex].speed = 1;
            return true;
        }
        return false;
    }

    function buySuperShell(Monaco monaco) private returns (bool) {
        if (aheadIndex == 2 || superShellBought) return false;
        uint256 tmpSpeed = 1;
        for (uint i = aheadIndex; i < 2; i++) {
            if (cars[i].speed > tmpSpeed) tmpSpeed = cars[i].speed;
        }
        if (tmpSpeed == 1) return false;
        uint cost = monaco.getSuperShellCost(1);
        if (cost > SUPER_SHELL_MAX) return false;
        if (cost < remainingBalance) {
            remainingBalance -= monaco.buySuperShell(1);
            superShellBought = true;
            bananasAhead = 0;
            for (uint i = aheadIndex; i < 2; i++) {
                cars[i].speed = 1;
            }
            return true;
        }
        return false;
    }

    function sayMyName() external pure returns (string memory) {
        return "Need for Gas";
    }
}
