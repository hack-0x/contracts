// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Hack0xManifesto is ERC721 {
    string immutable MANIFESTO =
        "hack the status quo - a manifesto.\n\n" +
            "the membership is 10 op. it's for life.\n" +
            "you get an on-chain attestation, and you have full access to the collective. " +
            "meaning: see all projects, create new projects, find contributors/partners-in-crime, get funds, support public goods.\n" +
            "break things, change things. give explanations to no one.\n" +
            "this is a manifesto, not a 'tos'\n" +
            "by signing, you share these collective values. you won't be giving up your data, your privacy, your identity, or whatever.\n" +
            "this is your self-sovereign choice, and it has a date. today.";

    constructor() ERC721("Hack0xManifesto", "H0xM") {}

    function sign() public payable {
        _safeMint(msg.sender, totalSupply());
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://hack0x.io/manifesto/"; // TODO - update
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        revert("Hack0xManifesto is not transferable");
    }
}
