let http = require("http")

let host = '0.0.0.0'
let port = 4000

let server = http.createServer((_, res) => {
    res.writeHead(200,
        // Toggle to display behavior when server properly sets connection header
        // {"Connection": "Close"},
    )
    res.end()
})

server.listen(port, host, () => {
    console.log(`Server is running on http://${host}:${port}`)
})
