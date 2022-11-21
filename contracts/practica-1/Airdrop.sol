// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// Do no modify TokenAIRDRP
contract TokenAIRDRP is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor() ERC20("Token para Airdrop", "TAIRDRP") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyRole(BURNER_ROLE) {
        _burn(from, amount);
    }
}

interface ITokenAIRDRP {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function balanceOf(address account) external returns (uint256);
}

contract Airdrop is AccessControl {
    address tokenAIRDRPAddress;
    uint256 constant prizeTokensBlueList = 10_000 * 10**18;
    uint256 constant amntTokensToBurn = 1_000 * 10**18;

    constructor(address _tokenAddress) {
        tokenAIRDRPAddress = _tokenAddress;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    struct Participant {
        uint256 feRegistro;
        bool isEnabled;
    }

    mapping(address => Participant) _whiteList;
    mapping(address => Participant) _blueList;

    function addToWhiteListBatch(
        address[] memory _addresses
    ) public onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 _length = _addresses.length;
        for (uint256 i = 0; i < _length; i++) {
            
            Participant memory participant = Participant({
                feRegistro: block.timestamp,
                isEnabled: true
            });
            
            _whiteList[_addresses[i]] = participant;
        }
    }

    function mintWithWhiteList() external {
        // accede a la informacion de msg.sender en _whiteList
        Participant memory participant = _whiteList[msg.sender];
        // verifica si esta en whitelist
        require(participant.isEnabled, "Participante no esta en whitelist");

        // valida que no hayan pasado mas de 24 h
        require(participant.feRegistro + 1 days > block.timestamp, "Pasaron mas de 24 horas");

        // entrega tokens a msg.sender
        uint256 _amntTokens = _getRandom();
        ITokenAIRDRP(tokenAIRDRPAddress).mint(msg.sender, _amntTokens);

        // eliminar de whitelist a msg.sender
        _whiteList[msg.sender].isEnabled = false;
    }

    function addToBlueListBatch(
        address[] memory _addresses
    ) public onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 _length = _addresses.length;
        for (uint256 i = 0; i < _length; i++) {
            
            Participant memory participant = Participant({
                feRegistro: block.timestamp,
                isEnabled: true
            });
            
            _blueList[_addresses[i]] = participant;
        }
    }

    function mintWithBlueList() external {
        // accede a la informacion de msg.sender en _blueList
        Participant memory participant = _blueList[msg.sender];

        // verifica si esta en bluelist
        require(participant.isEnabled, "Participante no esta en bluelist");

        uint256 tEnQueIngresoMsgSender = participant.feRegistro; // /** pasa el tiempo en el que ingreso*/
        uint256 _amntTokens = _getTokensBasedOnTime(tEnQueIngresoMsgSender);
        ITokenAIRDRP(tokenAIRDRPAddress).mint(msg.sender, _amntTokens);

        // eliminar de blue list
        _blueList[msg.sender].isEnabled = false;
    }

    function burnMyTokensToParticipate() external {
        // usar amntTokensToBurn que es igual a 1,000 tokens
        // incluye validaciones
        uint256 bal = ITokenAIRDRP(tokenAIRDRPAddress).balanceOf(msg.sender);
        require(bal >= amntTokensToBurn, "No tiene suficientes tokens para quemar");

        require(!_whiteList[msg.sender].isEnabled, "Esta en lista blanca");

        // burn tokens del caller
        ITokenAIRDRP(tokenAIRDRPAddress).burn(msg.sender, amntTokensToBurn);

        // ingresa a msg.sender en lista blanca
        _whiteList[msg.sender] = Participant({
            feRegistro: block.timestamp,
            isEnabled: true
        });
    }

    //////////////////////////////////////////////////
    //////////            HELPERS           //////////
    //////////////////////////////////////////////////

    function _getTokensBasedOnTime(uint256 _enterTime)
        internal
        view
        returns (uint256)
    {
        // usa la variable prizeTokensBlueList
        // multiplica primero y luego divide

        // m: tiempo pasado para hacer mint
        // r: tiempo restante para completar 60 minutos
        // m + r = 60 minutos

        uint256 totalTime = 60 * 60; // m + r -> 60 min x 60 sec
        uint256 timePased = block.timestamp - _enterTime; // m -> block.timestamp - _enterTime
        require(totalTime > timePased, "Pasaron mas de 60 minutos");

        uint256 remainingTime = totalTime - timePased; // r -> totalTime - m
        // tokens a entregar = (r * prizeTokensBlueList) / ( m + r)
        return (remainingTime * prizeTokensBlueList) / (timePased + remainingTime);
    }

    function _getRandom() internal view returns (uint256) {
        // denro de "abi.encodePacked" se pueden añadir tantas varialbes globales como sean posibles
        // lo importante es que devuelve un numero random cada vez que ejecuta el metodo
        // random =  uint256(keccak256(abi.encodePacked(msg.sender, address(this), block.timestamp)))
        // user el mod % N para encontrar un numero random menor a N
        // el mod % empieza en cero
        // multiplicar por 10**18 por los decimales

        uint256 random = (uint256(keccak256(abi.encodePacked(msg.sender, address(this), block.timestamp))) % 1000) + 1;

        return random * 10**18;
    }
}