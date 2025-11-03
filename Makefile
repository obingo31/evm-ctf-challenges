# ╔═══════════════════════════════════════════════════════════════╗
# ║           EVM CTF Challenges - Makefile                      ║
# ║           Created: 2025-10-20                                ║
# ║           Author: @obingo31                                  ║
# ╚═══════════════════════════════════════════════════════════════╝

.PHONY: help install build test clean echidna echidna-all coverage gas-report

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
RED := \033[0;31m
YELLOW := \033[0;33m
NC := \033[0m # No Color

# ═══════════════════════════════════════════════════════════════
# Help
# ═══════════════════════════════════════════════════════════════

help: ## Display this help message
	@echo "$(BLUE)════════════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)║          EVM CTF Challenges - Make Commands          ║$(NC)"
	@echo "$(BLUE)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Usage: make [target]$(NC)"
	@echo ""

# ═══════════════════════════════════════════════════════════════
# Setup & Installation
# ═══════════════════════════════════════════════════════════════

install: ## Install dependencies (Foundry & Echidna)
	@echo "$(BLUE)Installing dependencies...$(NC)"
	@command -v forge >/dev/null 2>&1 || { \
		echo "$(RED)Foundry not found. Installing...$(NC)"; \
		curl -L https://foundry.paradigm.xyz | bash; \
		foundryup; \
	}
	@command -v echidna >/dev/null 2>&1 || { \
		echo "$(YELLOW)Echidna not found. Please install manually:$(NC)"; \
		echo "  macOS:    brew install echidna"; \
		echo "  Linux:    See https://github.com/crytic/echidna"; \
	}
	@forge install
	@echo "$(GREEN)✓ Dependencies installed!$(NC)"

check-tools: ## Check if required tools are installed
	@echo "$(BLUE)Checking tools...$(NC)"
	@command -v forge >/dev/null 2>&1 && echo "$(GREEN)✓ Foundry installed$(NC)" || echo "$(RED)✗ Foundry missing$(NC)"
	@command -v echidna >/dev/null 2>&1 && echo "$(GREEN)✓ Echidna installed$(NC)" || echo "$(RED)✗ Echidna missing$(NC)"
	@command -v cast >/dev/null 2>&1 && echo "$(GREEN)✓ Cast installed$(NC)" || echo "$(RED)✗ Cast missing$(NC)"

# ═══════════════════════════════════════════════════════════════
# Build & Test
# ═══════════════════════════════════════════════════════════════

build: ## Build all contracts
	@echo "$(BLUE)Building contracts...$(NC)"
	@forge build
	@echo "$(GREEN)✓ Build complete!$(NC)"

test: ## Run all Foundry tests
	@echo "$(BLUE)Running tests...$(NC)"
	@forge test -vv

test-verbose: ## Run tests with verbose output
	@echo "$(BLUE)Running tests (verbose)...$(NC)"
	@forge test -vvvv

test-gas: ## Run tests with gas reporting
	@echo "$(BLUE)Running tests with gas report...$(NC)"
	@forge test --gas-report

coverage: ## Generate coverage report
	@echo "$(BLUE)Generating coverage report...$(NC)"
	@forge coverage
	@forge coverage --report lcov
	@echo "$(GREEN)✓ Coverage report generated!$(NC)"

clean: ## Clean build artifacts
	@echo "$(BLUE)Cleaning...$(NC)"
	@forge clean
	@rm -rf cache out broadcast
	@echo "$(GREEN)✓ Clean complete!$(NC)"

# ═══════════════════════════════════════════════════════════════
# Challenge-Specific Tests
# ═══════════════════════════════════════════════════════════════

test-reentrancy: ## Test Reentrancy challenge
	@echo "$(BLUE)Testing Reentrancy challenge...$(NC)"
	@forge test --match-path "challenges/01-Reentrancy/test/*.t.sol" -vv

test-fallback: ## Test Fallback challenge
	@echo "$(BLUE)Testing Fallback challenge...$(NC)"
	@forge test --match-path "challenges/02-Fallback/test/*.t.sol" -vv

test-telephone: ## Test Telephone challenge
	@echo "$(BLUE)Testing Telephone challenge...$(NC)"
	@cd challenges/03-Telephone && forge test -vv

test-telephone-verbose: ## Test Telephone challenge with verbose output
	@echo "$(BLUE)Testing Telephone challenge (verbose)...$(NC)"
	@cd challenges/03-Telephone && forge test -vvvv

test-telephone-assembly: ## Test Telephone assembly attack specifically
	@echo "$(BLUE)Testing Telephone assembly attack...$(NC)"
	@cd challenges/03-Telephone && forge test --match-test testAssemblyAttackExploit -vvvv

test-telephone-txorigin: ## Test tx.origin demonstration
	@echo "$(BLUE)Testing tx.origin vs msg.sender demonstration...$(NC)"
	@cd challenges/03-Telephone && forge test --match-test testTxOriginVsMsgSender -vvvv

# ─── Challenge 04: DoubleEntryPoint ───

test-doubleentrypoint: ## Test DoubleEntryPoint challenge
	@echo "$(BLUE)Testing DoubleEntryPoint challenge...$(NC)"
	@cd challenges/04-DoubleEntryPoint && forge test -vv

test-doubleentrypoint-verbose: ## Test DoubleEntryPoint challenge with verbose output
	@echo "$(BLUE)Testing DoubleEntryPoint challenge (verbose)...$(NC)"
	@cd challenges/04-DoubleEntryPoint && forge test -vvvv

test-doubleentrypoint-assembly: ## Test DoubleEntryPoint assembly attack specifically
	@echo "$(BLUE)Testing DoubleEntryPoint assembly attack...$(NC)"
	@cd challenges/04-DoubleEntryPoint && forge test --match-test test_AssemblyAttack -vvvv

test-doubleentrypoint-detection: ## Test detection bot functionality
	@echo "$(BLUE)Testing DoubleEntryPoint detection bot...$(NC)"
	@cd challenges/04-DoubleEntryPoint && forge test --match-test test_DetectionBot -vvvv

# ─── Challenge 05: Casino ───

test-casino: ## Test Casino challenge
	@echo "$(BLUE)Testing Casino challenge...$(NC)"
	@forge test --match-path "test/casino/*.t.sol" -vv
	@cd challenges/05-Casino && forge test -vv

test-casino-verbose: ## Test Casino challenge with verbose output
	@echo "$(BLUE)Testing Casino challenge (verbose)...$(NC)"
	@forge test --match-path "test/casino/*.t.sol" -vvvv
	@cd challenges/05-Casino && forge test -vvvv

test-casino-assembly: ## Test Casino assembly attack specifically
	@echo "$(BLUE)Testing Casino assembly attack...$(NC)"
	@cd challenges/05-Casino && forge test --match-test test_AssemblyAttackWinsTwice -vvvv

test-casino-exploits: ## Test top-level Casino exploit harnesses
	@echo "$(BLUE)Testing Casino exploit contracts...$(NC)"
	@forge test --match-path "test/casino/*.t.sol" -vv

# ─── Challenge 06: CrackMe ───

test-crackme: ## Test CrackMe challenge
	@echo "$(BLUE)Testing CrackMe challenge...$(NC)"
	@cd challenges/06-CrackMe && forge test -vv

test-crackme-verbose: ## Test CrackMe challenge with verbose output
	@echo "$(BLUE)Testing CrackMe challenge (verbose)...$(NC)"
	@cd challenges/06-CrackMe && forge test -vvvv

test-crackme-solution: ## Test CrackMe solution contract specifically
	@echo "$(BLUE)Testing CrackMe solution...$(NC)"
	@cd challenges/06-CrackMe && forge test --match-test testSolutionContractSolves -vvvv

test-crackme-reverse-engineering: ## Test CrackMe byte leakage mechanism
	@echo "$(BLUE)Testing CrackMe byte leakage...$(NC)"
	@cd challenges/06-CrackMe && forge test --match-path "test/ReverseEngineering.t.sol" -vvvv

# ─── Challenge 07: PrivilegeFinance ───

test-privilegefinance: ## Test PrivilegeFinance challenge
	@echo "$(BLUE)Testing PrivilegeFinance challenge...$(NC)"
	@cd challenges/07-PrivilegeFinance && forge test -v

test-privilegefinance-verbose: ## Test PrivilegeFinance challenge with verbose output
	@echo "$(BLUE)Testing PrivilegeFinance challenge (verbose)...$(NC)"
	@cd challenges/07-PrivilegeFinance && forge test -vvv

test-privilegefinance-exploit: ## Test PrivilegeFinance exploit specifically
	@echo "$(BLUE)Testing PrivilegeFinance exploit...$(NC)"
	@cd challenges/07-PrivilegeFinance && forge test --match-test testExploitSucceeds -vv

test-privilegefinance-solve: ## Test PrivilegeFinance complete solution
	@echo "$(BLUE)Testing PrivilegeFinance complete solve...$(NC)"
	@cd challenges/07-PrivilegeFinance && forge test --match-test testCompleteChallenge -vv

# ─── Challenge 08: LittleMoney ───

test-littlemoney: ## Test LittleMoney challenge
	@echo "$(BLUE)Testing LittleMoney challenge...$(NC)"
	@cd challenges/08-LittleMoney && forge test -vv

test-littlemoney-verbose: ## Test LittleMoney challenge with verbose output
	@echo "$(BLUE)Testing LittleMoney challenge (verbose)...$(NC)"
	@cd challenges/08-LittleMoney && forge test -vvvv

test-littlemoney-exploit: ## Test LittleMoney exploit specifically
	@echo "$(BLUE)Testing LittleMoney exploit...$(NC)"
	@cd challenges/08-LittleMoney && forge test --match-test testExploitSucceeds -vv

test-littlemoney-solve: ## Test LittleMoney complete solution
	@echo "$(BLUE)Testing LittleMoney complete solve...$(NC)"
	@cd challenges/08-LittleMoney && forge test --match-test testCompleteChallenge -vv

# ─── Challenge 09: ManipulateMint ───

test-manipulatemint: ## Test ManipulateMint challenge
	@echo "$(BLUE)Testing ManipulateMint storage slot manipulation challenge...$(NC)"
	@cd challenges/09-ManipulateMint && forge test -vv

test-manipulatemint-verbose: ## Test ManipulateMint challenge with verbose output
	@echo "$(BLUE)Testing ManipulateMint challenge (verbose)...$(NC)"
	@cd challenges/09-ManipulateMint && forge test -vvvv

test-manipulatemint-vulnerability: ## Test ManipulateMint storage manipulation specifically
	@echo "$(BLUE)Testing ManipulateMint storage slot vulnerability...$(NC)"
	@cd challenges/09-ManipulateMint && forge test --match-test testManipulateMintVulnerability -vvvv

test-manipulatemint-inconsistency: ## Test ManipulateMint storage inconsistency
	@echo "$(BLUE)Testing ManipulateMint storage inconsistency detection...$(NC)"
	@cd challenges/09-ManipulateMint && forge test --match-test testManipulateMintVulnerability -vvvv

test-manipulatemint-assembly: ## Test ManipulateMint assembly operations
	@echo "$(BLUE)Testing ManipulateMint assembly storage manipulation...$(NC)"
	@cd challenges/09-ManipulateMint && forge test --match-test testStorageSlotCalculation -vvvv

test-manipulatemint-solution: ## Test ManipulateMint complete challenge solution
	@echo "$(BLUE)Testing ManipulateMint challenge completion...$(NC)"
	@cd challenges/09-ManipulateMint && forge test --match-test testChallengeCompletion -vvvv

deploy-manipulatemint: ## Deploy ManipulateMint to testnet (requires YOUR_PRIVATE_KEY)
	@echo "$(BLUE)Deploying ManipulateMint to Sepolia testnet...$(NC)"
	@if [ -z "$$YOUR_PRIVATE_KEY" ]; then \
		echo "$(RED)❌ Error: YOUR_PRIVATE_KEY environment variable not set$(NC)"; \
		echo "$(YELLOW)Please set: export YOUR_PRIVATE_KEY=\"0x...\"$(NC)"; \
		echo "$(YELLOW)⚠️  Use test accounts only - NEVER commit real keys!$(NC)"; \
		exit 1; \
	fi
	@cd challenges/09-ManipulateMint && ./deploy_direct.sh

exploit-manipulatemint-live: ## Exploit live ManipulateMint contract on Sepolia
	@echo "$(BLUE)Exploiting live ManipulateMint contract...$(NC)"
	@echo "$(YELLOW)Target: 0xd30dC089482993B6Aee1e788b78e6A27aa5d129b$(NC)"
	@if [ -z "$$YOUR_PRIVATE_KEY" ]; then \
		echo "$(RED)❌ Error: YOUR_PRIVATE_KEY not set$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)🎯 Checking contract state...$(NC)"
	@cast call 0xd30dC089482993B6Aee1e788b78e6A27aa5d129b "totalSupply()" \
		--rpc-url https://eth-sepolia.g.alchemy.com/v2/demo
	@echo "$(BLUE)⚡ Executing storage manipulation exploit...$(NC)"
	@cast send 0xd30dC089482993B6Aee1e788b78e6A27aa5d129b \
		"manipulateMint(uint256)" 5000000000000000000000000 \
		--private-key $$YOUR_PRIVATE_KEY \
		--rpc-url https://eth-sepolia.g.alchemy.com/v2/demo && \
	echo "$(GREEN)✅ Exploit executed! Check balance exceeds max supply$(NC)"

check-manipulatemint-live: ## Check live ManipulateMint contract state
	@echo "$(BLUE)Checking ManipulateMint contract state on Sepolia...$(NC)"
	@echo "$(YELLOW)Contract: 0xd30dC089482993B6Aee1e788b78e6A27aa5d129b$(NC)"
	@echo ""
	@echo "$(BLUE)📊 Contract Information:$(NC)"
	@echo -n "  Name: "
	@cast call 0xd30dC089482993B6Aee1e788b78e6A27aa5d129b "name()" \
		--rpc-url https://eth-sepolia.g.alchemy.com/v2/demo | \
		cast --to-ascii
	@echo -n "  Symbol: "
	@cast call 0xd30dC089482993B6Aee1e788b78e6A27aa5d129b "symbol()" \
		--rpc-url https://eth-sepolia.g.alchemy.com/v2/demo | \
		cast --to-ascii
	@echo ""
	@echo "$(BLUE)📈 Supply Information:$(NC)"
	@TOTAL_SUPPLY_HEX=$$(cast call 0xd30dC089482993B6Aee1e788b78e6A27aa5d129b "totalSupply()" --rpc-url https://eth-sepolia.g.alchemy.com/v2/demo); \
	TOTAL_SUPPLY_DEC=$$(cast --to-dec $$TOTAL_SUPPLY_HEX); \
	echo "  Total Supply: $$TOTAL_SUPPLY_DEC tokens ($$TOTAL_SUPPLY_HEX)"
	@MAX_SUPPLY_HEX=$$(cast call 0xd30dC089482993B6Aee1e788b78e6A27aa5d129b "MAX_SUPPLY()" --rpc-url https://eth-sepolia.g.alchemy.com/v2/demo); \
	MAX_SUPPLY_DEC=$$(cast --to-dec $$MAX_SUPPLY_HEX); \
	MAX_SUPPLY_TOKENS=$$(cast --to-unit $$MAX_SUPPLY_HEX ether); \
	echo "  Max Supply: $$MAX_SUPPLY_TOKENS tokens ($$MAX_SUPPLY_DEC wei)"
	@echo "$(GREEN)✅ Contract state retrieved$(NC)"

analyze-manipulatemint: ## Analyze ManipulateMint assembly operations
	@echo "$(BLUE)Analyzing ManipulateMint assembly vulnerabilities...$(NC)"
	@echo ""
	@echo "$(YELLOW)🔍 Searching for assembly blocks:$(NC)"
	@cd challenges/09-ManipulateMint && grep -n "assembly\|sstore" src/ManipulateMint.sol || echo "No matches found"
	@echo ""
	@echo "$(YELLOW)🔍 Function signatures:$(NC)"
	@echo "  manipulateMint(uint256): $$(cast sig 'manipulateMint(uint256)')"
	@echo "  checkSolution(): $$(cast sig 'checkSolution()')"
	@echo "  getStorageInconsistency(): $$(cast sig 'getStorageInconsistency()')"
	@echo ""
	@echo "$(YELLOW)📋 Storage Layout Analysis:$(NC)"
	@echo "  _balances mapping slot: 0"
	@echo "  Storage calculation: keccak256(address, 0)"
	@echo "$(GREEN)✅ Assembly analysis complete$(NC)"

decode-hex: ## Convert hex values to readable format (usage: make decode-hex HEX=0x123...)
	@if [ -z "$(HEX)" ]; then \
		echo "$(RED)Error: HEX parameter required$(NC)"; \
		echo "$(YELLOW)Usage: make decode-hex HEX=\"0x1234...\"$(NC)"; \
		echo "$(YELLOW)Example: make decode-hex HEX=\"0x00000000000000000000000000000000000000000000d3c21bcecceda1000000\"$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Hex Value Decoder$(NC)"
	@echo "$(YELLOW)Input:$(NC) $(HEX)"
	@echo "$(YELLOW)Decimal:$(NC) $$(cast --to-dec $(HEX))"
	@echo "$(YELLOW)Ether:$(NC) $$(cast --to-unit $(HEX) ether) ETH"
	@echo "$(YELLOW)Tokens (18 decimals):$(NC) $$(cast --to-unit $(HEX) ether) tokens"

decode-manipulatemint-values: ## Decode the specific hex values from live contract
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║      ManipulateMint Live Contract Value Decoder    ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)📊 Total Supply Analysis:$(NC)"
	@$(MAKE) decode-hex HEX="0x0000000000000000000000000000000000000000000000000000000000000000"
	@echo ""
	@echo "$(YELLOW)📊 Max Supply Analysis:$(NC)"
	@$(MAKE) decode-hex HEX="0x00000000000000000000000000000000000000000000d3c21bcecceda1000000"
	@echo ""
	@echo "$(GREEN)💡 Analysis Result:$(NC)"
	@echo "  • Total Supply: 0 tokens (normal after deployment)"
	@echo "  • Max Supply: 1,000,000 tokens (1M token limit)"
	@echo "  • Vulnerability: Assembly can bypass the 1M limit!"
	@echo "  • Attack Goal: Get balance > 1,000,000 tokens"

demo-manipulatemint: ## Complete ManipulateMint challenge demonstration
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║     ManipulateMint Challenge Complete Demo        ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)▸ 1. Running comprehensive test suite$(NC)"
	@$(MAKE) test-manipulatemint
	@echo ""
	@echo "$(YELLOW)▸ 2. Analyzing assembly vulnerability$(NC)"
	@$(MAKE) analyze-manipulatemint
	@echo ""
	@echo "$(YELLOW)▸ 3. Testing specific vulnerability$(NC)"
	@$(MAKE) test-manipulatemint-vulnerability
	@echo ""
	@echo "$(YELLOW)▸ 4. Checking live contract state$(NC)"
	@$(MAKE) check-manipulatemint-live
	@echo ""
	@echo "$(GREEN)✅ ManipulateMint demonstration complete!$(NC)"
	@echo "$(BLUE)🎯 Challenge: Storage slot manipulation via assembly$(NC)"
	@echo "$(BLUE)💡 Key Learning: Assembly can bypass ALL Solidity safety checks$(NC)"

list-manipulatemint: ## List all ManipulateMint commands
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║        ManipulateMint Challenge Commands          ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)Testing Commands:$(NC)"
	@echo "  make test-manipulatemint           - Run all tests"
	@echo "  make test-manipulatemint-verbose   - Verbose test output"
	@echo "  make test-manipulatemint-vulnerability - Test assembly exploit"
	@echo "  make test-manipulatemint-assembly  - Test storage manipulation"
	@echo "  make test-manipulatemint-solution  - Test challenge completion"
	@echo ""
	@echo "$(GREEN)Analysis Commands:$(NC)"
	@echo "  make analyze-manipulatemint        - Assembly vulnerability analysis"
	@echo "  make check-manipulatemint-live     - Check live contract state"
	@echo "  make decode-manipulatemint-values  - Decode live contract hex values"
	@echo "  make decode-hex HEX=\"0x123...\"     - Convert any hex to readable format"
	@echo ""
	@echo "$(GREEN)Deployment Commands:$(NC)"
	@echo "  make deploy-manipulatemint         - Deploy to Sepolia (needs YOUR_PRIVATE_KEY)"
	@echo "  make exploit-manipulatemint-live   - Exploit live contract"
	@echo ""
	@echo "$(GREEN)Demo Command:$(NC)"
	@echo "  make demo-manipulatemint           - Complete demonstration"
	@echo ""
	@echo "$(YELLOW)Security Reminder:$(NC)"
	@echo "  ⚠️  Always use test private keys - NEVER commit real keys!"
	@echo "  📖 See challenges/09-ManipulateMint/SECURITY.md for guidelines"

manipulatemint-summary: ## Show complete ManipulateMint challenge summary
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║       ManipulateMint Challenge Summary            ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)🎯 Challenge Goal:$(NC)"
	@echo "  Exploit storage slot manipulation to mint unlimited tokens"
	@echo ""
	@echo "$(YELLOW)🔍 Vulnerability:$(NC)"
	@echo "  Assembly 'sstore' bypasses ALL Solidity safety checks"
	@echo ""
	@echo "$(YELLOW)📊 Live Contract Analysis:$(NC)"
	@$(MAKE) check-manipulatemint-live
	@echo ""
	@echo "$(YELLOW)⚡ Exploit Impact:$(NC)"
	@echo "  • Normal limit: 1,000,000 tokens maximum"
	@echo "  • Assembly bypass: Unlimited token creation"
	@echo "  • Result: balance > totalSupply (broken economics)"
	@echo ""
	@echo "$(YELLOW)🛠️  Key Commands:$(NC)"
	@echo "  make demo-manipulatemint           # Complete walkthrough"
	@echo "  make test-manipulatemint-vulnerability # See the exploit"
	@echo "  make decode-manipulatemint-values  # Understand hex values"
	@echo ""
	@echo "$(GREEN)💡 Educational Value:$(NC)"
	@echo "  Learn why assembly requires extreme caution in smart contracts!"

# ═══════════════════════════════════════════════════════════════
# Challenge 10: PhantomOwner - Fake Ownership Renouncement
# ═══════════════════════════════════════════════════════════════

test-phantomowner: ## Run PhantomOwner challenge test suite
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║         PhantomOwner Challenge Test Suite          ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)Running comprehensive PhantomOwner tests...$(NC)"
	@cd challenges/10-PhantomOwner && forge test
	@echo "$(GREEN)✅ PhantomOwner tests completed$(NC)"

