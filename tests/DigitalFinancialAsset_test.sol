// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
pragma abicoder v2;

import "remix_tests.sol"; 
import "../contracts/DigitalFinancialAsset.sol";

contract DigitalFinancialAssetTest{

    function burnTest() public{

        DigitalFinancialAsset dfa = new DigitalFinancialAsset(
            "TokenName",
            "TN",
            "IssuerName",
            1000,
            1000,
            1,
            1828897786,
            2,
            1628897786,
            10,
            12
        );

        address investor = 0x44c088CF58926a04278944847c49B64290B99489;

        dfa.increaseBalance(investor, 1);

        uint balanceBeforeBurn =  dfa.balanceOf(investor);

        Assert.equal(1,balanceBeforeBurn, "wrong balance");
        
        dfa.burn(investor, 1);

        uint balanceAfterBurn =  dfa.balanceOf(investor);

        Assert.equal(0,balanceAfterBurn, "wrong balance");
    }
}
