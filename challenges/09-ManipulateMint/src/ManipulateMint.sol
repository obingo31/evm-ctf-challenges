// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ManipulateMint - Storage Slot Manipulation Challenge
 * @dev A vulnerable ERC-20 token that demonstrates direct storage manipulation
 *      to bypass token supply constraints and mint unlimited tokens.
 * 
 * VULNERABILITY: The manipulateMint function allows the owner to directly
 * modify storage slots to set arbitrary token balances, bypassing all
 * traditional ERC-20 safety checks and max supply limits.
 */
contract ManipulateMint {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 public constant MAX_SUPPLY = 1000000 * 10**18; // 1M tokens max supply
    string public name = "VulnerableToken";
    string public symbol = "VULN";
    uint8 public decimals = 18;
    
    address public owner;
    bool public isSolved = false;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event ChallengeSolved(address solver, uint256 balance);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        // Initial supply is 0 - owner needs to use manipulateMint to get tokens
    }

    /**
     * @dev Transfer ownership to a new owner (for factory pattern)
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }

    /**
     * @dev Standard ERC-20 functions with proper safety checks
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        address sender = msg.sender;
        _transfer(sender, to, amount);
        return true;
    }

    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner_ = msg.sender;
        _approve(owner_, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Traditional mint function with proper supply checks
     *      This function correctly enforces the MAX_SUPPLY limit
     */
    function safeMint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Mint to zero address");
        require(_totalSupply + amount <= MAX_SUPPLY, "Exceeds max supply");
        
        _totalSupply += amount;
        _balances[to] += amount;
        
        emit Transfer(address(0), to, amount);
    }

    /**
     * @dev VULNERABLE FUNCTION: Direct storage manipulation
     *      This function bypasses all safety checks and allows unlimited minting
     *      by directly writing to storage slots.
     * 
     * EXPLOIT: The function calculates the storage slot for _balances[caller()]
     * and directly writes the amount to that slot, completely bypassing:
     * - Max supply checks
     * - Total supply tracking
     * - Zero address checks
     * - Any other validation logic
     */
    function manipulateMint(uint256 amount) public onlyOwner {
        assembly {
            // Load the caller's address into memory at position 0x00
            mstore(0x00, caller())
            
            // Load the _balances mapping slot (slot 0) into memory at position 0x20
            mstore(0x20, 0)
            
            // Compute the storage slot for _balances[caller()]
            // This uses the standard Solidity mapping storage layout:
            // keccak256(abi.encodePacked(key, slot))
            let balancesHash := keccak256(0x00, 0x40)
            
            // Directly write the amount to the computed storage slot
            // This bypasses ALL Solidity-level checks and validations
            sstore(balancesHash, amount)
        }
        
        // Optional: Emit transfer event for appearance of legitimacy
        // Note: This doesn't update _totalSupply, creating inconsistency
        emit Transfer(address(0), msg.sender, amount);
    }

    /**
     * @dev Challenge completion check
     *      Player wins if they have more tokens than the max supply allows
     */
    function checkSolution() public {
        require(balanceOf(msg.sender) > MAX_SUPPLY, "Balance must exceed max supply");
        isSolved = true;
        emit ChallengeSolved(msg.sender, balanceOf(msg.sender));
    }

    /**
     * @dev Internal transfer function with standard checks
     */
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "Transfer amount exceeds balance");
        
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    /**
     * @dev Internal approve function
     */
    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "Approve from zero address");
        require(spender != address(0), "Approve to zero address");

        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    /**
     * @dev Internal allowance spending function
     */
    function _spendAllowance(address owner_, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner_, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Insufficient allowance");
            unchecked {
                _approve(owner_, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Emergency function to demonstrate the vulnerability's impact
     *      Shows how storage manipulation creates inconsistent state
     */
    function getStorageInconsistency() public view returns (
        uint256 reportedTotalSupply,
        uint256 ownerBalance,
        bool isInconsistent
    ) {
        reportedTotalSupply = _totalSupply;
        ownerBalance = _balances[owner];
        isInconsistent = ownerBalance > reportedTotalSupply;
    }
}