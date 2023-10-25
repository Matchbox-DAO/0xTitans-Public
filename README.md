# OxTitans

This repository contains the OxTitans(based on the original 0xMonaco) developed by Matchbox-DAO.

For the platform please visit 

https://0xtitans.com

# Instructions

## Requirements
To use this project, you need to have Node (>=14) and Foundry installed. You can find instructions on how to install it at https://book.getfoundry.sh/getting-started/installation.

## Set Up 
To set up the project, follow these steps:

1. Clone the repository:
   ```bash
   git clone https://github.com/Matchbox-DAO/0xTitans-Public.git 
   ```

2. Install dependencies:
   ```bash
   forge install  
   ```

3. Install node modules:
   ```bash
   yarn install  
   ```

4. Add a `logs` folder to the root of the project.

5. Run tests:
   ```bash
   forge test
   ```

6. Make sure all tests passed

## How to test your strategies
To test your strategies, follow these steps:

1. Go to `test/Monaco.t.sol`

2. Import your car strategy contract.

3. Go to `testGames()` on line 50.

4. Add strategies as `w1`, `w2`, and `w3`.

5. Add a `logs` folder to the root of the project (if not done yet).

6. Run the command `forge test` to execute the tests.

7. Check the logs for any errors or issues, as well as the full simulation of the race and any additional data.


# How to create a strategy
All car strategies should be based on the `ICar` interface. You can check the `src/samples` directory to get a better idea of different car strategies. We've added a few successful cars from previous editions, so feel free to test your car against them. You can test your car against the previous finalists, including Polygon, Uniswap, and OtterSec.

 `However, note that these cars have been created for different versions of the game contract and might be less effective for the current version`

## How to produce bytecode
In the platform, you won't submit the actual source code but only the bytecode of it. In order to produce bytecode of your car contract, run the command:

```bash
forge inspect <contract name> b
```

By following these steps, you should be able to create and test your car strategy for the OxTitans project.