test-phantomowner-verbose: ## Run PhantomOwner tests with verbose output
	@echo "$(BLUE)Running PhantomOwner tests in verbose mode...$(NC)"
	@cd challenges/10-PhantomOwner && forge test -vvv

test-phantomowner-vulnerability: ## Test specific phantom ownership vulnerability
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║     PhantomOwner Vulnerability Demonstration       ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)Testing fake ownership renouncement exploit...$(NC)"
	@cd challenges/10-PhantomOwner && forge test --match-test "testFakeOwnershipRenouncement" -vv
	@echo "$(GREEN)✅ Phantom ownership vulnerability demonstrated$(NC)"

test-phantomowner-assembly: ## Test PhantomOwner assembly backdoors
	@echo "$(BLUE)Testing PhantomOwner assembly backdoor mechanisms...$(NC)"
	@cd challenges/10-PhantomOwner && forge test --match-test "testAssemblyOwnershipReclaim" -vv
	@cd challenges/10-PhantomOwner && forge test --match-test "testShadowReclaimBackdoor" -vv
	@echo "$(GREEN)✅ Assembly backdoor tests completed$(NC)"

test-phantomowner-renouncement: ## Test fake renouncement behavior
	@echo "$(BLUE)Testing PhantomOwner fake renouncement scenarios...$(NC)"
	@cd challenges/10-PhantomOwner && forge test --match-test "testFakeOwnershipRenouncement" -vv
	@cd challenges/10-PhantomOwner && forge test --match-test "testMultipleRenounceReclaimCycles" -vv
	@echo "$(GREEN)✅ Fake renouncement tests completed$(NC)"

