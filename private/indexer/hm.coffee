casper = require('casper').create(
  clientScripts: ["../../client/lib/jquery.js"]
  waitTimeout: 10000
)
fs = require('fs')

LINKS = [{productType: "sweaters", url: "http://www.hm.com/us/subdepartment/LADIES?pageSize=MORE&Nr=4294928033"},
         {productType: "tops", url: "http://www.hm.com/us/subdepartment/LADIES?Nr=4294962278#pageSize=MORE&Nr=4294962278"}]
BASE_URL = "http://www.hm.com"
DATA_STORAGE_FILENAME = "../data/hm.json"
data = []

casper.on 'remote.message', (msg) ->
  @echo("REMOTE: " + msg)

writeData = (data) ->
  currentFile = require('system').args[3]
  fs.write(DATA_STORAGE_FILENAME, data, "w")

evaluateData = (casper, productType) ->
  casper.then ->
    result = @evaluate (productType, baseUrl) ->
      productContainers = document.querySelectorAll("ul#list-products > li")
      console.log(productContainers.length)
      collection = []
      $.each productContainers, (i, e) ->
        price = (e.querySelector(".price span").innerHTML)
        price = (parseInt($.trim(price).slice(1), 10)*100)
        currentResult =
          productType: productType
          productBrand: "H&M"
          imageUrl: ("http:" + e.querySelector("img:last-of-type").getAttribute("src"))
          productUrl: ((e.querySelector("a:first-of-type").getAttribute("href")))
          productName: $.trim(e.querySelector("span.details").innerHTML)
          productPrice: price
        collection.push(currentResult)
      collection
    , { productType: productType, baseUrl: BASE_URL }
    data = data.concat(result)

populateData = (casper) ->
  linkCounter = 0
  while linkCounter < LINKS.length
    casper.thenOpen(LINKS[linkCounter].url)
    casper.waitForSelector("#list-products")
    evaluateData(casper, LINKS[linkCounter].productType)
    linkCounter += 1

getExtraInformation = (casper, dataObject) ->
  casper.thenOpen(dataObject.productUrl)
  casper.then ->
    @echo dataObject.productUrl
  casper.waitForSelector("#content")
  casper.then ->
    newInfo = @evaluate ->
      extraInfo: document.querySelector(".description").innerHTML
    dataObject.extraInformation = newInfo.extraInfo

scrape = (casper) ->
  casper.start()
  populateData(casper)

  casper.then ->
    @echo data.length
    @echo "GETTING EXTRA INFORMATION"
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
