Products = new Meteor.Collection("products")
NUM_COLS = 4

if Meteor.isClient
  Meteor.startup ->
    Session.setDefault("productType", "tees")
    Session.setDefault("productsSortOrder", {productPrice: 1})

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

  changeActiveStatus = (e, majorContainer, minorContainer) ->
    $(e.currentTarget).closest(majorContainer).find(".active").removeClass("active")
    $(e.currentTarget).closest(minorContainer).addClass("active")

  Template.products.rows = ->
    allProducts = Products.find({'productType': Session.get("productType")},
      {sort: Session.get("productsSortOrder")})
    createRows(allProducts, NUM_COLS)

  Template.products.helpers
    "displayPrice": (number) ->
      "$" + (number / 100).toFixed(0).toString()

  Template.sort_by_dropdown.events
    'click .price-lowest-first': (e) ->
      Session.set("productsSortOrder", {productPrice: 1})
      changeActiveStatus(e, "ul.dropdown-menu", "li")
    'click .price-highest-first': (e) ->
      Session.set("productsSortOrder", {productPrice: -1})
      changeActiveStatus(e, "ul.dropdown-menu", "li")

  Template.banner_categories.events
    "click .categories.tees": (e) ->
      Session.set("productType", "tees")
      changeActiveStatus(e, "ul.nav.navbar-nav", "li")
    "click .categories.sweaters": (e) ->
      Session.set("productType", "sweaters")
      changeActiveStatus(e, "ul.nav.navbar-nav", "li")
    "click .categories.tops": (e) ->
      Session.set("productType", "tops")
      changeActiveStatus(e, "ul.nav.navbar-nav", "li")

if Meteor.isServer
  fs = Npm.require("fs")

  insertResults = (filename) ->
    result = fs.readFileSync(process.env.PWD + filename)
    for product in JSON.parse(result)
      Products.insert(product)

  Meteor.startup ->
    Products.remove({})
    insertResults("/private/data/everlane.json")
    insertResults("/private/data/neiman_marcus.json")
