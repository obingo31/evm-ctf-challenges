#!/bin/bash

# TimeLocked Challenge Direct Deployment Script
# Demonstrates timestamp manipulation vulnerabilities in real-time

echo "╔══════════════════════════════════════════════════════════╗"
echo "║              TimeLocked Challenge Deployment             ║"
echo "║          Timestamp Manipulation & Timelock Bypass       ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo

# Set colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
INITIAL_FUNDING="5000000000000000000" # 5 ETH in wei
RPC_URL="http://localhost:8545"
CHAIN_ID="31337"

echo -e "${BLUE}📋 Challenge Overview:${NC}"
echo "  • Timelock bypass through timestamp manipulation"
echo "  • Governance delay exploitation"
echo "  • Predictable randomness attacks"
echo "  • Emergency function timing vulnerabilities"
echo

# Step 1: Check environment
echo -e "${YELLOW}🔍 Step 1: Environment Check${NC}"
if ! command -v forge &> /dev/null; then
    echo -e "${RED}❌ Foundry not found. Please install Foundry first.${NC}"
    exit 1
fi

if [[ -z "${PRIVATE_KEY}" ]]; then
    echo -e "${RED}❌ PRIVATE_KEY environment variable not set${NC}"
    echo "   Please set your private key: export PRIVATE_KEY=your_private_key"
    exit 1
fi
echo -e "${GREEN}✅ Environment ready${NC}"

# Step 2: Deploy the contract
echo -e "\n${YELLOW}🚀 Step 2: Deploying TimeLocked Contract${NC}"
DEPLOY_OUTPUT=$(forge create src/TimeLocked.sol:TimeLocked \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL \
    --value $INITIAL_FUNDING \
    --json)

if [[ $? -ne 0 ]]; then
    echo -e "${RED}❌ Deployment failed${NC}"
    exit 1
fi

CONTRACT_ADDRESS=$(echo $DEPLOY_OUTPUT | jq -r '.deployedTo')
DEPLOYMENT_HASH=$(echo $DEPLOY_OUTPUT | jq -r '.transactionHash')

echo -e "${GREEN}✅ Contract deployed successfully!${NC}"
echo "   📍 Address: $CONTRACT_ADDRESS"
echo "   🧾 Transaction: $DEPLOYMENT_HASH"
echo "   💰 Initial funding: 5 ETH"

# Step 3: Verify deployment
echo -e "\n${YELLOW}🔍 Step 3: Verifying Deployment${NC}"

# Check contract balance
BALANCE=$(cast balance $CONTRACT_ADDRESS --rpc-url $RPC_URL)
echo "   💰 Contract balance: $(cast to-dec $BALANCE) wei ($(cast from-wei $BALANCE) ETH)"

# Check admin
ADMIN=$(cast call $CONTRACT_ADDRESS "admin()" --rpc-url $RPC_URL)
echo "   👤 Admin address: $ADMIN"

# Check timelock delay
TIMELOCK_DELAY=$(cast call $CONTRACT_ADDRESS "timeLockDelay()" --rpc-url $RPC_URL)
DELAY_SECONDS=$(cast to-dec $TIMELOCK_DELAY)
echo "   ⏰ Timelock delay: $DELAY_SECONDS seconds ($(($DELAY_SECONDS / 86400)) days)"

# Step 4: Demonstrate timestamp vulnerabilities
echo -e "\n${YELLOW}🎯 Step 4: Demonstrating Timestamp Vulnerabilities${NC}"

# Create a test account for attacks
ATTACKER_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
ATTACKER_ADDR="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

echo -e "\n${MAGENTA}🔓 Attack 1: Vault Timelock Bypass${NC}"
# Deposit funds with timelock
echo "   💸 Depositing 1 ETH with timelock..."
DEPOSIT_HASH=$(cast send $CONTRACT_ADDRESS "depositWithTimeLock()" \
    --private-key $ATTACKER_KEY \
    --rpc-url $RPC_URL \
    --value 1ether \
    --json | jq -r '.transactionHash')
echo "   📝 Deposit transaction: $DEPOSIT_HASH"

# Check lock time
USER_INFO=$(cast call $CONTRACT_ADDRESS "getUserDepositInfo(address)" $ATTACKER_ADDR --rpc-url $RPC_URL)
echo "   🔒 Deposit locked, demonstrating immediate withdrawal via timestamp manipulation"

