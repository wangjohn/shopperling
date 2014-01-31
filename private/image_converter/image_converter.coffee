gm = require("gm")
fs = require("fs")
path = require("path")
http = require("http")
crypto = require("crypto")
async = require("async")

dataDirectory = path.resolve(path.join(__dirname, "../data/"))
imageDirectory = path.resolve(path.join(__dirname, "../../public/images"))
dataFiles = fs.readdirSync(dataDirectory)

generatePngNameStub = ->
  crypto.randomBytes(4).readUInt32LE(0) + ".png"

generateFilename = (nameStub) ->
  path.join(imageDirectory, nameStub)

generateTempFilename = ->
  path.join(path.resolve("/tmp"), crypto.randomBytes(4).readUInt32LE(0) + ".png")

download = (path, tempFilename, finalFilename, cb) ->
  writeStream = fs.createWriteStream(tempFilename)
  http.get path, (res) ->
    res.pipe(writeStream)
    res.on "end", ->
      resizeImage(tempFilename, finalFilename, cb)

resizeImage = (tempFilename, finalFilename, cb) ->
  gm(tempFilename)
    .resize(2000, 2000)
    .gravity("Center")
    .extent(1700, 1700)
    .stream "png", (err, stdout, stderr) ->
      writeStream = fs.createWriteStream(finalFilename)
      stdout.pipe(writeStream)
      stdout.on("end", cb)

readFiles = (dataDirectory, files) ->
  allProducts = []
  newProducts = []
  for dataFile in files
    unless dataFile == "all_products.json"
      filename = path.resolve(path.join(dataDirectory, dataFile))
      data = fs.readFileSync(filename)
      products = JSON.parse(data)
      allProducts = allProducts.concat(products)

  convertProduct(allProducts, newProducts)

convertProduct = (products, newProducts) ->
  console.log(products.length)
  if products.length > 0
    product = products.pop()
    tempFilename = generateTempFilename()
    nameStub = generatePngNameStub()
    finalFilename = generateFilename(nameStub)
    download(product.imageUrl, tempFilename, finalFilename, ->
      product["storageImageFilename"] = nameStub
      newProducts.push(product)
      convertProduct(products, newProducts)
    )
  else
    filename = path.join(dataDirectory, "all_products.json")
    if fs.existsSync(filename)
      previousProducts = JSON.parse(fs.readFileSync(filename))
      allProducts = previousProducts.concat(newProducts)
    else
      allProducts = newProducts
    productsToWrite = JSON.stringify(allProducts)
    console.log(allProducts.length)
    console.log("WRITING TO: " + filename)
    fs.writeFileSync(filename, productsToWrite)

readFiles(dataDirectory, dataFiles)
