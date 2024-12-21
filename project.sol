// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EduFiInvestment {
    struct Investment {
        string studentName;
        string course;
        uint256 fundingGoal;
        uint256 amountFunded;
        address payable student;
        bool isFunded;
    }

    struct Investor {
        address wallet;
        uint256 amountInvested;
    }

    mapping(uint256 => Investment) public investments;
    mapping(address => uint256) public investorBalances;

    uint256 public totalInvestments;
    address public owner;

    event InvestmentCreated(uint256 investmentId, string studentName, uint256 fundingGoal);
    event Funded(uint256 investmentId, address investor, uint256 amount);
    event Withdrawn(address investor, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Create a new investment opportunity
    function createInvestment(string memory _studentName, string memory _course, uint256 _fundingGoal) public {
        require(_fundingGoal > 0, "Funding goal must be greater than 0");

        investments[totalInvestments] = Investment({
            studentName: _studentName,
            course: _course,
            fundingGoal: _fundingGoal,
            amountFunded: 0,
            student: payable(msg.sender),
            isFunded: false
        });

        emit InvestmentCreated(totalInvestments, _studentName, _fundingGoal);
        totalInvestments++;
    }

    // Fund an investment
    function fundInvestment(uint256 _investmentId) public payable {
        Investment storage investment = investments[_investmentId];
        require(!investment.isFunded, "Investment is already fully funded");
        require(msg.value > 0, "Funding amount must be greater than 0");
        require(investment.amountFunded + msg.value <= investment.fundingGoal, "Exceeds funding goal");

        investment.amountFunded += msg.value;
        investorBalances[msg.sender] += msg.value;

        if (investment.amountFunded == investment.fundingGoal) {
            investment.isFunded = true;
        }

        emit Funded(_investmentId, msg.sender, msg.value);
    }

    // Withdraw funds for a student
    function withdrawFunds(uint256 _investmentId) public {
        Investment storage investment = investments[_investmentId];
        require(investment.isFunded, "Investment is not fully funded yet");
        require(msg.sender == investment.student, "Only the student can withdraw funds");

        uint256 amount = investment.amountFunded;
        investment.amountFunded = 0; // Reset amount to avoid reentrancy
        investment.student.transfer(amount);
    }

    // Withdraw funds for investors
    function withdrawInvestorFunds() public {
        uint256 balance = investorBalances[msg.sender];
        require(balance > 0, "No funds to withdraw");

        investorBalances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);

        emit Withdrawn(msg.sender, balance);
    }

    // Get details of a specific investment
    function getInvestmentDetails(uint256 _investmentId)
        public
        view
        returns (
            string memory studentName,
            string memory course,
            uint256 fundingGoal,
            uint256 amountFunded,
            bool isFunded
        )
    {
        Investment memory investment = investments[_investmentId];
        return (
            investment.studentName,
            investment.course,
            investment.fundingGoal,
            investment.amountFunded,
            investment.isFunded
        );
    }
}
