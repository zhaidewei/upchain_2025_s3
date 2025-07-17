CONTRACT_ADDRESS=0x838E9A34F1D2B55901B4ABa763B0F2ACb14b3033
forge verify-contract $CONTRACT_ADDRESS \
	src/Erc20Token.sol:MyToken \
	--chain sepolia \
	--watch \
	--constructor-args $(cast abi-encode "constructor(string,string)" "MyToken" "MTK")
