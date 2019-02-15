pragma  solidity >=  0.4.24;

import  "github.com/OpenZeppelin/zeppelin-solidity/contracts/ownership/Ownable.sol";
import  "./DOSOnChainSDK.sol";

// An examnple user contract asks anything from off-chain world through a url.
contract  Example  is  Ownable,  DOSOnChainSDK  {

  string  public  response;

  // query_id -> valid_status
  mapping(uint => bool) private _valid; bool public repeated_call = false;
  // Default timeout for Etheruem in seconds: Two blocks.

  uint public timeout  =  14 * 2;
  string public last_queried_url;
  string public last_queried_selector;

  event SetTimeout(uint previousTimeout, uint newTimeout);
  event ResponseReady(uint requestId);

  function setQueryMode(bool new_mode) public onlyOwner {
    repeated_call = new_mode;
  }

  function setTimeout(uint new_timeout) public onlyOwner {
    emit SetTimeout(timeout, new_timeout);
    timeout = new_timeout;
  }

  function request(string memory url, string memory selector) public {

    last_queried_url = url;
    last_queried_selector = selector;

    uint id = DOSQuery(timeout, url, selector);

    if (id != 0x0) {

      _valid[id] = true;

    } else {

      revert("Invalid query id.");

    }

  }

  // User-defined callback function to take and process response.

  function callback(uint  requestId,  bytes  memory  result)  external  {
    require(msg.sender  ==  fromDOSProxyContract(),  "Unauthenticated  response.");
    require(_valid[requestId],  "Response  with  invalid  query  id!");

    emit  ResponseReady(requestId);
    response = string(result); delete _valid[requestId];



    if (repeated_call) {
      request(last_queried_url,  last_queried_selector);
    }

  }

}
