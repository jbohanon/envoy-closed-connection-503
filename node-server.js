let http = require("http")

let host = '0.0.0.0'
let port = 4000

let server = http.createServer((_, res) => {
    res.writeHead(200)
    res.end()
})

server.listen(port, host, () => {
    console.log(`Server is running on http://${host}:${port}`)
})
