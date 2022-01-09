from brownie import network, config, accounts, MockV3Aggregator
from web3 import Web3

FORKED_LOCAL_ENVIRONMENTS = ["mainnet-fork", "mainnet-forked-dev"]
LOCAL_BLOCKCHAIN_ENVIRONMENTS = ["development", "ganache-local"]

DECIMALS = 8
# This is 2,000
STARTING_PRICE = 2000 * (10 ** 8)


# The accounts version should differ based on the network.
# Use brownie generated accounts for local environments
# Use metamask account for testing networks
def get_account():
    if (
        network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS
        or network.show_active() in FORKED_LOCAL_ENVIRONMENTS
    ):
        return accounts[0]
    else:
        return accounts.add(config["wallets"]["from_key"])


# deploys MockV3Aggregator.sol if none have been deployed onto the network
# The actual contracts (i.e., AggregatorV3Interface) exists on testing networks but not on
# development networks. Hence we need to deploy MockV3Aggregator to test the aggregator functions
# We need to add the contract under /contracts/test/MockV3Aggregator.sol
def deploy_mocks():
    # Don't need to deploy Mock if it already exists on the network
    if len(MockV3Aggregator) <= 0:
        print("The active network is {}".format(network.show_active()))
        print("Deploying Mocks...")
        MockV3Aggregator.deploy(DECIMALS, STARTING_PRICE, {"from": get_account()})
        print("Mocks Deployed")
    else:
        print(
            "There's an existing MockV3Aggregator deployed at {}".format(
                MockV3Aggregator[-1].address
            )
        )
