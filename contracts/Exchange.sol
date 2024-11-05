// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./RoubleToken.sol";
import "./DigitalFinancialAsset.sol";
import "./ExchangeViewer.sol";

contract ExchangeContract {
    RoubleToken private roubleToken;
    ExchangeViewer private exchangeViewer;
    address private _owner;

    mapping(address => DigitalFinancialAsset) public dfaContracts;
    address[] public dfaAddresses;

    event TokenCreated(address indexed tokenAddress, string name, string symbol, uint64 totalSupply);
    event TokensBought(address indexed buyer, address indexed dfa, uint64 amount);
    event TokensRedeemed(address indexed redeemer, address indexed dfa, uint64 amount);
    event TokensRefunded(address indexed refundedAddress, address indexed dfa, uint64 amount);
    event Transfer (address indexed from, address indexed to, uint64 amount);

    constructor() {
        _owner = msg.sender;
        roubleToken = new RoubleToken();
        exchangeViewer = new ExchangeViewer();
    }

    function getShowcase() external view returns (ExchangeViewer.ShowcaseItem[] memory) {
       return exchangeViewer.getShowcase(dfaAddresses);
    }

    function getPortfolio(address account) external view returns (ExchangeViewer.Asset[] memory) {
        DigitalFinancialAsset[] memory allDfas = new DigitalFinancialAsset[](dfaAddresses.length);
        for (uint64 i = 0; i < allDfas.length; i++)
        {
            allDfas[i] = dfaContracts[dfaAddresses[i]];
        }

        return exchangeViewer.getPortfolio(account, allDfas);
    }

    function mintRoubles(address to, uint64 amount, string memory paymentReference) public   {
        require(msg.sender == _owner);
        roubleToken.mint(to, amount, paymentReference);
    }

    function getRoubleBalance(address account) external view returns (uint) {
        return roubleToken.balanceOf(account);
    }

    function withdrawRoubles(uint64 amount, address from, string memory withdrawReference)public {
        require(msg.sender == _owner);
        roubleToken.withdraw(from, amount, withdrawReference);
    }

    function createDFA(string memory _name, string memory _symbol, string memory _issuer, uint64 _initialSupply,
    uint64 _price, uint64 _salesStartDate, uint64 _salesEndDate, uint64 _threshold, uint64 _redeemDate,
    uint16 _annualInterestRate, uint64 _minimalInvestmentAmount) public  returns (address) {
        require(msg.sender == _owner);
        require(_redeemDate > _salesEndDate);
        DigitalFinancialAsset dfa = new DigitalFinancialAsset(_name, _symbol, _issuer, _initialSupply,
            _price, _salesStartDate, _salesEndDate, _threshold, _redeemDate, _annualInterestRate, _minimalInvestmentAmount);
        address dfaAddress = address(dfa);

        dfaContracts[dfaAddress] = dfa;
        dfaAddresses.push(dfaAddress);

        emit TokenCreated(dfaAddress, _name, _symbol, _initialSupply);
        return dfaAddress;
    }

    function buyDFA(address buyer, address dfaAddress, uint64 amount) public {
        require(msg.sender == _owner);
        DigitalFinancialAsset dfa = dfaContracts[dfaAddress];
        require(dfa.getReserve() >= amount);
        require(dfa.salesOpened());

        uint64 sum = amount * dfa.getPrice();
        require(roubleToken.balanceOf(buyer) >= sum);

        roubleToken.purchase(buyer, sum, dfa.getPrice(), amount, dfaAddress);

        dfa.buy(buyer, amount);
        emit TokensBought(buyer, dfaAddress, amount);
    }

    function getDfaReserve(address dfaAddress) external view returns (uint64) {
        DigitalFinancialAsset dfa = dfaContracts[dfaAddress];

        return dfa.getReserve();
    }

    function refundDFA(address buyer, address dfaAddress, uint64 amount) public  {
        require(msg.sender == _owner);
        DigitalFinancialAsset dfa = dfaContracts[dfaAddress];
        require(dfa.balanceOf(buyer) >= amount);
        require(dfa.salesOpened());

        dfa.takeBack(buyer, amount);

        uint64 sum = dfa.getPrice() * amount;

        roubleToken.refund(buyer, sum, dfa.getPrice(), amount, dfaAddress);

        emit TokensRefunded(buyer, dfaAddress, amount);
    }

    function fundriseFail(address dfaAddress) public  {
        require(msg.sender == _owner);
        DigitalFinancialAsset dfa = dfaContracts[dfaAddress];
        require(dfa.threshold() > dfa.totalSold());
        require(block.timestamp < dfa.salesEndDate());

        address[] memory investors = dfa.getInvestors(); 
        for (uint64 i = 0; i < investors.length; i++) {
            address investor = investors[i];
            uint64 balance = dfa.balanceOf(investor);

            if (balance > 0) {
                uint64 price = dfa.getPrice();
                uint64 refundSum = balance * price; 
                dfa.burn(investor, balance); 

                roubleToken.refund(investor, refundSum, price, balance, dfaAddress);

                emit TokensRefunded(investor, dfaAddress, balance);
            }
        }
    }

    function getRoubleTransactions(address account) external view returns (
        RoubleToken.Payment[] memory, RoubleToken.Withdrawal[] memory, RoubleToken.Purchase[] memory, RoubleToken.Refund[] memory,
        RoubleToken.Redeem[] memory, RoubleToken.InterestAccrual[] memory) {
        return roubleToken.getAccountTransactions(account);
    }

    // Погашение токенов DFA
    function redeemDFA(address investor, address dfaAddress, uint64 amount) external {
        require(msg.sender == _owner);
        DigitalFinancialAsset dfa = dfaContracts[dfaAddress];
        require(dfa.balanceOf(investor) >= amount);
        require(dfa.redeemStarted());

        uint64 investmentSum = dfa.price() * amount;
        uint64 term = dfa.redeemDate() - dfa.salesEndDate();

        dfa.burn(investor, amount);

        roubleToken.redeemPayment(dfa.price(), amount, investor, dfaAddress);
        
        roubleToken.interestAccrual(investmentSum, term, dfa.annualInterestRate(), investor, dfaAddress);

        emit TokensRedeemed(investor, dfaAddress, amount);
    }

    function getDFABalance(address dfaAddress, address account) external view returns (uint64) {
        return dfaContracts[dfaAddress].balanceOf(account);
    }

    function getTokenTotalSold(address dfaAddress) external view returns (uint64){
        return dfaContracts[dfaAddress].getTotalSold();
    }

    function transferAllAssets(address from, address to) public  {
        require(msg.sender == _owner);
        require(from != address(0) &&  to != address(0));

        roubleToken.recover(from, to);

        for (uint64 i = 0; i < dfaAddresses.length; i++) {
            DigitalFinancialAsset dfa = dfaContracts[dfaAddresses[i]];
            uint64 dfaBalance = dfa.balances(from);
            if (dfaBalance > 0) {
                dfa.setBalance(from, 0);
                dfa.increaseBalance(to,dfaBalance);
                emit Transfer(from, to, dfaBalance);
                }
            }
    }
}