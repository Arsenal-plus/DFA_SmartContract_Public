// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract DigitalFinancialAsset {
    string public name; 
    string public symbol; 
    uint8 public decimals = 0;
    string public issuer;
    uint64 public initialSupply; 
    uint64 public price;
    uint64 public salesStartDate;
    uint64 public salesEndDate;
    uint64 public threshold;
    uint64 public redeemDate;
    uint16 public annualInterestRate;
    uint64 public minimalInvestmentAmount;

    uint64 public totalRedeemed;
    uint64 public totalSold;

    address private _owner;

    mapping(address => uint64) public balances;

    address[] private investorAddresses; 

    event Transfer(address indexed from, address indexed to, uint64 value);
    event DebugOwner(address indexed sender, address indexed owner); 

    constructor(string memory _name, string memory _symbol, string memory _issuer, uint64 _initialSupply,
    uint64 _price, uint64 _salesStartDate, uint64 _salesEndDate, uint64 _threshold, uint64 _redeemDate,
    uint16 _annualInterestRate, uint64 _minimalInvestmentAmount) {
        name = _name;
        symbol = _symbol;
        issuer = _issuer;
        initialSupply = _initialSupply;
        price = _price;
        salesStartDate = _salesStartDate;
        salesEndDate = _salesEndDate;
        threshold = _threshold;
        redeemDate = _redeemDate;
        annualInterestRate = _annualInterestRate;
        minimalInvestmentAmount = _minimalInvestmentAmount;

        _owner = msg.sender;
        balances[msg.sender] = initialSupply; 
        emit Transfer(address(0), msg.sender, initialSupply);
    }

    function totalSupply() public view returns (uint256) {
        return uint256(initialSupply);
    }

    function transfer(address, uint256) public pure returns (bool) {
        revert("Transfer not supported");
    }

    function approve(address, uint256) public pure returns (bool) {
        revert("Approve not supported");
    }

    function transferFrom(address, address, uint256) public pure returns (bool) {
        revert("TransferFrom not supported");
    }

    function allowance(address, address) public pure returns (uint256) {
        return 0;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function balanceOf(address account) public view returns (uint64) {
        return balances[account];
    }

    function getReserve() public view returns (uint64) {
        return balances[_owner];
    }

    function getPrice() public view returns (uint64) {
        return price;
    }

    function getTotalSold() public view returns (uint64) {
        return totalSold;
    }

    function salesOpened() public view returns (bool){
        return salesStartDate <= block.timestamp && block.timestamp <= salesEndDate;
    }

    function redeemStarted() public view returns (bool){
        return block.timestamp >= redeemDate;
    }

    function buy(address account, uint64 amount) public  {
        require(msg.sender == _owner, "Only the owner can transfer tokens");
        require(balances[_owner] >= amount, "Not enough tokens in the bank");
        require(salesStartDate <= block.timestamp && block.timestamp <= salesEndDate, "The asset is not available for buying");
        require(amount >= minimalInvestmentAmount, "Not enough for min investment");

        if (balances[account] == 0) {
            investorAddresses.push(account);
        }

        balances[_owner] -= amount;
        balances[account] += amount;
        totalSold += amount;
        emit Transfer(_owner, account, amount);
    }

    function takeBack(address account, uint64 amount) public returns (uint64) {
        require(msg.sender == _owner, "Only the owner can transfer tokens");
        require(balances[account] >= amount, "Not enough tokens at the address");
        require(block.timestamp < salesEndDate, "Too late to recall");
        
        balances[account] -= amount;
        balances[_owner] += amount;
        totalSold -= amount;

        emit Transfer(_owner, account, amount);
        return balanceOf(account);
    }

    function getInvestors() public view returns (address[] memory) {
        uint64 count = 0;

        for (uint64 i = 0; i < investorAddresses.length; i++) {
            if (balances[investorAddresses[i]] > 0) {
                count++;
            }
        }

        address[] memory activeInvestors = new address[](count);
        uint64 index = 0;

        for (uint64 i = 0; i < investorAddresses.length; i++) {
            if (balances[investorAddresses[i]] > 0) {
                activeInvestors[index] = investorAddresses[i];
                index++;
            }
        }

        return activeInvestors;
    }

    function burn(address account, uint64 amount) public  {
        require(msg.sender == _owner, "Only the owner can burn tokens");
        require(balances[account] >= amount, "Burn amount exceeds balance");

        balances[account] -= amount;
        totalRedeemed += amount;

        emit Transfer(account, address(0), amount);
    }

    function recover(address oldAddress, address newAddress) public {
        require(msg.sender == _owner, "Only the owner can recover tokens");
        require(oldAddress != address(0), "Old address is the zero address");
        require(newAddress != address(0), "New address is the zero address");
       
        emit DebugOwner(msg.sender, _owner); // Логирование владельца контракта

        uint64 balance = balances[oldAddress];
        require(balance > 0, "Old address has no tokens");

        balances[oldAddress] = 0;
        balances[newAddress] += balance;

        emit Transfer(oldAddress, newAddress, balance);
    }

    function setBalance(address account, uint64 amount) public {
        require(msg.sender == _owner, "Permission denied");
        balances[account] = amount;
    }

    function increaseBalance(address account, uint64 amount) public {
        require(msg.sender == _owner, "Permission denied");
        balances[account] += amount;
    }

    function decreaseBalance(address account, uint64 amount) public {
        require(msg.sender == _owner, "Permission denied");
        require(balances[account] >= amount, "Insufficient balance");
        balances[account] -= amount;
    }
}