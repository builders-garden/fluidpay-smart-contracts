// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Enum.sol";
interface PancakeRouter02 {

function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

}