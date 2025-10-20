#!/bin/bash
# Reference commands for bytecode disassembly and JUMPDEST analysis
# Run these in /workspaces/evm-ctf-challenges/challenges/08-LittleMoney after forge build

# Extract bytecode from build artifacts
BYTECODE=$(jq -r '.deployedBytecode.object' out/LittleMoney.sol/LittleMoney.json)

# Full disassembly
cast disassemble $BYTECODE

# List all JUMPDEST locations
cast disassemble $BYTECODE | grep JUMPDEST

# Find specific opcodes around an address (e.g., emit at 0x292)
cast disassemble $BYTECODE | grep -A 10 00000292

# Search for patterns (e.g., LOG2 for events)
cast disassemble $BYTECODE | grep LOG

# Example: Find renounce JUMPDEST context
cast disassemble $BYTECODE | grep -A 5 0000035d