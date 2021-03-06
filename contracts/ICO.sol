pragma solidity 0.4.24;

/* solhint-disable max-line-length */
import "openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol"; // solium-disable-line max-len
import "openzeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol"; // solium-disable-line max-len
import "openzeppelin-solidity/contracts/crowdsale/validation/IndividuallyCappedCrowdsale.sol"; // solium-disable-line max-len
import "openzeppelin-solidity/contracts/crowdsale/validation/WhitelistedCrowdsale.sol"; // solium-disable-line max-len
import "openzeppelin-solidity/contracts/crowdsale/distribution/FinalizableCrowdsale.sol"; // solium-disable-line max-len
import "openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "./crowdsale/distribution/VestingCrowdsale.sol";
import "./crowdsale/price/FiatCrowdsale.sol";
import "./crowdsale/validation/PausableCrowdsale.sol";
import "./crowdsale/validation/ManagedCrowdsale.sol";
/* solhint-enable max-line-length */

/**
 * @title ENQ Private Sale Smart Contract
 * @author GeekHack t.me/GeekHack
 */
// solium-disable-next-line max-len
contract ICO is Crowdsale, MintedCrowdsale, CappedCrowdsale, IndividuallyCappedCrowdsale, WhitelistedCrowdsale, PausableCrowdsale, ManagedCrowdsale, FiatCrowdsale, FinalizableCrowdsale, VestingCrowdsale { // solhint-disable-line max-line-length
	constructor(
		uint256 _rate,
		address _wallet,
		address _token,
		uint256 _cap,
		uint256 _openingTime,
		uint256 _closingTime,
		string _url,
		uint _scale,
		uint _delay,
		uint256 _lockup
	)
	public
	payable
	Crowdsale(_rate, _wallet, MintableToken(_token))
	CappedCrowdsale(_cap)
	TimedCrowdsale(_openingTime, _closingTime)
	FiatCrowdsale()
	VestingCrowdsale()
	{ // solhint-disable-line bracket-align, no-empty-blocks
		_setFiatOraclizeQueryURL(_url);
		if (_scale > 0) {
			_setFiatScale(_scale);
		}
		if (_delay > 0) {
			_setFiatOraclizeQueryDelay(_delay);
		}
		_setFiatOraclizeQueryGasPrice(6000000000);
		_setFiatOraclizeQueryGasLimit(200000);
		_updateFiatPrice(0);

		_setVestingStart(_closingTime);
		_setVestingCliff(60);
		_setVestingDuration(_lockup);
	}

	/**
	* @dev Sets maximum contribution at a specific stage.
	* @param _cap Limit for total contribution
	*/
	function setCap(uint256 _cap) external onlyOwner {
		require(_cap > 0);
		if (cap == _cap) revert();
		cap = _cap;
	}

	/**
	* @dev Sets crowdsale closing time.
	* @param _closingTime (unix time stamp)
	*/
	function setClosingTime(uint256 _closingTime) external onlyOwner {
		require(_closingTime >= openingTime);
		if (closingTime == _closingTime) revert();
		closingTime = _closingTime;
	}

	/**
	* @dev Withdraw all ether to wallet.
	*/
	function withdrawBalance() external onlyOwner {
		_withdrawBalance();
	}

	/**
	* @dev add an address to the whitelist
	* @param _operator address
	* @return true if the address was added to the whitelist, false if
	* the address was already in the whitelist
	*/
	// solium-disable-next-line max-len
	function managerAddAddressToWhitelist(address _operator) external onlyManager { // solhint-disable-line max-line-length
		addRole(_operator, ROLE_WHITELISTED);
	}

	/**
	* @dev add addresses to the whitelist
	* @param _operators addresses
	* @return true if at least one address was added to the whitelist,
	* false if all addresses were already in the whitelist
	*/
	// solium-disable-next-line max-len
	function managerAddAddressesToWhitelist(address[] _operators) external onlyManager { // solhint-disable-line max-line-length
		for (uint256 i = 0; i < _operators.length; i++) {
			addRole(_operators[i], ROLE_WHITELISTED);
		}
	}

	/**
	* @dev Sets a specific user's maximum contribution.
	* @param _beneficiary Address to be capped
	* @param _cap Wei limit for individual contribution
	*/
	// solium-disable-next-line max-len
	function managerSetUserCap(address _beneficiary, uint256 _cap) external onlyManager { // solhint-disable-line max-line-length
		caps[_beneficiary] = _cap;
	}

	/**
	* @dev Sets a group of users' maximum contribution.
	* @param _beneficiaries List of addresses to be capped
	* @param _cap Wei limit for individual contribution
	*/
	// solium-disable-next-line max-len
	function managerSetGroupCap(address[] _beneficiaries, uint256 _cap) external onlyManager { // solhint-disable-line max-line-length
		for (uint256 i = 0; i < _beneficiaries.length; i++) {
			caps[_beneficiaries[i]] = _cap;
		}
	}

	/**
	* @dev Withdraw all ether to wallet.
	*/
	function _withdrawBalance() internal {
		wallet.transfer(address(this).balance);
	}
	
	/**
	* @dev Extend parent behavior to transfer ownership of token & ether to wallet
	*/
	function finalization() internal {
		MintableToken(token).transferOwnership(wallet);
		_withdrawBalance();
		super.finalization();
	}
}