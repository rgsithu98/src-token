/**
 * @title SwissRealCoin Liquidatation Wallet
 * handles ERC20 tokens (Ex: W-ETH), not unwrapped ether
 * @version 1.0
 * @author Validity Labs AG <info@validitylabs.org>
 */
pragma solidity ^0.4.19;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/token/ERC20/ERC20.sol';

contract LiquidationWallet is Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public payments;
    uint256 public totalPayments;

    ERC20 public token;

    /*** EVENTS ***/
    event PaymentAuthorized(address beneficiary, uint amount);

    /*** MODIFIERS ***/
    modifier onlyValidAddress(address _address) {
        require(_address != address(0));
        _;
    }

    /**
    * @dev contructor
    * @param _token ERC20
    */
    function LiquidationWallet(ERC20 _token) public onlyValidAddress(address(_token)) {
        token = _token;
    }

    /**
    * @dev fallback function - refuse receiving ether
    */
    function () public payable {
        revert();
    }

    /**
    * @dev allows onlyOwner to set new ERC20 token for payouts
    * @param _token ERC20
    */
    function setNewErc20Token(ERC20 _token) public onlyOwner onlyValidAddress(address(_token)) {
        token = _token;
    }

    /**
    * @dev authorize payment to benificiary
    * @param _dest address
    * @param _amount uint256
    */
    function authorizePayment(address _dest, uint256 _amount) public onlyOwner {
        asyncSend(_dest, _amount);
        PaymentAuthorized(_dest, _amount);
    }

    /**
    * @dev withdraw accumulated balance, called by payee.
    */
    function withdrawPayments() public {
        address payee = msg.sender;
        uint256 payment = payments[payee];

        require(payment != 0);
        require(token.balanceOf(this) >= payment);

        totalPayments = totalPayments.sub(payment);
        payments[payee] = 0;

        assert(token.transfer(payee, payment));
    }

    /**
    * @dev deposit remaining balance to beneficiary, called by onlyOwner.
    */
    function depositRemaindingFunds(address _beneficiary) public onlyValidAddress(_beneficiary) onlyOwner {
        uint256 payment = token.balanceOf(this);
        require(payment > 0);

        assert(token.transfer(_beneficiary, payment));
    }

    /**
    * @dev Called by the payer to store the sent amount as credit to be pulled.
    * @param _dest The destination address of the funds.
    * @param _amount The amount to transfer.
    */
    function asyncSend(address _dest, uint256 _amount) internal {
        payments[_dest] = payments[_dest].add(_amount);
        totalPayments = totalPayments.add(_amount);
    }
}
