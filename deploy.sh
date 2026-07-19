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

echo "=== [4/5] Injecting Public DNS into template ==="
if [ -f docker-compose.yml ]; then
    # 移除之前可能错加的 host 模式，改为强行注入公共 DNS
    sed -i '/network_mode: "host"/d' docker-compose.yml
    sed -i '/image: ghcr.io\/tensorcash/a \    dns:\n      - 8.8.8.8\n      - 1.1.1.1' docker-compose.yml
fi

echo "=== [5/5] Launching official run.sh with DNS fix ==="
./run.sh

echo "=== 🎉 Deployment completed successfully! ==="
