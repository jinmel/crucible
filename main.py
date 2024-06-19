from eth_utils import to_checksum_address, to_bytes
import json
from web3 import Web3

import os


from absl import app
from absl import flags
from absl import logging

import requests


flags.DEFINE_string('addr', 'http://localhost:8545', 'Service to op-builder')
flags.DEFINE_string('target', '0x5FbDB2315678afecb367f032d93F642f64180aa3', 'contract address')
flags.DEFINE_string('abi', '', 'ABI of the contract')
flags.DEFINE_string('priv', '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80', 'Private key')


FLAGS = flags.FLAGS

RPC1 = os.getenv('RPC1', 'http://localhost:8545')
RPC2 = os.getenv('RPC2', 'http://localhost:8545')
RPC3 = os.getenv('RPC3', 'http://localhost:8545')
RPC4 = os.getenv('RPC4', 'http://localhost:8545')


def get_msg_json(chainId, data, target, value):
    # Convert inputs to appropriate formats
    chainId_str = str(chainId)
    data_bytes = to_bytes(hexstr=data)
    target_address = to_checksum_address(target)
    value_str = str(value)

    # Create the message dictionary
    message = {
        "chainId": chainId_str,
        "data": data_bytes.hex(),
        "target": target_address,
        "value": value_str,
    }

    message_json = json.dumps(message)
    return message_json


def load_abi(abi_path):
    with open(abi_path, 'r') as abi_file:
        return json.load(abi_file)


def send_graph_bundle(msgs):
    params = {
        "crossBundle": {
            "messages": msgs
        }
    }
    rpc_json = {
        "jsonrpc": "2.0",
        "method": "eth_sendGraphBundle",
        "params": [params],
        "id": 1
    }
    response = requests.post(FLAGS.addr, json=rpc_json)
    return response


def main(_):
    web3_src = Web3(Web3.HTTPProvider(RPC1))
    web3_dst = Web3(Web3.HTTPProvider(RPC2))

    abi = load_abi(FLAGS.abi)
    contract_address = to_checksum_address(FLAGS.target)
    contract = web3_src.eth.contract(address=contract_address, abi=abi['abi'])
    account = web3_src.eth.account.from_key(FLAGS.priv)

    transaction = contract.functions.test().build_transaction({
        'chainId': web3_src.eth.chain_id,
        'gas': 2000000,
        'gasPrice': web3_src.eth.gas_price,
        'nonce': web3_src.eth.get_transaction_count(account.address),
    })

    calldata = transaction['data']
    logging.info('Calldata: %s', calldata)

    msg1 = get_msg_json(web3_src.eth.chain_id, calldata, FLAGS.target, 0)

    abi = load_abi(FLAGS.abi)
    contract_address = to_checksum_address(FLAGS.target)
    contract = web3_dst.eth.contract(address=contract_address, abi=abi['abi'])
    account = web3_dst.eth.account.from_key(FLAGS.priv)


    transaction = contract.functions.test().build_transaction({
        'chainId': web3_dst.eth.chain_id,
        'gas': 2000000,
        'gasPrice': web3_dst.eth.gas_price,
        'nonce': web3_dst.eth.get_transaction_count(account.address),
    })

    calldata = transaction['data']
    logging.info('Calldata: %s', calldata)

    msg2 = get_msg_json(web3_dst.eth.chain_id, calldata, FLAGS.target, 0)

    logging.info("msg1 %s", msg1)
    logging.info("msg2 %s", msg2)

    response = send_graph_bundle([msg1, msg2])

    # Print the response
    logging.info("Response: %s", response.text)


if __name__ == '__main__':
    app.run(main)
