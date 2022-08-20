// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Bipsea {
    // Owner address can delist inappropriate items. Will delegate to DAO
    address public owner;

    // Item to sell
    struct Item {
        address seller;     // Address of content creator. Gets 99% of sale
        address investor;   // Address of user paying for tx fees. Gets 1% of sale
        string  uri;        // Metadata uri: https://ipfs.io/ipfs/bafkreigjdoplg6qattgtkx7zrfreky3xjk52dpxeqxf7bqx7funa2z6vpu
        uint256 price;      // Price of item in smallest unit (wei)
    }

    // Stores all items: itemId => Item
    mapping(uint256 => Item) public items;

    // Check if itemId has been purchaed by buyer: itemId => buyer address => true
    mapping(uint256 => mapping(address => bool)) public purchase;

    // Balance of sellers: 0xAlice => 99 wei
    mapping(address => uint256) public balances;

    // Events
    event Sell(uint256 _itemId);
    event Buy(uint256 indexed _itemId, address indexed _buyer, uint256 _amount);
    event Withdraw(address indexed _sellerAddress, uint256 _sellerAmount, address _withdrawerAddress, uint256 _withdrawerAmount);
    event Delist(uint64 indexed _itemId, address indexed _seller);

    // Constructor
    constructor() {
        owner == msg.sender;
    }

    // Sell item
    function sell(
        uint256 _itemId,
        address _seller,
        address _investor,
        string memory _uri,
        uint256 _price
    ) public {
        require(items[_itemId].seller == address(0), "Item Already Listed");
        require(items[_itemId].investor == address(0), "Item Already Listed");
        // create item to sell
        items[_itemId] = Item({
            seller: _seller,
            investor: _investor,
            uri: _uri,
            price: _price
        });
        // emit Sell event
        emit Sell(_itemId);
    }

    // Buy item
    function buy(uint64 _itemId) public payable {
        require(msg.value >= items[_itemId].price, "Insufficient Funds");
        require(purchase[_itemId][msg.sender] == false, "Already Purchased");
        // Set purchase to true
        purchase[_itemId][msg.sender] = true;
        // Seller gets 99% of sale
        uint256 sellerValue = (msg.value * 99) / 100;
        // Investory gets 1% of sale
        uint256 investorValue = (msg.value * 1) / 100;
        // Deposit into seller's account
        balances[items[_itemId].seller] += sellerValue;
        // Depost into investor's account
        balances[items[_itemId].investor] += investorValue;
        // emit Buy event
        emit Buy(_itemId, msg.sender, msg.value);
    }

    // Withdraw funds
    function withdraw(address _sellerAddress) public payable {
        require(balances[_sellerAddress] / 10000 * 10000 == balances[_sellerAddress], "Balance too small");
        // get withdrawer address
        address withdrawerAddress = msg.sender;
        // withdrawer gets 0.01% or 1 basis point
        uint256 withdrawerAmount = balances[_sellerAddress] / 10000;
        // seller gets 99.99%
        uint256 sellerAmount = balances[_sellerAddress] - (balances[_sellerAddress] / 10000);
        // set balance to 0
        balances[_sellerAddress] = 0;
        // transfer seller amount
        payable(_sellerAddress).transfer(sellerAmount);
        // transfer withdrawer amount
        payable(withdrawerAddress).transfer(withdrawerAmount);
        // emit Withdraw event
        emit Withdraw(_sellerAddress, sellerAmount, withdrawerAddress, withdrawerAmount);
    }

    // Delist Item
    function delist(uint64 _itemId) public {
        require(msg.sender == items[_itemId].seller || msg.sender == owner, "Only seller || owner can delist");
        delete items[_itemId];
        emit Delist(_itemId, msg.sender);
    }

    // Set Owner
    function setOwner(address _newOwner) public {
        require(msg.sender == owner, "Only owner set");
        owner = _newOwner;
    }

}
