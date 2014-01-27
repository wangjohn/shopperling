casper = require("casper").create(
  clientScripts: ["client/lib/jquery.js"]
)
fs = require('fs')

EVERLANE_URL = "http://www.everlane.com/collections/womens-tees"
casper.start EVERLANE_URL, ->
  console.log("ASDF")


casper.on("remote.message", (msg) ->
  @echo(msg)
) 

products = []

console.log(EVERLANE_URL)
casper.then ->
  @echo "ASDF"
  console.log(products)
  products = @evaluate ->
    productContainers = document.querySelectorAll(".product-image-container")
    console.log(productContainers)
  console.log(products)
