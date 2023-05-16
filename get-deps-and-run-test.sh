#!/usr/bin/bash

SCRIPT_CALL_PATH="$(ps $$ | tail -1 | awk '{print $6}')"
if [[ $SCRIPT_CALL_PATH =~ [^.]/get-deps-and-run-test.sh ]]; then
  echo "script must be run from within testing directory"
  exit 1
fi

if [[ -z $(which curl) ]]; then
  echo "script requires curl command to download dependencies"
  exit 1
fi

# Get k6
if [ ! -f "./k6" ]; then
  curl -LO "https://github.com/grafana/k6/releases/download/v0.44.1/k6-v0.44.1-linux-amd64.tar.gz"
  tar -zxf k6-v0.44.1-linux-amd64.tar.gz
  mv k6-v0.44.1-linux-amd64/k6 ./k6
  rm -rf ./k6-v0.44.1-linux-amd64
  rm ./k6-v0.44.1-linux-amd64.tar.gz
fi

# Get node
if [ ! -f "./node" ]; then
  curl -LO "https://nodejs.org/dist/v18.16.0/node-v18.16.0-linux-x64.tar.xz"
  tar -xf node-v18.16.0-linux-x64.tar.xz
  ln -s "$(pwd)/node-v18.16.0-linux-x64/bin/node" ./node
  rm ./node-v18.16.0-linux-x64.tar.xz
fi

# Get envoy
if [ ! -f "./envoy" ] && [ -z "${USE_NGINX}" ]; then
  curl -LO "https://github.com/envoyproxy/envoy/releases/download/v1.26.1/envoy-1.26.1-linux-x86_64"
  mv envoy-1.26.1-linux-x86_64 envoy
  chmod +x envoy
fi

# Get nginx
if [ ! -d "./nginx" ] && [ -n "${USE_NGINX}" ]; then
  curl -LO "https://nginx.org/download/nginx-1.24.0.tar.gz"
  tar -zxf nginx-1.24.0.tar.gz
  cd nginx-1.24.0 || exit 1
  mkdir -p "$(pwd)/out/logs"
  ./configure --prefix="$(pwd)/out"
  make
  # sudo make install
  cp ../nginx.conf ./out/
  cd ..
  rm nginx-1.24.0.tar.gz
fi

if [ -z "${USE_NGINX}" ]; then
  # Run envoy
  ./envoy --config-path ./envoy.yaml --log-level debug 1>./envoy.log 2>&1 &
  PROXY_PID=$!
else
  # Run nginx
  ./nginx-1.24.0/objs/nginx -c nginx.conf &
fi

# Run our test upstream
./node node-server.js &
NODE_SERVER_PID=$!

# Run our k6 test
./k6 run ./k6-proxy-node.js

if [ -z "${USE_NGINX}" ]; then
  curl http://localhost:19000/stats -o ./envoy_metrics
  curl http://localhost:19000/clusters -o ./envoy_clusters
  curl http://localhost:19000/routes -o ./envoy_routes
  curl http://localhost:19000/server_info -o ./envoy_server_info
  kill -s INT $PROXY_PID
else
  nginx-1.24.0/objs/nginx -s stop
fi

kill -9 $NODE_SERVER_PID

