// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {Monaco} from "../src/Monaco.sol";
import {Car} from "../src/cars/Car.sol";
import "../src/cars/ExampleCar.sol";
import {MockCar} from "./utils/MockCar.sol";

contract MockMonaco is Monaco{

    function setCarData(Car car, CarData memory data) public {
        getCarData[car] = data;
    }
}

contract MonacoAbilitiesTest is Test {
    MockMonaco monaco;

    MockCar public mockCar1;
    MockCar public mockCar2;
    MockCar public mockCar3;

    function setUp() public {
        monaco = new MockMonaco();

        mockCar1 = new MockCar(monaco);
        mockCar2 = new MockCar(monaco);
        mockCar3 = new MockCar(monaco);

        monaco.register(mockCar1);
        monaco.register(mockCar2);
        monaco.register(mockCar3);
    }

    function test_storageOverwrite(uint32 balance, uint32 speed, uint32 shield, uint32 y) public {
        monaco.setCarData(mockCar1, Monaco.CarData({balance: balance, car: mockCar1, speed: speed, shield:shield, y: y}));

        (uint32 balance_, uint32 speed_ , uint32 y_, uint32 shield_ , Car car_) = monaco.getCarData(mockCar1);

        assertEq(balance,balance_);
        assertEq(speed,speed_);
        assertEq(shield,shield_);
        assertEq(y,y_);
        assertEq(address(mockCar1),address(car_));
    }
    
    function testAction_accelerate() public {
        uint256 amount = 5;

        (uint32 balance, , uint32 preMoveY, ,) = monaco.getCarData(mockCar1);

        try monaco.getAccelerateCost(amount) returns (uint256 cost){
            if(cost > balance) return;
        }
        catch{
            return;
        }

        mockCar1.setAction(Monaco.ActionType.ACCELERATE,amount);

        monaco.play(3);

        (, , uint32 postMoveY, ,) = monaco.getCarData(mockCar1);

        assertEq(postMoveY, preMoveY + amount);
    }

    function testAction_shell() public {
        // Position the first car ahead
        monaco.setCarData(mockCar1, Monaco.CarData({balance: 15000, car: mockCar1, speed: 100, shield:0, y: 200}));

        mockCar2.setAction(Monaco.ActionType.SHELL,1);
        
        monaco.play(1);

        (, uint32 speed , uint32 y, ,) = monaco.getCarData(mockCar1);

        assertEq(speed, 1); // Shelled speed
        assertEq(y, 200 + speed);
    }

    function testAction_superShell() public {
        // Position the first car ahead
        monaco.setCarData(mockCar3, Monaco.CarData({balance: 15000, car: mockCar3, speed: 100, shield:0, y: 200}));
        monaco.setCarData(mockCar1, Monaco.CarData({balance: 15000, car: mockCar1, speed: 200, shield:0, y: 500}));

        mockCar2.setAction(Monaco.ActionType.SUPER_SHELL,1);
        
        // Simulate the turn only for car2 -> first car to act
        monaco.play(1);

        (, uint32 speed1 , uint32 y1, ,) = monaco.getCarData(mockCar1);
        (, uint32 speed3 , uint32 y3, ,) = monaco.getCarData(mockCar3);

        assertEq(speed1, 1);
        assertEq(speed3, 1);
    }

    function testAction_shield() public {
        // Position the first car ahead
        uint32 car2Start = 200;
        uint32 car2Speed = 100;
        monaco.setCarData(mockCar2, Monaco.CarData({balance: 15000, car: mockCar2, speed: car2Speed, shield:0, y: car2Start}));
        mockCar2.setAction(Monaco.ActionType.SHIELD,2);

        uint32 car1Start = 0;
        uint32 car1Speed = 100;
        monaco.setCarData(mockCar1, Monaco.CarData({balance: 15000, car: mockCar1, speed: car1Speed, shield:0, y: car1Start}));
        mockCar1.setAction(Monaco.ActionType.SHELL,1);
        
        // Simulate one move per car -> 3 turns
        monaco.play(3);

        (, uint32 speed1 , uint32 y1, ,) = monaco.getCarData(mockCar1);
        (, uint32 speed2 , uint32 y2, ,) = monaco.getCarData(mockCar2);

        // car 2 is shielded and ahead
        // car 1 launches shell
        assertEq(speed1, 1);
        assertEq(y1, car1Start + 201); // 2 turns at full speed, 1 with reduced
        assertEq(speed2, car2Speed);
        assertEq(y2, car2Start + 300); // 3 turns at full speed
    }

    function testAction_shield_duration() public {
    }

    function testAction_superShell_ignores_shield() public {
        // Position the first car ahead
        monaco.setCarData(mockCar3, Monaco.CarData({balance: 15000, car: mockCar3, speed: 100, shield:0, y: 200}));
        monaco.setCarData(mockCar2, Monaco.CarData({balance: 15000, car: mockCar2, speed: 200, shield:0, y: 500}));

        mockCar3.setAction(Monaco.ActionType.SHIELD,1);
        mockCar2.setAction(Monaco.ActionType.SHIELD,2);
        mockCar1.setAction(Monaco.ActionType.SUPER_SHELL,1);
        
        // Simulate one move per car -> 3 turns
        monaco.play(3);

        (, uint32 speed2 , uint32 y2, ,) = monaco.getCarData(mockCar2);
        (, uint32 speed3 , uint32 y3, ,) = monaco.getCarData(mockCar3);

        assertEq(speed2, 1);
        assertEq(speed3, 1);
    }
}

