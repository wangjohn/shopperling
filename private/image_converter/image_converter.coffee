gm = require("gm")
fs = require("fs")
path = require("path")
http = require("http")
crypto = require("crypto")
async = require("async")

dataDirectory = path.resolve(path.join(__dirname, "../data/"))
imageDirectory = path.resolve(path.join(__dirname, "../../public/images"))
dataFiles = fs.readdirSync(dataDirectory)

generateFilename = ->
  path.join(imageDirectory, crypto.randomBytes(4).readUInt32LE(0) + ".png")

generateTempFilename = ->
  path.join(path.resolve("/tmp"), crypto.randomBytes(4).readUInt32LE(0) + ".png")

download = (path, tempFilename, finalFilename) ->
  writeStream = fs.createWriteStream(tempFilename)
  http.get path, (res) ->
    res.pipe(writeStream)
    res.on "end", ->
      resizeImage(tempFilename, finalFilename)

resizeImage = (tempFilename, finalFilename) ->
  gm(tempFilename)
    .resize(300, 300)
    .gravity("Center")
    .extent(200, 200)
    .stream "png", (err, stdout, stderr) ->
      writeStream = fs.createWriteStream(finalFilename)
      stdout.pipe(writeStream)

readFiles = (dataDirectory, dataFiles) ->
  for dataFile in dataFiles
    filename = path.resolve(path.join(dataDirectory, dataFile))
    data = fs.readFileSync(filename)
    products = JSON.parse(data)
    console.log(products.length)
    for product in products
      convertProduct(product)

    newProducts = JSON.stringify(products)
    fs.writeFileSync(filename, newProducts)
    console.log("WROTE: " + filename)

convertProduct = (product) ->
  tempFilename = generateTempFilename()
  finalFilename = generateFilename()
  download(product.imageUrl, tempFilename, finalFilename)
  product.storageImageFilename = finalFilename
  product

readFiles(dataDirectory, dataFiles)
