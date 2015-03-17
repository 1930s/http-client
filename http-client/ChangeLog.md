## 0.4.9

* Add RequestBody smart constructors `streamFile` and `streamFileObserved`, the latter with accompanying type `StreamFileStatus`.

## 0.4.8.1

* Automatically call withSocketsDo everywhere [#107](https://github.com/snoyberg/http-client/issues/107)

## 0.4.8

* Add the `ResponseLengthAndChunkingBothUsed` exception constructor [#108](https://github.com/snoyberg/http-client/issues/108)

## 0.4.7.2

* Improved `timeout` implementation for high contention cases [#98](https://github.com/snoyberg/http-client/issues/98)

## 0.4.7.1

* Fix for shared connections in proxy servers [#103](https://github.com/snoyberg/http-client/issues/103)

## 0.4.7

* [Support http\_proxy and https\_proxy environment variables](https://github.com/snoyberg/http-client/issues/94)

## 0.4.6.1

Separate tests not requiring internet access. [#93](https://github.com/snoyberg/http-client/pull/93)

## 0.4.6

Add `onRequestBodyException` to `Request` to allow for recovering from
exceptions when sending the request. Most useful for servers which terminate
the connection after sending a response body without flushing the request body.

## 0.4.5

Add `openSocketConnectionSize` and increase default chunk size to 8192.

## 0.4.4

Add `managerModifyRequest` field to `ManagerSettings`.

## 0.4.3

Add `requestVersion` field to `Request`.

## 0.4.2

The reaper thread for a manager will go to sleep completely when there are no connection to manage. See: https://github.com/snoyberg/http-client/issues/70

## 0.4.1

* Provide the `responseOpenHistory`/`withResponseHistory` API. See: https://github.com/snoyberg/http-client/pull/79

## 0.4.0

* Hide the `Part` constructor, and allow for additional headers. See: https://github.com/snoyberg/http-client/issues/76
