.PHONY: init_install dry-run verify verify-contract

init_install:
	forge install OpenZeppelin/openzeppelin-contracts

dry-run:
	forge create --rpc-url sepolia \
	 --account myMetaMaskAcc \
	 --password '' \
	 src/Erc20Token.sol:MyToken \
	 --constructor-args "MyToken" "MTK"

deploy:
	forge create --rpc-url sepolia \
	 --account myMetaMaskAcc \
	 --password '' \
	 src/Erc20Token.sol:MyToken \
	 --broadcast \
	 --constructor-args "MyToken" "MTK"
deploy_via_script:
	forge script script/DeployMyToken.s.sol \
	--rpc-url sepolia \
	--account myMetaMaskAcc \
	--password '' \
	--broadcast

verify:
	@echo "Please provide the deployed contract address:"
	@read CONTRACT_ADDRESS; \
	forge verify-contract $$CONTRACT_ADDRESS \
	src/Erc20Token.sol:MyToken \
	--chain sepolia \
	--constructor-args $$(cast abi-encode "constructor(string,string)" "MyToken" "MTK") \
	--watch

verify-contract:
	@if [ -z "$(CONTRACT_ADDRESS)" ]; then \
		echo "Usage: make verify-contract CONTRACT_ADDRESS=0x..."; \
		exit 1; \
	fi
	forge verify-contract $(CONTRACT_ADDRESS) \
	src/Erc20Token.sol:MyToken \
	--chain sepolia \
	--constructor-args $$(cast abi-encode "constructor(string,string)" "MyToken" "MTK") \
	--watch
