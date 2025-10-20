// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DelegateERC20
 * @notice Interface for delegation functionality
 */
interface DelegateERC20 {
    function delegateTransfer(address to, uint256 value, address origSender) external returns (bool);
}

/**
 * @title IDetectionBot
 * @notice Interface for detection bots that monitor transactions
 */
interface IDetectionBot {
    function handleTransaction(address user, bytes calldata msgData) external;
}

/**
 * @title IForta
 * @notice Interface for the Forta monitoring system
 */
interface IForta {
    function setDetectionBot(address detectionBotAddress) external;
    function notify(address user, bytes calldata msgData) external;
    function raiseAlert(address user) external;
}

/**
 * @title Forta
 * @notice Monitoring system that manages detection bots and alerts
 * @dev This contract manages detection bots for users and handles alert notifications
 */
contract Forta is IForta {
    mapping(address => IDetectionBot) public usersDetectionBots;
    mapping(address => uint256) public botRaisedAlerts;

    event DetectionBotSet(address indexed user, address indexed detectionBot);
    event AlertRaised(address indexed user, address indexed detectionBot);

    /**
     * @notice Set a detection bot for the calling user
     * @param detectionBotAddress Address of the detection bot contract
     */
    function setDetectionBot(address detectionBotAddress) external override {
        usersDetectionBots[msg.sender] = IDetectionBot(detectionBotAddress);
        emit DetectionBotSet(msg.sender, detectionBotAddress);
    }

    /**
     * @notice Notify a user's detection bot about a transaction
     * @param user The user whose bot should be notified
     * @param msgData The transaction data to analyze
     */
    function notify(address user, bytes calldata msgData) external override {
        if (address(usersDetectionBots[user]) == address(0)) return;
        try usersDetectionBots[user].handleTransaction(user, msgData) {
            return;
        } catch {}
    }

    /**
     * @notice Raise an alert (called by detection bots)
     * @param user The user associated with the alert
     */
    function raiseAlert(address user) external override {
        if (address(usersDetectionBots[user]) != msg.sender) return;
        botRaisedAlerts[msg.sender] += 1;
        emit AlertRaised(user, msg.sender);
    }
}

/**
 * @title CryptoVault
 * @notice A vault that can sweep tokens but not the underlying token
 * @dev VULNERABILITY: The underlying token check can be bypassed through delegation
 */
contract CryptoVault {
    address public sweptTokensRecipient;
    IERC20 public underlying;

    event TokenSwept(address indexed token, uint256 amount);
    event UnderlyingSet(address indexed token);

    /**
     * @notice Initialize the vault with a recipient for swept tokens
     * @param recipient Address that will receive swept tokens
     */
    constructor(address recipient) {
        sweptTokensRecipient = recipient;
    }

    /**
     * @notice Set the underlying token (can only be set once)
     * @param latestToken Address of the underlying token
     */
    function setUnderlying(address latestToken) public {
        require(address(underlying) == address(0), "Already set");
        underlying = IERC20(latestToken);
        emit UnderlyingSet(latestToken);
    }

    /**
     * @notice Sweep any token except the underlying token
     * @param token The token to sweep
     * @dev VULNERABILITY: This check can be bypassed if the token delegates transfers
     */
    function sweepToken(IERC20 token) public {
        require(token != underlying, "Can't transfer underlying token");
        uint256 balance = token.balanceOf(address(this));
        token.transfer(sweptTokensRecipient, balance);
        emit TokenSwept(address(token), balance);
    }
}

/**
 * @title LegacyToken
 * @notice An older ERC20 token that can delegate transfers to a new contract
 * @dev This token can delegate its transfer functionality to another contract
 */
contract LegacyToken is ERC20("LegacyToken", "LGT"), Ownable {
    DelegateERC20 public delegate;

    event DelegateSet(address indexed newDelegate);

    /**
     * @notice Mint tokens (only owner)
     * @param to Recipient address
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice Set a new contract to handle transfers
     * @param newContract Address of the new contract to delegate to
     */
    function delegateToNewContract(DelegateERC20 newContract) public onlyOwner {
        delegate = newContract;
        emit DelegateSet(address(newContract));
    }

    /**
     * @notice Transfer tokens (with delegation support)
     * @param to Recipient address
     * @param value Amount to transfer
     * @return success True if transfer succeeded
     * @dev If delegate is set, transfers are handled by the delegate contract
     */
    function transfer(address to, uint256 value) public override returns (bool) {
        if (address(delegate) == address(0)) {
            return super.transfer(to, value);
        } else {
            return delegate.delegateTransfer(to, value, msg.sender);
        }
    }
}

/**
 * @title DoubleEntryPoint
 * @notice The main vulnerable contract that handles delegated transfers
 * @dev VULNERABILITY: The delegateTransfer function can be exploited to drain the vault
 */
contract DoubleEntryPoint is ERC20("DoubleEntryPointToken", "DET"), DelegateERC20, Ownable {
    address public cryptoVault;
    address public player;
    address public delegatedFrom;
    Forta public forta;

    event DelegateTransferCalled(address indexed to, uint256 value, address indexed origSender);

    /**
     * @notice Initialize the DoubleEntryPoint token
     * @param legacyToken Address of the legacy token that delegates to this contract
     * @param vaultAddress Address of the crypto vault
     * @param fortaAddress Address of the Forta monitoring system
     * @param playerAddress Address of the player
     */
    constructor(address legacyToken, address vaultAddress, address fortaAddress, address playerAddress) {
        delegatedFrom = legacyToken;
        forta = Forta(fortaAddress);
        player = playerAddress;
        cryptoVault = vaultAddress;
        _mint(cryptoVault, 100 ether);
    }

    /**
     * @notice Modifier to ensure only the legacy contract can call
     */
    modifier onlyDelegateFrom() {
        require(msg.sender == delegatedFrom, "Not legacy contract");
        _;
    }

    /**
     * @notice Modifier to notify Forta and check for alerts
     * @dev If detection bot raises an alert, the transaction reverts
     */
    modifier fortaNotify() {
        address detectionBot = address(forta.usersDetectionBots(player));

        // Cache old number of bot alerts
        uint256 previousValue = forta.botRaisedAlerts(detectionBot);

        // Notify Forta
        forta.notify(player, msg.data);

        // Continue execution
        _;

        // Check if alarms have been raised
        if (forta.botRaisedAlerts(detectionBot) > previousValue) revert("Alert has been triggered, reverting");
    }

    /**
     * @notice Handle delegated transfers from the legacy token
     * @param to Recipient address
     * @param value Amount to transfer
     * @param origSender Original sender of the transfer
     * @return success True if transfer succeeded
     * @dev VULNERABILITY: Can be exploited to transfer vault's tokens by calling
     *      vault.sweepToken(legacyToken) which triggers legacyToken.transfer() which
     *      delegates to this function with origSender=vault, allowing vault drainage
     */
    function delegateTransfer(address to, uint256 value, address origSender)
        public
        override
        onlyDelegateFrom
        fortaNotify
        returns (bool)
    {
        _transfer(origSender, to, value);
        emit DelegateTransferCalled(to, value, origSender);
        return true;
    }
}