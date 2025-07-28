#!/bin/bash
cast sig-event "Transfer(address indexed from, address indexed to, uint256 value)"

# 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
# Generate event signatures from event string
# cast sig-event [OPTIONS] [EVENT_STRING]

cast sig-event "Transfer(address indexed, address indexed, uint256)"
# 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
# Note. same as above

cast sig-event "Transfer(address,address,uint256)"
# 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
# Note. Same as above
cast sig-event "Transfer(uint256,address,address)"
# 0x0a429aba3d89849a2db0153e4534d95c46a1d83c8109d73893f55ebc44010ff4 -> different
