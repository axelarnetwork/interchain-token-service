// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IPausable {
    event PausedSet(bool paused);

    error Paused();

    function isPaused() external view returns (bool);
}
