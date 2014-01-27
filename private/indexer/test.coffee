casper = require('casper').create()

EVERLANE_LINK = "https://www.everlane.com/collections/womens-tees"

casper.start EVERLANE_LINK

casper.waitForSelector ".products"

casper.then ->
  imageLinks = @evaluate ->
    productContainers = document.querySelectorAll(".product-image-container")
    Array::map.call productContainers, (element) ->
      imageUrl: element.querySelector("img").getAttribute("src")
      productName: element.querySelector(".product-name").innerHTML
      productPrice: element.querySelector(".product-price").innerHTML

  @echo imageLinks

casper.run
