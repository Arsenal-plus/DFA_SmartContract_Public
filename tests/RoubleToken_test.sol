// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "remix_tests.sol"; // Импортируем библиотеку тестирования Remix
import "../contracts/RoubleToken.sol"; // Подключаем контракт для тестирования
import "hardhat/console.sol";


contract RoubleTokenTest {
    RoubleToken roubleToken;
    address owner = address(this);
    address addr1 = 0x1234567890123456789012345678901234567890;
    address addr2 = 0x9876543210987654321098765432109876543210;
    address addr3 = 0x44c088CF58926a04278944847c49B64290B99489;

    function beforeEach() public {
        // Разворачиваем контракт перед каждым тестом
        roubleToken = new RoubleToken();
    }

    // Тестируем начальные значения
    function testInitialValues() public {
        Assert.equal(roubleToken.name(), "Russian Rouble", "Incorrect name");
        Assert.equal(roubleToken.symbol(), "RUB", "Incorrect symbol");
    }

    // Тестируем функцию mint с граничными условиями
    function testMint() public {
        roubleToken.mint(addr1, 100, "paymentRef1");
        Assert.equal(roubleToken.balanceOf(addr1), 100, "Balance should be 100");

        // Проверяем, что нельзя создать токены с тем же paymentReference
        (bool r, ) = address(roubleToken).call(
            abi.encodeWithSignature("mint(address,uint256,string)", addr1, 50, "paymentRef1")
        );
        Assert.ok(!r, "Should not allow minting with the same paymentReference");        
    }

    // Тестируем функцию withdraw с граничными условиями
    function testWithdraw() public {
        roubleToken.mint(addr1, 100, "paymentRef1");
        roubleToken.withdraw(addr1, 50, "withdrawRef1");
        Assert.equal(roubleToken.balanceOf(addr1), 50, "Balance should be 50 after withdrawal");

        // Проверяем, что нельзя снять больше, чем на балансе
        (bool r, ) = address(roubleToken).call(
            abi.encodeWithSignature("withdraw(address,uint256,string)", addr1, 60, "withdrawRef2")
        );
        Assert.ok(!r, "Should not allow withdrawing more than balance");

        // Проверка события TokensWithdrawn
        RoubleToken.Withdrawal[] memory withdrawals = roubleToken.getWithdrawals(addr1);
        Assert.equal(withdrawals.length, 1, "There should be one withdrawal");
        Assert.equal(withdrawals[0].amount, 50, "Withdrawal amount should be 50");
    }

    // Тестируем функцию purchase с граничными условиями
    function testPurchase() public {
        roubleToken.mint(addr1, 200, "paymentRef1");
        roubleToken.purchase(addr1, 100, 10, 10, addr2);
        Assert.equal(roubleToken.balanceOf(addr1), 100, "Balance should be 100 after purchase");

        // Проверяем, что нельзя купить при недостаточном балансе
        (bool r, ) = address(roubleToken).call(
            abi.encodeWithSignature("purchase(address,uint256,uint256,uint256,address)", addr1, 150, 15, 15, addr2)
        );
        Assert.ok(!r, "Should not allow purchase with insufficient balance");

        // Проверка события Purchases
        RoubleToken.Purchase[] memory purchases = roubleToken.getPurchases(addr1);
        Assert.equal(purchases.length, 1, "There should be one purchase");
        Assert.equal(purchases[0].sum, 100, "Purchase sum should be 100");
    }

    // Тестируем функцию interestAccrual с граничными условиями
    function testInterestAccrual() public {
        roubleToken.mint(addr1, 1000, "paymentRef1");
        roubleToken.interestAccrual(1000, 30*24*60*60, 5, addr1, addr2);
        Assert.equal(roubleToken.balanceOf(addr1), 1004, "Balance should include accrued interest");

        // Проверяем, что функция не работает с нулевыми значениями
        (bool r, ) = address(roubleToken).call(
            abi.encodeWithSignature("interestAccrual(uint,uint,uint,address,address)", 0, 30, 5, addr1, addr2)
        );
        Assert.ok(!r, "Should not allow zero sum");

        (r, ) = address(roubleToken).call(
            abi.encodeWithSignature("interestAccrual(uint,uint,uint,address,address)", 1000, 0, 5, addr1, addr2)
        );
        Assert.ok(!r, "Should not allow zero term");

        (r, ) = address(roubleToken).call(
            abi.encodeWithSignature("interestAccrual(uint,uint,uint,address,address)", 1000, 30, 0, addr1, addr2)
        );
        Assert.ok(!r, "Should not allow zero rate");
    }

    function interestAccrualSuccess() public {
        roubleToken.interestAccrual(1000, 15768000, 100, addr3, addr1);
        uint finalBalance = roubleToken.balanceOf(addr3);
        Assert.equal(finalBalance, 500, "Incorrect interest");
    }

    function redeemPaymentTest() public {
        address receiver = 0xc5480FA4421892a0c411c8ff874eC0B5Cc43a684;
        roubleToken.redeemPayment(1000, 10, receiver, addr1);
        uint finalBalance = roubleToken.balanceOf(receiver);
        Assert.equal(finalBalance, 10000, "Incorrect redeem payment");
    }

    function getAllTransactions() public {
        address receiver = address(1);
        roubleToken.mint(receiver, 10000, "paymentRef1");
        roubleToken.interestAccrual(1000, 15768000, 100, receiver, addr1);
        roubleToken.redeemPayment(500, 1, receiver, addr1);
        roubleToken.refund(receiver, 321, 1,321, addr1);
        roubleToken.withdraw(receiver, 2, "invoiceId");
        roubleToken.purchase(receiver, 100, 10, 10, addr1);

        // Call the getAccountTransactions function
        (
            RoubleToken.Payment[] memory payments, 
            RoubleToken.Withdrawal[] memory withdrawals, 
            RoubleToken.Purchase[] memory purchases, 
            RoubleToken.Refund[] memory refunds, 
            RoubleToken.Redeem[] memory redeems, 
            RoubleToken.InterestAccrual[] memory interestAccruals
        ) = roubleToken.getAccountTransactions(receiver);

        // Assertions
        Assert.equal(payments.length, 1, "Incorrect number of payments");
        Assert.equal(payments[0].amount, 10000, "Incorrect payment amount");

        Assert.equal(redeems.length, 1, "Incorrect number of redeems");
        Assert.equal(redeems[0].sum, 500, "Incorrect redeem amount");

        Assert.equal(interestAccruals.length, 1, "Incorrect number of interestAccruals");
        Assert.equal(interestAccruals[0].sum, 500, "Incorrect interestAccrual amount");

        Assert.equal(refunds.length, 1, "Incorrect number of refunds");
        Assert.equal(refunds[0].sum, 321, "Incorrect refund amount");

        Assert.equal(withdrawals.length, 1, "Incorrect number of withdrawals");
        Assert.equal(withdrawals[0].amount, 2, "Incorrect withdraw amount");

        Assert.equal(purchases.length, 1, "Incorrect number of purchases");
        Assert.equal(purchases[0].sum, 100, "Incorrect purchase amount");

    }
}
