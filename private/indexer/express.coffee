casper = require('casper').create(
  clientScripts: ["../../client/lib/jquery.js"]
)
fs = require('fs')

LINKS = [{productType: "sweaters", url: "http://www.express.com/clothing/Women/Sweaters+and+Cardigans/cat/cat2012?viewAll=true"},
         {productType: "tops", url: "http://www.express.com/clothing/Apparel/Tops+and+Tees/cat/cat550015?pageNumber=1&viewAll=true"}]
BASE_URL = "http://www.express.com"
DATA_STORAGE_FILENAME = "../data/express.json"
data = []

casper.on 'remote.message', (msg) ->
  @echo("REMOTE: " + msg)

writeData = (data) ->
  currentFile = require('system').args[3]
  fs.write(DATA_STORAGE_FILENAME, data, "w")

evaluateData = (casper, productType) ->
  casper.then ->
    result = @evaluate (productType, baseUrl) ->
      productContainers = document.querySelectorAll(".cat-thu-product.cat-thu-product-all")
      Array::map.call productContainers, (e) ->
        productType: productType
        productBrand: "Express"
        imageUrl: ("http://" + (e.querySelector(".cat-thu-p-cont img.cat-thu-p-ima").getAttribute("src")).slice(2))
        productUrl: (baseUrl + e.querySelector(".cat-cat-prod-name a").getAttribute("href"))
        productName: $.trim(e.querySelector(".cat-cat-prod-name a").innerHTML)
    , { productType: productType, baseUrl: BASE_URL }
    data = data.concat(result)

populateData = (casper) ->
  linkCounter = 0
  while linkCounter < LINKS.length
    casper.thenOpen(LINKS[linkCounter].url)
    casper.waitForSelector("#glo-body-content")
    evaluateData(casper, LINKS[linkCounter].productType)
    linkCounter += 1

getExtraInformation = (casper, dataObject) ->
  casper.thenOpen(dataObject.productUrl)
  casper.then ->
    newInfo = @evaluate ->
      extraInfo: document.querySelector("#cat-pro-con-detail .cat-pro-desc").innerHTML
      productPrice: (parseInt(document.querySelector(".cat-pro-price span[itemprop='price']").innerHTML, 10) * 100)
    @echo newInfo.productPrice
    dataObject.extraInformation = newInfo.extraInfo
    dataObject.productPrice = newInfo.productPrice

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
