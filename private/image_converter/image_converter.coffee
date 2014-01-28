gm = require("gm")
fs = require("fs")
path = require("path")
http = require("http")
crypto = require("crypto")

dataDirectory = path.resolve(path.join(__dirname, "../data/"))
imageDirectory = path.resolve(path.join(__dirname, "../../public/images/"))
dataFiles = fs.readdirSync(dataDirectory)

for dataFile in dataFiles
  fs.readFile dataFile, (err, data) ->
    products = JSON.parse(data)
    for product in products
      filename = generateFilename(product)
      download(request(product.productUrl), filename)

generateFilename = (product) ->
  imageDirectory + crypto.randomBytes(16)

download = (path, filename) ->
  http.get(path, (res) ->
    imageData = ""
    res.setEncoding("binary")

    res.on "data", (chunk) ->
      imageData += chunk

    res.on "end", ->
      fs.writeFile filename, imagedata, "binary", (err) ->
        if (err) throw err
        resizeImage (filename)

resizeImage = (filename) ->
  gm(filename)
    .resize(300, 300)
    .write(filename, (err) ->
      if (err) throw err
