pragma solidity 0.8.7;

// SPDX-License-Identifier: MIT

interface IHakkaIntelligence {
    function reveal(address _player) external returns (uint256 score);
    function revealOpen() external view returns (uint256);
    function revealClose() external view returns (uint256);
    function periodStop() external view returns (uint256);
    function proceed() external;
}

contract HakkaIntelligenceMock {
    uint256 internal ro;
    uint256 internal rc;
    uint256 internal ps;
    mapping(address => bool) public revealed;

    constructor() {
        ps = block.timestamp + 60;
    }

    function reveal(address _player) external returns (uint256 score) {
        require(block.timestamp > ro && block.timestamp < rc);
        require(!revealed[_player]);
        revealed[_player] = true;
        return 1;
    }
    function proceed() external {
        require(block.timestamp > ps);
        ro = block.timestamp + 300;
        rc = block.timestamp + 1800;
    }
    function periodStop() external view returns (uint256) {
        return ps;
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
    uint256 public flag;

    event Register(address indexed user);
    event Perform(address indexed user);
    event Init(address HI, uint256 cost);

    constructor() {
        owner = msg.sender;
    }

    function init(address _HI, uint256 _cost) external {
        require(msg.sender == owner, "not owner");
        require(queue.length == index, "Work not done yet");
        HI = IHakkaIntelligence(_HI);
        cost = _cost;
        index = 0;
        delete queue;
        flag = 1;
        emit Init(_HI, _cost);
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
        if(flag == 2)
            return HI.revealOpen() < block.timestamp && HI.revealClose() > block.timestamp && queue.length > index;
        else if(flag == 1)
            return HI.periodStop() >= block.timestamp;
        else return false;
    }

    function checkUpkeep(bytes calldata) external view returns (bool upkeepNeeded, bytes memory performData) {
        return (validate(), bytes(""));
    }

    function performUpkeep(bytes calldata) external {
        require(validate(), "invalid upkeep");

        if(flag == 1) {
            if(HI.revealOpen() == 0) HI.proceed();
            flag = 2;
        }
        else {
            address target = queue[index];
            bytes memory data = abi.encodeWithSelector(HI.reveal.selector, target);
            (bool success, ) = address(HI).call(data);
            if ( success) emit Perform(target);
            ++index;
        }
    }

    function withdraw() external {
        (bool success, ) = payable(owner).call{value:address(this).balance}("");
        require(success, "withdraw fail");
    }

}
