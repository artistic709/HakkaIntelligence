pragma solidity 0.8.7;

// SPDX-License-Identifier: MIT

interface IHakkaIntelligence {
    function reveal(address _player) external returns (uint256 score);
    function revealOpen() external view returns (uint256);
    function revealClose() external view returns (uint256);
}

contract HakkaIntelligenceMock {
    uint256 internal ro;
    uint256 internal rc;
    mapping(address => bool) public revealed;

    constructor() {
        ro = block.timestamp + 600;
        rc = block.timestamp + 1800;
    }

    function reveal(address _player) external returns (uint256 score) {
        require(block.timestamp > ro && block.timestamp < rc);
        require(!revealed[_player]);
        revealed[_player] = true;
        return 1;
    }
    function revealOpen() external view returns (uint256) {
        return ro;
    }
    function revealClose() external view returns (uint256) {
        return rc;
    }
}

contract keeper {
    IHakkaIntelligence public HI;

    uint256 public cost;
    uint256 public index;
    address public owner;
    address[] public queue;

    event Register(address indexed user);
    event Perform(address indexed user);

    constructor(address _HI, uint256 _cost) {
        HI = IHakkaIntelligence(_HI);
        cost = _cost;
        owner = msg.sender;
    }

    function getQueueLength() external view returns (uint256) {
        return queue.length;
    }

    function register() external payable {
        require(msg.value >= cost);
        queue.push(msg.sender);
        emit Register(msg.sender);
    }

    function validate() internal view returns (bool) {
        return HI.revealOpen() < block.timestamp && HI.revealClose() > block.timestamp && queue.length > index;
    }

    function checkUpkeep(bytes calldata) external view returns (bool upkeepNeeded, bytes memory performData) {
        return (validate(), bytes(""));
    }

    function performUpkeep(bytes calldata) external {
        require(validate(), "invalid");
        address target = queue[index];
        bytes memory data = abi.encodeWithSelector(HI.reveal.selector, target);
        (bool success, ) = address(HI).call(data);
        if ( success) emit Perform(target);
        ++index;
    }

    function withdraw() external {
        (bool success, ) = payable(owner).call{value:address(this).balance}("");
        require(success, "withdraw fail");
    }

}
