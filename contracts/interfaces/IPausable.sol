// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPausable {
    event PausedSet(bool paused);

    error Paused();

    // TODO: define event here
    // event PausedSet(bool paused);

    // TODO: add method to interface
    // function isPaused() external view returns (bool);
}
