Products = new Meteor.Collection("products")

if Meteor.isClient
  Template.products.products = ->
    Products.find()

if Meteor.isServer
  Meteor.startup ->
    casper = Npm.require("casper").create(
      clientScripts: ["client/lib/jquery.js"]
    )
    fs = Npm.require('fs')

    EVERLANE_URL = "http://www.everlane.com/collections/womens-tees"
    casper.start(EVERLANE_URL)

    casper.on("remote.message", (msg) ->
      @echo(msg)

    products = []

    casper.then ->
      products = @evaluate ->
        productContainers = document.querySelectorAll(".product-image-container")
        console.log(productContainers)
