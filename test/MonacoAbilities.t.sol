// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import {Monaco} from "../src/Monaco.sol";
import {ICar} from "../src/interfaces/ICar.sol";
import "../src/cars/ExampleCar.sol";
import {MockCar} from "./utils/MockCar.sol";

contract MockMonaco is Monaco {
    // Mock function to set the current state for a car
    function setCarData(ICar car, CarData memory data) public {
        getCarData[car] = data;
    }

    // Mock function to add bananas
    function addBanana(uint256 atPosition) public {
        bananas.push(atPosition);
        bananas = getBananasSortedByY();
    }
}

contract MonacoAbilitiesTest is Test {
    MockMonaco monaco;

    MockCar public mockCar1;
    MockCar public mockCar2;
    MockCar public mockCar3;

    function setUp() public {
        monaco = new MockMonaco();

        mockCar1 = new MockCar();
        mockCar2 = new MockCar();
        mockCar3 = new MockCar();

        monaco.register(mockCar1);
        monaco.register(mockCar2);
        monaco.register(mockCar3);
    }

    function test_storageOverwrite(
        uint32 balance,
        uint32 speed,
        uint32 shield,
        uint32 y
    ) public {
        monaco.setCarData(
            mockCar1,
            Monaco.CarData({
                balance: balance,
                car: mockCar1,
                speed: speed,
                shield: shield,
                y: y
            })
        );

        (
            uint32 balance_,
            uint32 speed_,
            uint32 y_,
            uint32 shield_,
            ICar car_
        ) = monaco.getCarData(mockCar1);

        assertEq(balance, balance_);
        assertEq(speed, speed_);
        assertEq(shield, shield_);
        assertEq(y, y_);
        assertEq(address(mockCar1), address(car_));
    }

    function testAction_accelerate() public {
        uint256 amount = 5;

        (uint32 balance, , uint32 preMoveY, , ) = monaco.getCarData(mockCar1);

        try monaco.getAccelerateCost(amount) returns (uint256 cost) {
            if (cost > balance) return;
        } catch {
            return;
        }

        mockCar1.setAction(Monaco.ActionType.ACCELERATE, amount);

        monaco.play(3);

        (, , uint32 postMoveY, , ) = monaco.getCarData(mockCar1);

        assertEq(postMoveY, preMoveY + amount);
    }

    function testAction_shell() public {
        // Position the first car ahead
        monaco.setCarData(
            mockCar1,
            Monaco.CarData({
                balance: 15000,
                car: mockCar1,
                speed: 100,
                shield: 0,
                y: 200
            })
        );

        mockCar2.setAction(Monaco.ActionType.SHELL, 1);

        monaco.play(1);

        (, uint32 speed, uint32 y, , ) = monaco.getCarData(mockCar1);

        assertEq(speed, 1); // Shelled speed
        assertEq(y, 200 + speed);
    }

    function testAction_shield() public {
        // Position the first car ahead
        uint32 car2Start = 200;
        uint32 car2Speed = 100;
        monaco.setCarData(
            mockCar2,
            Monaco.CarData({
                balance: 15000,
                car: mockCar2,
                speed: car2Speed,
                shield: 0,
                y: car2Start
            })
        );
        mockCar2.setAction(Monaco.ActionType.SHIELD, 2);

        uint32 car1Start = 0;
        uint32 car1Speed = 100;
        monaco.setCarData(
            mockCar1,
            Monaco.CarData({
                balance: 15000,
                car: mockCar1,
                speed: car1Speed,
                shield: 0,
                y: car1Start
            })
        );
        mockCar1.setAction(Monaco.ActionType.SHELL, 1);

        // Simulate one move per car -> 3 turns
        monaco.play(3);

        (, uint32 speed1, uint32 y1, , ) = monaco.getCarData(mockCar1);
        (, uint32 speed2, uint32 y2, , ) = monaco.getCarData(mockCar2);

        // car 2 is shielded and ahead
        // car 1 launches shell
        assertEq(speed1, 1);
        assertEq(y1, car1Start + 201); // 2 turns at full speed, 1 with reduced
        assertEq(speed2, car2Speed);
        assertEq(y2, car2Start + 300); // 3 turns at full speed
    }

    function testAction_shield_duration() public {
        uint256 turns = 5;
        mockCar2.setAction(Monaco.ActionType.SHIELD, turns);
        for (uint256 i = 0; i < turns; ++i) {
            monaco.play(1);
            (, , , uint32 shield, ) = monaco.getCarData(mockCar2);
            assertEq(shield, uint32(turns - i));
        }
    }

    function testAction_superShell() public {
        // Position two cars ahead
        monaco.setCarData(
            mockCar3,
            Monaco.CarData({
                balance: 15000,
                car: mockCar3,
                speed: 100,
                shield: 0,
                y: 200
            })
        );
        monaco.setCarData(
            mockCar1,
            Monaco.CarData({
                balance: 15000,
                car: mockCar1,
                speed: 200,
                shield: 0,
                y: 500
            })
        );

        // First car that acts should super shell both cars ahead
        mockCar2.setAction(Monaco.ActionType.SUPER_SHELL, 1);

        // Simulate the turn only for car2 -> first car to act
        monaco.play(1);

        (, uint32 speed1, , , ) = monaco.getCarData(mockCar1);
        (, uint32 speed3, , , ) = monaco.getCarData(mockCar3);

        assertEq(speed1, 1);
        assertEq(speed3, 1);
    }

    function testAction_superShell_ignores_shield() public {
        // Position the first car ahead
        monaco.setCarData(
            mockCar3,
            Monaco.CarData({
                balance: 15000,
                car: mockCar3,
                speed: 100,
                shield: 0,
                y: 200
            })
        );
        monaco.setCarData(
            mockCar2,
            Monaco.CarData({
                balance: 15000,
                car: mockCar2,
                speed: 200,
                shield: 0,
                y: 500
            })
        );

        mockCar3.setAction(Monaco.ActionType.SHIELD, 1);
        mockCar2.setAction(Monaco.ActionType.SHIELD, 2);
        mockCar1.setAction(Monaco.ActionType.SUPER_SHELL, 1);

        // Simulate one move per car, shield -> shield -> super shell
        monaco.play(3);

        (, uint32 speed2, , , ) = monaco.getCarData(mockCar2);
        (, uint32 speed3, , , ) = monaco.getCarData(mockCar3);

        assertEq(speed2, 1);
        assertEq(speed3, 1);
    }

    function testAction_banana() public {
        uint32 carPosition = 100;
        monaco.setCarData(
            mockCar2,
            Monaco.CarData({
                balance: 15000,
                car: mockCar2,
                speed: 200,
                shield: 0,
                y: carPosition
            })
        );
        mockCar2.setAction(Monaco.ActionType.BANANA, 1);

        // Check that we have no bananas
        vm.expectRevert();
        monaco.bananas(0);

        // Simulate a few turns
        monaco.play(3);

        // Banana should be at car position
        assertEq(monaco.bananas(0), carPosition);
    }

    function testAction_banana_collision() public {
        uint32 bananaPos = 100;
        monaco.setCarData(
            mockCar2,
            Monaco.CarData({
                balance: 15000,
                car: mockCar2,
                speed: 0,
                shield: 0,
                y: bananaPos
            })
        );
        mockCar2.setAction(Monaco.ActionType.BANANA, 1);

        uint32 car3Speed1 = 60;
        monaco.setCarData(
            mockCar3,
            Monaco.CarData({
                balance: 15000,
                car: mockCar3,
                speed: car3Speed1,
                shield: 0,
                y: 0
            })
        );

        monaco.play(1);

        // Banana should be at car position
        assertEq(monaco.bananas(0), bananaPos);

        monaco.play(1);

        // Banana collision should occur for car3
        (, uint32 car3Speed2, uint32 car3Pos, , ) = monaco.getCarData(mockCar3);

        // ICar stopped at the banana
        assertEq(car3Pos, bananaPos);

        // Banana slowed the car
        assertTrue(car3Speed1 > car3Speed2);

        // Banana should be deleted
        vm.expectRevert();
        monaco.bananas(0);
    }

    function testAction_banana_multipleCollision() public {
        // Test a single car colliding with multiple bananas
        uint256 banana1Pos = 100;
        uint256 banana2Pos = 110;
        uint256 banana3Pos = 120;
        monaco.addBanana(banana1Pos);
        monaco.addBanana(banana2Pos);
        monaco.addBanana(banana3Pos);

        monaco.setCarData(
            mockCar2,
            Monaco.CarData({
                balance: 15000,
                car: mockCar2,
                speed: 100,
                shield: 0,
                y: 50
            })
        );

        monaco.play(1);

        assertEq(monaco.bananas(0), banana2Pos);
        (, , uint32 car2Pos1, , ) = monaco.getCarData(mockCar2);

        // ICar stopped at the banana
        assertEq(car2Pos1, banana1Pos);

        monaco.play(1);

        assertEq(monaco.bananas(0), banana3Pos);

        (, , uint32 car2Pos2, , ) = monaco.getCarData(mockCar2);

        // ICar stopped at the banana
        assertEq(car2Pos2, banana2Pos);

        monaco.play(1);

        // No more bananas
        vm.expectRevert();
        monaco.bananas(0);

        (, uint32 car2Speed, uint32 car2Pos3, , ) = monaco.getCarData(mockCar2);
        assertEq(car2Pos3, banana3Pos);

        assertEq(car2Speed, 12);
    }

    function testAction_shell_banana() public {
        uint32 car1Position = 100;
        monaco.addBanana(car1Position);
        monaco.setCarData(
            mockCar1,
            Monaco.CarData({
                balance: 15000,
                car: mockCar1,
                speed: 100,
                shield: 0,
                y: car1Position
            })
        );

        uint32 car2Position = 50;
        monaco.setCarData(
            mockCar2,
            Monaco.CarData({
                balance: 15000,
                car: mockCar2,
                speed: 100,
                shield: 0,
                y: car2Position
            })
        );
        mockCar2.setAction(Monaco.ActionType.SHELL, 1);

        monaco.play(1);

        // Car2 shoots the banana
        vm.expectRevert();
        monaco.bananas(0);

        // Car1 should be unaffected
        (, uint32 car1Speed, uint32 car1Pos, , ) = monaco.getCarData(mockCar1);
        assertEq(car1Speed, 100);
        assertEq(car1Pos, car1Position + car1Speed);

        // Car2 should be unaffected
        (, uint32 car2Speed, uint32 car2Pos, , ) = monaco.getCarData(mockCar2);
        assertEq(car2Speed, 100);
        assertEq(car2Pos, car2Position + car2Speed);
    }

    function testAction_superShell_bananas() public {
        // Add a few bananas
        monaco.addBanana(15);
        monaco.addBanana(14);
        monaco.addBanana(13);
        monaco.addBanana(12);
        monaco.addBanana(11);
        monaco.addBanana(10);

        // Set super shell as the next action for car2
        monaco.setCarData(
            mockCar2,
            Monaco.CarData({
                balance: 15000,
                car: mockCar2,
                speed: 100,
                shield: 0,
                y: 0
            })
        );
        mockCar2.setAction(Monaco.ActionType.SUPER_SHELL, 1);

        // Place car1 in front of car2
        monaco.setCarData(
            mockCar1,
            Monaco.CarData({
                balance: 15000,
                car: mockCar1,
                speed: 100,
                shield: 0,
                y: 20
            })
        );

        monaco.play(1);

        // Car2 shoots all the bananas
        vm.expectRevert();
        monaco.bananas(0);

        // Car1 is shelled
        (, uint32 car1Speed, uint32 car1Pos, , ) = monaco.getCarData(mockCar1);
        assertEq(car1Speed, 1);
        assertEq(car1Pos, 20 + car1Speed);

        // Car2 should be unaffected
        (, uint32 car2Speed, uint32 car2Pos, , ) = monaco.getCarData(mockCar2);
        assertEq(car2Speed, 100);
        assertEq(car2Pos, car2Speed);
    }
}
