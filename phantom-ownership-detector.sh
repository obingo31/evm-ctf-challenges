#!/bin/bash
# Phantom Ownership Detection Script
# Analyzes contracts for potential fake ownership renouncement

echo "🔍 PHANTOM OWNERSHIP DETECTOR"
echo "=============================="
echo ""

if [ -z "$1" ]; then
    echo "Usage: $0 <contract_address> [rpc_url]"
    echo "Example: $0 0x1234... https://eth-sepolia.g.alchemy.com/v2/demo"
    exit 1
fi

CONTRACT_ADDRESS=$1
RPC_URL=${2:-"https://eth-sepolia.g.alchemy.com/v2/demo"}

echo "📊 Analyzing Contract: $CONTRACT_ADDRESS"
echo "Network: $RPC_URL"
echo ""

# Check 1: Owner function
echo "🔍 Step 1: Owner Function Analysis"
OWNER=$(cast call $CONTRACT_ADDRESS "owner()" --rpc-url $RPC_URL 2>/dev/null || echo "NO_OWNER_FUNCTION")

if [ "$OWNER" = "NO_OWNER_FUNCTION" ]; then
    echo "  ❌ No owner() function found"
    echo "  Status: Not an ownable contract"
else
    echo "  ✅ Owner function found"
    echo "  Current Owner: $OWNER"
    
    if [ "$OWNER" = "0x0000000000000000000000000000000000000000000000000000000000000000" ]; then
        echo "  ⚠️  WARNING: Owner is zero address!"
        echo "  ⚠️  Could be legitimate renouncement OR phantom attack"
    else
        echo "  ✅ Owner is set (not zero address)"
    fi
fi

echo ""

# Check 2: Storage slot analysis
echo "🔍 Step 2: Storage Slot Analysis (looking for hidden backdoors)"
for i in {0..10}; do
    SLOT_VALUE=$(cast storage $CONTRACT_ADDRESS $i --rpc-url $RPC_URL 2>/dev/null || echo "0x0000000000000000000000000000000000000000000000000000000000000000")
    
    # Check if slot contains an address (20 bytes)
    if [[ $SLOT_VALUE =~ ^0x[0-9a-fA-F]{24}[0-9a-fA-F]{40}$ ]] && [ "$SLOT_VALUE" != "0x0000000000000000000000000000000000000000000000000000000000000000" ]; then
        ADDRESS_IN_SLOT="0x${SLOT_VALUE:26:40}"
        echo "  Slot $i: $SLOT_VALUE"
        echo "    └─ Contains potential address: $ADDRESS_IN_SLOT"
        
        if [ "$OWNER" = "0x0000000000000000000000000000000000000000000000000000000000000000" ]; then
            echo "    ⚠️  SUSPICIOUS: Address found while owner is zero!"
        fi
    elif [ "$SLOT_VALUE" != "0x0000000000000000000000000000000000000000000000000000000000000000" ]; then
        echo "  Slot $i: $SLOT_VALUE (non-zero data)"
    fi
done

echo ""

# Check 3: Function signature analysis
echo "🔍 Step 3: Suspicious Function Analysis"
echo "Checking for phantom ownership functions..."

RECLAIM_SIG="0xc1c8277f"  # reclaimOwnership()
SHADOW_SIG="0x96c81508"   # shadowReclaim()
VERIFY_SIG="0x7f5ad2a1"   # verifyPhantomOwnership()

echo "  Checking for reclaimOwnership()..."
RECLAIM_CHECK=$(cast call $CONTRACT_ADDRESS $RECLAIM_SIG --rpc-url $RPC_URL 2>/dev/null && echo "FOUND" || echo "NOT_FOUND")
if [ "$RECLAIM_CHECK" = "FOUND" ]; then
    echo "    ⚠️  WARNING: reclaimOwnership() function detected!"
fi

echo "  Checking for shadowReclaim()..."
SHADOW_CHECK=$(cast call $CONTRACT_ADDRESS $SHADOW_SIG --rpc-url $RPC_URL 2>/dev/null && echo "FOUND" || echo "NOT_FOUND")
if [ "$SHADOW_CHECK" = "FOUND" ]; then
    echo "    🚨 ALERT: shadowReclaim() backdoor detected!"
fi

echo "  Checking for verifyPhantomOwnership()..."
VERIFY_CHECK=$(cast call $CONTRACT_ADDRESS $VERIFY_SIG --rpc-url $RPC_URL 2>/dev/null && echo "FOUND" || echo "NOT_FOUND")
if [ "$VERIFY_CHECK" = "FOUND" ]; then
    echo "    🚨 CRITICAL: verifyPhantomOwnership() found - definitely phantom!"
fi

echo ""

# Risk Assessment
echo "📊 RISK ASSESSMENT"
echo "=================="

RISK_SCORE=0

if [ "$OWNER" = "0x0000000000000000000000000000000000000000000000000000000000000000" ]; then
    RISK_SCORE=$((RISK_SCORE + 3))
    echo "  ⚠️  Owner is zero address (+3 risk)"
fi

if [ "$RECLAIM_CHECK" = "FOUND" ]; then
    RISK_SCORE=$((RISK_SCORE + 5))
    echo "  🚨 reclaimOwnership() function exists (+5 risk)"
fi

if [ "$SHADOW_CHECK" = "FOUND" ]; then
    RISK_SCORE=$((RISK_SCORE + 8))
    echo "  🚨 shadowReclaim() backdoor exists (+8 risk)"
fi

if [ "$VERIFY_CHECK" = "FOUND" ]; then
    RISK_SCORE=$((RISK_SCORE + 10))
    echo "  🚨 verifyPhantomOwnership() exists (+10 risk)"
fi

echo ""
echo "Total Risk Score: $RISK_SCORE"

if [ $RISK_SCORE -eq 0 ]; then
    echo "✅ LOW RISK: Appears to be legitimate ownership"
elif [ $RISK_SCORE -le 3 ]; then
    echo "🟡 MEDIUM RISK: Potentially legitimate renouncement"
elif [ $RISK_SCORE -le 8 ]; then
    echo "🟠 HIGH RISK: Suspicious patterns detected"
else
    echo "🔴 CRITICAL RISK: Likely phantom ownership attack!"
fi

echo ""
echo "🎯 RECOMMENDATIONS:"
if [ $RISK_SCORE -ge 5 ]; then
    echo "  1. 🚨 DO NOT TRUST this contract!"
    echo "  2. 🔍 Perform thorough code audit"
    echo "  3. 🕵️ Check for assembly blocks in source code"
    echo "  4. ⚠️ Owner may be able to reclaim control anytime"
else
    echo "  1. ✅ Contract appears safe from phantom ownership"
    echo "  2. 🔍 Still recommended to audit source code"
fi

echo ""
echo "💡 Learn more: challenges/10-PhantomOwner/README.md"