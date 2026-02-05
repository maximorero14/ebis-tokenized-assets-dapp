# 🚀 Guía de Despliegue en Vercel

Sigue estos pasos para poner tu dApp en internet usando Vercel.

## 1. Preparación del Código

Actualmente tienes cambios sin guardar. Primero debemos asegurarnos de que todos tus cambios estén en Git.

 Abre una terminal en la carpeta raíz del proyecto y ejecuta:

```bash
# Guardar todos los cambios
git add .
git commit -m "Preparando para deploy en Vercel"

# Si aún no tienes un repositorio remoto conectado en GitHub:
# 1. Crea un repo en GitHub (https://github.com/new)
# 2. Conéctalo (reemplaza URL_DE_TU_REPO):
# git remote add origin URL_DE_TU_REPO
# git branch -M main
# git push -u origin main
```

## 2. Configuración en Vercel

1. Ve a [vercel.com](https://vercel.com) e inicia sesión (puedes usar tu cuenta de GitHub).
2. Haz clic en **"Add New..."** -> **"Project"**.
3. Selecciona tu repositorio de GitHub `ebis-tokenized-assets-dapp` (o como lo hayas llamado).
4. Haz clic en **"Import"**.

## 3. Configuración del Proyecto (¡Muy Importante!)

En la pantalla de configuración de Vercel, debes ajustar lo siguiente antes de dar clic en "Deploy":

### 📂 Root Directory (Directorio Raíz)
Como tu frontend no está en la raíz, sino en una carpeta, debes indicarlo:
1. Busca la sección **"Root Directory"**.
2. Haz clic en **"Edit"**.
3. Selecciona la carpeta **`ebis-fund-front`**.

### ⚙️ Framework Preset
Vercel debería detectar automáticamente que es **Vite**. Si no, selecciónalo manualmente:
- **Framework Preset:** Vite
- **Build Command:** `npm run build` (o `vite build`)
- **Output Directory:** `dist`

### 🔑 Environment Variables (Variables de Entorno)
Esto es CRÍTICO para que la dApp funcione. Debes copiar las variables de tu archivo `.env`.

1. Despliega la sección **"Environment Variables"**.
2. Copia y pega cada una de las variables que tienes en `ebis-fund-front/.env`:

| Key (Nombre) | Value (Valor) |
|--------------|---------------|
| `VITE_DIGITAL_EURO_ADDRESS` | `0xCfE13DbeF03A25f6f2c6B436aA380f488367FC1C` |
| `VITE_FINANCIAL_ASSETS_ADDRESS` | `0x2d5fC6b78ED4C0EEd0795C28fdbF9BF4004b7130` |
| `VITE_PRIMARY_MARKET_ADDRESS` | `0x2e329AE807c91f37bc4e49cB94A67328cFE34d35` |
| `VITE_SECONDARY_MARKET_ADDRESS` | `0x30333d882c50c1A28D56572088051f7932c201f2` |
| `VITE_CHAIN_ID` | `11155111` |
| `VITE_CHAIN_ID_HEX` | `0xaa36a7` |
| `VITE_NETWORK_NAME` | `Sepolia Testnet` |
| `VITE_RPC_URL` | `https://rpc.sepolia.org` |

> **Tip:** Puedes copiar todo el contenido de tu archivo `.env` y pegarlo directamente en el primer campo de Vercel; a veces detecta el formato automáticamente.

## 4. Despliegue

1. Haz clic en **"Deploy"**.
2. Espera a que termine el proceso de build.
3. ¡Listo! Vercel te dará una URL (ej: `ebis-fund-front.vercel.app`) donde tu dApp está viva.

## 5. Verificación

1. Abre la URL que te dio Vercel.
2. Abre la consola del navegador (F12) para verificar que no haya errores de conexión.
3. Conecta tu Wallet y prueba ver tu balance.

---

### ⚠️ Solución de Problemas Comunes

- **Error 404 / Pantalla en blanco:** Generalmente pasa si no configuraste bien el **Root Directory** (`ebis-fund-front`).
- **La dApp no conecta / Balance en 0:** Probablemente faltan o están mal las **Variables de Entorno**. Verifica en Settings -> Environment Variables en Vercel.
