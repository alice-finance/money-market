pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

import "../base/Base.sol";

contract DelegatedBase is Base {
    /** Public state variables */
    uint256 internal _version;

    event Initialized(uint256 from, uint256 to);

    modifier delegated() {
        require(
            _loan != address(0) && _loan != address(this),
            "cannot call this contract directly"
        );
        _;
    }

    modifier initialized() {
        require(_version >= 1, "not initialized");
        _;
    }

    function version() public view returns (uint256) {
        return _version;
    }

    modifier checkVersion(uint256 minimumVersion) {
        require(
            _version >= minimumVersion,
            "version must be at least minimum required version"
        );
        _;
    }

    /** Public functions */
    function _initialize(uint256 newVersion)
        internal
        delegated
        onlyOwner
        returns (bool)
    {
        require(newVersion >= 1, "version must be at least 1");
        require(newVersion != _version, "version already initialized");
        require(newVersion - 1 == _version, "version must be continuous");

        emit Initialized(_version, newVersion);
        _version = newVersion;

        return true;
    }
}
