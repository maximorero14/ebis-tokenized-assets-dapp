# EBIS Euro Capital DeFi - Metadata para IPFS

Esta carpeta contiene los metadatos en formato ERC-1155 para los activos financieros del protocolo.

## 📁 Estructura

```
metadata/
├── 0000...0000.json  (ID 0) - Nexus Technology Fund
├── 0000...0001.json  (ID 1) - Goldstone Precious Metals Fund
├── 0000...0002.json  (ID 2) - Apex Real Estate Capital Fund
├── 0000...0003.json  (ID 3) - Green Future Sustainable Energy Fund
├── 0000...0004.json  (ID 4) - MediCare Healthcare & Biotech Fund
├── 0000...0005.json  (ID 5) - Cyber Sentinel Security Fund
├── tech_fund.png
├── gold_fund.png
├── real_estate.png
├── green_energy.png
├── healthcare.png
└── cyber_security.png
```

## 🚀 Cómo subir a Pinata (IPFS)

### Paso 1: Subir las imágenes primero

1. Ve a [Pinata.cloud](https://pinata.cloud) y haz login
2. Haz clic en **"Upload"** → **"Folder"**
3. Selecciona **solo las imágenes PNG** (tech_fund.png, gold_fund.png, etc.)
4. Ponle un nombre a la carpeta: `ebis-fund-images`
5. Una vez subido, **copia el CID** (ejemplo: `QmXXXXXXX...`)

### Paso 2: Actualizar los JSON con el CID de imágenes

Antes de subir los JSON, reemplaza en **todos los archivos .json**:

```json
"image": "ipfs://PLACEHOLDER_CID/tech_fund.png"
```

Por:

```json
"image": "ipfs://TU_CID_DE_IMAGENES/tech_fund.png"
```

**Importante:** Usa el CID que obtuviste en el Paso 1.

### Paso 3: Subir la carpeta metadata completa

1. En Pinata, haz clic en **"Upload"** → **"Folder"**
2. Selecciona la carpeta **metadata** completa (con los JSON ya actualizados)
3. Ponle nombre: `ebis-fund-metadata`
4. Una vez subido, **copia el CID de los metadatos** (ejemplo: `QmYYYYYYY...`)

### Paso 4: Actualizar el contrato

En tu deployment script (`CompleteEcosystem.ts`), actualiza la URI:

```typescript
const financialAssets = m.contract("FinancialAssets", [
    "ipfs://TU_CID_DE_METADATA/{id}.json"
]);
```

## 📊 Fondos Disponibles

| ID | Nombre | Símbolo | Sector | Riesgo | Rentabilidad Esperada |
|----|--------|---------|--------|--------|---------------------|
| 0 | Nexus Technology Fund | TECH | Tecnología | Alto | 12-18% |
| 1 | Goldstone Precious Metals | GOLD | Metales Preciosos | Medio-Bajo | 5-8% |
| 2 | Apex Real Estate Capital | REAL | Inmobiliario | Medio | 7-10% |
| 3 | Green Future Energy | GREEN | Energía Renovable | Medio-Alto | 10-15% |
| 4 | MediCare Healthcare | HEALTH | Salud/Biotech | Medio | 9-14% |
| 5 | Cyber Sentinel Security | CYBER | Ciberseguridad | Alto | 15-20% |

## ✅ Verificación

Después de subir a IPFS, puedes verificar que funciona accediendo a:

```
https://ipfs.io/ipfs/TU_CID_DE_METADATA/0000000000000000000000000000000000000000000000000000000000000000.json
```

O a través de cualquier gateway de IPFS como:
- `https://cloudflare-ipfs.com/ipfs/[CID]/[filename]`
- `https://amethyst-accessible-lemming-653.mypinata.cloud/ipfs/[CID]/[filename]`

## 🔐 Características de los metadatos

Cada archivo JSON incluye:

- ✅ **Nombre del fondo** claro y profesional
- ✅ **Descripción detallada** en español
- ✅ **Imagen** profesional generada por IA
- ✅ **Atributos financieros realistas**:
  - Sector de inversión
  - Nivel de riesgo
  - Rentabilidad anual esperada
  - Horizonte de inversión recomendado
  - Inversión mínima en DEUR
  - Liquidez (frecuencia de reembolso)
  - Diversificación de activos
  - Región geográfica
  - Rating ESG (sostenibilidad)

## 💡 Consejos

1. **No pierdas los CIDs**: Guárdalos en un documento seguro
2. **Verifica antes de desplegar**: Prueba que los enlaces IPFS funcionen
3. **Gateway de respaldo**: Pinata provee su propio gateway rápido
4. **Inmutabilidad**: Si cambias algo en un JSON, cambiarás el CID completo

## 🎨 Imágenes generadas

Todas las imágenes fueron generadas profesionalmente con IA y optimizadas para NFT metadata. Tienen:
- ✅ Formato cuadrado (1:1)
- ✅ Alta calidad
- ✅ Diseño profesional y moderno
- ✅ Colores coherentes con cada sector