test-phantomowner-storage: ## Test storage manipulation in PhantomOwner
	@echo "$(BLUE)Testing PhantomOwner storage slot manipulation...$(NC)"
	@cd challenges/10-PhantomOwner && forge test --match-test "testStorageSlotInspection" -vv
	@cd challenges/10-PhantomOwner && forge test --match-test "testStorageLayoutInfo" -vv
	@echo "$(GREEN)✅ Storage manipulation tests completed$(NC)"

build-phantomowner: ## Build PhantomOwner contracts
	@echo "$(BLUE)Building PhantomOwner contracts...$(NC)"
	@cd challenges/10-PhantomOwner && forge build
	@echo "$(GREEN)✅ PhantomOwner contracts built$(NC)"

deploy-phantomowner: ## Deploy PhantomOwner to Sepolia testnet
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║       Deploy PhantomOwner to Sepolia Testnet      ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@if [ -z "$(PRIVATE_KEY)" ]; then \
		echo "$(RED)Error: PRIVATE_KEY environment variable is required$(NC)"; \
		echo "$(YELLOW)Usage: PRIVATE_KEY=your_key make deploy-phantomowner$(NC)"; \
		echo "$(YELLOW)⚠️  Security: Use test keys only - NEVER commit real keys!$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Deploying PhantomOwner with fake ownership renouncement...$(NC)"
	@cd challenges/10-PhantomOwner && chmod +x deploy_direct.sh && ./deploy_direct.sh
	@echo "$(GREEN)✅ PhantomOwner deployment completed$(NC)"

