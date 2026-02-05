# 🌐 dApp de Activos Tokenizados - Aplicación Web Descentralizada
**Caso Práctico - Máster en Ingeniería y Desarrollo Blockchain**

Aplicación web descentralizada (dApp) para la interacción con el ecosistema de tokenización de activos financieros desarrollado previamente. Permite a inversores conectar sus wallets y operar con activos tokenizados y moneda digital (CBDC simulada) de forma segura e intuitiva.

[![React](https://img.shields.io/badge/React-19.2.0-61DAFB.svg)](https://react.dev/)
[![Vite](https://img.shields.io/badge/Vite-7.2.4-646CFF.svg)](https://vitejs.dev/)
[![ethers.js](https://img.shields.io/badge/ethers.js-6.16.0-2535A0.svg)](https://docs.ethers.org/)
[![Foundry](https://img.shields.io/badge/Foundry-Contracts-FFDB1C.svg)](https://getfoundry.sh/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Live on Sepolia](https://img.shields.io/badge/Live-Sepolia%20Testnet-success)](https://sepolia.etherscan.io/)

---

## 📑 Tabla de Contenidos

- [Descripción](#-descripción)
- [Sobre los Smart Contracts](#-sobre-los-smart-contracts)
- [Stack Tecnológico](#-stack-tecnológico)
- [Arquitectura de la dApp](#️-arquitectura-de-la-dapp)
- [Funcionalidades Principales](#-funcionalidades-principales)
- [Decisiones de Diseño Frontend](#-decisiones-de-diseño-frontend)
- [Instalación y Configuración](#-instalación-y-configuración)
- [Uso de la Aplicación](#-uso-de-la-aplicación)
- [Demostración en Vivo](#-demostración-en-vivo)
- [Capturas de Pantalla](#-capturas-de-pantalla)

---

## 🎯 Descripción

Esta **aplicación web descentralizada (dApp)** permite a usuarios interactuar de manera intuitiva y segura con un ecosistema completo de tokenización de activos financieros. Los usuarios pueden:

✅ **Conectar su wallet** (MetaMask, WalletConnect, etc.)  
✅ **Ver su balance** de Digital Euro (CBDC) en tiempo real  
✅ **Transferir CBDC** a otras wallets  
✅ **Gestionar emisión** de CBDC y activos tokenizados (funcionalidad restringida)  
✅ **Comprar activos** en el mercado primario (IPO)  
✅ **Operar en mercado secundario** (P2P) con escrow y DvP atómico  
✅ **Visualizar su portfolio** de activos tokenizados

### 🎓 Contexto Académico

Este proyecto es la **segunda parte** del caso práctico del Máster en Blockchain:

- **Tema 3 (Anterior):** Desarrollo de Smart Contracts con Hardhat
- **Tema 5 (Actual):** Desarrollo de la dApp frontend + migración a Foundry

---

## 📜 Sobre los Smart Contracts

### Migración a Foundry

Los smart contracts utilizados en esta dApp son los **mismos desarrollados en el caso práctico anterior** (Tema 3), con **mínimas correcciones** y migrados de **Hardhat a Foundry**.

**¿Por qué la migración?**

En esta materia (Tema 5) se trabaja con **Foundry** como framework de desarrollo, por lo que se realizó la migración completa del proyecto:

- ✅ Migración de **Hardhat** → **Foundry**
- ✅ Migración de **tests TypeScript** → **tests Solidity nativos**
- ✅ Correcciones menores en los contratos (eventos, errores personalizados)
- ✅ **91 tests** en Solidity con cobertura completa
- ✅ Deployment scripts en Solidity

### Contratos del Ecosistema

El ecosistema blockchain consta de **4 smart contracts** desplegados en Sepolia:

| Contrato | Descripción | Dirección |
|----------|-------------|-----------|
| **DigitalEuro** | Token ERC-20 que simula CBDC (6 decimales) | `0xCfE13Dbe...367FC1C` |
| **FinancialAssets** | Activos tokenizados ERC-1155 multi-asset | `0x2d5fC6b7...004b7130` |
| **PrimaryMarket** | Mercado de emisión (IPO) con DvP | `0x2e329AE8...FE34d35` |
| **SecondaryMarket** | Mercado P2P con escrow y DvP atómico | `0x30333d88...2c201f2` |

📄 Para más información sobre los contratos, ver [SEPOLIA_DEPLOYMENT_DEMO.md](./SEPOLIA_DEPLOYMENT_DEMO.md)

---

## 🚀 Stack Tecnológico

### Frontend (dApp)

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| **React** | 19.2.0 | Framework UI moderno |
| **Vite** | 7.2.4 | Build tool ultra-rápido con HMR instantáneo |
| **ethers.js** | 6.16.0 | Librería para interacción con Ethereum |
| **Web3-Onboard** | 2.24.1 | Gestión multi-wallet (MetaMask, WalletConnect, etc.) |
| **CSS Vanilla** | - | Estilos personalizados con glassmorphism |

### Backend (Smart Contracts)

| Tecnología | Propósito |
|------------|-----------|
| **Foundry** | Framework de desarrollo Solidity |
| **Solidity** | Lenguaje de smart contracts (v0.8.30) |
| **OpenZeppelin** | Librerías seguras (ERC-20, ERC-1155, AccessControl) |

### Infraestructura

- **Sepolia Testnet** - Red de pruebas Ethereum
- **Pinata IPFS** - Almacenamiento descentralizado de metadata
- **Etherscan** - Explorador de bloques y verificación de contratos

---

## 🏗️ Arquitectura de la dApp

### Estructura de Directorios

```
ebis-fund-front/
├── src/
│   ├── components/
│   │   ├── Navbar.jsx                    # Header con conexión wallet + balance
│   │   ├── SecondaryNav.jsx              # Navegación entre secciones
│   │   ├── dashboard/
│   │   │   ├── TransferCard.jsx          # 💸 Transferir DEUR P2P
│   │   │   └── HoldingsCard.jsx          # 👀 Ver portfolio de activos
│   │   ├── governance/
│   │   │   ├── MintCBDCCard.jsx          # 🏦 Mintear DEUR (solo owner)
│   │   │   ├── CreateAssetCard.jsx       # ➕ Crear nuevos fondos
│   │   │   ├── MintAssetCard.jsx         # 📊 Mintear shares de fondos
│   │   │   └── AllAssetsList.jsx         # 📋 Lista de todos los fondos
│   │   ├── market/
│   │   │   ├── PrimaryMarket.jsx         # 📈 Compra en IPO
│   │   │   └── SecondaryMarket.jsx       # 🔄 Trading P2P
│   │   └── sections/
│   │       ├── Dashboard.jsx             # Sección principal
│   │       ├── ProtocolGovernance.jsx    # Gestión de protocolos
│   │       └── LiveMarket.jsx            # Mercados
│   ├── context/
│   │   ├── Web3Context.jsx               # 🌐 Estado global Web3
│   │   └── AssetsContext.jsx             # 📊 Estado de fondos
│   ├── contracts/
│   │   ├── DigitalEuroABI.json
│   │   ├── FinancialAssetsABI.json
│   │   ├── PrimaryMarketABI.json
│   │   └── SecondaryMarketABI.json
│   ├── hooks/
│   │   ├── useDEURBalance.js
│   │   └── useAssetBalance.js
│   ├── App.jsx
│   ├── main.jsx
│   └── index.css
├── public/
│   ├── logo.png
│   └── video2.mp4                        # Background animado
├── .env
├── package.json
└── vite.config.js
```

---

## ✨ Funcionalidades Principales

### 1. 🔌 Conexión de Wallet

**Tecnología:** Web3-Onboard

```javascript
// Web3Context.jsx
const onboard = Onboard({
    wallets: [injectedModule()],
    chains: [{ id: '0xaa36a7', token: 'ETH', label: 'Sepolia Testnet' }],
    appMetadata: {
        name: 'EBIS Fund',
        icon: '/logo.png',
        description: 'Tokenized Assets Trading Platform'
    }
});
```

**Características:**
- ✅ Multi-wallet: MetaMask, WalletConnect, Coinbase Wallet, etc.
- ✅ Auto-reconexión al recargar la página
- ✅ Detección automática de cambio de cuenta
- ✅ Detección automática de cambio de red
- ✅ Validación de red correcta (Sepolia)

---

### 2. 💰 Visualización de Balance DEUR

**Componente:** `Navbar.jsx`

```javascript
const contract = new ethers.Contract(
    DIGITAL_EURO_ADDRESS,
    DigitalEuroABI,
    provider
);

const balanceWei = await contract.balanceOf(account);
const formatted = ethers.formatUnits(balanceWei, 6); // 6 decimales
```

**Características:**
- ✅ Balance en tiempo real en el header
- ✅ Actualización automática cada 10 segundos
- ✅ Formato con separadores de miles (1,000.50 DEUR)
- ✅ Indicador de carga

---

### 3. 💸 Transferir DEUR a Otras Wallets

**Componente:** `TransferCard.jsx`

```javascript
const deurContract = new ethers.Contract(
    DIGITAL_EURO_ADDRESS,
    DigitalEuroABI,
    signer // ← Usar signer para enviar transacciones
);

const tx = await deurContract.transfer(toAddress, amountInWei);
await tx.wait(); // Esperar confirmación
```

**Características:**
- ✅ Validación de dirección Ethereum
- ✅ Conversión automática de unidades (DEUR → Wei)
- ✅ Estados de carga (Transferring... → Success)
- ✅ Manejo de errores (saldo insuficiente, etc.)

---

### 4. 🏦 Gestión de Emisión (Solo Owner/Fund Manager)

#### Mintear CBDC (Solo Owner)

**Componente:** `MintCBDCCard.jsx`

```javascript
const contract = new ethers.Contract(DIGITAL_EURO_ADDRESS, DigitalEuroABI, signer);
const tx = await contract.mint(toAddress, amountInWei);
await tx.wait();
```

**Restricción:** Requiere rol `MINTER_ROLE` en el contrato.

#### Crear Asset Type (Solo Fund Manager)

**Componente:** `CreateAssetCard.jsx`

```javascript
const contract = new ethers.Contract(FINANCIAL_ASSETS_ADDRESS, FinancialAssetsABI, signer);
const tx = await contract.createAssetType(assetId, name, symbol);
await tx.wait();
```

**Restricción:** Requiere rol `FUND_MANAGER_ROLE`.

#### Mintear Asset Shares (Solo Fund Manager)

**Componente:** `MintAssetCard.jsx`

```javascript
const tx = await contract.mint(assetId, amount);
await tx.wait();
```

---

### 5. 📈 Mercado Primario (IPO)

**Componente:** `PrimaryMarket.jsx`

**Flujo de Compra:**

```javascript
// 1. Aprobar DEUR para que el contrato pueda gastarlos
const deurContract = new ethers.Contract(DIGITAL_EURO_ADDRESS, DigitalEuroABI, signer);
const approveTx = await deurContract.approve(PRIMARY_MARKET_ADDRESS, totalCost);
await approveTx.wait();

// 2. Comprar activos (DvP atómico)
const marketContract = new ethers.Contract(PRIMARY_MARKET_ADDRESS, PrimaryMarketABI, signer);
const buyTx = await marketContract.buyAsset(assetId, amount);
await buyTx.wait();
```

**Características:**
- ✅ Listado de fondos disponibles con metadata IPFS
- ✅ Precio IPO mostrado en tiempo real
- ✅ Cálculo automático del costo total
- ✅ **DvP atómico**: Pago y entrega en 1 transacción
- ✅ Estados de UI: Idle → Approving → Buying → Success

---

### 6. 🔄 Mercado Secundario (P2P Trading)

**Componente:** `SecondaryMarket.jsx`

#### Crear Listing (Vender)

```javascript
// 1. Aprobar activos para que el mercado los transfiera
const assetsContract = new ethers.Contract(FINANCIAL_ASSETS_ADDRESS, FinancialAssetsABI, signer);
await assetsContract.setApprovalForAll(SECONDARY_MARKET_ADDRESS, true);

// 2. Crear listing (activos van a escrow automáticamente)
const marketContract = new ethers.Contract(SECONDARY_MARKET_ADDRESS, SecondaryMarketABI, signer);
await marketContract.createListing(assetId, amount, pricePerShare);
```

**Resultado:** Activos bloqueados en escrow del contrato, vendedor no puede gastarlos.

#### Comprar en Listing (Ejecutar Trade)

```javascript
// 1. Aprobar DEUR
await deurContract.approve(SECONDARY_MARKET_ADDRESS, totalCost);

// 2. Ejecutar trade (DvP atómico: DEUR ↔ Assets)
await marketContract.executeTrade(listingId, amount);
```

**Características:**
- ✅ Visualización de listings activos
- ✅ **Escrow automático** de activos del vendedor
- ✅ **Compras parciales** soportadas
- ✅ Cancelación de listings disponible
- ✅ **DvP atómico**: Cero riesgo de contraparte

---

### 7. 👀 Visualización de Portfolio

**Componente:** `HoldingsCard.jsx`

```javascript
// Obtener balances de múltiples activos eficientemente
const assetsContract = new ethers.Contract(FINANCIAL_ASSETS_ADDRESS, FinancialAssetsABI, provider);

const balances = await assetsContract.balanceOfBatch(
    [account, account, account, ...], // Repetir cuenta N veces
    [0, 1, 2, 3, 4, 5]                // IDs de todos los fondos
);
```

**Características:**
- ✅ Muestra balance de cada fondo (TECH, GOLD, HEALTH, etc.)
- ✅ Cálculo de valor total en DEUR
- ✅ Integración con metadata IPFS (nombres, símbolos)
- ✅ Actualización automática

---

## 🎨 Decisiones de Diseño Frontend


### 1. Extracción Automatizada de ABIs

**Script:** `extract-abis.sh`

```bash
#!/bin/bash
contracts=("DigitalEuro" "FinancialAssets" "PrimaryMarket" "SecondaryMarket")

for contract in "${contracts[@]}"; do
  cat "ebis-euro-capital-defi-foundry/out/$contract.sol/$contract.json" | \
    python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin)['abi'], indent=2))" \
    > "ebis-fund-front/src/contracts/${contract}ABI.json"
done
```

**Ventajas:**
- ✅ Sincronización automática contratos ↔ frontend
- ✅ Evita errores al copiar ABIs manualmente
- ✅ Un solo comando después de compilar contratos

---

### 2. Variables de Entorno

```bash
# ebis-fund-front/.env
VITE_DIGITAL_EURO_ADDRESS=0xCfE13DbeF03A25f6f2c6B436aA380f488367FC1C
VITE_FINANCIAL_ASSETS_ADDRESS=0x2d5fC6b78ED4C0EEd0795C28fdbF9BF4004b7130
VITE_PRIMARY_MARKET_ADDRESS=0x2e329AE807c91f37bc4e49cB94A67328cFE34d35
VITE_SECONDARY_MARKET_ADDRESS=0x30333d882c50c1A28D56572088051f7932c201f2
VITE_CHAIN_ID=11155111
VITE_CHAIN_ID_HEX=0xaa36a7
```

**Ventajas:**
- ✅ Fácil cambiar de red (Sepolia → Mainnet)
- ✅ No hardcodear direcciones en código
- ✅ Configuración centralizada

---

## 🚀 Instalación y Configuración

### Requisitos Previos

- **Node.js** v18 o v20 (LTS)
- **npm** o **pnpm**
- **MetaMask** u otra wallet compatible
- **Sepolia ETH** (para realizar transacciones)

### Pasos de Instalación

#### 1. Clonar el Repositorio

```bash
git clone <your-repo-url>
cd ebis-tokenized-assets-dapp
```

#### 2. Instalar Dependencias del Frontend

```bash
cd ebis-fund-front
npm install
```

#### 3. Configurar Variables de Entorno

```bash
# Copiar el archivo de ejemplo
cp .env.example .env

# Editar .env con tus valores (opcional si usas Sepolia)
# Las direcciones de los contratos ya están configuradas para Sepolia
```

**Contenido de `.env`:**

```bash
# Direcciones de Contratos en Sepolia
VITE_DIGITAL_EURO_ADDRESS=0xCfE13DbeF03A25f6f2c6B436aA380f488367FC1C
VITE_FINANCIAL_ASSETS_ADDRESS=0x2d5fC6b78ED4C0EEd0795C28fdbF9BF4004b7130
VITE_PRIMARY_MARKET_ADDRESS=0x2e329AE807c91f37bc4e49cB94A67328cFE34d35
VITE_SECONDARY_MARKET_ADDRESS=0x30333d882c50c1A28D56572088051f7932c201f2

# Configuración de Red
VITE_CHAIN_ID=11155111
VITE_CHAIN_ID_HEX=0xaa36a7
VITE_NETWORK_NAME=Sepolia Testnet
VITE_RPC_URL=https://rpc.sepolia.org
```

#### 4. Iniciar la Aplicación

```bash
npm run dev
```

La aplicación estará disponible en: **http://localhost:5173**

---

## 📱 Uso de la Aplicación

### 1️⃣ Conectar Wallet

1. Abre la aplicación en http://localhost:5173
2. Haz clic en **"Connect"** en la esquina superior derecha
3. Selecciona tu wallet (MetaMask recomendado)
4. Acepta la conexión
5. Asegúrate de estar en **Sepolia Testnet**

**Nota:** Si no estás en Sepolia, la aplicación te mostrará una advertencia.

---

### 2️⃣ Dashboard

#### Ver Balance DEUR

- Se muestra automáticamente en el header después de conectar
- Se actualiza cada 10 segundos

#### Ver Portfolio de Activos

1. Ve a la sección **"Dashboard"**
2. Verás tus holdings de todos los fondos:
   - Nombre del fondo
   - Cantidad de shares
   - Valor en DEUR
   - Total del portfolio

#### Transferir DEUR

1. En **"Dashboard"** → **"Transfer DEUR"**
2. Ingresa la dirección destino
3. Ingresa la cantidad (en DEUR, no wei)
4. Haz clic en **"Transfer"**
5. Confirma la transacción en MetaMask
6. Espera la confirmación

---

### 3️⃣ Protocol Governance (Solo Owner/Fund Manager)

> **⚠️ Nota:** Estas funciones requieren roles especiales en los contratos.

#### Mintear CBDC (Solo Owner)

1. Ve a **"Protocol Governance"**
2. En **"Mint CBDC"**:
   - Ingresa dirección destino
   - Ingresa cantidad
   - Clic en **"Mint"**
   - Confirma en MetaMask

#### Crear Nuevo Asset Type

1. En **"Create Asset"**:
   - Ingresa Asset ID (número único, ej: 6)
   - Ingresa Nombre (ej: "Infrastructure Fund")
   - Ingresa Símbolo (ej: "INFRA")
   - Clic en **"Create"**
   - Confirma en MetaMask

#### Mintear Asset Shares

1. En **"Mint Asset"**:
   - Selecciona el fondo del dropdown
   - Ingresa cantidad de shares
   - Clic en **"Mint"**
   - Confirma en MetaMask

---

### 4️⃣ Primary Market (IPO)

1. Ve a **"Primary Market"**
2. Explora los fondos disponibles
3. Selecciona un fondo que te interese
4. Ingresa la cantidad de shares a comprar
5. Verás el costo total calculado automáticamente
6. Haz clic en **"Buy Now"**
7. **Confirma 2 transacciones** en MetaMask:
   - **TX 1:** Aprobar DEUR (permite al contrato gastar tus DEUR)
   - **TX 2:** Comprar activos (DvP atómico: pago + entrega)

**Resultado:** Recibirás los activos instantáneamente en tu wallet.

---

### 5️⃣ Secondary Market (P2P Trading)

#### Ver Listings Activos

- Ve a **"Secondary Market"**
- Se muestran todas las ofertas de venta activas
- Puedes ver: Vendedor, Fondo, Cantidad, Precio

#### Comprar en Mercado Secundario

1. Selecciona un listing que te interese
2. Ingresa la cantidad a comprar (puede ser parcial)
3. Verás el costo total
4. Haz clic en **"Buy"**
5. **Confirma 2 transacciones**:
   - **TX 1:** Aprobar DEUR
   - **TX 2:** Ejecutar trade (DvP atómico)

**Resultado:** Recibes los activos del vendedor, él recibe tus DEUR.

#### Vender Activos (Crear Listing)

1. Ve a **"Create Listing"**
2. Selecciona el fondo que quieres vender
3. Ingresa cantidad de shares
4. Ingresa precio por share (en DEUR)
5. Haz clic en **"Create Listing"**
6. **Confirma 2 transacciones**:
   - **TX 1:** Aprobar activos
   - **TX 2:** Crear listing (tus activos van a **escrow**)

**Resultado:** Tus activos están bloqueados en el contrato hasta que se vendan o canceles.

#### Cancelar Listing

1. Ve a **"Your Listings"**
2. Haz clic en **"Cancel"** en tu listing
3. Confirma en MetaMask
4. Tus activos regresan del escrow a tu wallet

---

## 🌐 Demostración en Vivo

### ✅ Contratos Desplegados en Sepolia

| Contrato | Dirección | Etherscan |
|----------|-----------|-----------|
| **Digital Euro** | `0xCfE13DbeF03A25f6f2c6B436aA380f488367FC1C` | [🔍 Ver](https://sepolia.etherscan.io/address/0xCfE13DbeF03A25f6f2c6B436aA380f488367FC1C) |
| **Financial Assets** | `0x2d5fC6b78ED4C0EEd0795C28fdbF9BF4004b7130` | [🔍 Ver](https://sepolia.etherscan.io/address/0x2d5fC6b78ED4C0EEd0795C28fdbF9BF4004b7130) |
| **Primary Market** | `0x2e329AE807c91f37bc4e49cB94A67328cFE34d35` | [🔍 Ver](https://sepolia.etherscan.io/address/0x2e329AE807c91f37bc4e49cB94A67328cFE34d35) |
| **Secondary Market** | `0x30333d882c50c1A28D56572088051f7932c201f2` | [🔍 Ver](https://sepolia.etherscan.io/address/0x30333d882c50c1A28D56572088051f7932c201f2) |

✅ **Todos los contratos están verificados en Etherscan**

### 📊 Fondos Disponibles en el Protocolo

| ID | Nombre | Símbolo | Metadata IPFS |
|----|--------|---------|---------------|
| 0 | Nexus Technology Fund | TECH | ✅ |
| 1 | Goldstone Precious Metals | GOLD | ✅ |
| 2 | Apex Real Estate Capital | REAL | ✅ |
| 3 | Green Future Sustainable Energy | GREEN | ✅ |
| 4 | MediCare Healthcare & Biotech | HEALTH | ✅ |
| 5 | Cyber Sentinel Security Fund | CYBER | ✅ |

**Metadata URI Base:**
```
https://amethyst-accessible-lemming-653.mypinata.cloud/ipfs/
  bafybeigus5qoiqcybdf67q3zv6n72nmm5mqomeibarmzyejug2jvwondbi/{id}.json
```

📄 **Logs completos del deployment:** [SEPOLIA_DEPLOYMENT_DEMO.md](./SEPOLIA_DEPLOYMENT_DEMO.md)


---

## 📊 Resumen del Proyecto

### Estadísticas

| Métrica | Valor |
|---------|-------|
| **Framework Frontend** | React 19.2.0 + Vite 7.2.4 |
| **Librería Web3** | ethers.js 6.16.0 |
| **Gestión de Wallets** | Web3-Onboard 2.24.1 |
| **Smart Contracts** | 4 (migrados de Hardhat a Foundry) |
| **Tests Foundry** | 91 (100% passing) |
| **Networks** | Sepolia Testnet |
| **Metadata Storage** | Pinata IPFS |
| **Fondos Tokenizados** | 6 fondos de inversión |

### Funcionalidades Implementadas

✅ **Conexión Multi-Wallet** - MetaMask, WalletConnect, etc.  
✅ **Balance DEUR en Tiempo Real** - Actualización automática  
✅ **Transferencias P2P de CBDC** - Enviar DEUR a cualquier dirección  
✅ **Gestión de Emisión** - Mintear CBDC y activos (solo roles autorizados)  
✅ **Compra en IPO** - Primary Market con DvP atómico  
✅ **Trading P2P** - Secondary Market con escrow y DvP  
✅ **Visualización de Portfolio** - Ver todos tus activos y valor total  
✅ **Metadata IPFS** - Integración completa con Pinata  
✅ **Diseño Responsive** - Funciona en desktop y mobile  
✅ **UX Premium** - Glassmorphism, animaciones, estados de carga

---

## 🔧 Desarrollo con Foundry

### Compilar Contratos

```bash
cd ebis-euro-capital-defi-foundry
forge build
```

### Ejecutar Tests

```bash
# Todos los tests
forge test

# Con output detallado
forge test -vvv

# Tests específicos
forge test --match-contract DigitalEuroTest
```

### Extraer ABIs para Frontend

```bash
# Desde la raíz del proyecto
./extract-abis.sh
```

### Deploy en Sepolia

```bash
# Importar cuenta
cast wallet import main_sepolia --interactive

# Deploy + verificación
forge script script/FullSystemDemo.s.sol \
  --rpc-url sepolia \
  --account main_sepolia \
  --broadcast \
  --verify
```

---

## 📄 Documentación Adicional

- [SEPOLIA_DEPLOYMENT_DEMO.md](./SEPOLIA_DEPLOYMENT_DEMO.md) - Logs completos del deployment
- [DESIGN_DECISIONS.md](./DESIGN_DECISIONS.md) - Decisiones de diseño detalladas
- [ebis-euro-capital-defi-foundry/metadata/README.md](./ebis-euro-capital-defi-foundry/metadata/README.md) - Guía de metadata IPFS

---

## 📄 Licencia

MIT License - Ver archivo [LICENSE](LICENSE)

---

## 👤 Autor

**Maximiliano Alexis Morero**

📚 EBIS - Máster en Ingeniería y Desarrollo Blockchain  
📝 Caso Práctico - Tema 5: Aplicaciones Descentralizadas (dApps)