// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

struct NetworkConfig {
  uint256 chainId;
  address linkToken;
  uint32 vrfCallbackGasLimit;
  uint16 vrfMinimumRequestConfirmations;
  address vrfV2Wrapper;
}

contract NetworkConfigHelper {
  uint256 private constant SEPOLIA_CHAIN_ID = 11155111;
  uint256 private constant ANVIL_CHAIN_ID = 31337;

  NetworkConfig private _currentNetworkConfig;

  constructor() {
    _setCurrentNetworkConfig();
  }

  function getCurrentNetworkConfig() public view returns (NetworkConfig memory) {
    return _currentNetworkConfig;
  }

  function _setCurrentNetworkConfig() private {
    if (block.chainid == SEPOLIA_CHAIN_ID) {
      _currentNetworkConfig = NetworkConfig({
        chainId: SEPOLIA_CHAIN_ID,
        linkToken: address(0x779877A7B0D9E8603169DdbD7836e478b4624789),
        vrfCallbackGasLimit: 200000,
        vrfMinimumRequestConfirmations: 4,
        vrfV2Wrapper: address(0xab18414CD93297B0d12ac29E63Ca20f515b3DB46)
      });
    }
  }
}
