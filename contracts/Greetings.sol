//SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

contract Greetings {
    string public greet = "Akwaaba, Hardhat";

    //function to update greeting by calling setGreeting()
    function setGreeting(string memory _greet)  public {
        greet = _greet;
    }
}