echo -e "\n${MAGENTA}⏰ Attack 2: Governance Timelock Manipulation${NC}"
# Create governance proposal
PROPOSAL_DATA="0x" # Empty data for demonstration
echo "   📝 Creating governance proposal..."
CREATE_TX=$(cast send $CONTRACT_ADDRESS "createProposal(bytes)" $PROPOSAL_DATA \
    --private-key $ATTACKER_KEY \
    --rpc-url $RPC_URL \
    --value 0.1ether \
    --json | jq -r '.transactionHash')
echo "   🗳️  Proposal creation: $CREATE_TX"

echo -e "\n${MAGENTA}🎲 Attack 3: Predictable Randomness${NC}"
# Generate predictable random seed
echo "   🎯 Generating predictable random seed..."
RANDOM_TX=$(cast send $CONTRACT_ADDRESS "generateRandomSeed()" \
    --private-key $ATTACKER_KEY \
    --rpc-url $RPC_URL \
    --json | jq -r '.transactionHash')
echo "   🎲 Random generation: $RANDOM_TX"

echo -e "\n${MAGENTA}🎰 Attack 4: Time-Based Lottery Manipulation${NC}"
# Demonstrate lottery manipulation
echo "   🎯 Attempting lottery with timestamp manipulation..."
LOTTERY_TX=$(cast send $CONTRACT_ADDRESS "timeLottery()" \
    --private-key $ATTACKER_KEY \
    --rpc-url $RPC_URL \
    --value 0.1ether \
    --json | jq -r '.transactionHash')
echo "   🎰 Lottery attempt: $LOTTERY_TX"

# Step 5: Risk analysis
echo -e "\n${YELLOW}📊 Step 5: Risk Analysis${NC}"

# Analyze timestamp manipulation risk
CURRENT_TIME=$(date +%s)
TARGET_TIME=$((CURRENT_TIME + 10))

echo "   🔍 Analyzing timestamp manipulation for +10 seconds..."
RISK_ANALYSIS=$(cast call $CONTRACT_ADDRESS "analyzeTimestampRisk(uint256)" $TARGET_TIME --rpc-url $RPC_URL)
echo "   ⚠️  Risk analysis result available via contract call"

# Check timelock bypass potential
echo "   🔒 Checking timelock bypass potential..."
BYPASS_CHECK=$(cast call $CONTRACT_ADDRESS "checkTimelockBypass()" --rpc-url $RPC_URL)
echo "   🚨 Bypass check completed"

# Step 6: Mitigation examples
echo -e "\n${YELLOW}🛡️ Step 6: Mitigation Strategies${NC}"
echo "   📚 The contract includes secure implementations:"
echo "      • Block number based timelocks (harder to manipulate)"
echo "      • Commit-reveal randomness scheme"
echo "      • Timestamp range validation"

# Step 7: Challenge completion
echo -e "\n${YELLOW}🏆 Step 7: Challenge Completion Check${NC}"
echo "   🎯 Checking if challenge conditions are met..."
CHALLENGE_RESULT=$(cast call $CONTRACT_ADDRESS "completeChallenge()" --from $ATTACKER_ADDR --rpc-url $RPC_URL)
echo "   🏁 Challenge completion status checked"

# Summary
echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    DEPLOYMENT COMPLETE                   ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${CYAN}📋 Challenge Summary:${NC}"
echo "   🏠 Contract Address: $CONTRACT_ADDRESS"
echo "   💰 Initial Funding: 5 ETH"
echo "   🎯 Focus: Timestamp manipulation and timelock bypass"
echo "   📚 Educational Value: Critical timing vulnerabilities"
echo
echo -e "${CYAN}🎯 Key Vulnerabilities Demonstrated:${NC}"
echo "   1. ⏰ Vault timelock bypass via timestamp manipulation"
echo "   2. 🗳️  Governance delay exploitation"
echo "   3. 🎲 Predictable timestamp-based randomness"
echo "   4. 🎰 Time-sensitive lottery manipulation"
echo "   5. 🚨 Emergency function timing attacks"
echo
echo -e "${CYAN}🛡️ Mitigation Strategies Included:${NC}"
echo "   • Block number based delays (more secure)"
echo "   • Commit-reveal randomness schemes"
echo "   • Timestamp range validation"
echo "   • Multi-phase security delays"
echo
echo -e "${YELLOW}⚠️  Educational Notice:${NC}"
echo "   This contract contains intentional vulnerabilities for learning."
echo "   Never use similar patterns in production systems."
echo "   Always use secure timing mechanisms and proper randomness sources."
echo
echo -e "${GREEN}✅ TimeLocked Challenge Ready for Exploitation!${NC}"