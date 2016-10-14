soapclient.d
============

Available methods
-----------------

### `getEndpoint()`
    - *string*
    - Return the endpoint URI the client is connecting to.
### `setHeader(string key, string value)`
    - *void*
    - Set a header to be sent along when the client calls a method.
### `getHeaders()`
    - *array*
    - Return an associative array of all headers that have been set.
### `clearHeaders()`
    - *void*
    - Clear all SOAP headers that may have been set up to this point.
### `getHeader(string key)`
    - *string*
    - Return the value of a specific header key.
### `getMethods()`
    - *array*
    - Return an array of available SOAP methods.
### `call(string method, Element payload)`
    - *void*
    - Call a specific method on the endpoint, feeding it a valid XML Element.
### `getResult()`
    - *string*
    - Return the result of our call.


Example usage
-------

```d
import soapclient;
import std.stdio;
import std.xml;

void main() {
    auto client = new SoapClient("http://10.0.10.2/wsa/wsa1");

    auto payload = new Element("GetDeliveryLines");
    payload ~= new Element("customer", "35754");
    payload ~= new Element("addressNumber", "0");
    payload ~= new Element("daysInThePast", "50");

    // Optionally set a namsepace
    payload.tag.attr["xmlns"] = "urn:acme:orderservice";

    // Optionallpy set SOAP headers
    client.setHeader("user", "john doe");
    client.setHeader("pass", "supersecret");

    client.call("GetDeliveryLine", payload);
    writeln(client.getResult());
}
```
