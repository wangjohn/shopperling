casper = require('casper').create(
  clientScripts: ["../../client/lib/jquery.js"]
  waitTimeout: 10000
)
fs = require('fs')

LINKS = [{productType: "sweaters", url: "http://www.calvinklein.com/shop/en/ck/search/womens-sweaters"},
         {productType: "tops", url: "http://www.calvinklein.com/shop/en/ck/search/womens-knits-tops"}]
BASE_URL = "http://www.calvinklein.com"
DATA_STORAGE_FILENAME = "../data/calvin_klein.json"
data = []

#casper.on 'remote.message', (msg) ->
#  @echo("REMOTE: " + msg)

writeData = (data) ->
  currentFile = require('system').args[3]
  fs.write(DATA_STORAGE_FILENAME, data, "w")

evaluateData = (casper, productType) ->
  casper.then ->
    result = @evaluate (productType, baseUrl) ->
      productContainers = document.querySelectorAll(".product_image.product")
      Array::map.call productContainers, (e) ->
        productType: productType
        productBrand: "Calvin Klein"
        imageUrl: (e.querySelector("img").getAttribute("data-src"))
        productUrl: (e.querySelector("a.productThumbnail").getAttribute("href"))
        productName: $.trim(e.querySelector(".productInfo .title a").innerHTML)
    , { productType: productType, baseUrl: BASE_URL }
    data = data.concat(result)

populateData = (casper) ->
  linkCounter = 0
  while linkCounter < LINKS.length
    casper.thenOpen(LINKS[linkCounter].url)
    casper.waitForSelector("#four-grid")
    evaluateData(casper, LINKS[linkCounter].productType)
    linkCounter += 1

getExtraInformation = (casper, dataObject) ->
  unless (/(13496756|14423249)/.test(dataObject.productUrl))
    casper.thenOpen(dataObject.productUrl)
    casper.then ->
      @echo dataObject.productUrl
    casper.waitForSelector("#product")
    casper.then ->
      newInfo = @evaluate ->
        extraInfo: document.querySelector("#product .hidden-phone .description").innerHTML
        productPrice: (parseInt($.trim(document.querySelector(".product_list span.price:last-of-type").innerHTML).slice(1), 10) * 100)
      @echo newInfo.productPrice
      dataObject.extraInformation = newInfo.extraInfo
      dataObject.productPrice = newInfo.productPrice

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
