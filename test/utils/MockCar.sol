// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../../src/cars/Car.sol";

contract MockCar is Car {
    event Idle(address);
    event Action(address, Monaco.ActionType, uint256);

    constructor(Monaco _monaco) Car(_monaco) {
        idle = true;
    }

    Monaco.ActionType public actionType;
    uint256 public amount;
    bool public idle;

    function setAction(Monaco.ActionType actionType_, uint256 amount_) public {
        actionType = actionType_;
        amount = amount_;
        idle = false;
    }

    function setIdle() public {
        idle = true;
    }

    function takeYourTurn(Monaco.CarData[] calldata /*allCars*/, uint256 /*ourCarIndex*/) external override {
        // Do nothing if we`re in idle mode
        if (idle) {
            emit Idle(address(this));
            return;
        }

        if(actionType == Monaco.ActionType.ACCELERATE){
            monaco.buyAcceleration(amount);
        } else  if(actionType == Monaco.ActionType.SHELL){
            monaco.buyShell(amount);
        } else  if(actionType == Monaco.ActionType.SUPER_SHELL){
            monaco.buySuperShell(amount);
        } else if(actionType == Monaco.ActionType.BANANA){
            monaco.buyBanana();
        } else if(actionType == Monaco.ActionType.SHIELD){
            monaco.buyShield(amount);
        }

        emit Action(address(this),actionType,amount);

        // Mark as idle after we play our move
        setIdle();
    }
}
