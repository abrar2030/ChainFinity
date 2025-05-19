// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title GovernanceToken
 * @dev ERC20 token with voting capabilities for ChainFinity governance
 */
contract GovernanceToken is ERC20Votes, Ownable {
    uint256 private constant _INITIAL_SUPPLY = 100_000_000 * 10**18; // 100 million tokens
    
    /**
     * @dev Constructor that initializes the token with name, symbol, and mints initial supply
     */
    constructor() 
        ERC20("ChainFinity Governance", "CFG") 
        ERC20Permit("ChainFinity Governance")
        Ownable(msg.sender) 
    {
        _mint(msg.sender, _INITIAL_SUPPLY);
    }
    
    /**
     * @dev Allows the owner to mint additional tokens if needed
     * @param to Address to receive the minted tokens
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    /**
     * @dev Override _afterTokenTransfer to update voting power
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    /**
     * @dev Override _mint to update voting power
     */
    function _mint(address account, uint256 amount) internal override(ERC20Votes) {
        super._mint(account, amount);
    }

    /**
     * @dev Override _burn to update voting power
     */
    function _burn(address account, uint256 amount) internal override(ERC20Votes) {
        super._burn(account, amount);
    }
}
