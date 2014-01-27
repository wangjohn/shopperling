casper = require('casper').create(
  clientScripts: ["../../client/lib/jquery.js"]
)
fs = require('fs')

EVERLANE_LINK = "http://www.everlane.com/collections/womens-tees"

writeData = (data) ->
  currentFile = require('system').args[3]
  fs.write("../data/everlane.json", data, "w")

data = []

casper.start EVERLANE_LINK

casper.waitForSelector ".products"

casper.then ->
  data = @evaluate ->
    productContainers = document.querySelectorAll(".product.column")
    Array::map.call productContainers, (e) ->
      imageUrl: e.querySelector(".product-image-container img").getAttribute("src").slice(2)
      productName: $.trim(e.querySelector(".product-name a").innerHTML)
      productPrice: $.trim(e.querySelector(".product-price").innerHTML)

casper.then ->
  jsonData = JSON.stringify(data)
  writeData(jsonData)
  @echo jsonData

casper.run ->
  @exit()
