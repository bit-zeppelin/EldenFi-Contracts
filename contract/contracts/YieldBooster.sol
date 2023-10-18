// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface INFTPool is IERC721 {
  function exists(uint256 tokenId) external view returns (bool);
  function hasDeposits() external view returns (bool);
  function getPoolInfo() external view returns (
    address lpToken, address grailToken, address sbtToken, uint256 lastRewardTime, uint256 accRewardsPerShare,
    uint256 lpSupply, uint256 lpSupplyWithMultiplier, uint256 allocPoint
  );
  function getStakingPosition(uint256 tokenId) external view returns (
    uint256 amount, uint256 amountWithMultiplier, uint256 startLockTime,
    uint256 lockDuration, uint256 lockMultiplier, uint256 rewardDebt,
    uint256 boostPoints, uint256 totalMultiplier
  );

  function boost(uint256 userAddress, uint256 amount) external;
  function unboost(uint256 userAddress, uint256 amount) external;
}

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

interface IYieldBooster {
  function deallocateAllFromPool(address userAddress, uint256 tokenId) external;
  function getMultiplier(address poolAddress, uint256 maxBoostMultiplier, uint256 amount, uint256 totalPoolSupply, uint256 allocatedAmount) external view returns (uint256);
}

/*
 * This contract is a xElden Usage (plugin) that can boost ksNFTs' yield (staking positions on NFTPools) when it
 * receives allocations from the xEldenToken contract
 */
