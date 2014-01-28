casper = require('casper').create(
  clientScripts: ["../../client/lib/jquery.js"]
)
fs = require('fs')

EVERLANE_LINKS = [{productType: "tees", url: "http://www.everlane.com/collections/womens-tees"},
                  {productType: "sweaters", url: "http://www.everlane.com/collections/womens-sweaters"},
                  {productType: "tops", url: "http://www.everlane.com/collections/womens-tops"}]
EVERLANE_BASE_URL = "http://www.everlane.com"
data = []
extraInformation = {}

writeData = (data) ->
  currentFile = require('system').args[3]
  fs.write("../data/everlane.json", data, "w")

evaluateData = (casper, productType) ->
  casper.then ->
    result = @evaluate (productType, baseUrl) ->
      productContainers = document.querySelectorAll(".product.column")
      Array::map.call productContainers, (e) ->
        productType: productType
        productBrand: "Everlane"
        imageUrl: ("http://" + e.querySelector(".product-image-container img").getAttribute("src").slice(2))
        productUrl: (baseUrl + e.querySelector(".main-product-link").getAttribute("href"))
        productName: $.trim(e.querySelector(".product-name a").innerHTML)
        productPrice: parseInt($.trim(e.querySelector(".product-price").innerHTML).slice(1), 10) * 100
    , { productType: productType, baseUrl: EVERLANE_BASE_URL }
    data = data.concat(result)

populateData = (casper) ->
  linkCounter = 0
  while linkCounter < EVERLANE_LINKS.length
    casper.thenOpen(EVERLANE_LINKS[linkCounter].url)
    casper.waitForSelector(".products")
    evaluateData(casper, EVERLANE_LINKS[linkCounter].productType)
    linkCounter += 1

getExtraInformation = (casper, dataObject) ->
  casper.thenOpen(dataObject.productUrl)
  casper.then ->
    extraInfo = @evaluate ->
      document.querySelector(".product-description-footer").innerHTML
    console.log("BLAH")
    dataObject.extraInformation = extraInfo

scrape = (casper) ->
  casper.start()
  populateData(casper)

  casper.then ->
    for datum in data
      getExtraInformation(casper, datum)

  casper.then ->
    jsonData = JSON.stringify(data)
    writeData(jsonData)
    @echo jsonData

  casper.then ->
    @exit()

  casper.run()

scrape(casper)
