#!/usr/bin/bash

if [[ $(uname) != Linux ]]; then
    echo "script must be run on Linux"
    exit 1
fi

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
  echo "downloading k6"
  curl -LsO "https://github.com/grafana/k6/releases/download/v0.44.1/k6-v0.44.1-linux-amd64.tar.gz"
  tar -zxf k6-v0.44.1-linux-amd64.tar.gz
  mv k6-v0.44.1-linux-amd64/k6 ./k6
  rm -rf ./k6-v0.44.1-linux-amd64
  rm ./k6-v0.44.1-linux-amd64.tar.gz
  echo "finished downloading k6"
fi

# Get node
if [ ! -f "./node" ]; then
  echo "downloading node"
  curl -LsO "https://nodejs.org/dist/v18.16.0/node-v18.16.0-linux-x64.tar.xz"
  tar -xf node-v18.16.0-linux-x64.tar.xz
  ln -s "$(pwd)/node-v18.16.0-linux-x64/bin/node" ./node
  rm ./node-v18.16.0-linux-x64.tar.xz
  echo "finished downloading node"
fi

# Get envoy
if [ ! -f "./envoy" ] && [ -z "${USE_NGINX}" ]; then
  echo "downloading envoy"
  curl -LsO "https://github.com/envoyproxy/envoy/releases/download/v1.26.1/envoy-1.26.1-linux-x86_64"
  mv envoy-1.26.1-linux-x86_64 envoy
  chmod +x envoy
  echo "finished downloading envoy"
fi

# Run envoy
echo "running envoy"
./envoy --config-path ./envoy.yaml --log-level debug 1>./envoy.log 2>&1 &

# Run our test upstream
echo "running node upstream server"
./node node-server.js 1>./node.log 2>&1 &

# Run our k6 test
echo "running k6 test"
./k6 run ./k6-proxy-node.js

# Get envoy data and stop
echo "getting envoy data and stopping envoy"
curl http://localhost:19000/stats -so ./envoy_metrics
curl http://localhost:19000/clusters -so ./envoy_clusters
curl http://localhost:19000/server_info -so ./envoy_server_info
curl -sX POST http://localhost:19000/quitquitquit

# Stop our node server
echo "closing node server"
curl -s http://localhost:4000/quitquitquit

if [[ ${CLEANUP} == DEPS ]] || [[ ${CLEANUP} == ALL ]]; then
    rm envoy k6 node
    rm -rf ./node-v18.16.0-linux-x64
fi
if [[ ${CLEANUP} == LOGS ]] || [[ ${CLEANUP} == ALL ]]; then
    rm envoy.log envoy_clusters envoy_metrics envoy_server_info node.log
fi
