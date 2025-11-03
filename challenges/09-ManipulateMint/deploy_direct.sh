#!/bin/bash
# Deploy ManipulateMint Challenge

echo "🚀 ManipulateMint Challenge Deployment"
echo ""

# Security check for private key
if [ -z "$YOUR_PRIVATE_KEY" ]; then
    echo "❌ Error: YOUR_PRIVATE_KEY environment variable not set"
    echo "Please set it first: export YOUR_PRIVATE_KEY=\"0x...\""
    echo "⚠️  NEVER commit real private keys to git!"
    exit 1
fi

# Deploy contract
echo "Deploying ManipulateMint contract..."
DEPLOY_OUTPUT=$(forge create src/ManipulateMint.sol:ManipulateMint \
  --rpc-url https://eth-sepolia.public.blastapi.io \
  --private-key $YOUR_PRIVATE_KEY \
  --broadcast 2>&1)

if [ $? -eq 0 ]; then
    echo "✅ ManipulateMint deployed successfully!"
    
    # Extract contract address
    CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep "Deployed to:" | awk '{print $3}')
    echo "Contract Address: $CONTRACT_ADDRESS"
    
    echo ""
    echo "🎯 Executing exploit..."
    
    # Execute the manipulateMint exploit
    cast send $CONTRACT_ADDRESS "manipulateMint(uint256)" 5000000000000000000000000 \
      --rpc-url https://eth-sepolia.public.blastapi.io \
      --private-key $YOUR_PRIVATE_KEY
    
    echo ""
    echo "✅ Exploit executed!"
    echo ""
    echo "📊 Results:"
    echo "Contract: $CONTRACT_ADDRESS"
    echo "Etherscan: https://sepolia.etherscan.io/address/$CONTRACT_ADDRESS"
    
else
    echo "❌ Deployment failed!"
    echo "$DEPLOY_OUTPUT"
fi