casper = require('casper').create(
  clientScripts: ["../../client/lib/jquery.js"]
  waitTimeout: 10000
)
fs = require('fs')

LINKS = [{productType: "sweaters", url: "http://bananarepublic.gap.com/browse/category.do?cid=5032&departmentRedirect=true#department=136"},
         {productType: "tops", url: "http://bananarepublic.gap.com/browse/category.do?cid=5040&departmentRedirect=true#department=136"}]
BASE_URL = "http://bananarepublic.gap.com"
DATA_STORAGE_FILENAME = "../data/banana_republic.json"
data = []

casper.on 'remote.message', (msg) ->
  @echo("REMOTE: " + msg)

writeData = (data) ->
  currentFile = require('system').args[3]
  fs.write(DATA_STORAGE_FILENAME, data, "w")

evaluateData = (casper, productType) ->
  casper.then ->
    result = @evaluate (productType, baseUrl) ->
      productContainers = document.querySelectorAll(".productCatItem")
      collection = []
      $.each productContainers, (i, e) ->
        if e.querySelector("span.priceDisplaySale")
          price = e.querySelector("span.priceDisplaySale").innerHTML
        else
          price = e.querySelector("span.priceDisplay").innerHTML
        price = (parseInt($.trim(price).slice(1), 10)*100)
        currentResult =
          productType: productType
          productBrand: "Banana Republic"
          imageUrl: (e.querySelector("img.gridProdImg").getAttribute("src"))
          productUrl: (baseUrl + (e.querySelector("a.productItemName").getAttribute("href")))
          productName: $.trim(e.querySelector("a.productItemName").innerHTML)
          productPrice: price
        collection.push(currentResult)
      collection
    , { productType: productType, baseUrl: BASE_URL }
    data = data.concat(result)

populateData = (casper) ->
  linkCounter = 0
  while linkCounter < LINKS.length
    casper.thenOpen(LINKS[linkCounter].url)
    casper.waitForSelector(".categoryFacetedSearch")
    evaluateData(casper, LINKS[linkCounter].productType)
    linkCounter += 1

getExtraInformation = (casper, dataObject) ->
  casper.thenOpen(dataObject.productUrl)
  casper.then ->
    @echo dataObject.productUrl
  casper.waitForSelector("#mainContent")
  casper.then ->
    newInfo = @evaluate ->
      extraInfo: document.querySelector("#tabWindow").innerHTML
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
