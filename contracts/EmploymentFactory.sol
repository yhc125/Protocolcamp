// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ISuperfluid, ISuperToken, ISuperApp, ISuperAgreement, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import {Employment} from "./Employment.sol";

contract EmploymentFactory {
    /// @notice counter which is iterated +1 for each new employment created.
    /// @dev Note that the value begins at 0 here, but the first one will start at one.
    uint256 public employmentId = 0;

    /// @notice mapping of loanId to the loan contract
    mapping(uint256 => Employment) public idToEmployment;

    /// @notice mapping of loan owner (i.e. the msg.sender on the call) to the loan Id
    mapping(address => uint256) public employmentOwners;


    /// @notice Creates new loan contract.
    /// @param _salaryMonths Amount to borrow.
     /// @param _employer Employer address.
    /// @param _employee Borrower address.
    /// @param _salaryToken Token to borrow.
    /// @param _host Superfluid host.
    /// @return Loan ID.
    function createNewEmployment(
        int256 _salaryMonths,
        address _employer,
        address _employee,
        ISuperToken _salaryToken,
        ISuperfluid _host
    ) external returns (uint256) {
        Employment newEmployment = new Employment(
            _salaryMonths,
            _employer,
            _employee,
            _salaryToken,
            _host
        );

        employmentId++;

        idToEmployment[employmentId] = newEmployment;
        employmentOwners[msg.sender] = employmentId;

        return employmentId;
    }

    function getEmploymentByID(uint256 _employmentId) external view returns (Employment) {
        return idToEmployment[_employmentId];
    }

    // 이 Factory에서 생성된 총 Employment 개수
    function getEmploymentID() external view returns (uint256) {
        return employmentId;
    }

}