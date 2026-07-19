#!/usr/bin/env bash
set -euo pipefail

WALLET="tc1qfdzu454008eh273kz5zcswkla87k4kf46e0kgr"
TAR_URL="https://dl.ariabrain.com/tsc-dl/7w64gs8zg2gsprwmb7/aria-worker-tsc-v2.4.tar.gz"
TAR_SHA256="a052f20a7b41374c9c72e55ba831d2eec316ffb8f2220c3dca012624d47fce9b"

echo "=== [1/6] Downloading and extracting worker package ==="
wget -qO aria-worker-tsc-v2.4.tar.gz "$TAR_URL"
echo "${TAR_SHA256}  aria-worker-tsc-v2.4.tar.gz" | sha256sum -c -   # 校验失败会直接退出
tar xzf aria-worker-tsc-v2.4.tar.gz
cd aria-worker-tsc

echo "=== [2/6] Configuring wallet address ==="
cat > .env <<EOF
WALLET_ADDRESS=$WALLET
POOL_URL=wss://pool.ariabrain.com/tsc-pool/ws
EOF

echo "=== [3/6] Fixing iptables-legacy FORWARD DROP (container egress) ==="
# 部分 VM 镜像残留 legacy 表且 FORWARD policy 为 DROP,只放行了 docker0,
# compose 自建的 br-* 网桥流量会被丢包,导致容器无法出网(拉不了 HF 模型、连不上矿池)
if command -v iptables-legacy >/dev/null 2>&1; then
  if iptables-legacy -L FORWARD -n 2>/dev/null | grep -q "policy DROP"; then
    iptables-legacy -C FORWARD -i br-+ -j ACCEPT 2>/dev/null || \
      iptables-legacy -I FORWARD 1 -i br-+ -j ACCEPT
    iptables-legacy -C FORWARD -o br-+ -j ACCEPT 2>/dev/null || \
      iptables-legacy -I FORWARD 2 -o br-+ -j ACCEPT
    echo "    legacy FORWARD: br-+ ACCEPT rules ensured"
    # 持久化(可选:如果装了 iptables-persistent)
    if [ -d /etc/iptables ]; then
      iptables-legacy-save > /etc/iptables/rules.v4
      echo "    rules persisted to /etc/iptables/rules.v4"
    fi
  else
    echo "    legacy FORWARD policy is not DROP, skip"
  fi
fi

echo "=== [4/6] Fixing directory mount conflicts ==="
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

echo "=== [5/6] Pulling Docker images and initializing environment ==="
./run.sh

echo "=== [6/6] Performing secondary check to ensure successful launch ==="
for inst in w0 w1 w2 w3 wtp2; do
  if [ -d "$inst/vllm_supervisor.py" ]; then
    rm -rf "$inst/vllm_supervisor.py"
    [ -f vllm_supervisor.py ] && cp -f vllm_supervisor.py "$inst/"
  fi
done
./run.sh

echo "=== 🎉 Deployment completed successfully! Miner is running in the background ==="
