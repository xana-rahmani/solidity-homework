pragma solidity ^0.5.10;

contract CustomERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => mapping(address => uint256)) private _allowancesExpireTime;

    uint256 private _totalSupply;
    string public tokenName;
	string public tokenSymbol;

    event Transfer(address sender, address recipient, uint256 amount);
    event Approval(address owner, address spender, uint256 amount);
    event TimeApproval(address owner, address spender, uint256 expireTime);
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;
    address private _pauser;

    constructor (uint256 total,string memory _tokenName,string memory _tokenSymbol,address pauser) internal {
        _totalSupply = total;
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        _pauser = pauser;
        _paused = true;
    }
    
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    modifier onlyPauser() {
        require(msg.sender == _pauser);
        _;
    }


    function paused() public view returns (bool) {
        return _paused;
    }


    function isPauser(address account) private view returns (bool) {
        if (account == _pauser)
            return true;
        return false;
    }


    function pause() public onlyPauser returns (bool) {
        _paused = true;
        emit Paused(msg.sender);
        return true;
    }


    function unpause() public onlyPauser {
        emit Unpaused(msg.sender);
        _paused = false;
    }


    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public whenNotPaused view returns (uint256) {
        return _balances[account];
    }


    function transfer(address recipient, uint256 amount) public whenNotPaused returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _transfer(msg.sender, recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view whenNotPaused returns (uint256) {
        if (_allowancesExpireTime[owner][spender]> now)
            return 0;
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount, uint expireTime) public whenNotPaused returns (bool) {
        require(spender != address(0));
        _approve(msg.sender, spender, amount);
        _approveExpireTime(msg.sender, spender, expireTime);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public whenNotPaused returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if (allowance(sender, msg.sender) > 0)
            return false;
        _transfer(sender, recipient, amount);
        _approve(sender, sender, _allowances[sender][sender] - amount);
        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= _balances[sender]);
        
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }


    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_balances[account] >= amount);
        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
    }

   
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _approveExpireTime(address owner, address spender, uint expireTime) internal {
        require(owner != address(0), "ERC20:  approve expire time from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(expireTime > 0);
        _allowancesExpireTime[owner][spender] = now + expireTime;
        emit TimeApproval(owner, spender, now + expireTime);
    }

    function _mint(address account, uint256 amount) internal {
         require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender] - amount);
    }
}
