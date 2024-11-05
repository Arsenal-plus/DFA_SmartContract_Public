// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract RoubleToken{
    string public name = "Russian Rouble";
    string public symbol = "RUB";

    address private _owner;

    struct Payment {
        uint64 amount;
        string invoiceId;
        uint timeStamp;
    }

    struct Withdrawal {
        uint64 amount;
        string invoiceId;
        uint timeStamp;
    }    
    
    struct Purchase {
        uint64 sum;
        uint64 price;
        uint64 amount;
        address tokenAddress;
        uint timeStamp;
    }

    struct Refund {
        uint64 sum;
        uint64 price;
        uint64 amount;
        address tokenAddress;
        uint timeStamp;
    }

    struct Redeem{
        uint64 sum;
        uint64 nominal;
        uint64 amount;
        address tokenAddress;
        uint timeStamp;
    }

    struct InterestAccrual{
        uint64 sum;
        uint64 rate;
        uint64 base;
        address tokenAddress;
        uint timeStamp;
    }

    event TokensMinted(address indexed to, uint64 amount, string paymentReference);
    event TokensWithdrawn(address indexed from, uint64 amount, string withdrawalReference);
    event Purchases(address indexed from, uint64 sum, uint64 price, uint64 amount, address indexed tokenAddress);
    event TokensRefunded(address indexed to, uint64 sum, uint64 price, uint64 tokensAmount, address indexed tokenAddress);
    event InterestAccruals(address indexed account, uint64 amount, uint64 rate, address indexed tokenAddress);
    event RedeemPayment(address account, uint64 nominalPrice, uint64 tokensAmount, address tokenAddress);

    mapping(address => uint64) private balances;

    mapping(address => Payment[]) private payments;

    mapping(address => Withdrawal[]) private withdrawals;

    mapping(address => Purchase[]) private purchases;

    mapping(address => Refund[]) private refunds;

    mapping(address => Redeem[]) private redeems;

    mapping(address => InterestAccrual[]) private interestAccruals;

    constructor() {
        _owner = msg.sender;
    }

    function mint(address to, uint64 amount, string memory invoiceId) public {
        require(msg.sender == _owner, "Only the owner can make transes");
        require(!paymentExists(to, invoiceId), "Payment already exists");

        balances[to] += amount;

        payments[to].push (Payment(
            amount, invoiceId, 
            block.timestamp
        ));

        emit TokensMinted(to, amount, invoiceId);
    }

    function purchase(address from, uint64 sum, uint64 price, uint64 amount, address tokenAddress) public {
        require(msg.sender == _owner, "Only the owner can make transes");
        require(balanceOf(from) >= sum, "Not enough tokens to purchase");
        
        balances[from] -= sum;

        purchases[from].push(
            Purchase(sum,price,amount,tokenAddress, block.timestamp)
            );

        emit Purchases(from, sum, price, amount, tokenAddress);
    }

    function refund(address to, uint64 sum, uint64 price, uint64 amount, address tokenAddress) public  {
        require(msg.sender == _owner, "Only the owner can make transes");

        balances[to] += sum;

        refunds[to].push(Refund(
            sum,
            price,
            amount,
            tokenAddress, 
            block.timestamp
        ));

        emit TokensRefunded(to, sum, price, amount, tokenAddress);
    }

    function withdraw(address from, uint64 amount, string memory invoiceId) public {
        require(msg.sender == _owner, "Only the owner can make transes");
        require(balanceOf(from) >= amount, "Insufficient balance to withdraw");
        require(!withdrawalExists(from, invoiceId), "Withdrawal already exists");

        balances[from] -= amount;

        withdrawals[from].push(Withdrawal(
            amount,
            invoiceId, 
            block.timestamp
        ));

        emit TokensWithdrawn(from, amount, invoiceId);
    }

    function interestAccrual(uint64 sum, uint64 term, uint64 annualRate, address account, address tokenAddress) public  {
        require(msg.sender == _owner, "Only the owner can make transes");
        require(sum > 0, "The sum cannot be equal to 0");
        require(term > 0, "The term cannot be equal to 0");
        require(annualRate > 0, "The rate cannot be equal to 0");
        require(account != address(0), "Account cannot be equal to 0");

        uint64 totalInterest = (sum * term * annualRate) / (365 * 24 * 60 * 60 * 100);
        
        balances[account] += totalInterest;

        interestAccruals[account].push(InterestAccrual(totalInterest, annualRate, sum, tokenAddress, block.timestamp));

        emit InterestAccruals(account, totalInterest, annualRate, tokenAddress);
    }

    function redeemPayment(uint64 nominalPrice, uint64 tokensAmount, address account, address tokenAddress)public  {
        require(msg.sender == _owner, "Only the owner can make transes");

        uint64 sum = nominalPrice * tokensAmount;

        balances[account] += sum;

        redeems[account].push(Redeem(sum, nominalPrice, tokensAmount, tokenAddress, block.timestamp));

        emit RedeemPayment(account, nominalPrice, tokensAmount, tokenAddress);
    }

    function recover(address oldAddress, address newAddress) public  {
        require(msg.sender == _owner, "Only the owner can make transes");
        require(oldAddress != address(0), "Old address cannot be zero");
        require(newAddress != address(0), "New address cannot be zero");
        require(oldAddress != newAddress, "Addresses must be different");

        // Перенос баланса
        uint64 oldBalance = balances[oldAddress];
        if (oldBalance > 0) {
            balances[newAddress] = oldBalance;
            balances[oldAddress] = 0;
        }

        payments[newAddress] = payments[oldAddress];
        delete payments[oldAddress];

        withdrawals[newAddress] = withdrawals[oldAddress];
        delete withdrawals[oldAddress];

        purchases[newAddress] = purchases[oldAddress];
        delete purchases[oldAddress];

        refunds[newAddress] = refunds[oldAddress];
        delete refunds[oldAddress];

        redeems[newAddress] = redeems[oldAddress];
        delete redeems[oldAddress];

        interestAccruals[newAddress] = interestAccruals[oldAddress];
        delete interestAccruals[oldAddress];
    }

    function getPayments(address account) external view returns (Payment[] memory) {
        return payments[account];
    }

    function getWithdrawals(address account) external view returns (Withdrawal[] memory) {
        return withdrawals[account];
    }

    function getPurchases(address account) external view returns (Purchase[] memory) {
        return purchases[account];
    }

    function getRefunds(address account) external view returns (Refund[] memory) {
        return refunds[account];
    }

    function getRedeems(address account) external view returns (Redeem[] memory) {
        return redeems[account];
    }
    function getInterestAccurals(address account) external view returns (InterestAccrual[] memory){
        return interestAccruals[account];
    }
    function balanceOf(address account) public view returns (uint64) {
        return balances[account];
    }

    function getAccountTransactions(address account) external view returns (
        Payment[] memory, Withdrawal[] memory, Purchase[] memory, 
        Refund[] memory, Redeem[] memory, InterestAccrual[] memory) {

        return (payments[account], withdrawals[account], 
        purchases[account], refunds[account], redeems[account], interestAccruals[account]);
    }

    function paymentExists(address to, string memory invoiceId) internal view returns (bool) {
    Payment[] storage userPayments = payments[to];

    for (uint64 i = 0; i < userPayments.length; i++) {
        if (keccak256(abi.encodePacked(userPayments[i].invoiceId)) == keccak256(abi.encodePacked(invoiceId))) {
            return true; 
        }
    }
    return false; 
    }

    function withdrawalExists(address from, string memory invoiceId) internal view returns (bool) {
    Withdrawal[] storage userWithdrawals = withdrawals[from];

    for (uint64 i = 0; i < userWithdrawals.length; i++) {
        if (keccak256(abi.encodePacked(userWithdrawals[i].invoiceId)) == keccak256(abi.encodePacked(invoiceId))) {
            return true; 
        }
    }
    return false; 
    }
}