analyze-phantomowner: ## Analyze PhantomOwner assembly operations and backdoors
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║     PhantomOwner Assembly Vulnerability Analysis   ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)🔍 Searching for assembly blocks and backdoors:$(NC)"
	@cd challenges/10-PhantomOwner && grep -n "assembly\|sstore\|mstore\|keccak256" src/PhantomOwner.sol || echo "No matches found"
	@echo ""
	@echo "$(YELLOW)🔍 Critical function signatures:$(NC)"
	@echo "  renounceOwnership(): $$(cast sig 'renounceOwnership()')"
	@echo "  reclaimOwnership(): $$(cast sig 'reclaimOwnership()')"
	@echo "  shadowReclaim(): $$(cast sig 'shadowReclaim()')"
	@echo "  verifyPhantomOwnership(): $$(cast sig 'verifyPhantomOwnership()')"
	@echo ""
	@echo "$(YELLOW)📋 Storage Layout Analysis:$(NC)"
	@echo "  _owner slot: 0x0"
	@echo "  oldOwner slot: keccak256('phantom.oldowner')"
	@echo "  Shadow storage: Assembly-manipulated slots"
	@echo ""
	@echo "$(RED)⚠️  Phantom Ownership Attack Pattern:$(NC)"
	@echo "  1. Contract appears to renounce ownership (owner = address(0))"
	@echo "  2. Hidden assembly backdoors preserve original owner in secret storage"
	@echo "  3. Owner can reclaim control anytime via assembly functions"
	@echo "  4. Users believe contract is decentralized while owner maintains control"
	@echo "$(GREEN)✅ PhantomOwner analysis complete$(NC)"

demo-phantomowner: ## Complete PhantomOwner challenge demonstration
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║     PhantomOwner Challenge Complete Demo          ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)▸ 1. Running comprehensive test suite$(NC)"
	@$(MAKE) test-phantomowner
	@echo ""
	@echo "$(YELLOW)▸ 2. Analyzing assembly backdoors$(NC)"
	@$(MAKE) analyze-phantomowner
	@echo ""
	@echo "$(YELLOW)▸ 3. Testing phantom ownership vulnerability$(NC)"
	@$(MAKE) test-phantomowner-vulnerability
	@echo ""
	@echo "$(YELLOW)▸ 4. Demonstrating fake renouncement$(NC)"
	@$(MAKE) test-phantomowner-renouncement
	@echo ""
	@echo "$(GREEN)✅ PhantomOwner demonstration complete!$(NC)"
	@echo "$(BLUE)🎯 Challenge: Fake ownership renouncement with assembly backdoors$(NC)"
	@echo "$(BLUE)💡 Key Learning: Never trust 'renounced' contracts without code audit!$(NC)"

list-phantomowner: ## List all PhantomOwner commands
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║         PhantomOwner Challenge Commands           ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)Testing Commands:$(NC)"
	@echo "  make test-phantomowner             - Run all tests"
	@echo "  make test-phantomowner-verbose     - Verbose test output"
	@echo "  make test-phantomowner-vulnerability - Test phantom ownership exploit"
	@echo "  make test-phantomowner-assembly    - Test assembly backdoors"
	@echo "  make test-phantomowner-renouncement - Test fake renouncement"
	@echo "  make test-phantomowner-storage     - Test storage manipulation"
	@echo ""
	@echo "$(GREEN)Analysis Commands:$(NC)"
	@echo "  make analyze-phantomowner          - Assembly backdoor analysis"
	@echo "  make build-phantomowner            - Build contracts"
	@echo ""
	@echo "$(GREEN)Deployment Commands:$(NC)"
	@echo "  make deploy-phantomowner           - Deploy to Sepolia (needs PRIVATE_KEY)"
	@echo ""
	@echo "$(GREEN)Demo Command:$(NC)"
	@echo "  make demo-phantomowner             - Complete demonstration"
	@echo ""
	@echo "$(YELLOW)Security Reminder:$(NC)"
	@echo "  ⚠️  This demonstrates dangerous fake decentralization attacks!"
	@echo "  📖 See challenges/10-PhantomOwner/README.md for detailed analysis"

phantomowner-summary: ## Show complete PhantomOwner challenge summary
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║        PhantomOwner Challenge Summary             ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)🎯 Challenge Goal:$(NC)"
	@echo "  Understand fake ownership renouncement with assembly backdoors"
	@echo ""
	@echo "$(YELLOW)🔍 Vulnerability:$(NC)"
	@echo "  Contracts appear decentralized but owner maintains secret control"
	@echo ""
	@echo "$(YELLOW)⚠️  Attack Pattern:$(NC)"
	@echo "  • renounceOwnership() sets owner = address(0)"
	@echo "  • Assembly stores real owner in hidden storage slot"
	@echo "  • reclaimOwnership() restores control via assembly"
	@echo "  • Users believe contract is trustless while owner controls everything"
	@echo ""
	@echo "$(YELLOW)🛡️  Defense:$(NC)"
	@echo "  • Always audit contract code before trusting 'renounced' ownership"
	@echo "  • Look for assembly blocks and hidden storage manipulation"
	@echo "  • Verify ownership renouncement through multiple analysis tools"
	@echo ""
	@echo "$(YELLOW)🛠️  Key Commands:$(NC)"
	@echo "  make demo-phantomowner             # Complete walkthrough"
	@echo "  make test-phantomowner-vulnerability # See the phantom attack"
	@echo "  make analyze-phantomowner          # Understand assembly backdoors"
	@echo ""
	@echo "$(GREEN)💡 Educational Value:$(NC)"
	@echo "  Learn to identify sophisticated ownership deception attacks!"

