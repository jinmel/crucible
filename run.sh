#!/bin/bash

set -ex

cd contracts

echo "Deploying contracts"

forge create -r $RPC1 UniswapInterop --constructor-args 0x95222290DD7278Aa3Ddd389Cc1E1d165CC4BAfe5 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

forge create -r $RPC2 UniswapInterop --constructor-args 0x95222290DD7278Aa3Ddd389Cc1E1d165CC4BAfe5 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

forge create -r $RPC3 UniswapInterop --constructor-args 0x95222290DD7278Aa3Ddd389Cc1E1d165CC4BAfe5 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

forge create -r $RPC4 UniswapInterop --constructor-args 0x95222290DD7278Aa3Ddd389Cc1E1d165CC4BAfe5 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

echo "Deployed contracts"

cd ..

echo "Starting op-builder"

$HOME/code/optimism/op-builder/bin/op-builder --rpc.addr 0.0.0.0 --rpc.port 8545 \
  --l2-eth-rpc 21=$RPC1 \
  --l2-eth-rpc 22=$RPC2 \
  --l2-eth-rpc 23=$RPC3 \
  --l2-eth-rpc 24=$RPC4
