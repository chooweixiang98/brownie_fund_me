// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

/*
 * While npm understands @chainlink/contracts/.. is a package that can be imported, brownie does not.
 * Brownie, can however, download materials from github. Thus, we need to specify the repository for download.
 * We need to specify the dependencies for brownier to import and download the files in the config file
 **/

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
// import  "openzeppelin/contracts/utils/math/SafeMath.sol"
// SafeMathChainLink is basically the same as openzeppelin SafeMath
// SafeMath is useful for versions below 0.8
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

/*
 * Library: a library is similar to contracts, but their purpose is that they
 * are deployed only once at a specifed address and their code is reused.
 *
 * 'using' keyword: the directive 'using A for B' can be used to attach library
 * functions (from libary A) to any type (B) in the context of a contract
 **/

contract FundMe {
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    AggregatorV3Interface public priceFeed;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // the address that deploys the contract is the owner of the contract.
    // only owner can withdraw the funds from the contract
    // AggregatorV3Interface contract address must be specified to deploy the contract
    // contract address for AggregatorV3Interface deployed on Rinkeby testnet for ETH /USD can be obtained from https://docs.chain.link/docs/ethereum-addresses/
    // the address is actually deployed in the testnet. Hence the contract needs to be deployed on test net as well
    // the interface implementation of AggregatorV3Interface can be found on https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    // payablel keyword indicates that ETH is transacted through the function
    // fund() allows funds to be paid to the contract owner
    // msg.sender refers otthe address that called the fund() function
    // msg.value refers to the amount of eth specified for funding
    function fund() public payable {
        uint256 minimumUSD = 50 * (10**18); // in denominations of Wei
        // line below specifies the requirement for the function to be called
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    // takes in amount in wei, and returns the current USD value of the ethAmount in denominations of wei.
    // To get the return value in decimal place price (price of 1 wei) => ethAmountInUSD / 10*18
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        // ethPrice and ethAmount are both in denominations of wei, hence, we must / 1000000000000000000 to get back ethAmountInUSD in correct denominations of Wei
        uint256 ethAmountInUSD = (ethAmount * ethPrice) / (10**18);
        return ethAmountInUSD;
    }

    // returns the mimimum amount of Eth to fund in denominations of wei
    function getEntranceFee() public view returns (uint256) {
        uint256 minimumUSD = 50 * (10**18);
        uint256 price = getPrice();
        uint256 precision = 1 * (10**18);
        return (minimumUSD * precision) / price;
    }

    // calls the version() function of the AggregatorV3Interface contract that has been deployed on the rinkeby testnet
    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    // 1eth = 1000000000 Gwei = 1000000000000000000 Wei
    // e.g., 2000.12345678 USD can buy 1eth = 1000000000 Gwei = 1000000000000000000 Wei
    // Note_that there are no decimals in solidity, so 2000.12345678 USD = 1000000000 Gwei
    // is represented by 200012345678 = 1000000000 Gwei
    // and 200012345678 * 1000000000 = 1000000000000000000 Wei
    // To get the price of an ETH with decimal place: 200012345678 * 1000000000 / 1000000000000000000 = 2000.12345678 USD

    // returns the current price of an eth in denominations of wei
    function getPrice() public view returns (uint256) {
        // (A,B,C) is the syntax for a tuple => tuple is a list of objects of potentially different types whoe number is a constant at compile-time
        // a tuple (structure) is first defined then values are assigned to the tuple using latestRoundData() function
        // in this case, priceFeed.latestRoundData() returns data in exactly the same format as the defined tuple
        // To clean up the code, we simply remove the unused variables from the tuple.
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        // 'answer' is returned in denominations of Gwei. Hence, we need to multiply the answer by (10 ** 10) to get answer in denominations of wei
        return uint256(answer * (10**10)); // type casting is needed as answer is of type int256
    }

    function withdraw() public payable onlyOwner {
        // transfer: sends eth from one address to the caller
        // this: refers to the contract that you're currently in
        // balance: refers to the balance of the contract.
        msg.sender.transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);
    }
}
