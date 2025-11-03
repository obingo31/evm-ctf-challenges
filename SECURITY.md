# 🔐 Security Guidelines for EVM CTF Challenges

## ⚠️ CRITICAL: Private Key Security

### 🚨 NEVER COMMIT PRIVATE KEYS

**This repository is configured to prevent accidental private key commits, but always be vigilant:**

### ✅ Safe Practices

```bash
# ✅ Use environment variables
export PRIVATE_KEY="0x1234..."  # Test key only!

# ✅ Use .env files (already gitignored)
echo "PRIVATE_KEY=0x1234..." > .env

# ✅ Use Foundry's built-in accounts for testing
forge test --fork-url $RPC_URL

# ✅ Use cast wallet for secure key management
cast wallet new
cast wallet import mykey --interactive
```

### ❌ Dangerous Practices

```bash
# ❌ NEVER hardcode in scripts
PRIVATE_KEY="0x1234..."  # DON'T DO THIS

# ❌ NEVER commit to git
git add private_key.txt  # DON'T DO THIS

# ❌ NEVER use real mainnet keys for testing
# Use dedicated test keys only!
```

### 🛡️ Protected Patterns

The `.gitignore` file protects against:

```ignore
# Environment files
.env
.env.*

# Private key files
*.key
*.pem
private_key*
privatekey*
PRIVATE_KEY*
secret*
mnemonic*
keystore/
wallets/

# Deployment artifacts
deployments/
deployment-*.json
addresses.json
```

### 🔍 Before Committing

Always run:

```bash
# Check what you're about to commit
git diff --cached

# Scan for potential secrets
git log --oneline | head -10

# Use git hooks for additional protection
# Consider tools like: git-secrets, detect-secrets
```

### 🚨 If You Accidentally Commit a Key

1. **IMMEDIATELY** stop using that key
2. Generate new keys
3. Remove from git history:

   ```bash
   git filter-branch --force --index-filter \
     'git rm --cached --ignore-unmatch path/to/key/file' \
     --prune-empty --tag-name-filter cat -- --all
   ```

4. Force push: `git push --force --all`
5. Notify team members to re-clone

### 🧪 Test Key Recommendations

For CTF challenges, use:

- **Anvil default accounts** (built into Foundry)
- **Hardhat default accounts**
- **Dedicated test keys** (never used for real funds)
- **Hardware wallet test mode** (if available)

### 📚 Resources

- [Foundry Security Best Practices](https://book.getfoundry.sh/tutorials/best-practices)
- [Ethereum Key Management](https://ethereum.org/en/developers/docs/accounts/#account-creation)
- [Git Secrets Detection](https://github.com/awslabs/git-secrets)

---

## 🛡️ Remember

Security is everyone's responsibility!