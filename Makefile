# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# Update dependencies
install         :; forge install
update          :; forge update


# Build & test
build           :; forge build
clean           :; forge clean
lint            :; yarn install && yarn run lint
test            :; forge test --no-match-path 'src/test/gas/*' # gas-estimation are skewed by mocked contracts
test-gas        :; forge test --match-path 'src/test/gas/*' --gas-report --fork-url $(ETH_RPC_URL)
