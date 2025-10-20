// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../src/DoubleEntryPoint.sol";
import "../src/DetectionBot.sol";

/**
 * @title DoubleEntryPointEchidna
 * @notice Echidna fuzzing contract for testing the DoubleEntryPoint delegation vulnerability
 * @dev Tests invariants and properties of the delegation attack and defense mechanisms
 */
contract DoubleEntryPointEchidna {
    // Core contracts
    Forta public forta;
    CryptoVault public vault;
    LegacyToken public legacyToken;
    DoubleEntryPoint public doubleEntryPoint;
    DoubleEntryPointFortaBot public detectionBot;

    // Test accounts
    address public player = address(0x1000);
    address public attacker = address(0x2000);
    address public recipient = address(0x3000);
    address public admin = address(0x4000);

    // Initial state
    uint256 public constant INITIAL_VAULT_BALANCE = 100 ether;
    uint256 public constant INITIAL_LEGACY_BALANCE = 50 ether;
    uint256 public initialVaultDETBalance;

    event EchidnaAssertion(string message, uint256 value1, uint256 value2);

    constructor() {
        // Deploy Forta monitoring system
        forta = new Forta();

        // Deploy CryptoVault with recipient for swept tokens
        vault = new CryptoVault(recipient);

        // Deploy LegacyToken with admin as owner
        legacyToken = new LegacyToken();

        // Deploy DoubleEntryPoint as the main vulnerable token
        doubleEntryPoint = new DoubleEntryPoint(
            address(legacyToken),
            address(vault),
            address(forta),
            player
        );

        // Set up the delegation: LegacyToken delegates to DoubleEntryPoint
        legacyToken.delegateToNewContract(DelegateERC20(address(doubleEntryPoint)));

        // Set DoubleEntryPoint as the vault's underlying token
        vault.setUnderlying(address(doubleEntryPoint));

        // Give vault some LegacyToken balance
        legacyToken.mint(address(vault), INITIAL_LEGACY_BALANCE);

        // Deploy detection bot
        detectionBot = new DoubleEntryPointFortaBot(IForta(address(forta)), address(vault));

        // Store initial state
        initialVaultDETBalance = doubleEntryPoint.balanceOf(address(vault));
    }

    /*//////////////////////////////////////////////////////////////
                            ECHIDNA PROPERTIES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Property: Vault should always have some DoubleEntryPoint tokens unless legitimately transferred
     * @dev This property will fail if the delegation vulnerability is exploited
     */
    function echidna_vault_should_retain_tokens() public view returns (bool) {
        uint256 currentBalance = doubleEntryPoint.balanceOf(address(vault));
        
        // Allow legitimate decreases through direct transfers, but not complete drainage
        // The vault should never lose ALL tokens through the sweepToken vulnerability
        if (currentBalance == 0 && initialVaultDETBalance > 0) {
            // Complete drainage detected - this should only happen through legitimate means
            // Check if this was due to the vulnerability by seeing if the recipient got the tokens
            uint256 recipientBalance = doubleEntryPoint.balanceOf(recipient);
            if (recipientBalance >= INITIAL_LEGACY_BALANCE) {
                // Vulnerability exploited - drainage through delegation
                return false;
            }
        }
        
        return true;
    }

    /**
     * @notice Property: LegacyToken balance should remain stable (it doesn't actually transfer)
     * @dev The LegacyToken balance shouldn't change due to delegation
     */
    function echidna_legacy_token_balance_stable() public view returns (bool) {
        return legacyToken.balanceOf(address(vault)) == INITIAL_LEGACY_BALANCE;
    }

    /**
     * @notice Property: Vault underlying token should always be DoubleEntryPoint
     * @dev This is a critical configuration that shouldn't change
     */
    function echidna_vault_underlying_immutable() public view returns (bool) {
        return address(vault.underlying()) == address(doubleEntryPoint);
    }

    /**
     * @notice Property: LegacyToken should always delegate to DoubleEntryPoint
     * @dev This delegation is necessary for the vulnerability to exist
     */
    function echidna_delegation_maintained() public view returns (bool) {
        return address(legacyToken.delegate()) == address(doubleEntryPoint);
    }

    /**
     * @notice Property: Detection bot should prevent vault drainage when active
     * @dev If detection bot is set, vault drainage should not be possible
     */
    function echidna_detection_bot_prevents_drainage() public view returns (bool) {
        address playerBot = address(forta.usersDetectionBots(player));
        
        if (playerBot == address(detectionBot)) {
            // Detection bot is active, vault should be protected
            uint256 currentBalance = doubleEntryPoint.balanceOf(address(vault));
            return currentBalance > 0; // Vault should not be completely drained
        }
        
        return true; // No protection expected without bot
    }

    /**
     * @notice Property: Total token supply should remain constant
     * @dev Tokens should only move between accounts, not be created/destroyed
     */
    function echidna_total_supply_constant() public view returns (bool) {
        return doubleEntryPoint.totalSupply() == INITIAL_VAULT_BALANCE;
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Simulate vault sweepToken call (potential vulnerability trigger)
     * @dev This is the main attack vector that Echidna will explore
     */
    function sweepLegacyToken() public {
        try vault.sweepToken(IERC20(address(legacyToken))) {
            // Sweep succeeded - check if it was legitimate or an exploit
            uint256 vaultBalance = doubleEntryPoint.balanceOf(address(vault));
            uint256 recipientBalance = doubleEntryPoint.balanceOf(recipient);
            
            emit EchidnaAssertion("Sweep executed", vaultBalance, recipientBalance);
        } catch Error(string memory reason) {
            // Sweep failed - might be due to detection bot or other protection
            emit EchidnaAssertion("Sweep failed", 0, 0);
        }
    }

    /**
     * @notice Simulate setting up detection bot protection
     * @dev Echidna can call this to test the defense mechanism
     */
    function setupDetectionBot() public {
        // Simulate player setting up the detection bot
        try forta.setDetectionBot(address(detectionBot)) {
            emit EchidnaAssertion("Detection bot set", 1, 0);
        } catch {
            emit EchidnaAssertion("Detection bot setup failed", 0, 0);
        }
    }

    /**
     * @notice Simulate legitimate token transfers
     * @dev This helps Echidna distinguish between legitimate and illegitimate balance changes
     */
    function legitimateTransfer(uint256 amount) public {
        // Bound the amount to reasonable values
        amount = amount % (INITIAL_VAULT_BALANCE + 1);
        
        if (amount > 0 && doubleEntryPoint.balanceOf(address(vault)) >= amount) {
            // Simulate legitimate transfer from vault
            try doubleEntryPoint.transfer(recipient, amount) {
                emit EchidnaAssertion("Legitimate transfer", amount, doubleEntryPoint.balanceOf(address(vault)));
            } catch {
                // Transfer failed - insufficient balance or other issue
            }
        }
    }

    /**
     * @notice Get current system state for debugging
     * @return vaultDETBalance Current DoubleEntryPoint balance of vault
     * @return vaultLegacyBalance Current LegacyToken balance of vault  
     * @return recipientDETBalance Current DoubleEntryPoint balance of recipient
     * @return botActive Whether detection bot is active for player
     */
    function getSystemState() public view returns (
        uint256 vaultDETBalance,
        uint256 vaultLegacyBalance,
        uint256 recipientDETBalance,
        bool botActive
    ) {
        vaultDETBalance = doubleEntryPoint.balanceOf(address(vault));
        vaultLegacyBalance = legacyToken.balanceOf(address(vault));
        recipientDETBalance = doubleEntryPoint.balanceOf(recipient);
        botActive = address(forta.usersDetectionBots(player)) == address(detectionBot);
    }
}