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
