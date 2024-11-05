// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import "./DigitalFinancialAsset.sol";

contract ExchangeViewer
{
        struct DfaInfo {
        string name;
        string symbol;
        string issuer;
        uint price;
        uint64 salesStartDate;
        uint64 salesEndDate;
        uint64 redeemDate;
        uint16 annualInterestRate;
        uint threshold;
        address assetAddress;
        uint totalSold;
        uint minimalInvestmentAmount;
        uint initialSupply;
    }

    struct Asset {
        DfaInfo dfaInfo;
        uint quantity;
    }

    struct ShowcaseItem {
        DfaInfo dfaInfo;
        uint currentReserve;
    }
        function getShowcase(address[] memory dfaAddresses) external view returns (ShowcaseItem[] memory) {
        ShowcaseItem[] memory showcase = new ShowcaseItem[](dfaAddresses.length);
        
        for (uint i = 0; i < dfaAddresses.length; i++) {
            DigitalFinancialAsset dfa = DigitalFinancialAsset(dfaAddresses[i]);
            
            showcase[i] = ShowcaseItem({
                dfaInfo: DfaInfo({
                    name: dfa.name(),
                    symbol: dfa.symbol(),
                    issuer: dfa.issuer(), 
                    price: dfa.price(),
                    salesStartDate: dfa.salesStartDate(), 
                    salesEndDate: dfa.salesEndDate(),
                    redeemDate: dfa.redeemDate(), 
                    annualInterestRate: dfa.annualInterestRate(),
                    threshold: dfa.threshold(),
                    assetAddress: dfaAddresses[i],
                    totalSold: dfa.getTotalSold(),
                    minimalInvestmentAmount: dfa.minimalInvestmentAmount(),
                    initialSupply: dfa.initialSupply()
                }),
                currentReserve: dfa.getReserve()
            });
        }
        return showcase;
    }

    function getPortfolio(address account, DigitalFinancialAsset[] memory allDfas) external view returns (Asset[] memory) {
        uint assetCount = 0;
        for (uint i = 0; i < allDfas.length; i++) {
            if (allDfas[i].balanceOf(account) > 0) {
                assetCount++;
            }
        }

        Asset[] memory portfolio = new Asset[](assetCount);
        uint index = 0;

        for (uint i = 0; i < allDfas.length; i++) {
            DigitalFinancialAsset dfa = allDfas[i];
            uint balance = dfa.balanceOf(account);
            if (balance > 0) {
                portfolio[index] = Asset({
                    dfaInfo: DfaInfo({
                        name: dfa.name(),
                        symbol: dfa.symbol(),
                        issuer: dfa.issuer(), 
                        price: dfa.price(),
                        salesStartDate: dfa.salesStartDate(), 
                        salesEndDate: dfa.salesEndDate(),
                        redeemDate: dfa.redeemDate(), 
                        annualInterestRate: dfa.annualInterestRate(),
                        threshold: dfa.threshold(),
                        assetAddress: address(dfa),
                        totalSold: dfa.getTotalSold(),
                        minimalInvestmentAmount: dfa.minimalInvestmentAmount(),
                        initialSupply: dfa.initialSupply()
                    }),

                quantity: balance
                });
                index++;
            }
        }
        return portfolio;
    }
}