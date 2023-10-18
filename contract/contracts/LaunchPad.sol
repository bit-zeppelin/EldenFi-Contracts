// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IxEldenTokenUsage {
    function allocate(address userAddress, uint256 amount, bytes calldata data) external;
    function deallocate(address userAddress, uint256 amount, bytes calldata data) external;
}

interface IxEldenToken is IERC20 {
  function usageAllocations(address userAddress, address usageAddress) external view returns (uint256 allocation);

  function allocateFromUsage(address userAddress, uint256 amount) external;
  function convertTo(uint256 amount, address to) external;
  function deallocateFromUsage(address userAddress, uint256 amount) external;

  function isTransferWhitelisted(address account) external view returns (bool);
}

/*
 * This contract is a xElden Usage (plugin) made to receive perks and benefits from EldenFi's launchpad
 */
contract Launchpad is Ownable, ReentrancyGuard, ERC20("EldenFi launchpad receipt", "xEldenReceipt"), ERC20Snapshot, IxEldenTokenUsage {
  using SafeMath for uint256;

  struct UserInfo {
    uint256 allocation;
    uint256 allocationTime;
  }

  IxEldenToken public xEldenToken; // xEldenToken contract

  mapping(address => UserInfo) public usersAllocation; // User's xElden allocation info
  uint256 public totalAllocation; // Contract's total xElden allocation

  uint256 public deallocationCooldown = 2592000; // 30 days

  constructor(IxEldenToken _xEldenToken) {
    xEldenToken = _xEldenToken;
  }

  /********************************************/
  /****************** EVENTS ******************/
  /********************************************/

  event Allocate(address indexed userAddress, uint256 amount);
  event Deallocate(address indexed userAddress, uint256 amount);
  event UpdateDeallocationCooldown(uint256 newDuration);


  /***********************************************/
  /****************** MODIFIERS ******************/
  /***********************************************/

  /**
   * @dev Checks if caller is the xEldenToken contract
   */
  modifier xEldenTokenOnly() {
    require(msg.sender == address(xEldenToken), "xEldenTokenOnly: caller should be xEldenToken");
    _;
  }


  /*******************************************/
  /****************** VIEWS ******************/
  /*******************************************/

  /**
   * @dev Returns total xElden allocated to this contract by "userAddress"
   */
  function getUserInfo(address userAddress) external view returns (uint256 allocation, uint256 allocationTime) {
    UserInfo storage userInfo = usersAllocation[userAddress];
    allocation = userInfo.allocation;
    allocationTime = userInfo.allocationTime;
  }


  /****************************************************/
  /****************** OWNABLE FUNCTIONS ***************/
  /****************************************************/

  /**
   * @dev Updates deallocationCooldown value
   *
   * Can only be called by owner
   */
  function updateDeallocationCooldown(uint256 duration) external onlyOwner {
    deallocationCooldown = duration;
    emit UpdateDeallocationCooldown(duration);
  }

  /**
   * @dev Updates xElden token when xElden is upgraded
   *
   * Can only be called by owner
   */
  function setxEldenToken(address _xElden ) external onlyOwner {
    xEldenToken = IxEldenToken(_xElden);
  }

  function snapshot() external onlyOwner {
    ERC20Snapshot._snapshot();
  }

  /*****************************************************************/
  /****************** EXTERNAL PUBLIC FUNCTIONS  *******************/
  /*****************************************************************/

  /**
   * Allocates "userAddress" user's "amount" of xElden to this launchpad contract
   *
   * Can only be called by xEldenToken contract, which is trusted to verify amounts
   * "data" is only here for compatibility reasons (IxEldenTokenUsage)
   */
  function allocate(address userAddress, uint256 amount, bytes calldata /*data*/) external override nonReentrant xEldenTokenOnly {
    UserInfo storage userInfo = usersAllocation[userAddress];

    userInfo.allocation = userInfo.allocation.add(amount);
    userInfo.allocationTime = _currentBlockTimestamp();
    totalAllocation = totalAllocation.add(amount);
    _mint(userAddress, amount);

    emit Allocate(userAddress, amount);
  }

  /**
   * Deallocates "userAddress" user's "amount" of xElden allocation from this launchpad contract
   *
   * Can only be called by xEldenToken contract, which is trusted to verify amounts
   * "data" is only here for compatibility reasons (IxEldenTokenUsage)
   */
  function deallocate(address userAddress, uint256 amount, bytes calldata /*data*/) external override nonReentrant xEldenTokenOnly {
    UserInfo storage userInfo = usersAllocation[userAddress];
    require(userInfo.allocation >= amount, "deallocate: non authorized amount");
    require(_currentBlockTimestamp() >= userInfo.allocationTime.add(deallocationCooldown), "deallocate: cooldown not reached");

    userInfo.allocation = userInfo.allocation.sub(amount);
    totalAllocation = totalAllocation.sub(amount);
    _burn(userAddress, amount);

    emit Deallocate(userAddress, amount);
  }


  /*****************************************************************/
  /********************* INTERNAL FUNCTIONS  ***********************/
  /*****************************************************************/

  /**
   * @dev Hook override to forbid transfers except from minting and burning
   */
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Snapshot) {
    require(from == address(0) || to == address(0), "transfer: not allowed");
    ERC20Snapshot._beforeTokenTransfer(from, to, amount);
  }

  /**
   * @dev Utility function to get the current block timestamp
   */
  function _currentBlockTimestamp() internal view virtual returns (uint256) {
    /* solhint-disable not-rely-on-time */
    return block.timestamp;
  }

}