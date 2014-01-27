casper = require('casper').create(
  clientScripts: ["../../client/lib/jquery.js"]
)

EVERLANE_LINK = "http://www.everlane.com/collections/womens-tees"

data = []

casper.start EVERLANE_LINK, ->
  @echo "ASDF"

casper.waitForSelector ".products"

casper.then ->
  data = @evaluate ->
    productContainers = document.querySelectorAll(".product.column")
    Array::map.call productContainers, (e) -> 
      imageUrl: e.querySelector(".product-image-container img").getAttribute("src")
      productName: $.trim(e.querySelector(".product-name a").innerHTML)
      productPrice: $.trim(e.querySelector(".product-price").innerHTML)

casper.run ->
  @echo JSON.stringify(data)
