// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.9;

import "../interfaces/IBentoBoxMinimal.sol";

/// @notice Escrow for ETH and ERC-20/721 tokens with BentoBox integration.
contract LexEscrow {
    IBentoBoxMinimal immutable bento;
    address public lexDAO;
    address immutable wETH;
    uint256 escrowCount;
    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public constant INVOICE_HASH = keccak256("DepositInvoiceSig(address depositor,address counterparty,address resolver,string details)");

    mapping(uint256 => string) public agreements;
    mapping(uint256 => Escrow) public escrows;
    mapping(address => Resolver) public resolvers;

    constructor(IBentoBoxMinimal _bento, address _lexDAO, address _wETH) {
        bento = _bento;
        bento.registerProtocol();
        lexDAO = _lexDAO;
        wETH = _wETH;
        
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("LexEscrow")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }
    
    /// @dev Events to assist web3 applications.
    event Deposit(
        bool bento,
        bool nft,
        address indexed depositor, 
        address indexed counterparty, 
        address resolver,
        address token, 
        uint256 value, 
        uint256 indexed registration,
        string details);
    event DepositInvoiceSig(address indexed depositor, address indexed counterparty);
    event Release(uint256 indexed registration);
    event Withdraw(uint256 indexed registration);
    event Resolve(uint256 indexed registration, uint256 indexed depositorAward, uint256 indexed counterpartyAward, string details);
    event RegisterResolver(address indexed resolver, bool indexed active, uint256 indexed fee);
    event RegisterAgreement(uint256 indexed index, string agreement);
    event UpdateLexDAO(address indexed lexDAO);
    
    /// @dev Tracks registered escrow status.
    struct Escrow {
        bool bento;
        bool nft; 
        address depositor;
        address counterparty;
        address resolver;
        address token;
        uint256 value;
        uint256 termination;
    }
    
    /// @dev Tracks registered resolver status.
    struct Resolver {
        bool active;
        uint8 fee;
    }

    // **** ESCROW PROTOCOL **** //
    // ------------------------ //
    /// @notice Deposits tokens (ERC-20/721) into escrow 
    // - locked funds can be released by `resolver`. 
    /// @param counterparty The account that can receive funds.
    /// @param resolver The account that unlock funds.
    /// @param token The asset used for funds.
    /// @param value The amount of funds - if `nft`, the 'tokenId' in first value is used.
    /// @param termination Unix time upon which `depositor` can claim back funds.
    /// @param nft If 'false', ERC-20 is assumed, otherwise, non-fungible asset.
    /// @param details Describes context of escrow - stamped into event.
    function deposit(
        address counterparty, 
        address resolver, 
        address token, 
        uint256 value,
        uint256 termination,
        bool nft, 
        string memory details
    ) public payable returns (uint256 registration) {
        require(resolvers[resolver].active, "RESOLVER_NOT_ACTIVE");
        require(resolver != msg.sender && resolver != counterparty, "RESOLVER_CANNOT_BE_PARTY"); /// @dev Avoid conflicts.
        
        /// @dev Handle ETH/ERC-20/721 deposit.
        if (msg.value != 0) {
            require(msg.value == value, "WRONG_MSG_VALUE");
            /// @dev Overrides to clarify ETH is used.
            if (token != address(0)) token = address(0);
            if (nft) nft = false;
        } else {
            safeTransferFrom(token, msg.sender, address(this), value);
        }
 
        /// @dev Increment registered escrows and assign # to escrow deposit.
        unchecked {
            escrowCount++;
        }
        registration = escrowCount;
        escrows[registration] = Escrow(false, nft, msg.sender, counterparty, resolver, token, value, termination);
        
        emit Deposit(false, nft, msg.sender, counterparty, resolver, token, value, registration, details);
    }

    /// @notice Deposits tokens (ERC-20/721) into BentoBox escrow 
    // - locked funds can be released by `resolver`. 
    /// @param counterparty The account that can receive funds.
    /// @param resolver The account that unlock funds.
    /// @param token The asset used for funds (note: NFT not supported in BentoBox).
    /// @param value The amount of funds (note: escrow converts to 'shares').
    /// @param termination Unix time upon which `depositor` can claim back funds.
    /// @param wrapBento If 'false', raw ERC-20 is assumed, otherwise, BentoBox 'shares'.
    /// @param details Describes context of escrow - stamped into event.
    function depositBento(
        address counterparty, 
        address resolver, 
        address token, 
        uint256 value,
        uint256 termination,
        bool wrapBento,
        string memory details
    ) public payable returns (uint256 registration) {
        require(resolvers[resolver].active, "RESOLVER_NOT_ACTIVE");
        require(resolver != msg.sender && resolver != counterparty, "RESOLVER_CANNOT_BE_PARTY"); /// @dev Avoid conflicts.
        
        /// @dev Handle ETH/ERC-20 deposit.
        if (msg.value != 0) {
            require(msg.value == value, "WRONG_MSG_VALUE");
            /// @dev Override to clarify wETH is used in BentoBox for ETH.
            if (token != wETH) token = wETH;
            (, value) = bento.deposit{value: msg.value}(address(0), address(this), address(this), msg.value, 0);
        } else if (wrapBento) {
            safeTransferFrom(token, msg.sender, address(bento), value);
            (, value) = bento.deposit(token, address(bento), address(this), value, 0);
        } else {
            bento.transfer(token, msg.sender, address(this), value);
        }

        /// @dev Increment registered escrows and assign # to escrow deposit.
        unchecked {
            escrowCount++;
        }
        registration = escrowCount;
        escrows[registration] = Escrow(true, false, msg.sender, counterparty, resolver, token, value, termination);
        
        emit Deposit(true, false, msg.sender, counterparty, resolver, token, value, registration, details);
    }
    
    /// @notice Validates deposit request 'invoice' for escrow escrow.
    /// @param counterparty The account that can receive funds.
    /// @param resolver The account that unlock funds.
    /// @param token The asset used for funds.
    /// @param value The amount of funds - if `nft`, the 'tokenId'.
    /// @param termination Unix time upon which `depositor` can claim back funds.
    /// @param bentoBoxed If 'false', regular deposit is assumed, otherwise, BentoBox.
    /// @param nft If 'false', ERC-20 is assumed, otherwise, non-fungible asset.
    /// @param wrapBento If 'false', raw ERC-20 is assumed, otherwise, BentoBox 'shares'.
    /// @param details Describes context of escrow - stamped into event.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function depositInvoiceSig(
        address counterparty, 
        address resolver, 
        address token, 
        uint256 value,
        uint256 termination,
        bool bentoBoxed,
        bool nft, 
        bool wrapBento,
        string memory details,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        /// @dev Validate basic elements of invoice.
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            INVOICE_HASH,
                            msg.sender,
                            counterparty,
                            resolver,
                            details
                        )
                    )
                )
            );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == counterparty, "INVALID_INVOICE");

        /// @dev Perform deposit.
        if (!bentoBoxed) {
            deposit(counterparty, resolver, token, value, termination, nft, details);
        } else {
            depositBento(counterparty, resolver, token, value, termination, wrapBento, details);
        }
        
        emit DepositInvoiceSig(msg.sender, counterparty);
    }
    
    /// @notice Releases escrowed assets back to designated `depositor` 
    // - can only be called by `depositor` if `termination` reached.
    /// @param registration The index of escrow deposit.
    function withdraw(uint256 registration) external {
        Escrow storage escrow = escrows[registration];
        
        require(msg.sender == escrow.depositor, "NOT_DEPOSITOR");
        require(block.timestamp >= escrow.termination, "NOT_TERMINATED");
        
        /// @dev Handle asset transfer.
        if (escrow.token == address(0)) { /// @dev Release ETH.
            safeTransferETH(escrow.depositor, escrow.value);
        } else if (escrow.bento) { /// @dev Release BentoBox shares.
            bento.transfer(escrow.token, address(this), escrow.depositor, escrow.value);
        } else if (!escrow.nft) { /// @dev Release ERC-20.
            safeTransfer(escrow.token, escrow.depositor, escrow.value);
        } else { /// @dev Release NFT.
            safeTransferFrom(escrow.token, address(this), escrow.depositor, escrow.value);
        }
        
        delete escrows[registration];
        
        emit Withdraw(registration);
    }

    // **** RELEASE PROTOCOL **** //
    // ------------------------- //
    /// @notice Resolves locked escrow deposit in split between parties - if NFT, must be complete award (so, one party receives '0')
    // - `resolverFee` is automatically deducted from both parties' awards.
    /// @param registration The registration index of escrow deposit.
    /// @param depositorAward The sum given to `depositor`.
    /// @param counterpartyAward The sum given to `counterparty`.
    /// @param details Description of resolution (note: can link to secure judgment details, etc.).
    function resolve(uint256 registration, uint256 depositorAward, uint256 counterpartyAward, string calldata details) external {
        Escrow storage escrow = escrows[registration]; 
        
        require(msg.sender == escrow.resolver, "NOT_RESOLVER");
        require(depositorAward + counterpartyAward == escrow.value, "NOT_REMAINDER");
        
        /// @dev Calculate resolution fee and apply to awards.
        uint256 resolverFee = escrow.value / resolvers[escrow.resolver].fee;
        depositorAward -= resolverFee / 2;
        counterpartyAward -= resolverFee / 2;
        
        /// @dev Handle asset transfers.
        if (escrow.token == address(0)) { /// @dev Split ETH.
            safeTransferETH(escrow.depositor, depositorAward);
            safeTransferETH(escrow.counterparty, counterpartyAward);
            safeTransferETH(escrow.resolver, resolverFee);
        } else if (escrow.bento) { /// @dev ...BentoBox shares.
            bento.transfer(escrow.token, address(this), escrow.depositor, depositorAward);
            bento.transfer(escrow.token, address(this), escrow.counterparty, counterpartyAward);
            bento.transfer(escrow.token, address(this), escrow.resolver, resolverFee);
        } else if (!escrow.nft) { /// @dev ...ERC20.
            safeTransfer(escrow.token, escrow.depositor, depositorAward);
            safeTransfer(escrow.token, escrow.counterparty, counterpartyAward);
            safeTransfer(escrow.token, escrow.resolver, resolverFee);
        } else { /// @dev Award NFT.
            if (depositorAward != 0) {
                safeTransferFrom(escrow.token, address(this), escrow.depositor, escrow.value);
            } else {
                safeTransferFrom(escrow.token, address(this), escrow.counterparty, escrow.value);
            }
        }
        
        delete escrows[registration];
        
        emit Resolve(registration, depositorAward, counterpartyAward, details);
    }
    
    /// @notice Registers an account to serve as a potential `resolver`.
    /// @param active Tracks willingness to serve - if 'true', can be joined to a escrow.
    /// @param fee The divisor to determine resolution fee - e.g., if '20', fee is 5% of escrow.
    function registerResolver(bool active, uint8 fee) external {
        require(fee != 0, "FEE_MUST_BE_GREATER_THAN_ZERO");
        resolvers[msg.sender] = Resolver(active, fee);
        emit RegisterResolver(msg.sender, active, fee);
    }

    // **** LEXDAO PROTOCOL **** //
    // ------------------------ //
    /// @notice Protocol for LexDAO to maintain agreements that can be stamped into escrows.
    /// @param index # to register agreement under.
    /// @param agreement Text or link to agreement, etc. - this allows for amendments.
    function registerAgreement(uint256 index, string calldata agreement) external {
        require(msg.sender == lexDAO, "NOT_LEXDAO");
        agreements[index] = agreement;
        emit RegisterAgreement(index, agreement);
    }

    /// @notice Protocol for LexDAO to update role.
    /// @param _lexDAO Account to assign role to.
    function updateLexDAO(address _lexDAO) external {
        require(msg.sender == lexDAO, "NOT_LEXDAO");
        lexDAO = _lexDAO;
        emit UpdateLexDAO(_lexDAO);
    }

    // **** BATCHER UTILITIES **** //
    // -------------------------- //
    /// @notice Enables calling multiple methods in a single call to this contract.
    /// @param data Payload for calls.
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        unchecked {
            for (uint256 i = 0; i < data.length; i++) {
                (bool success, bytes memory result) = address(this).delegatecall(data[i]);
                if (!success) {
                    if (result.length < 68) revert();
                    assembly { result := add(result, 0x04) }
                    revert(abi.decode(result, (string)));
                }
                results[i] = result;
            }
        }
    }

    /// @notice Provides EIP-2612 signed approval for this contract to spend user tokens.
    /// @param token Address of ERC-20 token.
    /// @param amount Token amount to grant spending right over.
    /// @param deadline Termination for signed approval in Unix time.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function permitThis(
        address token,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        /// @dev permit(address,address,uint256,uint256,uint8,bytes32,bytes32).
        (bool success, ) = token.call(abi.encodeWithSelector(0xd505accf, msg.sender, address(this), amount, deadline, v, r, s));
        require(success, "PERMIT_FAILED");
    }

    /// @notice Provides DAI-derived signed approval for this contract to spend user tokens.
    /// @param token Address of ERC-20 token.
    /// @param nonce Token owner's nonce - increases at each call to {permit}.
    /// @param expiry Termination for signed approval in Unix time.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function permitThisAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        /// @dev permit(address,address,uint256,uint256,bool,uint8,bytes32,bytes32).
        (bool success, ) = token.call(abi.encodeWithSelector(0x8fcbaf0c, msg.sender, address(this), nonce, expiry, true, v, r, s));
        require(success, "PERMIT_FAILED");
    }

    /// @dev Provides way to sign approval for `bento` spends by escrow.
    /// @param v The recovery byte of the signature.
    /// @param r Half of the ECDSA signature pair.
    /// @param s Half of the ECDSA signature pair.
    function setBentoApproval(uint8 v, bytes32 r, bytes32 s) external {
        bento.setMasterContractApproval(msg.sender, address(this), true, v, r, s);
    }
    
    // **** TRANSFER HELPERS **** //
    // ------------------------- //
    /// @notice Provides 'safe' ERC-20 {transfer} for tokens that don't consistently return 'true/false'.
    /// @param token Address of ERC-20 token.
    /// @param recipient Account to send tokens to.
    /// @param value Token amount to send.
    function safeTransfer(address token, address recipient, uint256 value) private {
        /// @dev transfer(address,uint256).
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, recipient, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    /// @notice Provides 'safe' ERC-20/721 {transferFrom} for tokens that don't consistently return 'true/false'.
    /// @param token Address of ERC-20/721 token.
    /// @param sender Account to send tokens from.
    /// @param recipient Account to send tokens to.
    /// @param value Token amount to send - if NFT, 'tokenId'.
    function safeTransferFrom(address token, address sender, address recipient, uint256 value) private {
        /// @dev transferFrom(address,address,uint256).
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, sender, recipient, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "PULL_FAILED");
    }
    
    /// @notice Provides 'safe' ETH transfer.
    /// @param recipient Account to send ETH to.
    /// @param value ETH amount to send.
    function safeTransferETH(address recipient, uint256 value) private {
        (bool success, ) = recipient.call{value: value}("");
        require(success, "ETH_TRANSFER_FAILED");
    }
}
