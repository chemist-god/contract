// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract NoteRegistry {
    struct Note {
        string title;
        string contentCID; // IPFS hash
        string category;
        uint256 timestamp;
        address author;
    }

    Note[] public notes;

    event NoteWritten(
        uint256 indexed noteId,
        address indexed author,
        string category,
        string contentCID
    );

   
}