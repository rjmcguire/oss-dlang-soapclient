module soapclient;

import std.stdio;
import std.xml;
import std.array;
import std.net.curl;

/**
 * A simple client to connect to and interact with SOAP services.
 *
 * License: MIT (cf. LICENSE file)
 * Authors: Jethro Van Thuyne <post@jethro.be>
 * Date: 2016-10-15
 */

class SoapClient {

    immutable string XMLNS_SOAP_ENV = "http://schemas.xmlsoap.org/soap/envelope/";
    immutable string XMLNS_XSI = "http://www.w3.org/2001/XMLSchema-instance";
    immutable string XMLNS_XSD = "http://www.w3.org/2001/XMLSchema";

    private string wsdl;
    private string[string] headers;
    private bool[string] methods;
    private string result;

    private Element doc;
    private Element docHeader;
    private Element docBody;

    /// Construct a new SoapClient instance.
    this(string wsdl) {
        this.wsdl = wsdl;

        this.doc = new Element("SOAP-ENV:Envelope");
        this.docHeader = new Element("SOAP-ENV:Header");
        this.docBody = new Element("SOAP-ENV:Body");

        this.doc.tag.attr["xmlns:SOAP-ENV"] = XMLNS_SOAP_ENV;
        this.doc.tag.attr["xmlns:xsi"] = XMLNS_XSI;
        this.doc.tag.attr["xmlns:xsd"] = XMLNS_XSD;

        this.fetchMethodsFromEndpoint();
    }

    /// Return the endpoint URI the client is connecting to.
    string getEndpoint() {
        return this.wsdl;
    }

    /// Set a header to be sent along when the client calls a method.
    void setHeader(string key, string value) {
        this.headers[key] = value;
        auto header = new Element(key, value);
        this.docHeader ~= header;
    }

    /// Return an associative array of all headers that have been set.
    string[string] getHeaders() {
        return this.headers;
    }

    /// Clear all SOAP headers that may have been set up to this point.
    void clearHeaders() {
        this.docHeader = new Element("soap:Headers");
    }

    /// Return the value of a specific header key.
    string getHeader(string key) {
        return this.headers[key];
    }

    /// Retrieve all available methods from the endpoint.
    private void fetchMethodsFromEndpoint() {
        try {
            auto wsdlFile = cast(string) std.net.curl.get(this.wsdl);
            check(wsdlFile);
            auto xml = new DocumentParser(wsdlFile);

            // Whenever we encounter operation definitions, store their names
            // uniquely as an available method.
            xml.onStartTag["wsdl:operation"] = (ElementParser xml) {
                this.methods[xml.tag.attr["name"]] = true;
            };
            xml.parse();
        } catch (Exception e) {
            writeln("Could not fetch methods from the endpoint.");
            return;
        };
    }

    /// Return an array of available SOAP methods.
    bool[string] getMethods() {
        return this.methods;
    }

    /// Call a specific method on the endpoint, feeding it a valid XML Element.
    void call(string method, Element payload) {
        auto HTTPClient = HTTP();

        this.docBody ~= payload;
        this.doc ~= this.docHeader;
        this.doc ~= this.docBody;
        string doc = "<?xml version=\"1.0\"?>" ~ this.doc.toString();

        try {
            HTTPClient.url = split(this.wsdl, "wsdl?")[0];
            HTTPClient.addRequestHeader("Content-Type", "text/xml;charset=UTF-8");
            HTTPClient.addRequestHeader("SOAPAction", "urn:" ~ method);
            HTTPClient.postData = doc;
            HTTPClient.onReceive = (ubyte[] data) {
                this.result ~= cast(const(char)[])data;
                return data.length;
            };
            HTTPClient.perform();
        } catch (Exception e) {
            writefln("FATAL ERROR %s", e.msg);
            return;
        }
    }

    /// Return the result of our call.
    string getResult() {
        return this.result;
    }
}
