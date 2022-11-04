// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ISuperfluid, ISuperToken, ISuperApp, ISuperAgreement, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import {CFAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/CFAv1Library.sol";

import {IConstantFlowAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

// import {IInstantDistributionAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IInstantDistributionAgreementV1.sol";

// import {IDAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/IDAv1Library.sol";

import {SuperAppBase} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";

error Unauthorized();

contract Employment is SuperAppBase {
    using CFAv1Library for CFAv1Library.InitData;
    // using IDAv1Library for IDAv1Library.InitData;

    // ---------------------------------------------------------------------------------------------
    // STORAGE & IMMUTABLES

    /// @notice Importing the CFAv1 Library to make working with streams easy.
    CFAv1Library.InitData public cfaV1;
    // IDAv1Library.InitData public idaV1;

    /// @notice Constant used for initialization of CFAv1 and for callback modifiers.
    bytes32 public constant CFA_ID =
        keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1");

    // /// @notice Index ID. Never changes.
    // uint32 public constant INDEX_ID = 0;

    /// @notice Total amount borrowed.
    int256 public immutable salaryMonths;

    /// @notice Address of employer - must be allow-listed for this example
    address public immutable employer;

    /// @notice Employee address
    address public immutable employee;

    /// @notice Superfluid Host.
    ISuperfluid public immutable host;

    /// @notice Token being payed
    ISuperToken public immutable salaryToken;

    /// @notice boolean flag to track whether or not the loan is open
    bool public salaryFluidOpen;

    /// @notice Timestamp of the salary give time.
    uint256 public salaryGiveTime;

    /// @notice Allow list.
    // 이후 부서별로 나눌 때 쓸 수도?
    mapping(address => bool) public accountList;

    
    /// @dev checks that only the CFA is being used
    ///@param agreementClass the address of the agreement which triggers callback
    function _isCFAv1(address agreementClass) private view returns (bool) {
        return ISuperAgreement(agreementClass).agreementType() == CFA_ID;
    }

    ///@dev checks that only the salaryToken is used when sending streams into this contract
    ///@param superToken the token being streamed into the contract
    function _isSameToken(ISuperToken superToken) private view returns (bool) {
        return address(superToken) == address(salaryToken);
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
        int256 _salaryMonths, // total payback months
        address _employer, // allow-listed employer address
        address _employee, // borrower address
        ISuperToken _salaryToken, // super token to be used in borrowing
        ISuperfluid _host // address of SF host
    ) {
        salaryMonths = _salaryMonths;
        employer = _employer;
        employee = _employee;
        salaryToken = _salaryToken;
        host = _host;
        salaryFluidOpen = false;

        // CFA lib initialization
        IConstantFlowAgreementV1 cfa = IConstantFlowAgreementV1(
            address(_host.getAgreementClass(CFA_ID))
        );

        cfaV1 = CFAv1Library.InitData(_host, cfa);

        //  // IDA Library Initialize.
        // idaV1 = IDAv1Library.InitData(
        //     _host,
        //     IInstantDistributionAgreementV1(
        //         address(
        //             _host.getAgreementClass(
        //                 keccak256(
        //                     "org.superfluid-finance.agreements.InstantDistributionAgreement.v1"
        //                 )
        //             )
        //         )
        //     )
        // );

        // // Creates the IDA Index through which tokens will be distributed
        // idaV1.createIndex(_salaryToken, INDEX_ID);

        // super app registration
        uint256 configWord = SuperAppDefinitions.APP_LEVEL_FINAL |
            SuperAppDefinitions.BEFORE_AGREEMENT_CREATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_UPDATED_NOOP |
            SuperAppDefinitions.BEFORE_AGREEMENT_TERMINATED_NOOP;

        // Using host.registerApp because we are using testnet. If you would like to deploy to
        // mainnet, this process will work differently. You'll need to use registerAppWithKey or
        // registerAppByFactory.
        // https://github.com/superfluid-finance/protocol-monorepo/wiki/Super-App-White-listing-Guide
        _host.registerApp(configWord);
    }

    /// @dev Calculates the flow rate to be sent to the lender to repay the stream.
    /// @return salaryFlowRate The flow rate to be paid to the lender.
    function getsalaryFlowRate() public view returns (int96 salaryFlowRate) {
        return (
            int96(
                salaryMonths / 30 * 86400
            )
        );
    }
    // ---------------------------------------------------------------------------------------------
    // FUNCTIONS & CORE LOGIC

    function getTotalAmountRemaining() public view returns (uint256) {
        int256 secondsLeft = (salaryMonths * int256((365 * 86400) / 12)) - 
            int256(block.timestamp - salaryGiveTime);
        if (secondsLeft <= 0) {
            return 0;
        } else {
            //if an amount is left, return the total amount to be paid
            return uint256(secondsLeft) * uint256(int256(getsalaryFlowRate()));
        }
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
    // function changeOwner(address _newOwner) external {
    //     if (msg.sender != employer) revert Unauthorized();

    //     employer = _newOwner;
    // }

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
    } 

    /// @notice Withdraw funds from the contract.
    /// @param token Token to withdraw.
    /// @param amount Amount to withdraw.
    function withdrawFunds(ISuperToken token, uint256 amount) external {
        if (!accountList[msg.sender] && msg.sender != employer) revert Unauthorized();

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
        if (!accountList[msg.sender] && msg.sender != employer) revert Unauthorized();

        cfaV1.updateFlow(receiver, token, flowRate);
    }

    /// @notice Delete flow from contract to specified address.
    /// @param token Token to stop streaming.
    /// @param receiver Receiver of stream.
    function deleteFlowFromContract(ISuperToken token, address receiver) external {
        if (!accountList[msg.sender] && msg.sender != employer) revert Unauthorized();

        cfaV1.deleteFlow(address(this), receiver, token);
    }


    // ---------------------------------------------------------------------------------------------
    // IDA OPERATIONS
    /// @notice Takes the entire balance of the designated salaryToken in the contract and distributes it out to unit holders w/ IDA
    // function distribute() public {
    //     uint256 salaryTokenBalance = salaryToken.balanceOf(address(this));

    //     (uint256 actualDistributionAmount, ) = idaV1.ida.calculateDistribution(
    //         salaryToken,
    //         address(this),
    //         INDEX_ID,
    //         salaryTokenBalance
    //     );

    //     idaV1.distribute(salaryToken, INDEX_ID, actualDistributionAmount);
    // }

    // ---------------------------------------------------------------------------------------------
    // SUPER APP CALLBACKS

    


}