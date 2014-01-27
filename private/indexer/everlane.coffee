casper = require('casper').create(
  clientScripts: ["../../client/lib/jquery.js"]
)
fs = require('fs')

EVERLANE_LINKS = [{productType: "tees", url: "http://www.everlane.com/collections/womens-tees"},
                  {productType: "sweaters", url: "http://www.everlane.com/collections/womens-sweaters"},
                  {productType: "tops", url: "http://www.everlane.com/collections/womens-tops"}]
data = []

writeData = (data) ->
  currentFile = require('system').args[3]
  fs.write("../data/everlane.json", data, "w")

evaluateData = (casper, productType) ->
  casper.then ->
    result = @evaluate (productType) ->
      productContainers = document.querySelectorAll(".product.column")
      Array::map.call productContainers, (e) ->
        productType: productType
        imageUrl: e.querySelector(".product-image-container img").getAttribute("src").slice(2)
        productName: $.trim(e.querySelector(".product-name a").innerHTML)
        productPrice: $.trim(e.querySelector(".product-price").innerHTML)
    , productType
    data = data.concat(result)

populateData = (casper) ->
  linkCounter = 0
  while linkCounter < EVERLANE_LINKS.length
    casper.thenOpen(EVERLANE_LINKS[linkCounter].url)
    casper.waitForSelector(".products")
    evaluateData(casper, EVERLANE_LINKS[linkCounter].productType)
    linkCounter += 1

scrape = (casper) ->
  casper.start()
  populateData(casper)

  casper.then ->
    jsonData = JSON.stringify(data)
    writeData(jsonData)
    @echo jsonData

  casper.run()

scrape(casper)
