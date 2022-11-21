// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ISuperfluid, ISuperToken, ISuperApp, ISuperAgreement, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import {CFAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/CFAv1Library.sol";

import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

import {SuperAppBase} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";

error Unauthorized();

contract Employment is SuperAppBase {
    using CFAv1Library for CFAv1Library.InitData;

    // ---------------------------------------------------------------------------------------------
    // STORAGE & IMMUTABLES

    /// @notice Importing the CFAv1 Library to make working with streams easy.
    CFAv1Library.InitData public cfaV1;

    /// @notice Constant used for initialization of CFAv1 and for callback modifiers.
    bytes32 public constant CFA_ID =
        keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1");

    /// @notice Total amount salary.
    int96 public salaryFlowRate;

    /// @notice Address of employer - must be allow-listed for this example
    address public employer;

    /// @notice Employee address
    address public immutable employee;

    /// @notice Superfluid Host.
    ISuperfluid public immutable host;

    /// @notice Token being payed
    ISuperToken public immutable salaryToken;

   /// @notice Employer로부터 발급받은 자신(Employee)의 Employment에 대해 Employee가 설정한 Id
    uint256 public immutable employeeId;

    /// @notice boolean flag to track whether or not the loan is open
    bool public salaryFluidOpen;

    /// @notice Timestamp of the salary give time.
    uint256 public salaryStartingTime;


    /// @notice Allow list.
    //  Employer가 서로 다른 계정에서 flow를 만들고 싶을 수 있으니까
    mapping(address => bool) public accountList;

    // ---------------------------------------------------------------------------------------------
    //MODIFIERS

    /// @dev checks that only the CFA is being used
    ///@param agreementClass the address of the agreement which triggers callback
    function _isCFAv1(address agreementClass) private view returns (bool) {
        return ISuperAgreement(agreementClass).agreementType() == CFA_ID;
    }

    ///@dev checks that only the borrowToken is used when sending streams into this contract
    ///@param superToken the token being streamed into the contract
    function _isSameToken(ISuperToken superToken) private view returns (bool) {
        return address(superToken) == address(salaryToken);
    }

    // Employer만 접근
    modifier onlyEmployer() {
        require(msg.sender != employee, "You do not have permission.");
        _;
    }

    ///@dev ensures that only the host can call functions where this is implemented
    //for usage in callbacks only
    modifier onlyHost() {
        require(msg.sender == address(cfaV1.host), "Only host can call callback");
        _;
    }

    ///@dev used to implement _isSameToken and _isCFAv1 modifiers
    ///@param superToken used when sending streams into contract to trigger callbacks
    ///@param agreementClass the address of the agreement which triggers callback
    modifier onlyExpected(ISuperToken superToken, address agreementClass) {
        require(_isSameToken(superToken), "RedirectAll: not accepted token");
        require(_isCFAv1(agreementClass), "RedirectAll: only CFAv1 supported");
        _;
    }

        constructor(
        int96 _salaryFlowRate, // total payback months
        uint256 _employeeId, // Id of employee
        address _employer, // allow-listed employer address
        address _employee, // borrower address
        ISuperToken _salaryToken, // super token to be used in borrowing
        ISuperfluid _host // address of SF host
    ) {
        salaryFlowRate = _salaryFlowRate;
        employer = _employer;
        employee = _employee;
        employeeId = _employeeId;
        salaryToken = _salaryToken;
        host = _host;
        salaryFluidOpen = false;

        // Initialize CFA Library
        cfaV1 = CFAv1Library.InitData(
            host,
            IConstantFlowAgreementV1(
                address(
                    host.getAgreementClass(
                        keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1")
                    )
                )
            )
        );

        accountList[_employer] = true;
        accountList[_employee] = true;

    }

    //@notice 이 Employment의 주인인 employee의 Id
    function getEmployeeId() external view returns (uint256) {
        return employeeId;
    }

    function getSalaryStartingTime() external view returns (uint256) {
        return salaryStartingTime;
    }

    /// @notice Add account to allow list.
    /// @param _account Account to allow.
    function allowAccount(address _account) external {
        if (msg.sender != employer) revert Unauthorized();

        accountList[_account] = true;
    }

    /// @notice Removes account from allow list.
    /// @param _account Account to disallow.
    function removeAccount(address _account) external {
        if (msg.sender != employer) revert Unauthorized();

        accountList[_account] = false;
    }

    /// @notice Transfer ownership.
    /// @param _newOwner New owner account.
    function changeOwner(address _newOwner) external {
        if (msg.sender != employer) revert Unauthorized();

        employer = _newOwner;
    }

    /// @notice Send a lump sum of super tokens into the contract.
    /// @dev This requires a super token ERC20 approval.
    /// @param token Super Token to transfer.
    /// @param amount Amount to transfer.
    function sendLumpSumToContract(ISuperToken token, uint256 amount) external {
        if (!accountList[msg.sender] && msg.sender != employer) revert Unauthorized();

        token.transferFrom(msg.sender, address(this), amount);
    }

    /// @notice Create a stream into the contract.
    /// @dev This requires the contract to be a flowOperator for the msg sender.
    /// @param token Token to stream.
    /// @param flowRate Flow rate per second to stream.
    function createFlowIntoContract(ISuperToken token, int96 flowRate) external {
        if (!accountList[msg.sender] && msg.sender != employer) revert Unauthorized();

        cfaV1.createFlowByOperator(msg.sender, address(this), token, flowRate);
        salaryFluidOpen = true;
    }

    /// @notice Update an existing stream being sent into the contract by msg sender.
    /// @dev This requires the contract to be a flowOperator for the msg sender.
    /// @param token Token to stream.
    /// @param flowRate Flow rate per second to stream.
    function updateFlowIntoContract(ISuperToken token, int96 flowRate) external {
        if (!accountList[msg.sender] && msg.sender != employer) revert Unauthorized();

        cfaV1.updateFlowByOperator(msg.sender, address(this), token, flowRate);
    }

    /// @notice Delete a stream that the msg.sender has open into the contract.
    /// @param token Token to quit streaming.
    function deleteFlowIntoContract(ISuperToken token) external {
        if (!accountList[msg.sender] && msg.sender != employer) revert Unauthorized();

        cfaV1.deleteFlow(msg.sender, address(this), token);
        salaryFluidOpen = false;
    } 

    /// @notice Withdraw funds from the contract.
    /// @param token Token to withdraw.
    /// @param amount Amount to withdraw.
    function withdrawSalary(ISuperToken token, uint256 amount) external {
        if (!accountList[msg.sender] && msg.sender != employee) revert Unauthorized();

        token.transfer(msg.sender, amount);
    }


    /// @notice Create flow from contract to specified address.
    /// @param token Token to stream.
    /// @param receiver Receiver of stream.
    /// @param flowRate Flow rate per second to stream.
    function createFlowFromContract(
        ISuperToken token,
        address receiver,
        int96 flowRate
    ) external {
        if (!accountList[msg.sender] && msg.sender != employer) revert Unauthorized();

        cfaV1.createFlow(receiver, token, flowRate);
        salaryStartingTime = block.timestamp;
    }

    /// @notice Update flow from contract to specified address.
    /// @param token Token to stream.
    /// @param receiver Receiver of stream.
    /// @param flowRate Flow rate per second to stream.
    function updateFlowFromContract(
        ISuperToken token,
        address receiver,
        int96 flowRate
    ) external {
        if (!accountList[msg.sender] && msg.sender != employee) revert Unauthorized();

        cfaV1.updateFlow(receiver, token, flowRate);
    }

    /// @notice Delete flow from contract to specified address.
    /// @param token Token to stop streaming.
    /// @param receiver Receiver of stream.
    function deleteFlowFromContract(ISuperToken token, address receiver) external {
        if (!accountList[msg.sender] && msg.sender != employee) revert Unauthorized();

        cfaV1.deleteFlow(address(this), receiver, token);
    }

    // @notice Update flowAmount Permission for changing salaryAmount
    function updateSalaryAmountPermission(int96 _newSalaryFlowAmount) external {
        if (!accountList[msg.sender] && msg.sender != employee) revert Unauthorized();

        cfaV1.updateFlowOperatorPermissions(address(this), salaryToken, 7, _newSalaryFlowAmount);
    }

    //@notice Get WorkingPeriod in this company
    function getWorkingPeriod() external view returns (uint256) {
        return block.timestamp - salaryStartingTime;
    }

        // ---------------------------------------------------------------------------------------------
    // SUPER APP CALLBACKS

    /// @dev super app after agreement created callback
    function afterAgreementCreated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, // _agreementId,
        bytes calldata, /*_agreementData*/
        bytes calldata, // _cbdata,
        bytes calldata ctx
    )
        external
        override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {
        
    }

    /// @dev super app after agreement updated callback
    function afterAgreementUpdated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, // _agreementId,
        bytes calldata, /*_agreementData*/
        bytes calldata, // _cbdata,
        bytes calldata ctx
    )
        external
        override
        onlyExpected(_superToken, _agreementClass)
        onlyHost
        returns (bytes memory newCtx)
    {

    }

    /// @dev super app after agreement terminated callback
    function afterAgreementTerminated(
        ISuperToken _superToken,
        address _agreementClass,
        bytes32, // _agreementId,
        bytes calldata, /*_agreementData*/
        bytes calldata, // _cbdata,
        bytes calldata ctx
    ) external override onlyHost returns (bytes memory newCtx) {
      
    }
    


}