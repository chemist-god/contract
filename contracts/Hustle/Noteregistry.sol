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

    function writeNote(
        string memory _title,
        string memory _contentCID,
        string memory _category
    ) external {
        notes.push(Note({
            title: _title,
            contentCID: _contentCID,
            category: _category,
            timestamp: block.timestamp,
            author: msg.sender
        }));

        emit NoteWritten(notes.length - 1, msg.sender, _category, _contentCID);
    }

    function getNoteCount() external view returns (uint256) {
        return notes.length;
    }

    function getNote(uint256 noteId) external view returns (
        string memory title,
        string memory contentCID,
        string memory category,
        uint256 timestamp,
        address author
    ) {
        require(noteId < notes.length, "Invalid note ID");
        Note storage note = notes[noteId];
        return (
            note.title,
            note.contentCID,
            note.category,
            note.timestamp,
            note.author
        );
    }
}