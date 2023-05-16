let http = require("http")

let host = '0.0.0.0'
let port = 4000

let server = http.createServer((req, res) => {
    if (req.url === "/quitquitquit") {
        res.writeHead(200, {"Connection":"Close"})
        res.end(() => {
            console.log("closing node server")
            server.close(() => console.log("node server closed"))
        })
    }
    res.writeHead(200,
        // Toggle to display behavior when server properly sets connection header
        // {"Connection": "Close"},
    )
    res.end()
}).listen(port, host, () => {
    console.log(`Server is running on http://${host}:${port}`)
})
