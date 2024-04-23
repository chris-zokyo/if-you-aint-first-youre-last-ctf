// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "src/FlashVault.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";



interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address) external returns (uint256);
    function approve(address,uint256) external;
}



contract TestAnswer is Test {

    address admin = vm.addr(1);
    address alice = vm.addr(2);
    address bob = vm.addr(3);
    address exploiter = vm.addr(4);


    FlashVault vault;

    IWETH weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);


    function setUp() public {

        // Setup Scenario
        uint256 forkId = vm.createFork("[YOUR-API-KEY]");
        vm.selectFork(forkId);
        vm.rollFork(19715489);

        vm.startPrank(admin);
        vault = new FlashVault("FlashCash Portfolio Manager", "FCPM");
        vm.stopPrank();

        deal(address(weth), exploiter, 8 ether);
        deal(address(weth), alice, 21.2 ether);
        deal(address(weth), bob, 12.6 ether);

    }

    function testAnswer() public {
        /*
        *
        *
        *  === Your Exploit Code Here ===
        * 
        */



        // === Do Not Change - Simulate User Interactions === 
        vm.startPrank(alice);
        weth.approve(address(vault), type(uint256).max);
        vault.deposit(21.1 ether, address(weth), alice);
        vm.stopPrank();

        vm.startPrank(bob);
        weth.approve(address(vault), type(uint256).max);
        vault.deposit(12.5 ether, address(weth), bob);
        vm.stopPrank();
        // ======================================= 


        /*
        *
        *
        *  === More Exploit Code Here If Required ===
        * 
        */



        // === Do Not Change - Exit Conditions ===
        // Asserts some funds have been stolen from victims
        assertGt(weth.balanceOf(exploiter), 10 ether);
        

    }
}