detect-phantom-ownership: ## Analyze a contract for phantom ownership patterns (usage: make detect-phantom-ownership CONTRACT=0x123...)
	@if [ -z "$(CONTRACT)" ]; then \
		echo "$(RED)Error: CONTRACT parameter required$(NC)"; \
		echo "$(YELLOW)Usage: make detect-phantom-ownership CONTRACT=\"0x1234...\"$(NC)"; \
		echo "$(YELLOW)Example: make detect-phantom-ownership CONTRACT=\"0xd30dC089482993B6Aee1e788b78e6A27aa5d129b\"$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Running phantom ownership detection on $(CONTRACT)...$(NC)"
	@./phantom-ownership-detector.sh $(CONTRACT)

analyze-manipulatemint-vs-phantomowner: ## Compare legitimate vs phantom ownership patterns
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║               OWNERSHIP ANALYSIS COMPARISON                    ║$(NC)"
	@echo "$(BLUE)║        Legitimate vs Phantom Ownership Patterns               ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)🟢 LEGITIMATE CONTRACT: ManipulateMint (Live on Sepolia)$(NC)"
	@$(MAKE) detect-phantom-ownership CONTRACT="0xd30dC089482993B6Aee1e788b78e6A27aa5d129b"
	@echo ""
	@echo "$(RED)🔴 PHANTOM OWNERSHIP ATTACK: PhantomOwner (Local Demo)$(NC)"
	@echo "Running local phantom ownership demonstration..."
	@$(MAKE) test-phantomowner-vulnerability
	@echo ""
	@echo "$(YELLOW)📊 COMPARISON SUMMARY:$(NC)"
	@echo "$(GREEN)✅ ManipulateMint:$(NC) Transparent ownership, legitimate contract"
	@echo "$(RED)⚠️  PhantomOwner:$(NC) Fake renouncement with assembly backdoors"
	@echo ""
	@echo "$(BLUE)🎯 Key Learning:$(NC) Always verify 'renounced' contracts with code audit!"

# ═══════════════════════════════════════════════════════════════
# Challenge 11: GasGrief - Gas Griefing & DoS Attacks
# ═══════════════════════════════════════════════════════════════

test-gasgrief: ## Run GasGrief challenge test suite
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║          GasGrief Challenge Test Suite             ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)Running comprehensive GasGrief tests...$(NC)"
	@cd challenges/11-GasGrief && forge test -v
	@echo "$(GREEN)✅ GasGrief tests completed$(NC)"

test-gasgrief-verbose: ## Run GasGrief tests with verbose output
	@echo "$(BLUE)Running GasGrief tests in verbose mode...$(NC)"
	@cd challenges/11-GasGrief && forge test -vv

test-gasgrief-attack: ## Test specific gas griefing attack vectors
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║       GasGrief Attack Vector Demonstration         ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)Testing gas griefing attack patterns...$(NC)"
	@cd challenges/11-GasGrief && forge test --match-test "testGasGriefing" -vv
	@cd challenges/11-GasGrief && forge test --match-test "testDoS" -vv
	@cd challenges/11-GasGrief && forge test --match-test "testExtreme" -vv
	@cd challenges/11-GasGrief && forge test --match-test "testBatchProcessingGasGrief" -vv
	@echo "$(GREEN)✅ Gas griefing attacks demonstrated$(NC)"

test-gasgrief-mitigation: ## Test gas-optimized mitigation functions
	@echo "$(BLUE)Testing GasGrief mitigation strategies...$(NC)"
	@cd challenges/11-GasGrief && forge test --match-test "testOptimized\|testPaginated" -vv
	@echo "$(GREEN)✅ Gas mitigation tests completed$(NC)"

test-gasgrief-analysis: ## Test gas consumption analysis functions
	@echo "$(BLUE)Testing GasGrief gas consumption analysis...$(NC)"
	@cd challenges/11-GasGrief && forge test --match-test "testGasAnalysis\|testGasSimulation\|testGasLimit" -vv
	@echo "$(GREEN)✅ Gas analysis tests completed$(NC)"

build-gasgrief: ## Build GasGrief contracts
	@echo "$(BLUE)Building GasGrief contracts...$(NC)"
	@cd challenges/11-GasGrief && forge build
	@echo "$(GREEN)✅ GasGrief contracts built$(NC)"

deploy-gasgrief: ## Deploy GasGrief to Sepolia testnet
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║        Deploy GasGrief to Sepolia Testnet          ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@if [ -z "$(PRIVATE_KEY)" ]; then \
		echo "$(RED)Error: PRIVATE_KEY environment variable is required$(NC)"; \
		echo "$(YELLOW)Usage: PRIVATE_KEY=your_key make deploy-gasgrief$(NC)"; \
		echo "$(YELLOW)⚠️  Security: Use test keys only - NEVER commit real keys!$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Deploying GasGrief with gas griefing vulnerabilities...$(NC)"
	@cd challenges/11-GasGrief && chmod +x deploy_direct.sh && ./deploy_direct.sh
	@echo "$(GREEN)✅ GasGrief deployment completed$(NC)"

analyze-gasgrief-consumption: ## Analyze gas consumption patterns and DoS vectors
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║     GasGrief Gas Consumption Analysis              ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)🔍 Gas Consumption Patterns:$(NC)"
	@echo "  • Normal operation: ~50,000 gas"
	@echo "  • 100 participants: ~2,000,000 gas"
	@echo "  • 1000 participants: ~20,000,000 gas (approaching block limit!)"
	@echo "  • 10000 participants: IMPOSSIBLE (exceeds block gas limit)"
	@echo ""
	@echo "$(YELLOW)⚠️  DoS Attack Vectors:$(NC)"
	@echo "  1. Unbounded loops in addParticipants()"
	@echo "  2. Linear gas growth in distributeRewards()"
	@echo "  3. Quadratic gas consumption in batchProcessOperations()"
	@echo "  4. User-controlled iterations in computeExpensiveFunction()"
	@echo ""
	@echo "$(YELLOW)🛡️  Mitigation Strategies:$(NC)"
	@echo "  • Implement gas limits (max 50 participants per batch)"
	@echo "  • Use pagination for large operations"
	@echo "  • Add circuit breakers (gasleft() checks)"
	@echo "  • Bound user-controlled loops"
	@echo "$(GREEN)✅ Gas consumption analysis complete$(NC)"

gas-report-gasgrief: ## Generate detailed gas report for GasGrief
	@echo "$(BLUE)Generating GasGrief gas consumption report...$(NC)"
	@cd challenges/11-GasGrief && forge test --gas-report
	@echo "$(GREEN)✅ Gas report generated$(NC)"

demo-gasgrief: ## Complete GasGrief challenge demonstration
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║        GasGrief Challenge Complete Demo            ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)▸ 1. Running comprehensive test suite$(NC)"
	@$(MAKE) test-gasgrief
	@echo ""
	@echo "$(YELLOW)▸ 2. Analyzing gas consumption patterns$(NC)"
	@$(MAKE) analyze-gasgrief-consumption
	@echo ""
	@echo "$(YELLOW)▸ 3. Demonstrating gas griefing attacks$(NC)"
	@$(MAKE) test-gasgrief-attack
	@echo ""

# ═══════════════════════════════════════════════════════════════
# Challenge 12: TimeLocked - Timestamp Manipulation & Timelock Bypass
# ═══════════════════════════════════════════════════════════════

test-timelocked: ## Run TimeLocked challenge test suite
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║         TimeLocked Challenge Test Suite            ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)Running comprehensive TimeLocked tests...$(NC)"
	@cd challenges/12-TimeLocked && forge test -v
	@echo "$(GREEN)✅ TimeLocked tests completed$(NC)"

