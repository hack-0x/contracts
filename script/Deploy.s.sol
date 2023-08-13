//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "forge-std/Vm.sol";

import "./DeployHelpers.s.sol";
import "../src/Hack0x.sol";
import "../src/Hack0xDAOPrizePool.sol";
import "../src/Hack0xMerit.sol";
import "../src/Hack0xManifesto.sol";

contract DeployScript is Script {
    Hack0x hack0x;
    Hack0xMerit hackMerit;
    Hack0xManifesto hackManifesto;

    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

    function getEASContract() internal view returns (address EASContract) {
        if (block.chainid == 420) {
            return address(0x1a5650D0EcbCa349DD84bAFa85790E3e6955eb84);
        } else {
            return address(1);
        }
    }

    function run() external {
        address easContract = getEASContract();

        bytes32 attestSchema = 0x00214100cb49b72ab49efeea7dbb47b31eadecd6134c861908c0eace083894ef;
        bytes32 doneTaskSchema = 0xa42a295d78e4ab4e895c4c6a20a13f00cd54a1a8dac25031fa2e971779886fd7;
        bytes32 projectCreationSchema = 0x35665436127f9be5adba2850e19d8255e30303fb122de9100d3ddd2b7b81874c;
        bytes32 attestUserSchema = 0x88dfb2b22b5410c70c8a21005e28d32e827b9fef514a469c9c8eb25cb0f6ab41;

        // address easContract = getEASContract();

        vm.startBroadcast(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);

        // Hack0x constructor

        // address EAS,
        // address _Hack0xMerit,
        // bytes32 _attestTaskSchema,
        // bytes32 _doneTaskSchema,
        // bytes32 _projectCreationSchema,
        // bytes32 _attestUserSchema

        hack0x = new Hack0x(
            easContract,
            attestSchema,
            doneTaskSchema,
            projectCreationSchema,
            attestUserSchema
            
        );

        vm.stopBroadcast();
        /**
         * This function generates the file containing the contracts Abi definitions.
         * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
         * This function should be called last.
         */

        // exportDeployments();

        // If your chain is not present in foundry's stdChain, then you need to call function with chainName:
        // exportDeployments("chiado")
    }

    function test() public {}
}