contract YieldBooster is Ownable, ReentrancyGuard, IxEldenTokenUsage, IYieldBooster {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.UintSet;

  IxEldenToken public xEldenToken; // xEldenToken contract

  uint256 public constant MAX_TOTAL_ALLOCATION_FLOOR = 1000 ether;
  // use to set a floor when calculating the multiplier on a pool
  // see _getMultiplier
  uint256 public totalAllocationFloor = 100 ether;

  // User's boosted positions
  // userAddress => poolAddress => tokenIds[]
  mapping(address => mapping(address => EnumerableSet.UintSet)) private _usersPositions;
  // User's position xElden total allocation
  // userAddress => poolAddress => tokenId => totalAllocation
  mapping(address => mapping(address => mapping(uint256 => uint256))) public usersPositionsAllocation;

  mapping(address => uint256) private _usersTotalAllocation; // User's xElden total allocation
  mapping(address => uint256) private _poolsTotalAllocation; // Pool's total allocation
  uint256 public totalAllocation; // Contract's total xElden allocation

  bool public forcedDeallocationStatus; // Authorize users to forcibly deallocate everything

  constructor(IxEldenToken xEldenToken_) {
    xEldenToken = xEldenToken_;
  }

  /********************************************/
  /****************** EVENTS ******************/
  /********************************************/

  event Allocate(address indexed userAddress, address indexed poolAddress, uint256 tokenId, uint256 amount);
  event Deallocate(address indexed userAddress, address indexed poolAddress, uint256 tokenId, uint256 amount);
  event EmergencyWithdraw(address caller, IERC20 token, uint256 amount);
  event UpdateForcedDeallocationStatus(address caller, bool status);
  event UpdateTotalAllocationFloor(uint256 newFloor);


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
   * @dev Returns corresponding yield boost multiplier
   *
   * returns multiplier * 1e4
   */
  function getMultiplier(address poolAddress, uint256 maxBoostMultiplier, uint256 lpAmount, uint256 totalLpSupply, uint256 userAllocation) external override view returns (uint256) {
    return _getMultiplier(maxBoostMultiplier, lpAmount, totalLpSupply, userAllocation, _poolsTotalAllocation[poolAddress]);
  }

  /**
   * @dev Returns corresponding yield boost multiplier
   * simulating poolTotalAllocation
   *
   * returns multiplier * 1e4
   */
  function getExpectedMultiplier(uint256 maxBoostMultiplier, uint256 lpAmount, uint256 totalLpSupply, uint256 userAllocation, uint256 poolTotalAllocation) external view returns (uint256){
    return _getMultiplier(maxBoostMultiplier, lpAmount, totalLpSupply, userAllocation, poolTotalAllocation);
  }

  /**
   * @dev Returns total xElden allocated to this contract by "userAddress"
   */
  function getUserTotalAllocation(address userAddress) external view returns (uint256) {
    return _usersTotalAllocation[userAddress];
  }

  /**
   * @dev Returns total xElden allocated to this contract by "poolAddress"
   */
  function getPoolTotalAllocation(address poolAddress) external view returns (uint256) {
    return _poolsTotalAllocation[poolAddress];
  }

  /**
   * @dev Returns allocated xElden to "tokenId" ksNFT from "poolAddress" NFTPool by "userAddress"
   */
  function getUserPositionAllocation(address userAddress, address poolAddress, uint256 tokenId) external view returns (uint256) {
    return usersPositionsAllocation[userAddress][poolAddress][tokenId];
  }

  /**
   * @dev Returns the amount of boosted tokenId for a given user on a given poolAddress
   */
  function getUserPositionsLength(address userAddress, address poolAddress) external view returns (uint256) {
    return _usersPositions[userAddress][poolAddress].length();
  }

  /**
   * @dev Returns the tokenId for a given user on a given poolAddress by index
   */
  function getUserPosition(address userAddress, address poolAddress, uint256 index) external view returns (uint256) {
    return _usersPositions[userAddress][poolAddress].at(index);
  }


  /****************************************************/
  /****************** OWNABLE FUNCTIONS ***************/
  /****************************************************/

  /**
   * @dev Updates totalAllocationFloor value
   *
   * Can only be called by owner
   * totalAllocationFloor cannot be set to 0
   */
  function setTotalAllocationFloor(uint256 floor) external onlyOwner {
    require(floor > 0 && floor <= MAX_TOTAL_ALLOCATION_FLOOR, "setTotalAllocationFloor: invalid floor");
    totalAllocationFloor = floor;
    emit UpdateTotalAllocationFloor(floor);
  }

  /**
   * @dev Updates forcedDeallocation status
   *
   * Can only be called by owner
   * Safety mechanism, should only be activated in case there is something wrong with this contract to avoid having
   * stuck allocated xElden
   * Contract should be discarded once activated
   */
  function updateForcedDeallocationStatus(bool status) external onlyOwner {
    forcedDeallocationStatus = status;
    emit UpdateForcedDeallocationStatus(msg.sender, status);
  }

  /**
   * @dev Emergency withdraw token's balance on the contract
   */
  function emergencyWithdraw(IERC20 token) public nonReentrant onlyOwner {
    uint256 balance = token.balanceOf(address(this));
    require(balance > 0, "emergencyWithdraw: token balance is null");

    emit EmergencyWithdraw(msg.sender, token, balance);
    token.safeTransfer(msg.sender, balance);
  }


  /*****************************************************************/
  /****************** EXTERNAL PUBLIC FUNCTIONS  *******************/
  /*****************************************************************/

  /**
   * Allocates "userAddress" user's "amount" of xElden to this usage contract
   * "data" should contain tokenId and poolAddress
   *
   * Can only be called by xEldenToken contract, which is trusted to verify amounts
   */
  function allocate(address userAddress, uint256 amount, bytes calldata data) external override nonReentrant xEldenTokenOnly {
    (address poolAddress, uint256 tokenId) = abi.decode(data, (address, uint256));
    _allocate(userAddress, poolAddress, tokenId, amount);

    // allocated xElden is added (as boost points) to ksNFT
    INFTPool(poolAddress).boost(tokenId, amount);
  }

  /**
   * Deallocates "userAddress" user's "amount" of xElden from this usage contract
   * "data" should contain tokenId and poolAddress
   *
   * Can only be called by xEldenToken contract, which is trusted to verify amounts
   */
  function deallocate(address userAddress, uint256 amount, bytes calldata data) external override nonReentrant xEldenTokenOnly {
    (address poolAddress, uint256 tokenId) = abi.decode(data, (address, uint256));
    _deallocate(userAddress, poolAddress, tokenId, amount);

    // should only be called if ksNFT has not been burned, to avoid having stuck xElden on it
    if(INFTPool(poolAddress).exists(tokenId)) {
      // allocated xElden is removed (as boost points) from the ksNFT
      INFTPool(poolAddress).unboost(tokenId, amount);
    }
  }

  /**
   * Deallocates "userAddress" user's "amount" of xElden from this usage contract
   *
   * Can only be used by a pool contract, as msg.sender is used as poolAddress
   * The pool should remove the allocated xElden (boost points) from its own ksNFT when calling this function
   */
  function deallocateAllFromPool(address userAddress, uint256 tokenId) external override nonReentrant {
    uint256 amount = usersPositionsAllocation[userAddress][msg.sender][tokenId];
    _deallocate(userAddress, msg.sender, tokenId, amount);

    // update user's xElden allocations balance
    xEldenToken.deallocateFromUsage(userAddress, amount);
  }

  /**
   * Deallocates msg.sender's "amount" of xElden from xEldenToken, without adjusting this contract allocations balances
   *
   * Safety mechanism (cf. updateForcedDeallocationStatus)
   */
  function forceDeallocate() external nonReentrant {
    require(forcedDeallocationStatus, "forceDeallocate: unauthorized");

    uint256 amount = xEldenToken.usageAllocations(msg.sender, address(this));

    // update user's xElden allocations balance
    xEldenToken.deallocateFromUsage(msg.sender, amount);
  }


  /*****************************************************************/
  /********************* INTERNAL FUNCTIONS  ***********************/
  /*****************************************************************/

  /**
   * @dev Returns multiplier that should be applied to a ksNFT based on its boost points (allocated xElden)
   *
   * The calculation is simply based on the ratio between userBoostPoints/totalPoolBoostPoints and userLP/totalLP
   * To get the max bonus on a position where a user owns 1% of the pool's LP supply, he will have to allocate at least
   * 1% of the pool's allocated xElden
   *
   * The amount is capped at maxBoostMultiplier
   */
  function _getMultiplier(uint256 maxBoostMultiplier, uint256 lpAmount, uint256 totalLpSupply, uint256 userAllocation, uint256 totalAllocation_) internal view returns (uint256) {
    if(totalAllocation_ < totalAllocationFloor) totalAllocation_ = totalAllocationFloor;
    if(totalAllocation_ == 0 || lpAmount == 0 || userAllocation == 0 || totalLpSupply == 0 || maxBoostMultiplier == 0) return 0;
    uint256 multiplier = userAllocation.mul(totalLpSupply).mul(maxBoostMultiplier).div(lpAmount.mul(totalAllocation_));
    return Math.min(multiplier, maxBoostMultiplier);
  }

  /**
   * @dev Allocates "userAddress" user's "amount" of xElden to "tokenId" ksNFT of "poolAddress" pool
   */
  function _allocate(address userAddress, address poolAddress, uint256 tokenId, uint256 amount) internal {
    _usersTotalAllocation[userAddress] = _usersTotalAllocation[userAddress].add(amount);
    usersPositionsAllocation[userAddress][poolAddress][tokenId] = usersPositionsAllocation[userAddress][poolAddress][tokenId].add(amount);
    _usersPositions[userAddress][poolAddress].add(tokenId);
    totalAllocation = totalAllocation.add(amount);
    _poolsTotalAllocation[poolAddress] = _poolsTotalAllocation[poolAddress].add(amount);

    emit Allocate(userAddress, poolAddress, tokenId, amount);
  }

  /**
   * @dev Deallocates "userAddress" user's "amount" of xElden allocated to "tokenId" ksNFT of "poolAddress" pool
   */
  function _deallocate(address userAddress, address poolAddress, uint256 tokenId, uint256 amount) internal {
    uint256 userPositionAllocation = usersPositionsAllocation[userAddress][poolAddress][tokenId];
    require(userPositionAllocation >= amount, "deallocate: not enough allocated xElden");

    _usersTotalAllocation[userAddress] = _usersTotalAllocation[userAddress].sub(amount);
    usersPositionsAllocation[userAddress][poolAddress][tokenId] = userPositionAllocation.sub(amount);
    if(userPositionAllocation.sub(amount) == 0){
      _usersPositions[userAddress][poolAddress].remove(tokenId);
    }

    totalAllocation = totalAllocation.sub(amount);
    _poolsTotalAllocation[poolAddress] = _poolsTotalAllocation[poolAddress].sub(amount);

    emit Deallocate(userAddress, poolAddress, tokenId, amount);
  }

}