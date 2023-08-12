// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IEAS, AttestationRequest, AttestationRequestData} from "@eas/contracts/IEAS.sol";
import {NO_EXPIRATION_TIME, EMPTY_UID} from "@eas/contracts/Common.sol";

// add custom ERC20 to be able to mint and burn from registries
