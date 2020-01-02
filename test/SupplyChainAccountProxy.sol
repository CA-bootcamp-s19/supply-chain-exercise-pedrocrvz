import "../contracts/SupplyChain.sol";

pragma solidity ^0.5.0;

/**
 * @title AccountProxy
 * @dev Proxy contract for account differentiation in Solidity testing, 
 * Modified from OpenZeppelin SDK upgradable proxy contract.
 */
contract SupplyChainAccountProxy {
  address internal callee;

  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  function () payable external {
    if(msg.data.length > 0) _fallback();
  }

  /**
   * @dev Set contract to be called by the AccountProxy
   * @param _callee to set.
   */
  function setCallee(address _callee) external {
    callee = _callee;
  }

  /**
   * @dev Call to a contract with new context.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the contract returns.
   * @param _callee to call.
   */
  function _call(address _callee) internal {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize)

      // Call the contract.
      // out and outsize are 0 because we don't know the size yet.
      let result := call(gas, _callee, callvalue, 0, calldatasize, 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize)

      switch result
      // call returns 0 on error.
      case 0 { revert(0, returndatasize) }
      default { return(0, returndatasize) }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal {
  }

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _call(callee);
  }

  function deploySupplyChainContract() external returns (address) {
        return address(new SupplyChain());
    }
}