Products = new Meteor.Collection("products")

if Meteor.isClient
  Template.products.rows = ->
    allProducts = Products.find()
    NUM_COLS = 4

    rows = []
    count = 0
    column = []
    allProducts.forEach (product) ->
      count = ((count + 1) % NUM_COLS)
      if count == 0
        rows.push({columns: column})
        column = [product]
      else
        column.push(product)

    rows

if Meteor.isServer
  Meteor.startup ->
    fs = Npm.require("fs")
    result = fs.readFileSync(process.env.PWD + "/private/data/everlane.json")
    Products.remove({})
    for product in JSON.parse(result)
      Products.insert(product)
