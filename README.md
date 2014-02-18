Password-free Token Communication Protocol (PfTC) is for passing an authentication token from a server to a client via a zero-knowledge intermediary without entering any information on the client, for use on devices that input is cumbersome or keylogger-proof short-term authentication is desired.

===Prereqs/Assumptions
* Server is assigned an unique ID.
* Server has generated a private key and shared the corresponding public key with the client out-of-band.
* Server has generated an oauth token to be passed to the mobile client.
* Client has a cryptographically secure key generator.
*Intermediary is untrusted.
* User is authenticated with the server already on some device that is capable of input.

===Client Procedure
1. Client generates a session keypair.
2. Client encrypts the public session key with the server’s public key.
3. Client opens an SSL websocket to the intermediary and submits the encrypted session key, client app ID, and any desired metadata, and receives back a ticket number. (Webhooks can also be used if the client is internet routable)
4. Client communicates the ticket number to the user and then waits.
5. Client will receive the oauth token to use encrypted with the public session key from the intermediary.

===Server Procedure
1. The user communicates to the server the ticket number their client gives them.
2. The server then does a GET with the ticket number and receives the encrypted session public key from the intermediary along with any optional metadata. (Authentication could be wrapped around this step but is not required)
3. The server decrypts the session public key with their server private key then encrypts the client’s token with the session public key.
4. The encrypted token is POSTed to the intermediary along with the ticket number and returns success if it successfully is received and verified by the client.

