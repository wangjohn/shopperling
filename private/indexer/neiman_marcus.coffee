casper = require('casper').create(
  clientScripts: ["../../client/lib/jquery.js"]
)
fs = require('fs')

LINKS = [{productType: "sweaters", url: "http://www.neimanmarcus.com/Womens-Clothing/Sweaters/cat41160752_cat17740747_cat000001/c.cat"},
         {productType: "tops", url: "http://www.neimanmarcus.com/Womens-Clothing/Tops/cat42960827_cat17740747_cat000001/c.cat?fromDrawer=true"}]
BASE_URL = "http://www.neimanmarcus.com"
DATA_STORAGE_FILENAME = "../data/neiman_marcus.json"
data = []

casper.on 'remote.message', (msg) ->
  @echo("REMOTE: " + msg)

writeData = (data) ->
  currentFile = require('system').args[3]
  fs.write(DATA_STORAGE_FILENAME, data, "w")

evaluateData = (casper, productType) ->
  casper.then ->
    result = @evaluate (productType, baseUrl) ->
      productContainers = document.querySelectorAll(".products .product")
      Array::map.call productContainers, (e) ->
        highlightedPrice = e.querySelector(".allpricing .priceadorn.highlight .price")
        if highlightedPrice
          price = highlightedPrice.innerHTML
        else
          price = e.querySelector(".allpricing").innerHTML
        price = parseInt($.trim(price).slice(1), 10) * 100

        productType: productType
        productBrand: "Neiman Marcus"
        imageUrl: e.querySelector(".productImageContainer img").getAttribute("src")
        productUrl: (baseUrl + e.querySelector(".productImageContainer a.prodImgLink").getAttribute("href"))
        productName: $.trim(e.querySelector(".productname a").innerHTML)
        productPrice: price
    , { productType: productType, baseUrl: BASE_URL }
    data = data.concat(result)

populateData = (casper) ->
  linkCounter = 0
  while linkCounter < LINKS.length
    casper.thenOpen(LINKS[linkCounter].url)
    casper.waitForSelector(".products")
    evaluateData(casper, LINKS[linkCounter].productType)
    linkCounter += 1

getExtraInformation = (casper, dataObject) ->
  casper.thenOpen(dataObject.productUrl)
  casper.then ->
    extraInfo = @evaluate ->
      document.querySelector("#productDetails .cutline.short").innerHTML
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
