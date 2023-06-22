// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPausable {
    event PausedSet(bool paused);

    error Paused();
}