test-timelocked-verbose: ## Run TimeLocked tests with verbose output
	@echo "$(BLUE)Running TimeLocked tests in verbose mode...$(NC)"
	@cd challenges/12-TimeLocked && forge test -vv

test-timelocked-attack: ## Test specific timestamp manipulation attack vectors
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║     Timestamp Manipulation Attack Demonstration   ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)Testing timestamp manipulation attack patterns...$(NC)"
	@cd challenges/12-TimeLocked && forge test --match-test "testTimestampManipulation" -vv
	@cd challenges/12-TimeLocked && forge test --match-test "testGovernanceTimelock" -vv
	@cd challenges/12-TimeLocked && forge test --match-test "testAdminTimelock" -vv
	@cd challenges/12-TimeLocked && forge test --match-test "testPredictableRandomness" -vv
	@cd challenges/12-TimeLocked && forge test --match-test "testTimeLotteryManipulation" -vv
	@cd challenges/12-TimeLocked && forge test --match-test "testEmergencyDelayBypass" -vv
	@echo "$(GREEN)✅ Timestamp manipulation attacks demonstrated$(NC)"

test-timelocked-mitigation: ## Test secure timing mechanisms and mitigations
	@echo "$(BLUE)Testing TimeLocked mitigation strategies...$(NC)"
	@cd challenges/12-TimeLocked && forge test --match-test "testSecureTimeLock\|testCommitReveal" -vv
	@echo "$(GREEN)✅ Timing security mitigation tests completed$(NC)"

test-timelocked-analysis: ## Test timestamp risk analysis and detection
	@echo "$(BLUE)Testing TimeLocked risk analysis functions...$(NC)"
	@cd challenges/12-TimeLocked && forge test --match-test "testTimestampRiskAnalysis\|testTimelockBypassCheck\|testContractState" -vv
	@echo "$(GREEN)✅ Timestamp risk analysis tests completed$(NC)"

build-timelocked: ## Build TimeLocked contracts
	@echo "$(BLUE)Building TimeLocked contracts...$(NC)"
	@cd challenges/12-TimeLocked && forge build
	@echo "$(GREEN)✅ TimeLocked contracts built$(NC)"

deploy-timelocked: ## Deploy TimeLocked to Sepolia testnet
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║       Deploy TimeLocked to Sepolia Testnet        ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@if [ -z "$(PRIVATE_KEY)" ]; then \
		echo "$(RED)Error: PRIVATE_KEY environment variable is required$(NC)"; \
		echo "$(YELLOW)Usage: PRIVATE_KEY=your_key make deploy-timelocked$(NC)"; \
		echo "$(YELLOW)⚠️  Security: Use test keys only - NEVER commit real keys!$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Deploying TimeLocked with timestamp vulnerabilities...$(NC)"
	@cd challenges/12-TimeLocked && chmod +x deploy_direct.sh && ./deploy_direct.sh
	@echo "$(GREEN)✅ TimeLocked deployment completed$(NC)"

analyze-timelocked-timing: ## Analyze timestamp manipulation windows and risks
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║    TimeLocked Timestamp Manipulation Analysis     ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)⏰ Timestamp Manipulation Windows:$(NC)"
	@echo "  • Miner manipulation range: ±15 seconds"
	@echo "  • Short timelock vulnerability: < 15 minutes"
	@echo "  • Medium risk window: 15 minutes - 1 hour"
	@echo "  • Long timelock security: > 1 hour"
	@echo ""
	@echo "$(YELLOW)🎯 Attack Vectors:$(NC)"
	@echo "  1. Vault withdrawal bypass (immediate unlock)"
	@echo "  2. Governance proposal acceleration (early execution)"
	@echo "  3. Admin timelock circumvention (instant changes)"
	@echo "  4. Random seed prediction (deterministic outcomes)"
	@echo "  5. Time-based lottery manipulation (guaranteed wins)"
	@echo "  6. Emergency function timing attacks (premature access)"
	@echo ""
	@echo "$(YELLOW)🛡️  Security Recommendations:$(NC)"
	@echo "  • Use block.number for delays < 256 blocks"
	@echo "  • Implement commit-reveal for randomness"
	@echo "  • Add timestamp manipulation detection"
	@echo "  • Design buffer zones around critical timeframes"
	@echo "  • Use oracle-based time for critical operations"
	@echo "$(GREEN)✅ Timestamp manipulation analysis complete$(NC)"

gas-report-timelocked: ## Generate detailed gas report for TimeLocked
	@echo "$(BLUE)Generating TimeLocked gas consumption report...$(NC)"
	@cd challenges/12-TimeLocked && forge test --gas-report
	@echo "$(GREEN)✅ Gas report generated$(NC)"

demo-timelocked: ## Complete TimeLocked challenge demonstration
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║       TimeLocked Challenge Complete Demo           ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)▸ 1. Running comprehensive test suite$(NC)"
	@$(MAKE) test-timelocked
	@echo ""
	@echo "$(YELLOW)▸ 2. Analyzing timestamp manipulation risks$(NC)"
	@$(MAKE) analyze-timelocked-timing
	@echo ""
	@echo "$(YELLOW)▸ 3. Demonstrating timestamp attacks$(NC)"
	@$(MAKE) test-timelocked-attack
	@echo ""
	@echo "$(YELLOW)▸ 4. Testing secure timing mitigations$(NC)"
	@$(MAKE) test-timelocked-mitigation
	@echo ""
	@echo "$(YELLOW)▸ 4. Testing mitigation strategies$(NC)"
	@$(MAKE) test-gasgrief-mitigation
	@echo ""
	@echo "$(GREEN)✅ GasGrief demonstration complete!$(NC)"
	@echo "$(BLUE)🎯 Challenge: Gas griefing attacks via unbounded loops$(NC)"
	@echo "$(BLUE)💡 Key Learning: Always implement gas limits and pagination!$(NC)"

list-gasgrief: ## List all GasGrief commands
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║           GasGrief Challenge Commands              ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)Testing Commands:$(NC)"
	@echo "  make test-gasgrief                 - Run all tests"
	@echo "  make test-gasgrief-verbose         - Verbose test output"
	@echo "  make test-gasgrief-attack          - Test gas griefing attacks"
	@echo "  make test-gasgrief-mitigation      - Test mitigation strategies"
	@echo "  make test-gasgrief-analysis        - Test gas analysis functions"
	@echo ""
	@echo "$(GREEN)Analysis Commands:$(NC)"
	@echo "  make analyze-gasgrief-consumption  - Gas consumption analysis"
	@echo "  make gas-report-gasgrief           - Generate detailed gas report"
	@echo "  make build-gasgrief                - Build contracts"
	@echo ""
	@echo "$(GREEN)Deployment Commands:$(NC)"
	@echo "  make deploy-gasgrief               - Deploy to Sepolia (needs PRIVATE_KEY)"
	@echo ""
	@echo "$(GREEN)Demo Command:$(NC)"
	@echo "  make demo-gasgrief                 - Complete demonstration"
	@echo ""
	@echo "$(YELLOW)Security Reminder:$(NC)"
	@echo "  ⚠️  This demonstrates dangerous DoS attack patterns!"
	@echo "  📖 See challenges/11-GasGrief/README.md for detailed analysis"

