// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Common.sol";

contract SkillEndorseResolver is SchemaResolver {
    using Address for address payable;

    IERC20 private immutable i_meritToken;
    IEAS private immutable i_eas;

    constructor(IEAS _eas, address _meritToken) SchemaResolver(_eas) {
        i_eas = _eas;
        i_meritToken = IERC20(_meritToken);
    }

    function onAttest(
        Attestation calldata attestation,
        uint256 /* value */
    ) internal override returns (bool) {
        // i_meritToken.mint(attestation.recipient, weight);

        return true;
    }

    function onRevoke(
        Attestation calldata /*attestation*/,
        uint256 /*value*/
    ) internal pure override returns (bool) {
        // i_meritToken.burn(Attestation.recipient, weight);

        return true;
    }

    function getMeritTokenAddress() public view returns (address) {
        return address(i_meritToken);
    }
}
