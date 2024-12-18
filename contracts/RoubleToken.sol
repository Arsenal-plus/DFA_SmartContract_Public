// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract RoubleToken{
    string public name = "Russian Rouble";
    string public symbol = "RUB";
    uint8 public decimals = 0;
    uint256 private totalSupply;

    mapping(address => mapping(address => uint256)) private allowances;

    address private _owner;

    struct Payment {
        uint256 amount;
        string invoiceId;
        uint timeStamp;
    }

    struct Withdrawal {
        uint256 amount;
        string invoiceId;
        uint timeStamp;
    }    
    
    struct Purchase {
        uint256 sum;
        uint256 price;
        uint256 amount;
        address tokenAddress;
        uint timeStamp;
    }

    struct Refund {
        uint256 sum;
        uint256 price;
        uint256 amount;
        address tokenAddress;
        uint timeStamp;
    }

    struct Redeem{
        uint256 sum;
        uint256 nominal;
        uint256 amount;
        address tokenAddress;
        uint timeStamp;
    }

    struct InterestAccrual{
        uint256 sum;
        uint256 rate;
        uint256 base;
        address tokenAddress;
        uint timeStamp;
    }

    event TokensMinted(address indexed to, uint256 amount, string paymentReference);
    event TokensWithdrawn(address indexed from, uint256 amount, string withdrawalReference);
    event Purchases(address indexed from, uint256 sum, uint256 price, uint256 amount, address indexed tokenAddress);
    event TokensRefunded(address indexed to, uint256 sum, uint256 price, uint256 tokensAmount, address indexed tokenAddress);
    event InterestAccruals(address indexed account, uint256 amount, uint256 rate, address indexed tokenAddress);
    event RedeemPayment(address account, uint256 nominalPrice, uint256 tokensAmount, address tokenAddress);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private balances;

    mapping(address => Payment[]) private payments;

    mapping(address => Withdrawal[]) private withdrawals;

    mapping(address => Purchase[]) private purchases;

    mapping(address => Refund[]) private refunds;

    mapping(address => Redeem[]) private redeems;

    mapping(address => InterestAccrual[]) private interestAccruals;

    constructor() {
        _owner = msg.sender;
    }

    function mint(address to, uint256 amount, string memory invoiceId) public {
        require(msg.sender == _owner, "Only the owner can make transes");
        require(!paymentExists(to, invoiceId), "Payment already exists");

        balances[to] += amount;

        totalSupply += amount;

        payments[to].push (Payment(
            amount, invoiceId, 
            block.timestamp
        ));

        emit Transfer(address(0), to, amount);

        emit TokensMinted(to, amount, invoiceId);
    }

    function purchase(address from, uint256 sum, uint256 price, uint256 amount, address tokenAddress) public {
        require(msg.sender == _owner, "Only the owner can make transes");
        require(balanceOf(from) >= sum, "Not enough tokens to purchase");
        
        balances[from] -= sum;

        totalSupply -= sum;

        purchases[from].push(
            Purchase(sum,price,amount,tokenAddress, block.timestamp)
            );
                

        emit Transfer(from, address(0), amount);

        emit Purchases(from, sum, price, amount, tokenAddress);
    }

    function refund(address to, uint256 sum, uint256 price, uint256 amount, address tokenAddress) public  {
        require(msg.sender == _owner, "Only the owner can make transes");

        balances[to] += sum;
        totalSupply +=sum;

        refunds[to].push(Refund(
            sum,
            price,
            amount,
            tokenAddress, 
            block.timestamp
        ));

        emit Transfer(address(0), to, amount);

        emit TokensRefunded(to, sum, price, amount, tokenAddress);
    }

    function withdraw(address from, uint256 amount, string memory invoiceId) public {
        require(msg.sender == _owner, "Only the owner can make transes");
        require(balanceOf(from) >= amount, "Insufficient balance to withdraw");
        require(!withdrawalExists(from, invoiceId), "Withdrawal already exists");

        balances[from] -= amount;
        totalSupply -= amount;

        withdrawals[from].push(Withdrawal(
            amount,
            invoiceId, 
            block.timestamp
        ));

        emit Transfer(from, address(0), amount);

        emit TokensWithdrawn(from, amount, invoiceId);
    }

    function interestAccrual(uint256 sum, uint256 term, uint256 annualRate, address account, address tokenAddress) public  {
        require(msg.sender == _owner, "Only the owner can make transes");
        require(sum > 0, "The sum cannot be equal to 0");
        require(term > 0, "The term cannot be equal to 0");
        require(annualRate > 0, "The rate cannot be equal to 0");
        require(account != address(0), "Account cannot be equal to 0");

        uint256 totalInterest = (sum * term * annualRate) / (365 * 24 * 60 * 60 * 100);
        
        balances[account] += totalInterest;
        totalSupply += totalInterest;
        interestAccruals[account].push(InterestAccrual(totalInterest, annualRate, sum, tokenAddress, block.timestamp));

        emit Transfer(address(0), account, totalInterest);

        emit InterestAccruals(account, totalInterest, annualRate, tokenAddress);
    }

    function redeemPayment(uint256 nominalPrice, uint256 tokensAmount, address account, address tokenAddress)public  {
        require(msg.sender == _owner, "Only the owner can make transes");

        uint256 sum = nominalPrice * tokensAmount;

        balances[account] += sum;
        totalSupply += sum;
        redeems[account].push(Redeem(sum, nominalPrice, tokensAmount, tokenAddress, block.timestamp));

        emit Transfer(address(0), account, sum);

        emit RedeemPayment(account, nominalPrice, tokensAmount, tokenAddress);
    }

    function recover(address oldAddress, address newAddress) public  {
        require(msg.sender == _owner, "Only the owner can make transes");
        require(oldAddress != address(0), "Old address cannot be zero");
        require(newAddress != address(0), "New address cannot be zero");
        require(oldAddress != newAddress, "Addresses must be different");

        // Перенос баланса
        uint256 oldBalance = balances[oldAddress];
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
    function balanceOf(address account) public view returns (uint256) {
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

    for (uint256 i = 0; i < userPayments.length; i++) {
        if (keccak256(abi.encodePacked(userPayments[i].invoiceId)) == keccak256(abi.encodePacked(invoiceId))) {
            return true; 
        }
    }
    return false; 
    }

    function withdrawalExists(address from, string memory invoiceId) internal view returns (bool) {
    Withdrawal[] storage userWithdrawals = withdrawals[from];

    for (uint256 i = 0; i < userWithdrawals.length; i++) {
        if (keccak256(abi.encodePacked(userWithdrawals[i].invoiceId)) == keccak256(abi.encodePacked(invoiceId))) {
            return true; 
        }
    }
    return false; 
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
}