gasgrief-summary: ## Show complete GasGrief challenge summary
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║         GasGrief Challenge Summary                 ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)🎯 Challenge Goal:$(NC)"
	@echo "  Learn to identify and prevent gas griefing & DoS attacks"
	@echo ""
	@echo "$(YELLOW)🔍 Vulnerability:$(NC)"
	@echo "  Unbounded loops allow attackers to consume excessive gas"
	@echo ""
	@echo "$(YELLOW)⚠️  Attack Patterns:$(NC)"
	@echo "  • addParticipants(): Unbounded array processing"
	@echo "  • distributeRewards(): Linear gas growth with participants"
	@echo "  • batchProcessOperations(): Nested loops (quadratic gas)"
	@echo "  • computeExpensiveFunction(): User-controlled iterations"
	@echo ""
	@echo "$(YELLOW)🛡️  Defense Strategies:$(NC)"
	@echo "  • Implement strict gas limits on operations"
	@echo "  • Use pagination for large data processing"
	@echo "  • Add circuit breakers (gasleft() monitoring)"
	@echo "  • Bound all user-controlled loop parameters"
	@echo ""
	@echo "$(YELLOW)🛠️  Key Commands:$(NC)"
	@echo "  make demo-gasgrief                 # Complete walkthrough"
	@echo "  make test-gasgrief-attack          # See gas griefing attacks"
	@echo "  make analyze-gasgrief-consumption  # Understand gas patterns"
	@echo ""
	@echo "$(GREEN)💡 Educational Value:$(NC)"
	@echo "  Learn to build gas-efficient and DoS-resistant smart contracts!"

# ═══════════════════════════════════════════════════════════════
# Echidna Fuzzing
# ═══════════════════════════════════════════════════════════════

echidna: ## Run Echidna on all challenges
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║         Running Echidna on All Challenges         ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@$(MAKE) echidna-fallback
	@$(MAKE) echidna-telephone
	@$(MAKE) echidna-doubleentrypoint
	@$(MAKE) echidna-casino

echidna-fallback: ## Run Echidna on Fallback challenge
	@echo "$(YELLOW)═══ Challenge 02: Fallback ═══$(NC)"
	@if [ -f challenges/02-Fallback/echidna/FallbackEchidna.sol ]; then \
		cd challenges/02-Fallback && \
		echidna echidna/FallbackEchidna.sol \
			--contract FallbackEchidna \
			--test-limit 50000 \
			--seq-len 50 \
			--format text && \
		echo "$(GREEN)✓ Fallback fuzzing complete!$(NC)" || \
		echo "$(RED)✗ Fallback fuzzing failed$(NC)"; \
	else \
		echo "$(RED)✗ Fallback Echidna harness not found$(NC)"; \
	fi
	@echo ""

echidna-fallback-quick: ## Quick Echidna test on Fallback (1000 tests)
	@echo "$(YELLOW)═══ Quick Fallback Test ═══$(NC)"
	@cd challenges/02-Fallback && \
		echidna echidna/FallbackEchidna.sol \
			--contract FallbackEchidna \
			--test-limit 1000

echidna-fallback-verbose: ## Verbose Echidna on Fallback
	@echo "$(YELLOW)═══ Fallback (Verbose) ═══$(NC)"
	@cd challenges/02-Fallback && \
		echidna echidna/FallbackEchidna.sol \
			--contract FallbackEchidna \
			--test-limit 50000 \
			--seq-len 50 \
			--format text \
			--corpus-dir corpus

echidna-fallback-coverage: ## Echidna on Fallback with coverage
	@echo "$(YELLOW)═══ Fallback (Coverage) ═══$(NC)"
	@cd challenges/02-Fallback && \
		echidna echidna/FallbackEchidna.sol \
			--contract FallbackEchidna \
			--test-limit 50000 \
			--coverage

echidna-telephone: ## Run Echidna on Telephone challenge
	@echo "$(YELLOW)═══ Challenge 03: Telephone ═══$(NC)"
	@if [ -f challenges/03-Telephone/echidna/TelephoneEchidna.sol ]; then \
		cd challenges/03-Telephone && \
		echidna echidna/TelephoneEchidna.sol \
			--contract TelephoneEchidna \
			--config echidna/telephone.yaml \
			--test-limit 50000 \
			--format text && \
		echo "$(GREEN)✓ Telephone fuzzing complete!$(NC)" || \
		echo "$(RED)✗ Telephone fuzzing failed$(NC)"; \
	else \
		echo "$(RED)✗ Telephone Echidna harness not found$(NC)"; \
	fi
	@echo ""

echidna-telephone-quick: ## Quick Echidna test on Telephone (10000 tests)
	@echo "$(YELLOW)═══ Quick Telephone Test ═══$(NC)"
	@echo "$(BLUE)Note: Echidna CAN exploit tx.origin vulnerability through helper contracts$(NC)"
	@cd challenges/03-Telephone && \
		echidna echidna/TelephoneEchidna.sol \
			--contract TelephoneEchidna \
			--test-limit 10000 \
			--format text; \
		echo "$(GREEN)✓ Telephone fuzzing complete! Vulnerability should be found$(NC)"

echidna-telephone-verbose: ## Verbose Echidna on Telephone
	@echo "$(YELLOW)═══ Telephone (Verbose) ═══$(NC)"
	@cd challenges/03-Telephone && \
		echidna echidna/TelephoneEchidna.sol \
			--contract TelephoneEchidna \
			--config echidna/telephone.yaml \
			--test-limit 100000 \
			--format text \
			--corpus-dir corpus

echidna-doubleentrypoint: ## Run Echidna on DoubleEntryPoint challenge
	@echo "$(YELLOW)═══ Challenge 04: DoubleEntryPoint ═══$(NC)"
	@if [ -f challenges/04-DoubleEntryPoint/echidna/DoubleEntryPointEchidna.sol ]; then \
		cd challenges/04-DoubleEntryPoint && \
		echidna echidna/DoubleEntryPointEchidna.sol \
			--contract DoubleEntryPointEchidna \
			--config echidna/doubleentrypoint.yaml \
			--test-limit 50000 \
			--format text && \
		echo "$(GREEN)✓ DoubleEntryPoint fuzzing complete!$(NC)" || \
		echo "$(RED)✗ DoubleEntryPoint fuzzing failed$(NC)"; \
	else \
		echo "$(RED)✗ DoubleEntryPoint Echidna harness not found$(NC)"; \
	fi
	@echo ""

echidna-doubleentrypoint-quick: ## Quick Echidna test on DoubleEntryPoint (10000 tests)
	@echo "$(YELLOW)═══ Quick DoubleEntryPoint Test ═══$(NC)"
	@echo "$(BLUE)Note: Testing delegation attack and detection bot protection$(NC)"
	@cd challenges/04-DoubleEntryPoint && \
		echidna echidna/DoubleEntryPointEchidna.sol \
			--contract DoubleEntryPointEchidna \
			--test-limit 10000 \
			--format text; \
		echo "$(GREEN)✓ DoubleEntryPoint fuzzing complete!$(NC)"

echidna-doubleentrypoint-verbose: ## Verbose Echidna on DoubleEntryPoint
	@echo "$(YELLOW)═══ DoubleEntryPoint (Verbose) ═══$(NC)"
	@cd challenges/04-DoubleEntryPoint && \
		echidna echidna/DoubleEntryPointEchidna.sol \
			--contract DoubleEntryPointEchidna \
			--config echidna/doubleentrypoint.yaml \
			--test-limit 100000 \
			--format text \
			--corpus-dir corpus

echidna-casino: ## Run Echidna on Casino challenge
	@echo "$(YELLOW)═══ Challenge 05: Casino ═══$(NC)"
	@if [ -f challenges/05-Casino/echidna/CasinoEchidna.sol ]; then \
		cd challenges/05-Casino && \
		echidna echidna/CasinoEchidna.sol \
			--contract CasinoEchidna \
			--config echidna/casino.yaml \
			--test-limit 20000 \
			--format text && \
		echo "$(GREEN)✓ Casino fuzzing complete!$(NC)" || \
		echo "$(RED)✗ Casino fuzzing failed$(NC)"; \
	else \
		echo "$(RED)✗ Casino Echidna harness not found$(NC)"; \
	fi
	@echo ""

# ═══════════════════════════════════════════════════════════════
# Development Helpers
# ═══════════════════════════════════════════════════════════════

format: ## Format code with forge fmt
	@echo "$(BLUE)Formatting code...$(NC)"
	@forge fmt
	@echo "$(GREEN)✓ Code formatted!$(NC)"

