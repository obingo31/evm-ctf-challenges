# Security Guidelines for ManipulateMint Challenge

## 🚨 **CRITICAL SECURITY REMINDERS**

### Private Key Protection
- [ ] ✅ Never commit private keys to git
- [ ] ✅ Use environment variables: `YOUR_PRIVATE_KEY`
- [ ] ✅ Use `.env` files (already gitignored)
- [ ] ✅ Use dedicated test accounts only
- [ ] ✅ Keep test funds minimal (< $10 worth)

### Safe Development Practices
```bash
# ✅ SECURE Setup
export YOUR_PRIVATE_KEY="0x..." # Test account only
./deploy_direct.sh

# ❌ INSECURE - Never do this
git add . && git commit -m "Added my private key" # DON'T!
```

### Test Account Best Practices
1. **Generate new test wallets**:
   ```bash
   cast wallet new  # Generate fresh test wallet
   ```

2. **Fund with minimal test ETH**:
   - Get Sepolia ETH from faucets
   - Keep amounts small (0.1 ETH max)

3. **Never use main wallets**:
   - Don't use MetaMask primary accounts
   - Don't use wallets with real funds

### Verification Checklist
Before running commands:
- [ ] Confirm you're on Sepolia testnet
- [ ] Verify private key is for test account only
- [ ] Check `.env` is in `.gitignore`
- [ ] Confirm no real funds at risk

## 🛡️ **If Private Key Gets Exposed**

1. **Immediately stop using the compromised key**
2. **Generate new test accounts**
3. **Audit git history for key exposure**
4. **Never reuse exposed keys**

Remember: This is educational content - security is paramount!