from brownie import FundMe, MockV3Aggregator, network, config
from scripts.helpful_scripts import (
    get_account,
    deploy_mocks,
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
)


# By default, calling 'run scripts/deploy.py' on the terminal invokes the development network
# To call the contract on the one of the test network add the flag '--network <network_name>'
def deploy_fund_me():
    account = get_account()

    # price_feed_address depends on the network
    # If deployed on testing (persistent) network, fetch address from config file
    # If deployed on local network, deploy a mock contract and utilize the mock contract
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        price_feed_address = config["networks"][network.show_active()][
            "eth_usd_price_feed"
        ]
    else:
        # Local blockchain network
        deploy_mocks()
        price_feed_address = MockV3Aggregator[-1].address

    # actual deployment of the FundMe contract
    # To verify contract automatically, we need to specify publish_source
    # and include ETHERSCAN_TOKEN in the .env file. The token is obtained from etherscan.io, under API Keys
    # Go to etherscan.io to check the status of the contract once it's deployed and verified
    fund_me = FundMe.deploy(
        price_feed_address,
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify"),
    )

    print("Contract deployed to {}".format(fund_me.address))
    return fund_me


def main():
    deploy_fund_me()
