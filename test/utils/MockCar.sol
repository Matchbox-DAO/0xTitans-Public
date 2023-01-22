// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./../../src/interfaces/ICar.sol";

contract MockCar is ICar {
    event Idle(address);
    event Action(address, Monaco.ActionType, uint256);

    constructor() {
        idle = true;
    }

    Monaco.ActionType public actionType;
    uint256 public amount;
    bool public idle;
    uint256 public repeat;

    function setAction(Monaco.ActionType actionType_, uint256 amount_, uint256 repeat_) public {
        actionType = actionType_;
        amount = amount_;
        idle = false;
        repeat = repeat_;
    }

    function setIdle() public {
        idle = true;
    }

    function takeYourTurn(Monaco monaco, Monaco.CarData[] calldata /*allCars*/, uint256[] calldata /*bananas*/, uint256 /*ourCarIndex*/) external override {
        // Do nothing if we`re in idle mode
        if (idle) {
            emit Idle(address(this));
            return;
        }

        for (uint256 i=0; i<repeat; ++i){
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
        }

        emit Action(address(this),actionType,amount);

        // Mark as idle after we play our move
        setIdle();
    }

    function sayMyName() external pure returns (string memory) {
        return "MockCar";
    }
}
