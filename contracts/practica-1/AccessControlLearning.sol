// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract AccessControlLearning {

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    event TransferOwnership(address _prevOwner, address _newOwner);
    event RenounceOwnership(address _prevOwner);

    // 1. definir un mapping doble para guardar una matriz de información.
    mapping(address => mapping(bytes32 => bool)) private _roles;

    //2. definir metodo de lectura de datos de la matriz hasRole
    function hasRole(
        address _account,
        bytes32 _role
    ) public view returns (bool) {
        return _roles[_account][_role];
    }

    //3. definir método para escribir datos en la matriz grantRole
    function grantRole(
        address _account,
        bytes32 _role
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        //console.log("grantRole %s ", _account);
        _roles[_account][_role]=true;
        _rolesTemporary[_account][_role]=0;
    }

    //4. crear modifier que verifica el acceso de los roles
    modifier onlyRole(bytes32 _role){

       (bool _hasTempRole,uint256 _limit) = hasTemporaryRole(msg.sender,_role);
       //console.log("_hasTempRole %s", _hasTempRole);
       if(_hasTempRole){
           _rolesTemporary[msg.sender][_role] = _limit - 1; 
       }

       bool _hasRole = _roles[msg.sender][_role];//hasRole(msg.sender,_role);
       //console.log("_hasRole %s", _hasRole);

       require(_hasRole || _hasTempRole,"Cuenta no tiene el rol necesario");
       _;
    }

    //5. utilizar el constructor para inicializar valores
    constructor (){
        _roles[msg.sender][DEFAULT_ADMIN_ROLE] = true;
        _rolesTemporary[msg.sender][DEFAULT_ADMIN_ROLE] = 0;
    }

    //6. Crear un método que se llame 'transferOwnership(address _newOwner)'
    function transferOwnership(
        address _newOwner
    ) public onlyRole(DEFAULT_ADMIN_ROLE){

        bool _hasRole = _roles[msg.sender][DEFAULT_ADMIN_ROLE];
        (bool _hasTempRole,uint256 _limit) = hasTemporaryRole(msg.sender,DEFAULT_ADMIN_ROLE);

        if(_hasRole){
            grantRole(_newOwner,DEFAULT_ADMIN_ROLE);
        }
        else if(_hasTempRole){
            grantRoleTemporarily(_newOwner,DEFAULT_ADMIN_ROLE,_limit);
        }
        renounceOwnership();

        emit TransferOwnership(msg.sender, _newOwner);
    }

    //7. Crear un método lalmada 'renounceOwnership'
    function renounceOwnership() public onlyRole(DEFAULT_ADMIN_ROLE){
        
        _roles[msg.sender][DEFAULT_ADMIN_ROLE]=false;
        _rolesTemporary[msg.sender][DEFAULT_ADMIN_ROLE] = 0;

        emit RenounceOwnership(msg.sender);
    }

    // 8. Crear un método llamado 'grantRoleTemporarily'
    mapping(address => mapping(bytes32 => uint256)) private _rolesTemporary;

    function grantRoleTemporarily(
        address _account,
        bytes32 _role,
        uint256 _limit
    ) public onlyRole(DEFAULT_ADMIN_ROLE){

        require(_limit >= 1, "El limite debe ser mayor a 1");
        _rolesTemporary[_account][_role]=_limit;
        _roles[_account][_role]=false;
    }

    //  9. Definir su getter llamado 'hasTemporaryRole(address _account, bytes32 _role) returns (bool, uint256)'
    function hasTemporaryRole(
        address _account, 
        bytes32 _role
    ) public view returns (bool, uint256){
        
        uint256 limit = _rolesTemporary[_account][_role];
        
        if( limit == 0){
            return (false,0);
        }
        
        return (true,limit);
    }
}