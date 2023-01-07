// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import "../src/Monaco.sol";
import "../src/cars/ExampleCar.sol";

import "../src/cars/samples/ThePackage.sol";

import {c000r} from "../src/cars/samples/c000r.sol";
import {PermaShield} from "../src/cars/samples/PermaShield.sol";
import {Sauce} from "../src/cars/samples/Saucepoint.sol";
import {MadCar} from "../src/cars/samples/MadCar.sol";
import {Floor} from "../src/cars/samples/Floor.sol";

uint256 constant CAR_LEN = 3;
uint256 constant ABILITY_LEN = 5;

// Data structure containing information regarding a turn
struct GameTurn{

    address[CAR_LEN] cars;
    uint256[CAR_LEN] balance;
    uint256[CAR_LEN] speed;
    uint256[CAR_LEN] y;
    uint256[CAR_LEN] shield;
    
    uint256[ABILITY_LEN] costs;
    uint256[ABILITY_LEN] bought;
    uint256[] bananas;

    // for this turn
    address currentCar;
    uint256[ABILITY_LEN] usedAbilities;
}

contract MonacoTest is Test {

    error MonacoTest__getCarIndex_carNotFound(address car);
    error MonacoTest__getAbilityCost_abilityNotFound(uint256 abilityIndex);

    Monaco monaco;
    address[CAR_LEN] cars;

    function setUp() public {
        monaco = new Monaco();
    }

    function testGames() public {
        ICar w1 = new PermaShield();
        ICar w2 = new Sauce();
        ICar w3 = new Floor();

        monaco.register(w1);
        monaco.register(w2);
        monaco.register(w3);

        cars[0] = address(w1);
        cars[1] = address(w2);
        cars[2] = address(w3);

        // You can throw these CSV logs into Excel/Sheets/Numbers or a similar tool to visualize a race!
        vm.writeFile(string.concat("logs/", vm.toString(address(w1)), ".csv"), "turns,balance,speed,y,shield\n");
        vm.writeFile(string.concat("logs/", vm.toString(address(w2)), ".csv"), "turns,balance,speed,y,shield\n");
        vm.writeFile(string.concat("logs/", vm.toString(address(w3)), ".csv"), "turns,balance,speed,y,shield\n");
        vm.writeFile("logs/prices.csv", "turns,accelerateCost,shellCost,superShellCost,shieldCost\n");
        vm.writeFile("logs/sold.csv", "turns,acceleratesBought,shellsBought,superShellBought,shieldsBought\n");

        // Create the game log json file
        vm.writeFile("logs/gameLog.json", '{');
        vm.writeLine("logs/gameLog.json", encodeCars());
        vm.writeLine("logs/gameLog.json", ',"turns":[');
        bool firstLine = true;

        while (monaco.state() != Monaco.State.DONE) {

            // Struct that will be added to the gameLog json
            GameTurn memory currentTurn;

            // set the current car
            currentTurn.currentCar = address(monaco.cars(monaco.turns() % CAR_LEN));
            
            // cache the current # abilities sold
            for (uint256 abilityIdx = 0; abilityIdx <= uint256(Monaco.ActionType.SHIELD); ++abilityIdx){
                currentTurn.usedAbilities[abilityIdx] = monaco.getActionsSold(Monaco.ActionType(abilityIdx));
            }

            for (uint256 i=0; i<CAR_LEN; ++i){
                currentTurn.cars[i] = address(monaco.cars(i));
            }

            monaco.play(1);

            // Save the bananas
            currentTurn.bananas = monaco.getAllBananas();
            // Compute the abilities used this turn
            for (uint256 abilityIdx = 0; abilityIdx <= uint256(Monaco.ActionType.SHIELD); ++abilityIdx){
                currentTurn.usedAbilities[abilityIdx] = monaco.getActionsSold(Monaco.ActionType(abilityIdx)) - currentTurn.usedAbilities[abilityIdx];
            }

            Monaco.CarData[] memory allCarData = monaco.getAllCarData();

            for (uint256 i = 0; i < allCarData.length; i++) {
                Monaco.CarData memory car = allCarData[i];

                // Add car data to the current turn
                uint256 carIndex = getCarIndex(address(car.car));
                currentTurn.balance[carIndex] = car.balance;
                currentTurn.speed[carIndex] = car.speed;
                currentTurn.y[carIndex] = car.y;
                currentTurn.shield[carIndex] = car.shield;
                for (uint256 abilityIdx = 0; abilityIdx <= uint256(Monaco.ActionType.SHIELD); ++abilityIdx){
                    currentTurn.costs[abilityIdx] = getAbilityCost(abilityIdx);
                    currentTurn.bought[abilityIdx] = monaco.getActionsSold(Monaco.ActionType(abilityIdx));
                }


                emit log_address(address(car.car));
                emit log_named_uint("balance", car.balance);
                emit log_named_uint("speed", car.speed);
                emit log_named_uint("y", car.y);
                emit log_named_uint("shield", car.shield);

                vm.writeLine(
                    string.concat("logs/", vm.toString(address(car.car)), ".csv"),
                    string.concat(
                        vm.toString(uint256(monaco.turns())),
                        ",",
                        vm.toString(car.balance),
                        ",",
                        vm.toString(car.speed),
                        ",",
                        vm.toString(car.y),
                        ",",
                        vm.toString(car.shield)
                    )
                );

                vm.writeLine(
                    "logs/prices.csv",
                    string.concat(
                        vm.toString(uint256(monaco.turns())),
                        ",",
                        vm.toString(monaco.getAccelerateCost(1)),
                        ",",
                        vm.toString(monaco.getShellCost(1)),
                        ",",
                        vm.toString(monaco.getSuperShellCost(1)),
                        ",",
                        vm.toString(monaco.getShieldCost(1))
                    )
                );

                vm.writeLine(
                    "logs/sold.csv",
                    string.concat(
                        vm.toString(uint256(monaco.turns())),
                        ",",
                        vm.toString(monaco.getActionsSold(Monaco.ActionType.ACCELERATE)),
                        ",",
                        vm.toString(monaco.getActionsSold(Monaco.ActionType.SHELL)),
                        ",",
                        vm.toString(monaco.getActionsSold(Monaco.ActionType.SUPER_SHELL)),
                        ",",
                        vm.toString(monaco.getActionsSold(Monaco.ActionType.SHIELD))
                    )
                );
            }

            vm.writeLine(
                "logs/gameLog.json",
                string.concat(
                    (firstLine) ? "" : ",",
                    encodeJson(currentTurn)
                )
            );

            firstLine = false;
        }

        // Close the json file
        vm.writeLine(
            "logs/gameLog.json",
            "]}"
        );
        emit log_named_uint("Number Of Turns", monaco.turns());
        emit log_named_address("\nWinner", address(monaco.getAllCarData()[0].car));
        emit log_named_address("\tCar 1:", address(w1));
        emit log_named_address("\tCar 2:", address(w2));
        emit log_named_address("\tCar 3:", address(w3));
    }


    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function encodeJson(GameTurn memory turn) view private returns (string memory){
        return string.concat(
            '{',
                '"currentCar":"',
                vm.toString(getCarIndex(turn.currentCar)),
                '",',
                encodeCars(turn),
                ',',
                // pack these together to avoid stack too deep
                encodeCarStats(turn),
                ',',
                encodeCosts(turn),
                ',',
                encodeBought(turn),
                ',',
                encodeUsedAbilities(turn),
            '}'
        );
    }

    function encodeCarStats(GameTurn memory turn) pure private returns (string memory){
        return string.concat(
            encodeBalance(turn),
            ',',
            encodeSpeed(turn),
            ',',
            encodeY(turn),
            ',',
            encodeShield(turn),
            ',',
            encodeBananas(turn)
        );
    }

    function encodeBalance(GameTurn memory turn) pure private returns (string memory){
        return string.concat(
            '"balance":[',
                vm.toString(turn.balance[0]),
                ',',
                vm.toString(turn.balance[1]),
                ',',
                vm.toString(turn.balance[2]),
            ']'
        );
    }

    function encodeSpeed(GameTurn memory turn) pure private returns (string memory){
        return string.concat(
            '"speed":[',
                vm.toString(turn.speed[0]),
                ',',
                vm.toString(turn.speed[1]),
                ',',
                vm.toString(turn.speed[2]),
            ']'
        );
    }

    function encodeY(GameTurn memory turn) pure private returns (string memory){
        return string.concat(
            '"y":[',
                vm.toString(turn.y[0]),
                ',',
                vm.toString(turn.y[1]),
                ',',
                vm.toString(turn.y[2]),
            ']'
        );
    }

    function encodeShield(GameTurn memory turn) pure private returns (string memory){
        return string.concat(
            '"shield":[',
                vm.toString(turn.shield[0]),
                ',',
                vm.toString(turn.shield[1]),
                ',',
                vm.toString(turn.shield[2]),
            ']'
        );
    }

    function encodeCosts(GameTurn memory turn) pure private returns (string memory){
        return string.concat(
            '"costs":[',
                vm.toString(turn.costs[0]),
                ',',
                vm.toString(turn.costs[1]),
                ',',
                vm.toString(turn.costs[2]),
                ',',
                vm.toString(turn.costs[3]),
                ',',
                vm.toString(turn.costs[4]),
            ']'
        );
    }

    function encodeBought(GameTurn memory turn) pure private returns (string memory){
        return string.concat(
            '"bought":[',
                vm.toString(turn.bought[0]),
                ',',
                vm.toString(turn.bought[1]),
                ',',
                vm.toString(turn.bought[2]),
                ',',
                vm.toString(turn.bought[3]),
                ',',
                vm.toString(turn.bought[4]),
            ']'
        );
    }

    function encodeUsedAbilities(GameTurn memory turn) pure private returns (string memory){
        return string.concat(
            '"usedAbilities":[',
                vm.toString(turn.usedAbilities[0]),
                ',',
                vm.toString(turn.usedAbilities[1]),
                ',',
                vm.toString(turn.usedAbilities[2]),
                ',',
                vm.toString(turn.usedAbilities[3]),
                ',',
                vm.toString(turn.usedAbilities[4]),
            ']'
        );
    }

    function encodeBananas(GameTurn memory turn) pure private returns (string memory){
        string memory bananas = '"bananas":[';
        uint256 len = turn.bananas.length;
        for (uint256 i=0; i < len; ++i){
            bananas = string.concat(
                bananas,
                (i>0)?",":"",
                vm.toString(turn.bananas[i])
            );
        }

        bananas = string.concat(
            bananas,
            ']'
        );

        return bananas;
    }


    function encodeCars() view private returns (string memory){
        return string.concat(
            '"cars":["',
            vm.toString(cars[0]),
            '","',
            vm.toString(cars[1]),
            '","',
            vm.toString(cars[2]),
            '"]'
        );
    }

    function encodeCars(GameTurn memory turn) view private returns (string memory){
        return string.concat(
            '"cars":["',
            vm.toString(getCarIndex(turn.cars[0])),
            '","',
            vm.toString(getCarIndex(turn.cars[1])),
            '","',
            vm.toString(getCarIndex(turn.cars[2])),
            '"]'
        );
    }

    function getCarIndex(address car) view private returns (uint256){
        for (uint256 i=0; i<3; ++i){
            if (cars[i] == car) return i;
        }

        revert MonacoTest__getCarIndex_carNotFound(car);
    }

    function getAbilityCost(uint256 abilityIdx) view private returns (uint256){
        if (abilityIdx == 0) return monaco.getAccelerateCost(1);
        if (abilityIdx == 1) return monaco.getShellCost(1);
        if (abilityIdx == 2) return monaco.getSuperShellCost(1);
        if (abilityIdx == 3) return monaco.getBananaCost();
        if (abilityIdx == 4) return monaco.getShieldCost(1);

        revert MonacoTest__getAbilityCost_abilityNotFound(abilityIdx);
    }
}
