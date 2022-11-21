// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ISuperfluid, ISuperToken, ISuperApp, ISuperAgreement, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import {Employment} from "./Employment.sol";

contract EmploymentFactory {
    /// @notice counter which is iterated +1 for each new employment created.

    /// @notice 이 Factory에서 발행된 총 Employment 계약 수
    uint256 public numberOfEmployment = 0;

    /// @notice mapping of loanId to the loan contract
    mapping(uint256 => Employment) public idToEmployment;

    /// @notice
    uint256[] public employeeIdList;

    /// @notice mapping of loan owner (i.e. the msg.sender on the call) to the loan Id
    mapping(address => uint256) public employmentOwners;
    

    /// @notice Creates new loan contract.
    /// @param _salaryFlowRate Amount to borrow.
    /// @param _employeeId EmployeeId of Employment to create
     /// @param _employer Employer address.
    /// @param _employee Borrower address.
    /// @param _salaryToken Token to borrow.
    /// @param _host Superfluid host.
    function createNewEmployment(
        int96 _salaryFlowRate,
        uint256 _employeeId,
        address _employer,
        address _employee,
        ISuperToken _salaryToken,
        ISuperfluid _host
    ) external {
        Employment newEmployment = new Employment(
            _salaryFlowRate,
            _employeeId,
            _employer,
            _employee,
            _salaryToken,
            _host
        );

        numberOfEmployment++;

        idToEmployment[_employeeId] = newEmployment;
        employmentOwners[_employee] = _employeeId;
        employeeIdList.push(_employeeId);
        
    }

    // @notice 사용자 Id에 Mapping된 Employment 계약서를 가져옴.
    function getEmploymentById(uint256 _employeeId) external view returns (Employment) {
        return idToEmployment[_employeeId];
    }

    // @notice 이 Factory에서 발급된 계약서 개수
    function getNumberOfEmployment() external view returns (uint256) {
        return numberOfEmployment;
    }

    function getEmployeeIdList() external view returns (uint256[] memory) {
        return employeeIdList;
    }
}