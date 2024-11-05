// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
pragma abicoder v2;

import "remix_tests.sol"; 
import "../contracts/Exchange.sol";
import "hardhat/console.sol";

contract ExchangeTest{
    RoubleToken roubleToken;
    ExchangeContract exchange;
    address addr1 = 0x1234567890123456789012345678901234567890;
    address addr2 = 0x9876543210987654321098765432109876543210;
    address addr3 = 0x44c088CF58926a04278944847c49B64290B99489;

    function beforeAll() public {
        exchange = new ExchangeContract();
        exchange.createDFA(
            "Name", "Symbol", "Issuer", 1000, 1000, 1, 1828897786, 2, 1928897786, 10, 2
        );
    }

    function deployToken() public {
        ExchangeViewer.ShowcaseItem[] memory showcaseArray = exchange.getShowcase();
        Assert.equal(showcaseArray.length, 1, "Only one str");
        Assert.equal(showcaseArray[0].dfaInfo.name, "Name", "Wrong name");
    }
    function buyToken() public {
        exchange.mintRoubles(addr1, 10000, "paymentRef1");

        ExchangeViewer.ShowcaseItem[] memory showcaseArray = exchange.getShowcase();
        address dfaAddress = showcaseArray[0].dfaInfo.assetAddress;

        exchange.buyDFA(addr1, dfaAddress, 2);

        ExchangeViewer.Asset[] memory investorsAssets = exchange.getPortfolio(addr1);

        Assert.equal(investorsAssets.length, 1, "Only one str");
    }

    function minLimitTest() public {
        exchange.mintRoubles(addr1, 10000, "paymentRef2");

        ExchangeViewer.ShowcaseItem[] memory showcaseArray = exchange.getShowcase();
        address dfaAddress = showcaseArray[0].dfaInfo.assetAddress;

        bool result = false;
        try exchange.buyDFA(addr1, dfaAddress, 1) {
            result = true;
        } catch {
            result = false;
        }

        Assert.equal(result, false, "Cannot purchase less than limit");
    }

    function redeemTokenTest() public {
        exchange.mintRoubles(addr3, 1000000, "paymentRef3");

        ExchangeViewer.ShowcaseItem[] memory showcaseArray = exchange.getShowcase();
        address dfaAddress = showcaseArray[0].dfaInfo.assetAddress;

        exchange.buyDFA(addr3, dfaAddress, 3);

        exchange.redeemDFA(addr3, dfaAddress, 3);        

        ExchangeViewer.Asset[] memory investorsAssets = exchange.getPortfolio(addr3);
        Assert.equal(investorsAssets.length, 0, "Must be burned");
    }
}