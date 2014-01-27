Products = new Meteor.Collection("products")
NUM_COLS = 4

if Meteor.isClient
  createRows = (allProducts, numCols) ->
    rows = []
    count = 0
    column = []
    allProducts.forEach (product) ->
      if count > 0 and count % numCols == 0
        rows.push({columns: column})
        column = [product]
      else
        column.push(product)
      count += 1

    rows

  changeActiveStatus = (e) ->
    $(e.currentTarget).closest("ul.dropdown-menu").find(".active").removeClass("active")
    $(e.currentTarget).closest("li").addClass("active")

  Template.products.rows = ->
    allProducts = Products.find({}, {sort: Session.get("productsSortOrder")})
    createRows(allProducts, NUM_COLS)

  Template.sort_by_dropdown.events
    'click .price-lowest-first': (e) ->
      changeActiveStatus(e)
      Session.set("productsSortOrder", {productPrice: 1})
    'click .price-highest-first': (e) ->
      changeActiveStatus(e)
      Session.set("productsSortOrder", {productPrice: -1})

if Meteor.isServer
  Meteor.startup ->
    fs = Npm.require("fs")
    result = fs.readFileSync(process.env.PWD + "/private/data/everlane.json")
    Products.remove({})
    for product in JSON.parse(result)
      Products.insert(product)