lint: ## Run linting checks
	@echo "$(BLUE)Linting code...$(NC)"
	@forge fmt --check
	@echo "$(GREEN)✓ Linting complete!$(NC)"

snapshot: ## Create gas snapshot
	@echo "$(BLUE)Creating gas snapshot...$(NC)"
	@forge snapshot
	@echo "$(GREEN)✓ Snapshot created!$(NC)"

# ═══════════════════════════════════════════════════════════════
# Utility Commands
# ═══════════════════════════════════════════════════════════════

selectors: ## Calculate function selectors
	@echo "$(BLUE)Common Function Selectors:$(NC)"
	@echo "$(GREEN)contribute():$(NC)    $$(cast keccak 'contribute()')"
	@echo "$(GREEN)withdraw():$(NC)      $$(cast keccak 'withdraw()')"
	@echo "$(GREEN)owner():$(NC)         $$(cast keccak 'owner()')"
	@echo "$(GREEN)donate(address):$(NC) $$(cast keccak 'donate(address)')"

calc-selector: ## Calculate selector for function (usage: make calc-selector SIG="functionName(type)")
	@if [ -z "$(SIG)" ]; then \
		echo "$(RED)Error: Please provide SIG parameter$(NC)"; \
		echo "$(YELLOW)Usage: make calc-selector SIG=\"functionName(type)\"$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Selector for $(SIG):$(NC)"
	@cast keccak "$(SIG)"

tree: ## Show project structure
	@echo "$(BLUE)Project Structure:$(NC)"
	@tree -L 3 -I 'node_modules|cache|out|artifacts|lib' || ls -R

list-challenges: ## List all challenges
	@echo "$(BLUE)Available Challenges:$(NC)"
	@find challenges -name "*.sol" -path "*/src/*" | \
		grep -v "test\|echidna" | \
		sed 's/challenges\//  /' | \
		sort

# ═══════════════════════════════════════════════════════════════
# CI/CD Commands
# ═══════════════════════════════════════════════════════════════

ci: ## Run all CI checks
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║              Running CI Pipeline                  ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@$(MAKE) clean
	@$(MAKE) build
	@$(MAKE) lint
	@$(MAKE) test
	@$(MAKE) coverage
	@echo "$(GREEN)✓ All CI checks passed!$(NC)"

# ═══════════════════════════════════════════════════════════════
# Documentation
# ═══════════════════════════════════════════════════════════════

docs: ## Generate documentation
	@echo "$(BLUE)Generating documentation...$(NC)"
	@forge doc
	@echo "$(GREEN)✓ Documentation generated!$(NC)"

serve-docs: ## Serve documentation locally
	@echo "$(BLUE)Serving documentation at http://localhost:3000$(NC)"
	@forge doc --serve --port 3000

# ═══════════════════════════════════════════════════════════════
# Advanced Testing
# ═══════════════════════════════════════════════════════════════

fuzz-all: ## Run all fuzzing tests (Foundry + Echidna)
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║            Running All Fuzzing Tests              ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)▸ Foundry Fuzz Tests$(NC)"
	@forge test --fuzz-runs 10000
	@echo ""
	@echo "$(YELLOW)▸ Echidna Property Tests$(NC)"
	@$(MAKE) echidna

benchmark: ## Run benchmarks
	@echo "$(BLUE)Running benchmarks...$(NC)"
	@forge test --gas-report | tee benchmark.txt
	@echo "$(GREEN)✓ Benchmarks saved to benchmark.txt$(NC)"

# ═══════════════════════════════════════════════════════════════
# Challenge Creation
# ═══════════════════════════════════════════════════════════════

new-challenge: ## Create new challenge structure (usage: make new-challenge NUM=03 NAME=Delegation)
	@if [ -z "$(NUM)" ] || [ -z "$(NAME)" ]; then \
		echo "$(RED)Error: NUM and NAME required$(NC)"; \
		echo "$(YELLOW)Usage: make new-challenge NUM=03 NAME=Delegation$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Creating challenge $(NUM)-$(NAME)...$(NC)"
	@mkdir -p challenges/$(NUM)-$(NAME)/src
	@mkdir -p challenges/$(NUM)-$(NAME)/test
	@mkdir -p challenges/$(NUM)-$(NAME)/echidna
	@echo "// SPDX-License-Identifier: MIT" > challenges/$(NUM)-$(NAME)/src/$(NAME).sol
	@echo "pragma solidity ^0.8.18;" >> challenges/$(NUM)-$(NAME)/src/$(NAME).sol
	@echo "" >> challenges/$(NUM)-$(NAME)/src/$(NAME).sol
	@echo "contract $(NAME) {" >> challenges/$(NUM)-$(NAME)/src/$(NAME).sol
	@echo "    // TODO: Implement vulnerable contract" >> challenges/$(NUM)-$(NAME)/src/$(NAME).sol
	@echo "}" >> challenges/$(NUM)-$(NAME)/src/$(NAME).sol
	@echo "$(GREEN)✓ Challenge structure created at challenges/$(NUM)-$(NAME)/$(NC)"

# ═══════════════════════════════════════════════════════════════
# Git Helpers
# ═══════════════════════════════════════════════════════════════

status: ## Show git status and project info
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║            EVM CTF Challenges Status               ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)Git Status:$(NC)"
	@git status -s
	@echo ""
	@echo "$(YELLOW)Challenges:$(NC)"
	@find challenges -maxdepth 1 -mindepth 1 -type d | wc -l | xargs echo "  Total:"
	@echo ""
	@echo "$(YELLOW)Contracts:$(NC)"
	@find challenges -name "*.sol" -path "*/src/*" | wc -l | xargs echo "  Source files:"
	@find challenges -name "*.sol" -path "*/test/*" | wc -l | xargs echo "  Test files:"

commit: ## Quick commit with message (usage: make commit MSG="your message")
	@if [ -z "$(MSG)" ]; then \
		echo "$(RED)Error: MSG required$(NC)"; \
		echo "$(YELLOW)Usage: make commit MSG=\"your commit message\"$(NC)"; \
		exit 1; \
	fi
	@git add .
	@git commit -m "$(MSG)"
	@echo "$(GREEN)✓ Committed: $(MSG)$(NC)"

push: ## Push to remote
	@echo "$(BLUE)Pushing to remote...$(NC)"
	@git push origin main
	@echo "$(GREEN)✓ Pushed to remote!$(NC)"

# ═══════════════════════════════════════════════════════════════
# Reporting
# ═══════════════════════════════════════════════════════════════

report: ## Generate comprehensive test report
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║             EVM CTF Test Report                    ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)Date:$(NC) $$(date '+%Y-%m-%d %H:%M:%S UTC')"
	@echo "$(YELLOW)User:$(NC) obingo31"
	@echo ""
	@echo "$(GREEN)═══ Foundry Tests ═══$(NC)"
	@forge test --gas-report 2>&1 | tee test-report.txt
	@echo ""
	@echo "$(GREEN)═══ Echidna Results ═══$(NC)"
	@$(MAKE) echidna 2>&1 | tee -a test-report.txt
	@echo ""
	@echo "$(GREEN)✓ Report saved to test-report.txt$(NC)"

# ═══════════════════════════════════════════════════════════════
# Special Targets
# ═══════════════════════════════════════════════════════════════

demo: ## Run demo of all challenges
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║          EVM CTF Challenges Demo                  ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@$(MAKE) test-reentrancy
	@echo ""
	@$(MAKE) test-fallback
	@echo ""
	@$(MAKE) echidna-fallback-quick
	@echo ""
	@echo "$(GREEN)✓ Demo complete!$(NC)"

all: ## Build, test, and fuzz everything
	@$(MAKE) clean
	@$(MAKE) build
	@$(MAKE) test
	@$(MAKE) echidna
	@echo "$(GREEN)✓ All tasks complete!$(NC)"

# ═══════════════════════════════════════════════════════════════
# End of Makefile
# ═══════════════════════════════════════════════════════════════
