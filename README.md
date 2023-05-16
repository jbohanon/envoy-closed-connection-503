This repo is used to demonstrate behavior whereby under heavy load against an upstream server
which will close connections without returning the `Connection: Close` header will experience
intermittent 503 responses. This is because Envoy has already reassigned the connection for reuse
when the FIN packet comes through and the socket is closed. This is a consequence of the highly
performant connection reuse algorithm employed by Envoy and upstream servers which do not
appropriately indicate their intention to terminate a connection.

This repo can be used to demonstrate the following:
- Intermittent 503 responses when requests are made against upstream which doesn't include `Connection: Close` in responses
- Configuring retries somewhat mitigates the issue, but inconsistently (see `retry_policy` block in `envoy.yaml`
- Increasing Envoy's concurrency parameter somewhat mitigates the issue, but might have other performance implications
- Configuring the injection of `Connection: Close` into each request to the upstream server eliminates this issue
  - See `request_headers_to_add` block in `envoy.yaml`
  - This works because of the way the node standard http library handles requests. Express uses the node http lib
- Configuring the upstream server to include `Connection: Close` in its response eliminates this issue

It is a bug in the upstream server that it will terminate connections without informing Envoy. This
could be a consequence of the performance of a node server vs Envoy moreso than a bug in the
application code itself of the upstream server, but nevertheless this is not considered a bug in Envoy.

The script `get-deps-and-run-test.sh` may be run from a Linux machine with `curl`.
It must be run from the root of the repo. Environment variable `CLEANUP` may be used
to automatically clean the executable dependencies, logs, or both.

```bash
git clone https://github.com/jbohanon/envoy-closed-connection-503.git

cd envoy-closed-connection-503

# Delete all added files after running the test
CLEANUP=ALL ./get-deps-and-run-test.sh

# Delete downloaded dependencies after running the test but leave logs and stats
CLEANUP=DEPS ./get-deps-and-run-test.sh

# Delete logs and stats after running the test but leave downloaded dependencies (the deps will not be downloaded again on subsequent runs)
CLEANUP=LOGS ./get-deps-and-run-test.sh
```
