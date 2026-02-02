# 🌐 Sepolia Testnet Deployment - Live Demo

**Network:** Sepolia Testnet (Chain ID: 11155111)  
**Demo Script:** `ebis-euro-capital-defi-foundry/script/FullSystemDemo.s.sol`  
**Deployment Block:** 10174739 - 10174781

---

## 📍 Deployed Contract Addresses

| Contrato | Dirección | Etherscan |
|----------|-----------|-----------|
| **Digital Euro (DEUR)** | `0xCfE13DbeF03A25f6f2c6B436aA380f488367FC1C` | [Ver en Etherscan](https://sepolia.etherscan.io/address/0xCfE13DbeF03A25f6f2c6B436aA380f488367FC1C) |
| **Financial Assets (ERC-1155)** | `0x2d5fC6b78ED4C0EEd0795C28fdbF9BF4004b7130` | [Ver en Etherscan](https://sepolia.etherscan.io/address/0x2d5fC6b78ED4C0EEd0795C28fdbF9BF4004b7130) |
| **Primary Market (IPO)** | `0x2e329AE807c91f37bc4e49cB94A67328cFE34d35` | [Ver en Etherscan](https://sepolia.etherscan.io/address/0x2e329AE807c91f37bc4e49cB94A67328cFE34d35) |
| **Secondary Market (P2P)** | `0x30333d882c50c1A28D56572088051f7932c201f2` | [Ver en Etherscan](https://sepolia.etherscan.io/address/0x30333d882c50c1A28D56572088051f7932c201f2) |

> ✅ **Todos los contratos están verificados en Etherscan**

---

## 👥 Participants

| Rol | Dirección Ethereum |
|-----|-------------------|
| 🏦 **Fund Manager** | `0xe30F5D336931186dD86b5C9426FD4493C34a5C5D` |
| 👤 **Investor 1** | `0x6Fc2Fbb2973E592EB6f932a10b3e72eeaA3113C0` |
| 👤 **Investor 2** | `0xdE4a466B7441357E1137A1a1E311bD70c1439eCB` |
| 👤 **Investor 3** | `0xac75578bBdd3C830B32F2De2B8E2a4fA36996082` |

---

## 💰 Deployment Costs

| Métrica | Valor |
|---------|-------|
| **Total Gas Used** | 7,826,440 gas |
| **Average Gas Price** | 1.04 gwei |
| **Total ETH Spent** | 0.008232 ETH |
| **Number of Transactions** | 43 transactions |

### Breakdown por Contrato

| Contrato | Gas Used | ETH Paid | Transaction Hash |
|----------|----------|----------|------------------|
| **DigitalEuro** | 797,264 | 0.000915 ETH | `0x49998c44da18f8b0417e3a9e8bb51bb1e642e2f563749557a7ea50986ce15c53` |
| **FinancialAssets** | 1,885,604 | 0.002029 ETH | `0x42dd44c1e6bf4ec33669b76f94d535c14c52811c431bb97472c78b8bd0d558a9` |
| **PrimaryMarket** | 964,786 | 0.000998 ETH | `0x4c45f0f89d97fdeff513bf0be9d1b28941365206500752ec30ad362441b21fbc` |
| **SecondaryMarket** | 1,214,263 | 0.001219 ETH | `0x1510e10b4bdade0300a94c66b7bbcd6424ccf19c3f4076be9b5738393891fb6a` |

---

## 🎬 Full Demo Output

```
======================================================================
FULL SYSTEM DEMO - HAPPY PATH
======================================================================
Complete workflow: Fund Creation -> IPO -> P2P Trading

===> Participants:
   Fund Manager: 0xe30F5D336931186dD86b5C9426FD4493C34a5C5D
   Investor 1:   0x6Fc2Fbb2973E592EB6f932a10b3e72eeaA3113C0
   Investor 2:   0xdE4a466B7441357E1137A1a1E311bD70c1439eCB
   Investor 3:   0xac75578bBdd3C830B32F2De2B8E2a4fA36996082

======================================================================
PHASE 1: SYSTEM DEPLOYMENT
======================================================================

===> Digital Euro (DEUR) deployed
   Address: 0xCfE13DbeF03A25f6f2c6B436aA380f488367FC1C

===> Financial Assets (ERC-1155) deployed
   Address: 0x2d5fC6b78ED4C0EEd0795C28fdbF9BF4004b7130

===> Primary Market (IPO) deployed
   Address: 0x2e329AE807c91f37bc4e49cB94A67328cFE34d35

===> Secondary Market (P2P) deployed
   Address: 0x30333d882c50c1A28D56572088051f7932c201f2

===> Configuring Primary Market in Financial Assets...
   Primary Market configured successfully

======================================================================
PHASE 2: FUND CREATION & SHARE ISSUANCE
======================================================================

===> Fund Manager creating investment funds...
   ✅ Created: Nexus Technology Fund (ID: 0)
   ✅ Created: Goldstone Precious Metals Fund (ID: 1)
   ✅ Created: Apex Real Estate Capital Fund (ID: 2)
   ✅ Created: Green Future Sustainable Energy Fund (ID: 3)
   ✅ Created: MediCare Healthcare & Biotech Fund (ID: 4)

===> Fund Manager issuing shares to Primary Market...
   ✅ Issued 1,000 TECH shares
   ✅ Issued 500 GOLD shares
   ✅ Issued 750 REAL shares
   ✅ Issued 800 GREEN shares
   ✅ Issued 600 HEALTH shares

===> Fund Manager setting IPO prices...
   ✅ TECH: 100 DEUR per share
   ✅ GOLD: 200 DEUR per share
   ✅ REAL: 150 DEUR per share
   ✅ GREEN: 80 DEUR per share
   ✅ HEALTH: 250 DEUR per share

======================================================================
PHASE 3: CENTRAL BANK - DEUR DISTRIBUTION
======================================================================

===> Central Bank minting Digital Euro to investors...
   ✅ Investor 1: 50,000 DEUR
   ✅ Investor 2: 30,000 DEUR
   ✅ Investor 3: 40,000 DEUR
   DEUR distributed - Investors ready to trade

======================================================================
PHASE 4: PRIMARY MARKET - IPO PURCHASES
======================================================================

===> Investor 1: Purchasing from IPO (Tech-focused strategy)...
   ✅ Bought 100 TECH shares for 10,000 DEUR
   ✅ Bought 50 GOLD shares for 10,000 DEUR
   💼 Total spent: 20,000 DEUR

===> Investor 2: Purchasing from IPO (ESG-focused strategy)...
   ✅ Bought 100 GREEN shares for 8,000 DEUR
   ✅ Bought 80 REAL shares for 12,000 DEUR
   💼 Total spent: 20,000 DEUR

===> Investor 3: Purchasing from IPO (Balanced strategy)...
   ✅ Bought 60 HEALTH shares for 15,000 DEUR
   ✅ Bought 30 GOLD shares for 6,000 DEUR
   ✅ Bought 50 TECH shares for 5,000 DEUR
   💼 Total spent: 26,000 DEUR

===> IPO Results:
   💰 Fund Treasury raised: 66,000 DEUR
   📊 TECH: 150/1,000 sold (15%)
   📊 GOLD: 80/500 sold (16%)
   📊 REAL: 80/750 sold (10.7%)
   📊 GREEN: 100/800 sold (12.5%)
   📊 HEALTH: 60/600 sold (10%)

======================================================================
PHASE 5: SECONDARY MARKET - CREATING LISTINGS
======================================================================

===> Scenario: Investors creating listings for various funds
   ✅ Approvals granted to Secondary Market

===> Investor 1: Listing TECH shares at premium...
   ✅ Listing 0: 60 TECH @ 120 DEUR/share (20% premium over IPO)
   🔒 60 TECH shares locked in escrow

===> Investor 2: Listing GREEN shares...
   ✅ Listing 1: 50 GREEN @ 85 DEUR/share (6% premium over IPO)
   🔒 50 GREEN shares locked in escrow

======================================================================
PHASE 6: SECONDARY MARKET - P2P TRADING (DvP)
======================================================================

===> Trade 1: Investor 2 buys TECH from Investor 1's listing

===> Investor 2: Purchasing TECH from Secondary Market...
   ✅ Bought 40 TECH from Investor 1 for 4,800 DEUR (40 × 120)
   ⚡ Atomic DvP: DEUR payment + Asset delivery in 1 transaction

   📊 Investor 2 now has: 40 TECH shares
   📊 Investor 1 received: 4,800 DEUR

===> Trade 2: Investor 3 buys GREEN from Investor 2's listing

===> Investor 3: Purchasing GREEN from Secondary Market...
   ✅ Bought 30 GREEN from Investor 2 for 2,550 DEUR (30 × 85)
   ⚡ Atomic DvP: DEUR payment + Asset delivery in 1 transaction

   📊 Investor 3 now has: 30 GREEN shares
   📊 Investor 2 received: 2,550 DEUR

======================================================================
📊 FINAL PORTFOLIO SUMMARY
======================================================================

👤 Investor 1 (Tech + Precious Metals):
   TECH: 40 shares (bought 100 IPO, sold 60 P2P)
   GOLD: 50 shares (bought 50 IPO)
   DEUR: 34,800 DEUR
   💡 Strategy: IPO investor who sold TECH at premium (120 DEUR vs 100 DEUR IPO)
   📈 P2P Profit: 800 DEUR (13.3% gain on 60 TECH shares sold)

👤 Investor 2 (ESG-focused + TECH):
   TECH: 40 shares (bought 40 P2P @ 120)
   GREEN: 50 shares (bought 100 IPO, sold 50 P2P)
   REAL: 80 shares (bought 80 IPO)
   DEUR: 7,750 DEUR
   💡 Strategy: ESG focus with opportunistic TECH purchase on secondary

👤 Investor 3 (Balanced Diversification):
   TECH: 50 shares (bought 50 IPO)
   GOLD: 30 shares (bought 30 IPO)
   GREEN: 30 shares (bought 30 P2P @ 85)
   HEALTH: 60 shares (bought 60 IPO)
   DEUR: 11,450 DEUR
   💡 Strategy: Well-diversified portfolio across 4 different fund types

💰 Fund Treasury:
   Total raised from IPO: 66,000 DEUR
   Deployment: Available for fund management and investments

📊 Market Statistics:
   Total IPO Volume: 66,000 DEUR
   Secondary Market Volume: 7,350 DEUR
   Total Trading Volume: 73,350 DEUR
   
   IPO Performance:
   - TECH sold: 150 shares
   - GOLD sold: 80 shares
   - REAL sold: 80 shares
   - GREEN sold: 100 shares
   - HEALTH sold: 60 shares
```

---

## ✨ Key Features Demonstrated

### ✅ Complete System Integration
- ✓ All 4 contracts working together seamlessly
- ✓ 5 diverse fund types: Technology, Gold, Real Estate, Green Energy, Healthcare
- ✓ Realistic user journey from IPO to P2P trading
- ✓ Multiple investment strategies demonstrated

### ✅ DvP (Delivery vs Payment) Settlement
- ✓ Primary Market: Atomic DEUR ↔ Asset swap
- ✓ Secondary Market: Atomic P2P settlement
- ✓ Multiple listings and trades (TECH @ 20% premium, GREEN @ 6% premium)
- ✓ Zero counterparty risk

### ✅ Market Functionality
- ✓ Primary Market (IPO) for initial distribution across all fund types
- ✓ Secondary Market (P2P) for price discovery and liquidity
- ✓ Partial fills enabling liquidity
- ✓ Asset escrow protecting both parties

### ✅ Tokenization Benefits
- ✓ 24/7 trading capability
- ✓ Fractional ownership (can buy 1 share)
- ✓ Instant settlement (no T+2 delays)
- ✓ Transparent on-chain history
- ✓ Programmable compliance (via roles)

---

## 🔧 Technical Details

### Compiler Configuration
- **Solidity Version:** 0.8.30
- **EVM Version:** Prague
- **Optimizer:** Enabled (200 runs)
- **Framework:** Foundry

### Contract Verification
All contracts have been successfully verified on Etherscan:
- ✅ DigitalEuro: [Verified](https://sepolia.etherscan.io/address/0xCfE13DbeF03A25f6f2c6B436aA380f488367FC1C#code)
- ✅ FinancialAssets: [Verified](https://sepolia.etherscan.io/address/0x2d5fC6b78ED4C0EEd0795C28fdbF9BF4004b7130#code)
- ✅ PrimaryMarket: [Verified](https://sepolia.etherscan.io/address/0x2e329AE807c91f37bc4e49cB94A67328cFE34d35#code)
- ✅ SecondaryMarket: [Verified](https://sepolia.etherscan.io/address/0x30333d882c50c1A28D56572088051f7932c201f2#code)

### Metadata URI
Financial Assets metadata is hosted on IPFS via Pinata:
```
https://amethyst-accessible-lemming-653.mypinata.cloud/ipfs/bafybeigus5qoiqcybdf67q3zv6n72nmm5mqomeibarmzyejug2jvwondbi/{id}.json
```

---

## 🚀 How to Run the Demo

### Prerequisites
```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone the repository
git clone <repository-url>
cd ebis-euro-capital-defi-foundry
```

### Configuration

#### 1. Configure Environment Variables
Create a `.env` file with:
```env
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_API_KEY
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY
```

#### 2. Configure Foundry Account

Importar tu cuenta al keystore de Foundry:
```bash
cast wallet import main_sepolia --interactive
```


### Run the Demo
```bash
# Load environment variables
source .env

# Run the full system demo on Sepolia
forge script script/FullSystemDemo.s.sol \
  --rpc-url sepolia \
  --account main_sepolia \
  --broadcast \
  --verify
```

---

## 📈 Investment Funds Overview

| Fund ID | Name | Symbol | IPO Price | Total Supply | Sold | Remaining |
|---------|------|--------|-----------|--------------|------|-----------|
| 0 | Nexus Technology Fund | TECH | 100 DEUR | 1,000 | 150 | 850 |
| 1 | Goldstone Precious Metals Fund | GOLD | 200 DEUR | 500 | 80 | 420 |
| 2 | Apex Real Estate Capital Fund | REAL | 150 DEUR | 750 | 80 | 670 |
| 3 | Green Future Sustainable Energy Fund | GREEN | 80 DEUR | 800 | 100 | 700 |
| 4 | MediCare Healthcare & Biotech Fund | HEALTH | 250 DEUR | 600 | 60 | 540 |

---

## 🎯 Demo Highlights

### Primary Market Success
- **Total Capital Raised:** 66,000 DEUR
- **Participation Rate:** 10-16% across all funds
- **Investor Diversity:** 3 different investment strategies demonstrated

### Secondary Market Activity
- **Total P2P Volume:** 7,350 DEUR
- **Price Discovery:** TECH trading at 20% premium, GREEN at 6% premium
- **Liquidity:** Partial fills enabled successful trades

### System Performance
- **Transaction Success Rate:** 100%
- **Average Gas Price:** 1.04 gwei (very efficient)
- **Settlement:** Instant atomic DvP on all trades

---

**🎉 Full System Demo Completed Successfully!**

*Todos los contratos están desplegados, verificados y funcionales en Sepolia Testnet* ✅
