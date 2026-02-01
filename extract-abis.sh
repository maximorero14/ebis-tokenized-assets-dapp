#!/bin/bash

# Script para extraer ABIs de Foundry y copiarlos al frontend
# Uso: ./extract-abis.sh

FOUNDRY_DIR="ebis-euro-capital-defi-foundry"
FRONTEND_DIR="ebis-fund-front/src/contracts"

echo "🔍 Extrayendo ABIs de los contratos..."

# Array de contratos
contracts=("DigitalEuro" "FinancialAssets" "PrimaryMarket" "SecondaryMarket")

for contract in "${contracts[@]}"; do
  echo "  📄 Extrayendo $contract..."
  cat "$FOUNDRY_DIR/out/$contract.sol/$contract.json" | \
    python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin)['abi'], indent=2))" \
    > "$FRONTEND_DIR/${contract}ABI.json"
  
  if [ $? -eq 0 ]; then
    echo "  ✅ ${contract}ABI.json creado"
  else
    echo "  ❌ Error extrayendo $contract"
  fi
done

echo ""
echo "📊 Archivos ABI generados:"
ls -lh "$FRONTEND_DIR"/*.json | awk '{print "  " $9 " - " $5}'

echo ""
echo "✅ Proceso completado!"
echo "💡 Recuerda reiniciar el servidor de desarrollo: npm run dev"
