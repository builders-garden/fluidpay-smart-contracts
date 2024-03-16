
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

import "./utils/IGnosisSafe.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract SingletonModule is AutomationCompatible {

    address internal owner; //Admin
    address internal upkeep; //Chainlink Upkeep

    address internal pancakeSwapRouter; //PancakeSwap Router
    address internal usdcAddress; //USDC on Base
    address internal usdcAavePool; //AAVE Pool

    uint256 internal minDepositAmount; //Minimum deposit amount to trigger the automation logic and deposit on AAVE

    address[] internal swapSafeRegistered; //List of Safe addresses that are allowed to use the swap service
    address[] internal depositSafeRegistered; //List of Safe addresses that are allowed to use the deposit service

    address[] internal s_swappableERC20; // 0x0000000000000000000000000000000000000000 ETH, 0xdAC17F958D2ee523a2206206994597C13D831ec7 //USDT on Base

    uint256 internal max_size_service; //Maximum size of the service arrays
    
    mapping(address => bool) public isSwapServiceRegistered; // all the safe addresses that are allowed to use the swap service
    mapping(address => bool) public isDepositServiceRegistered; // all the safe addresses that are allowed to use the deposit service

    modifier onlyUpkeep() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == upkeep, "Only upkeep allowed");
        _;
    }
    
    constructor(address _owner, address _upkeep, address _usdcAddress, address _usdcAavePool, address[] memory _swappableERC20, uint256 _minDeposit, uint256 _maxSizeService) {
        owner = _owner;
        upkeep = _upkeep;
        usdcAddress = _usdcAddress;
        usdcAavePool = _usdcAavePool;
        s_swappableERC20 = _swappableERC20;
        minDepositAmount = _minDeposit;
        max_size_service = _maxSizeService;
    }

    /*///////////////////////////////////////////////////////////////
                        Only Owner Functions
    //////////////////////////////////////////////////////////////*/

    function setMinDepositAmount(uint256 _minDeposit) public onlyOwner {
        minDepositAmount = _minDeposit;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    /*///////////////////////////////////////////////////////////////
                        Service Management Functions
    //////////////////////////////////////////////////////////////*/

    function registerSwapService(address safe) public onlyOwner {
        //check if the Safe is not already whitelisted
        require(!isSwapServiceRegistered[safe], "Safe already registered");
        swapSafeRegistered.push(safe);
        isSwapServiceRegistered[safe] = true;
    }

    function unregisterSwapService(address safe) public onlyOwner {
        //check if the Safe is whitelisted
        require(isSwapServiceRegistered[safe], "Safe not registered");
        isSwapServiceRegistered[safe] = false;
    }

    function registerDepositService(address safe) public onlyOwner {
        //check if the Safe is not already whitelisted
        require(!isDepositServiceRegistered[safe], "Safe already registered");
        depositSafeRegistered.push(safe);
        isDepositServiceRegistered[safe] = true;
    }
    
    function unregisterDepositService(address safe) public onlyOwner {
        //check if the Safe is whitelisted
        require(isDepositServiceRegistered[safe], "Safe not registered");
        isDepositServiceRegistered[safe] = false;
    }

    /*///////////////////////////////////////////////////////////////
                        onlyUpkeep Functions 
    //////////////////////////////////////////////////////////////*/

    /**
   * @dev checkUpkeep function called off-chain by Chainlink Automation infrastructure
   * @dev Checks for balances elegible for swap (ETH and USDT)
   * @return upkeepNeeded A boolean indicating whether upkeep is needed.
   * @return performData The performData parameter triggering the performUpkeep
   * @notice This function is external, view, and implements the Upkeep interface.
   */
  function checkUpkeep(
    bytes calldata
  )
    external
    view
    override
    returns (bool upkeepNeeded, bytes memory performData)
  {
    (upkeepNeeded, performData) = _checkUpkeep();
  }

  function _checkUpkeep() internal view returns (bool, bytes memory) {
    address[] memory swappableERC20 = s_swappableERC20;
    address[] memory walletsToCheckForSwap = swapSafeRegistered; 
    address[] memory walletsToCheckForDeposit = depositSafeRegistered;
    address[] memory tokensToSwap = new address[](swappableERC20.length);
    address[] memory filteredTokensToSwap;
    //check address[] length to avoid too expensive computation
    require(walletsToCheckForSwap.length <= max_size_service, "Too many wallets to check for swap");
    require(walletsToCheckForDeposit.length <= max_size_service, "Too many wallets to check for deposit");
    uint256 walletsToCheckLingth = walletsToCheckForSwap.length;
    uint count;
    /*
    for (uint i; i < walletsToCheckLingth; i++) {
      for (uint j; j < swappableERC20.length; ++j) {
        if (IERC20(swappableERC20[j]).balanceOf(walletsToCheckForSwap[i]) > 0 && isSwapServiceRegistered[walletsToCheckForSwap[i]]) {
          tokensToSwap[count] = swappableERC20[j];
          ++count;
        }
      }
      filteredTokensToSwap = new address[](count);
      for (uint k; k < count; ++k) {
        filteredTokensToSwap[k] = tokensToSwap[k];
      }

      if (filteredTokensToSwap.length > 0) {
        return (true, abi.encode(walletsToCheckForSwap[i], filteredTokensToSwap, true));
      }
    }
    for (uint i; i < walletsToCheckForDeposit.length; ++i) {
      if (IERC20(usdcAddress).balanceOf(walletsToCheckForDeposit[i]) > minDepositAmount && isDepositServiceRegistered[walletsToCheckForDeposit[i]]) {
        address[] memory empty;
        return (true, abi.encode(walletsToCheckForDeposit[i], empty, false));
      }
    }
    */
    for (uint i = 0; i < walletsToCheckLingth; /* no increment here */) {
        for (uint j = 0; j < swappableERC20.length; /* no increment here */) {
            if (IERC20(swappableERC20[j]).balanceOf(walletsToCheckForSwap[i]) > minDepositAmount && isSwapServiceRegistered[walletsToCheckForSwap[i]]) {
                tokensToSwap[count] = swappableERC20[j];
                ++count;
            }
            // Increment j manually
            unchecked { j++; }
        }

        filteredTokensToSwap = new address[](count);
        for (uint k = 0; k < count; /* no increment here */) {
            filteredTokensToSwap[k] = tokensToSwap[k];
            // Increment k manually
            unchecked { k++; }
        }

        if (filteredTokensToSwap.length > 0) {
            return (true, abi.encode(walletsToCheckForSwap[i], filteredTokensToSwap, true));
        }

        // Increment i manually
        unchecked { i++; }
    }

    for (uint i = 0; i < walletsToCheckForDeposit.length; /* no increment here */) {
        if (IERC20(usdcAddress).balanceOf(walletsToCheckForDeposit[i]) > minDepositAmount && isDepositServiceRegistered[walletsToCheckForDeposit[i]]) {
            address[] memory empty;
            return (true, abi.encode(walletsToCheckForDeposit[i], empty, false));
        }
        // Increment i manually
        unchecked { i++; }
    }
  }

  /**
   * @dev performUpkeep function called by Chainlink Automation infrastructure after checkUpkeep checks
   * @param performData the data inputed by Chainlink Automation retrieved by checkUpkeep
   */
  function performUpkeep(
    bytes calldata performData
  ) external override(AutomationCompatibleInterface) onlyUpkeep {
    (address wallet, address[] memory tokensToSwap, bool isSwapService) = abi.decode(performData,(address, address[], bool));
    // validate checkUpkeep parameters
    require(wallet != address(0), "Invalid wallet");
    require(tokensToSwap.length > 0, "Invalid tokens to swap");
    if (isSwapService) {
      for (uint i; i < tokensToSwap.length; ++i) {
        _swap(tokensToSwap[i], IERC20(tokensToSwap[i]).balanceOf(wallet), wallet, true);
      }
    } else {
      _swap(usdcAddress, IERC20(usdcAddress).balanceOf(wallet), wallet, false);
    }
  }

    /*///////////////////////////////////////////////////////////////
                        Pancake Swap Functions 
    //////////////////////////////////////////////////////////////*/

    function _swap(address _tokenIn, uint256 _amount, address _safe, bool isSimpleSwap) internal {
        require(_tokenIn != usdcAddress && _amount > 0, "Invalid token or amount");
        // Approve token to spend on Pancake Swap
        bytes memory approveData = abi.encodeWithSignature("approve(address,uint256)", pancakeSwapRouter, _amount);
        require(GnosisSafe(_safe).execTransactionFromModule(_tokenIn, 0, approveData, Enum.Operation.Call), "Could not execute token approval");
        // Swap token for usdc on Pancakeswap
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = usdcAddress; 
        // Swap token on Uniswap
        bytes memory swapData = abi.encodeWithSignature("swapExactTokensForTokens(uint256,uint256,address[],address)", _amount, _amount, path, _safe);
        if (_tokenIn == address(0)) {
            require(GnosisSafe(_safe).execTransactionFromModule(pancakeSwapRouter, _amount, swapData, Enum.Operation.Call), "Could not execute token swap");
        } else {
            require(GnosisSafe(_safe).execTransactionFromModule(pancakeSwapRouter, 0, swapData, Enum.Operation.Call), "Could not execute token swap");
        }
        // Deposit wsteth on AAVE
        if (!isSimpleSwap) {
            _deposit(IERC20(usdcAddress).balanceOf(_safe), _safe);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Deposit Functions
    //////////////////////////////////////////////////////////////*/

    function _deposit(uint256 _amount, address _safe) internal {
        // Approve AAVE pool to spend USDC
        bytes memory approveData = abi.encodeWithSignature("approve(address,uint256)", usdcAavePool, _amount);
        require(GnosisSafe(_safe).execTransactionFromModule(usdcAddress, 0, approveData, Enum.Operation.Call), "Could not execute token approval");
        // Supply token to AAVE
        bytes memory supplyData = abi.encodeWithSignature("supply(address,uint256, address, uint16)", usdcAddress , _amount, _safe, 0);
        require(GnosisSafe(_safe).execTransactionFromModule(usdcAavePool, 0, supplyData, Enum.Operation.Call), "Could not execute token supply");
    }
}