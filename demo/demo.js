#!/usr/bin/env -S node --perf-basic-prof
// Magic-trace requires a map of JIT-ed symbols, which node will
// generate if you provide --perf-basic-prof.

// Spams HTTP requests to an HTTP server. One connection, one request in flight at all times.
const http = require('http');
const PORT = 40210

function req(req, resp) {
   resp.end()
}

server = http.createServer(req);
server.listen(PORT);

const options = { host: '127.0.0.1', method: 'GET', path: '/', port: PORT }

const reqloop = () => {
   var request = http.request(options, (response) => reqloop())
   request.end()
};

reqloop();
