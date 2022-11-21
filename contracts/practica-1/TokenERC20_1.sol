// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "./AccessControlLearning.sol";

interface IERC20Metadata {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender,uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/**is IERC20, IERC20Metadata */
contract TokenERC20_1 is IERC20, IERC20Metadata, AccessControlLearning{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 totalMinted;

    // mapping de balances
    mapping(address => uint256) private _balances;
    
    // mapping de permisos
    // owner => spender => amount
    mapping(address => mapping(address => uint256)) private _allowances;

    //cantidad total de tokens erc20 que tiene el contrato
    uint256 private _totalSupply;
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
         _name = name_;
         _symbol = symbol_;
         _decimals = decimals_;
    }

    function name() public view returns (string memory){
        return _name;
    }

    function symbol() public view returns (string memory){
        return _symbol;
    }
    
    function decimals() public view returns (uint8){
        return _decimals;
    }

    function totalSupply() public view returns (uint256){
		return _totalSupply;
	} 

	function balanceOf(address account) public view returns(uint256){
		return _balances[account];
	} 

	function transfer(
        address to, 
		uint256 amount
    ) public  returns (bool){
        
		address owner = msg.sender;
		_transfer(owner, to, amount);
		return true;
	}

	//devolver cuantos tokens han sido asignados a un spender
	function allowance(
        address owner, 
		address spender
    ) public  view returns(uint256){
        console.log("_allowances[owner][spender] %s",_allowances[owner][spender]);
		return _allowances[owner][spender];
	}

	function approve(
        address spender,
		uint256 amount
    ) public  returns(bool){

		address owner = msg.sender;
		_approve(owner, spender, amount);
		return true;
	}

	function transferFrom(
		address from,
		address to,
		uint256 amount
    ) public returns (bool){

		address spender = msg.sender;
		_spendAllowance(from, spender, amount);
		_transfer(from, to, amount);
        
		return true;
	}

    /**************************************************************/
    function _transfer(
        address from,
        address to,
        uint256 amount
	) internal virtual {
        
		require(from != address(0),"ERC20: transfer from the zero address");
		require(to != address(0),"Spender no puede ser zero");
		
		uint256 fromBalance = _balances[from];
       
		require(fromBalance>=amount,"ERC20: transfer amout exceeds balance");
		unchecked {
			_balances[from] = fromBalance - amount;
		}
       
       _balances[to]+= amount;
        
        emit Transfer(from, to, amount);
	}

    function _approve(
		address owner,
		address spender,
		uint256 amount
	) internal virtual {
		require(owner!=address(0),"ERC20: approve from the zero address");
		require(spender!=address(0),"Spender no puede ser zero");
		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

    function _spendAllowance(
		address owner,
		address spender,
		uint256 amount
	) internal virtual {
		uint256 currentAllowance = allowance(owner,spender);
		//if(currentAllowance != type(uint256).max){
			require(currentAllowance >= amount,"ERC20; insufficient allowance");
			unchecked {
				_approve(owner, spender, amount);
			}
		//}
	}

    /**************************************************************/
    //permite crear tokens desde address(0)
	function _mint(
		address account,
		uint256 amount
	) internal virtual {
		require(account != address(0),"Mint a favor del address zero");
		
		_totalSupply += amount;
		_balances[account] += amount;
		emit Transfer(address(0), account, amount);
		
	}

	//permite destruir tokens
	//address(0) 0x00000000 nunca ser usado
	function _burn(
		address account,
		uint256 amount
	) internal virtual {
		require(account != address(0),"ERC20: burn from the zero account");
		
		uint256 accountBalance = _balances[account];
		require(accountBalance >= amount,"ERC20: burn amout excced balance");
		unchecked{
			_balances[account] = accountBalance - amount;
		}
		_totalSupply -= amount;
		emit Transfer(account, address(0),amount);
		
	}
    /*************************************************/
    function mint(
        address to, 
        uint256 amount
    ) public {
        _mint(to, amount);
    }

    function burn(
        uint256 _amount
    ) public {
        _burn(msg.sender, _amount);
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool){
		address owner = msg.sender;
		_approve(owner, spender, _allowances[owner][spender]+addedValue);
		return true;
	}

	function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool){
		address owner = msg.sender;
		uint256 currentAllowance = _allowances[owner][spender];
		require(currentAllowance >= subtractedValue,"ERC20: decreased allowance below zero");
		//permite ahorrar gas
		unchecked {
			_approve(owner, spender, currentAllowance-subtractedValue);
		}
		return true;
	}

    function mintProtected(
        address _account, 
        uint256 _amount
    ) public onlyRole(MINTER_ROLE){
        _mint(_account, _amount);
    }

}