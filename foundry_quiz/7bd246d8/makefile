.PHONY: init_install dry-run

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
