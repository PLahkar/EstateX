// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EstateX {
    
    struct Property {
        uint256 id;
        string name;
        uint256 totalTokens;
        uint256 tokensSold;
        uint256 rentalIncome;
        address[] investors;
        mapping(address => uint256) tokenBalances;
    }

    uint256 public nextPropertyId;
    mapping(uint256 => Property) public properties;
    address public owner;

    event PropertyTokenized(uint256 indexed propertyId, string name, uint256 totalTokens);
    event TokensPurchased(uint256 indexed propertyId, address indexed investor, uint256 amount);
    event TokensSold(uint256 indexed propertyId, address indexed investor, uint256 amount);
    event RentalIncomeDistributed(uint256 indexed propertyId, uint256 totalIncome);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can execute this");
        _;
    }

    // Tokenize a property
    function tokenizeProperty(string memory _name, uint256 _totalTokens, uint256 _rentalIncome) public onlyOwner {
        Property storage property = properties[nextPropertyId];
        property.id = nextPropertyId;
        property.name = _name;
        property.totalTokens = _totalTokens;
        property.rentalIncome = _rentalIncome;

        emit PropertyTokenized(nextPropertyId, _name, _totalTokens);
        nextPropertyId++;
    }

    // Buy tokens representing fractional ownership of a property
    function buyTokens(uint256 _propertyId, uint256 _amount) public payable {
        Property storage property = properties[_propertyId];
        require(property.totalTokens > 0, "Property not found");
        require(property.tokensSold + _amount <= property.totalTokens, "Not enough tokens available");
        require(msg.value == _amount * getTokenPrice(_propertyId), "Incorrect Ether sent");

        if (property.tokenBalances[msg.sender] == 0) {
            property.investors.push(msg.sender);
        }

        property.tokenBalances[msg.sender] += _amount;
        property.tokensSold += _amount;

        emit TokensPurchased(_propertyId, msg.sender, _amount);
    }

    // Sell tokens representing fractional ownership of a property
    function sellTokens(uint256 _propertyId, uint256 _amount) public {
        Property storage property = properties[_propertyId];
        require(property.tokenBalances[msg.sender] >= _amount, "Insufficient tokens to sell");

        property.tokenBalances[msg.sender] -= _amount;
        property.tokensSold -= _amount;

        uint256 etherAmount = _amount * getTokenPrice(_propertyId);
        payable(msg.sender).transfer(etherAmount);

        emit TokensSold(_propertyId, msg.sender, _amount);
    }

    // Distribute rental income to token holders
    function distributeRentalIncome(uint256 _propertyId) public onlyOwner {
        Property storage property = properties[_propertyId];
        require(property.totalTokens > 0, "Property not found");

        uint256 totalIncome = property.rentalIncome;
        uint256 totalTokens = property.totalTokens;

        for (uint256 i = 0; i < property.investors.length; i++) {
            address investor = property.investors[i];
            uint256 investorTokens = property.tokenBalances[investor];
            uint256 investorShare = (investorTokens * totalIncome) / totalTokens;

            payable(investor).transfer(investorShare);
        }

        emit RentalIncomeDistributed(_propertyId, totalIncome);
    }

    // Get token balance of an investor for a specific property
    function getTokenBalance(uint256 _propertyId, address _investor) public view returns (uint256) {
        return properties[_propertyId].tokenBalances[_investor];
    }

    // Get token price (can be a fixed value or dynamic based on demand)
    function getTokenPrice(uint256 _propertyId) public pure returns (uint256) {
        // Implement pricing logic (e.g., fixed price or dynamic based on demand)
        return 1 ether; // Example fixed price of 1 ETH per token
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
