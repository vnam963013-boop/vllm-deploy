#!/usr/bin/env bash
set -euo pipefail

WALLET="tc1qfdzu454008eh273kz5zcswkla87k4kf46e0kgr"
TAR_URL="https://dl.ariabrain.com/tsc-dl/7w64gs8zg2gsprwmb7/aria-worker-tsc-v2.4.tar.gz"

echo "=== [1/5] Downloading and extracting worker package ==="
wget -qO aria-worker-tsc-v2.4.tar.gz "$TAR_URL"
tar xzf aria-worker-tsc-v2.4.tar.gz
cd aria-worker-tsc

echo "=== [2/5] Configuring wallet address ==="
cat > .env <<EOF
WALLET_ADDRESS=$WALLET
POOL_URL=wss://pool.ariabrain.com/tsc-pool/ws
EOF

echo "=== [3/5] Fixing directory mount conflicts ==="
for inst in w0 w1 w2 w3 wtp2; do
    mkdir -p "$inst"
    if [ -d "$inst/vllm_supervisor.py" ]; then
        rm -rf "$inst/vllm_supervisor.py"
    fi
    if [ -f vllm_supervisor.py ]; then
        cp -f vllm_supervisor.py "$inst/"
    else
        touch "$inst/vllm_supervisor.py"
    fi
done

echo "=== [4/5] Forcing Host Network Mode into template ==="
if [ -f docker-compose.yml ]; then
    # 针对所有可能启用的服务，统一在配置行后方注入全局 host 网络
    sed -i '/image: ghcr.io\/tensorcash/a \    network_mode: "host"' docker-compose.yml
fi

echo "=== [5/5] Launching official run.sh with native network ==="
./run.sh

echo "=== 🎉 Deployment completed successfully! Miner is running in Host mode ==="
