// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {DigitalEuro} from "../src/DigitalEuro.sol";
import {FinancialAssets} from "../src/FinancialAssets.sol";
import {PrimaryMarket} from "../src/PrimaryMarket.sol";
import {SecondaryMarket} from "../src/SecondaryMarket.sol";

contract DeployCompleteEcosystem is Script {
    function run() external {
        vm.startBroadcast();

        console.log("Started Deploying Complete Ecosystem...");

        // 1. Deploy DigitalEuro
        DigitalEuro digitalEuro = new DigitalEuro("Digital Euro", "DEUR");
        console.log("DigitalEuro deployed at:", address(digitalEuro));

        // 2. Deploy FinancialAssets
        string
            memory baseUri = "https://amethyst-accessible-lemming-653.mypinata.cloud/ipfs/bafybeignpqpasdhwfe4h5zj3vyfnezmeid3aq36g7h4jt6nktadcihisna/{id}.json";
        FinancialAssets financialAssets = new FinancialAssets(baseUri);
        console.log("FinancialAssets deployed at:", address(financialAssets));

        // 3. Deploy PrimaryMarket
        PrimaryMarket primaryMarket = new PrimaryMarket(
            address(digitalEuro),
            address(financialAssets)
        );
        console.log("PrimaryMarket deployed at:", address(primaryMarket));

        // 4. Deploy SecondaryMarket
        SecondaryMarket secondaryMarket = new SecondaryMarket(
            address(digitalEuro),
            address(financialAssets)
        );
        console.log("SecondaryMarket deployed at:", address(secondaryMarket));

        // 5. Configure FinancialAssets to recognize PrimaryMarket
        financialAssets.setPrimaryMarket(address(primaryMarket));
        console.log(
            "FinancialAssets: PrimaryMarket address set to",
            address(primaryMarket)
        );

        vm.stopBroadcast();

        console.log("\n========================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("========================================");
        console.log("DigitalEuro:", address(digitalEuro));
        console.log("FinancialAssets:", address(financialAssets));
        console.log("PrimaryMarket:", address(primaryMarket));
        console.log("SecondaryMarket:", address(secondaryMarket));
        console.log("========================================");
    }
}
