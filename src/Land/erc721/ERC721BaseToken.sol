/* solhint-disable func-order */

pragma solidity 0.5.9;

import "../../../contracts_common/src/Interfaces/ERC721Events.sol";
import "../../Sand.sol";


/**
 * @title Land
 * @notice This contract is the core of our lands
 */
contract ERC721BaseToken is ERC721Events {
    // Our grid contains 408 * 408 lands
    uint256 private constant SIZE = 408;

    uint256 private constant LAYER = 0xFF00000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant LAYER_1x1 = 0x0000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant LAYER_3x3 = 0x0100000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant LAYER_6x6 = 0x0200000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant LAYER_12x12 = 0x0300000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant LAYER_24x24 = 0x0400000000000000000000000000000000000000000000000000000000000000;

    mapping (address => uint256) public numNFTPerAddress;
    mapping (uint256 => address) public owners;
    mapping (address => mapping(address => bool)) public operatorsForAll;
    mapping (uint256 => address) public operators;
    mapping (uint256 => string) public metadataURIs;
    Sand public sandContract;

    constructor(address sandAddress) public {
        initERC721BaseToken(sandAddress);
    }

    /**
     * @dev Initialize the LAND contract
     * @param sandAddress The address of the SAND contract
     */
    function initERC721BaseToken(address sandAddress) public {
        sandContract = Sand(sandAddress);
    }

    /**
     * @dev Transfer a token between 2 addresses
     * @param _from The send of the token
     * @param _to The recipient of the token
     * @param _id The id of the token
     */
    function _transferFrom(address _from, address _to, uint256 _id) internal {
        require(_to != address(0), "Invalid to address");

        if (_from != msg.sender && msg.sender != address(sandContract)) {
            require(
                operatorsForAll[_from][msg.sender] ||
                    operators[_id] == msg.sender,
                "Operator not approved"
            );
        }

        numNFTPerAddress[_from]--;
        numNFTPerAddress[_to]++;
        owners[_id] = _to;
        operators[_id] = address(0);
        emit Transfer(_from, _to, _id);
    }

    /**
     * @dev Return the balance of an address
     * @param _owner The address to look for
     * @return The balance of the address
     */
    function balanceOf(address _owner) external view returns (
        uint256 _balance
    ) {
        require(_owner != address(0), "zero owner");
        return numNFTPerAddress[_owner];
    }

    /**
     * @dev Mint a new block
     * @param to The recipient of the new block
     * @param size The size of the new block
     * @param x The x coordinate of the new block
     * @param y The y coordinate of the new block
     */
    function mintBlock(address to, uint8 size, uint16 x, uint16 y) external {
        require(x % size == 0 && y % size == 0, "invalid coordinates");
        require(x < SIZE && y < SIZE, "out of bounds");

        uint256 blockId;
        uint256 id = x + y * SIZE;

        if (size == 1) {
            blockId = id;
        } else if (size == 3) {
            blockId = LAYER_3x3 + id;
        } else if (size == 6) {
            blockId = LAYER_6x6 + id;
        } else if (size == 12) {
            blockId = LAYER_12x12 + id;
        } else if (size == 24) {
            blockId = LAYER_24x24 + id;
        } else {
            require(false, "invalid size");
        }

        // WARNING: Potential issue here, it seems possible mint multiple times with within the same area
        for (uint16 xi = x; xi < x + size; xi += 1) {
            for (uint16 yi = y; yi < y + size; yi += 1) {
                uint256 id1x1 = xi + yi * SIZE;
                require(_ownerOf(id1x1) == address(0), "already exists");
                emit Transfer(address(0), to, id1x1);
            }
        }

        owners[blockId] = to;
        numNFTPerAddress[to] += size * size;
    }

    /**
     * @dev Return the owner of a token
     * @param _id The id of the token
     * @return The address of the owner
     */
    function _ownerOf(uint256 _id) internal view returns (address) {
        uint256 x = _id % SIZE;
        uint256 y = _id / SIZE;
        address owner1x1 = owners[_id];

        if (owner1x1 != address(0)) {
            return owner1x1;
        } else {
            address owner3x3 = owners[LAYER_3x3 + x + y * SIZE];
            if (owner3x3 != address(0)) {
                return owner3x3;
            } else {
                address owner6x6 = owners[LAYER_6x6 + x + y * SIZE];
                if (owner6x6 != address(0)) {
                    return owner6x6;
                } else {
                    address owner12x12 = owners[LAYER_12x12 + x + y * SIZE];
                    if (owner12x12 != address(0)) {
                        return owner12x12;
                    } else {
                        return owners[LAYER_24x24 + x + y * SIZE];
                    }
                }
            }
        }
    }

    /**
     * @dev Return the owner of a token
     * @param _id The id of the token
     * @return The address of the owner
     */
    function ownerOf(uint256 _id) external view returns (address _owner) {
        require(_id & LAYER == 0, "invalid token id");
        _owner = _ownerOf(_id);
        require(_owner != address(0), "does not exist");
    }

    /**
     * @dev Approve an operator to spend tokens on the sender behalf
     * @param _sender The address giving the approval
     * @param _operator The address receiving the approval
     * @param _id The id of the token
     */
    function approveFor(
        address _sender,
        address _operator,
        uint256 _id
    ) external {
        require(_id & LAYER == 0, "invalid token id");
        require(
            msg.sender == _sender || msg.sender == address(sandContract),
            "only msg.sender or sandContract can act on behalf of sender"
        );
        require(_ownerOf(_id) == _sender, "only owner can change operator");

        operators[_id] = _operator;
        emit Approval(_sender, _operator, _id);
    }

    /**
     * @dev Approve an operator to spend tokens on the sender behalf
     * @param _operator The address receiving the approval
     * @param _id The id of the token
     */
    function approve(address _operator, uint256 _id) external {
        require(_id & LAYER == 0, "invalid token id");
        require(_ownerOf(_id) == msg.sender, "only owner can change operator");

        operators[_id] = _operator;
        emit Approval(msg.sender, _operator, _id);
    }

    /**
     * @dev Get the approved operator for a specific token
     * @param _id The id of the token
     * @return The address of the operator
     */
    function getApproved(uint256 _id) external view returns (address _operator) {
        require(_id & LAYER == 0, "invalid token id");
        require(_ownerOf(_id) != address(0), "does not exist");
        return operators[_id];
    }

    /**
     * @dev Transfer a token between 2 addresses
     * @param _from The send of the token
     * @param _to The recipient of the token
     * @param _id The id of the token
     */
    function transferFrom(address _from, address _to, uint256 _id) external {
        require(_id & LAYER == 0, "invalid token id");
        address owner = _ownerOf(_id);
        require(owner != address(0), "not an NFT");
        require(owner == _from, "only owner can change operator");
        _transferFrom(_from, _to, _id);
    }

    /**
     * @dev Transfer a token between 2 addresses
     * @param _from The send of the token
     * @param _to The recipient of the token
     * @param _id The id of the token
     * @param _data Additional data
     */
    function transferFrom(address _from, address _to, uint256 _id, bytes calldata _data) external {
        require(_id & LAYER == 0, "invalid token id");
        address owner = _ownerOf(_id);
        require(owner != address(0), "not an NFT");
        require(owner == _from, "only owner can change operator");
        _transferFrom(_from, _to, _id); // TODO _data
    }

    /**
     * @dev Transfer a token between 2 addresses
     * @param _from The send of the token
     * @param _to The recipient of the token
     * @param _id The id of the token
     * @param _data Additional data
     */
    function safeTransferFrom(address _from, address _to, uint256 _id, bytes calldata _data) external {
        require(_id & LAYER == 0, "invalid token id");
        address owner = _ownerOf(_id);
        require(owner != address(0), "not an NFT");
        require(owner == _from, "only owner can change operator");
        _transferFrom(_from, _to, _id); // TODO _data + safe
    }

    /**
     * @dev Transfer a token between 2 addresses
     * @param _from The send of the token
     * @param _to The recipient of the token
     * @param _id The id of the token
     */
    function safeTransferFrom(address _from, address _to, uint256 _id) external {
        require(_id & LAYER == 0, "invalid token id");
        address owner = _ownerOf(_id);
        require(owner != address(0), "not an NFT");
        require(owner == _from, "only owner can change operator");
        _transferFrom(_from, _to, _id); // TODO safe
    }

    /**
     * @dev Return the name of the token contract
     * @return The name of the token contract
     */
    function name() external pure returns (string memory _name) {
        return "SANDBOX LAND";
    }

    /**
     * @dev Return the symbol of the token contract
     * @return The symbol of the token contract
     */
    function symbol() external pure returns (string memory _symbol) {
        return "SLD"; // TODO define symbol
    }

    /**
     * @dev Return the URI of a specific token
     * @param _id The id of the token
     * @return The URI of the token
     */
    function tokenURI(uint256 _id) public view returns (string memory) {
        require(_id & LAYER == 0, "invalid token id");
        require(_ownerOf(_id) != address(0));
        return string(metadataURIs[_id]);
    }

    function supportsInterface(bytes4) external view returns (bool) {
        // TODO _interfaceId)
        return true; // TODO
    }

    /**
     * @dev Set the approval for an operator to manage all the tokens of the sender
     * @param _sender The address giving the approval
     * @param _operator The address receiving the approval
     * @param _approved The determination of the approval
     */
    function setApprovalForAllFor(
        address _sender,
        address _operator,
        bool _approved
    ) external {
        require(
            msg.sender == _sender || msg.sender == address(sandContract),
            "only msg.sender or _sandContract can act on behalf of sender"
        );

        _setApprovalForAll(_sender, _operator, _approved);
    }

    /**
     * @dev Set the approval for an operator to manage all the tokens of the sender
     * @param _operator The address receiving the approval
     * @param _approved The determination of the approval
     */
    function setApprovalForAll(address _operator, bool _approved) external {
        _setApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @dev Set the approval for an operator to manage all the tokens of the sender
     * @param _sender The address giving the approval
     * @param _operator The address receiving the approval
     * @param _approved The determination of the approval
     */
    function _setApprovalForAll(
        address _sender,
        address _operator,
        bool _approved
    ) internal {
        operatorsForAll[_sender][_operator] = _approved;

        emit ApprovalForAll(_sender, _operator, _approved);
    }

    /**
     * @dev Check if the sender approved the operator
     * @param _owner The address of the owner
     * @param _operator The address of the operator
     * @return The status of the approval
     */
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool isOperator)
    {
        return operatorsForAll[_owner][_operator];
    }
}
