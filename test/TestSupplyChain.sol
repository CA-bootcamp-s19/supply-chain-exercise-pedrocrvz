pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";
import "./SupplyChainAccountProxy.sol";

contract TestSupplyChain {

    // Test for failing conditions in this contracts:
    // https://truffleframework.com/tutorials/testing-for-throws-in-solidity-tests

    uint256 public initialBalance = 500 wei;

    SupplyChain supplyChain;

    SupplyChainAccountProxy ownerAccount;
    SupplyChainAccountProxy sellerAccount;
    SupplyChainAccountProxy buyerAccount;
    SupplyChainAccountProxy otherAccount;

    function beforeEach() public {
        ownerAccount = new SupplyChainAccountProxy();
        sellerAccount = new SupplyChainAccountProxy();
        buyerAccount = new SupplyChainAccountProxy();
        otherAccount = new SupplyChainAccountProxy();

        supplyChain = SupplyChain(ownerAccount.deploySupplyChainContract());

        ownerAccount.setCallee(address(supplyChain));
        sellerAccount.setCallee(address(supplyChain));
        buyerAccount.setCallee(address(supplyChain));
        otherAccount.setCallee(address(supplyChain));

        Assert.equal(supplyChain.owner(), address(ownerAccount), "Contract owner address must equal to ownerAccount address");
    }

        // buyItem
    function testAddItem() public {
        //test add item
        SupplyChain(address(sellerAccount)).addItem('car', 50 wei);
        (string memory name, , uint256 price, SupplyChain.State state, address seller,address buyer) = supplyChain.items(0);
        Assert.equal(name, 'car', "Item name should be 'car' ");
        Assert.equal(price, 50 wei, "Item price should be 50 wei");
        Assert.equal(int(state), 0, "Item state should be ForSale");
        Assert.equal(seller, address(sellerAccount), "Item seller should be sellerAccount");
        Assert.equal(buyer, address(0), "Item buyer should be address(0)");
     }

    // buyItem
    function testBuyItem() public {
        //add item
        SupplyChain(address(sellerAccount)).addItem('car', 50 wei);

        //test buy item
        SupplyChain(address(buyerAccount)).buyItem.value(70 wei)(0);
        (,,,SupplyChain.State state,,address buyer) = supplyChain.items(0);
        Assert.equal(int(state), 1, "Item state should be Sold");
        Assert.equal(buyer, address(buyerAccount), "Item buyer should be buyerAccount");
        Assert.equal(address(buyerAccount).balance, 20 wei, "Buyer's balance should be refunded");
     }
        // test for failure if user does not send enough funds
    function testForFailureIfNotEnoughFunds() public {
        SupplyChain(address(sellerAccount)).addItem('car', 50 wei);
        (bool status, ) = address(buyerAccount).call.value(10 wei)(abi.encodeWithSignature("buyItem(uint256)", 0));
        Assert.isFalse(status, "Should fail if not enough funds");
    }
    // test for purchasing an item that is not for Sale
    function testForFailureIfNotForSale() public {
        (bool status, ) = address(buyerAccount).call.value(10 wei)(abi.encodeWithSignature("buyItem(uint256)", 0));
        Assert.isFalse(status, "Should fail if not for sale");
    }

    // shipItem
    function testShipItem() public {
        SupplyChain(address(sellerAccount)).addItem('car', 20 wei);
        SupplyChain(address(buyerAccount)).buyItem.value(20 wei)(0);
        SupplyChain(address(sellerAccount)).shipItem(0);

        (,,,SupplyChain.State state,,) = supplyChain.items(0);
        Assert.equal(int(state), 2, "Item state should be Shipped");
    }

    // test for calls that are made by not the seller 
    function testForFailureIfShipNotFromSeller() public {
        SupplyChain(address(sellerAccount)).addItem('car', 10 wei);
        SupplyChain(address(buyerAccount)).buyItem.value(10 wei)(0);

        (bool status, ) = address(otherAccount).call(abi.encodeWithSignature("shipItem(uint256)", 0));
        Assert.isFalse(status, "Only seller can change item state to Shipped");
    } 
    // test for trying to ship an item that is not marked Sold
    function testForFailureIfNotMarkedSold() public {
        SupplyChain(address(sellerAccount)).addItem('car', 10 wei);

        (bool status, ) = address(sellerAccount).call(abi.encodeWithSignature("shipItem(uint256)", 0));
        Assert.isFalse(status, "Only item marked as Sold can be changed to Shipped");
    }

    // receiveItem
    function testReceiveItem() public {
        SupplyChain(address(sellerAccount)).addItem('car', 10 wei);
        SupplyChain(address(buyerAccount)).buyItem.value(10 wei)(0);
        SupplyChain(address(sellerAccount)).shipItem(0);
        SupplyChain(address(buyerAccount)).receiveItem(0);

        (,,,SupplyChain.State state,,) = supplyChain.items(0);
        Assert.equal(int(state), 3, "Item state should be Received");
    }

    // test calling the function from an address that is not the buyer
    function testForFailureIfReceiveNotFromBuyer() public {
        SupplyChain(address(sellerAccount)).addItem('car', 10 wei);
        SupplyChain(address(buyerAccount)).buyItem.value(10 wei)(0);
        SupplyChain(address(sellerAccount)).shipItem(0);

        (bool status, ) = address(otherAccount).call(abi.encodeWithSignature("receiveItem(uint256)", 0));
        Assert.isFalse(status, "Only buyer can change item state to Received");
    }    
    // test calling the function on an item not marked Shipped
    function testForFailureIfNotMarkedShipped() public {
        SupplyChain(address(sellerAccount)).addItem('car', 40 wei);
        SupplyChain(address(buyerAccount)).buyItem.value(40 wei)(0);

        (bool status, ) = address(buyerAccount).call(abi.encodeWithSignature("receiveItem(uint256)", 0));
        Assert.isFalse(status, "Only item marked as Shipped can be changed to Received");
    }

}
