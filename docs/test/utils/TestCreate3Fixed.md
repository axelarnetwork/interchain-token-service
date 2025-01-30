# Solidity API

## TestCreate3Fixed

### Deployed

```solidity
event Deployed(address addr)
```

### deploy

```solidity
function deploy(bytes code, bytes32 salt) public payable returns (address addr)
```

### deployedAddress

```solidity
function deployedAddress(bytes32 salt) public view returns (address addr)
```

