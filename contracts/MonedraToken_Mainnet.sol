// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/access/Ownable.sol";

contract Monedra is ERC20, Ownable {
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 10**18;

    address public treasuryWallet;

    uint256 public burnFee = 2;       // Aktiv: 2% Burn
    uint256 public treasuryFee = 1;   // Aktiv: 1% Treasury

    mapping(address => bool) public blacklist;

    constructor(address _treasuryWallet) ERC20("Monedra", "MONE") {
        require(_treasuryWallet != address(0), "Invalid treasury wallet");
        treasuryWallet = _treasuryWallet;
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function setTreasuryWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "Invalid address");
        treasuryWallet = newWallet;
    }

    function setFees(uint256 _burnFee, uint256 _treasuryFee) external onlyOwner {
        require(_burnFee + _treasuryFee <= 10, "Too high total fee");
        burnFee = _burnFee;
        treasuryFee = _treasuryFee;
    }

    function blacklistAddress(address user, bool value) external onlyOwner {
        blacklist[user] = value;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(!blacklist[from] && !blacklist[to], "Blacklisted");

        uint256 burnAmount = (amount * burnFee) / 100;
        uint256 treasuryAmount = (amount * treasuryFee) / 100;
        uint256 netAmount = amount - burnAmount - treasuryAmount;

        if (burnAmount > 0) {
            super._transfer(from, address(0), burnAmount);
        }

        if (treasuryAmount > 0) {
            super._transfer(from, treasuryWallet, treasuryAmount);
        }

        super._transfer(from, to, netAmount);
    }
}
