@Products = new Meteor.Collection("products")
NUM_COLS = 4

if Meteor.isClient
  Session.setDefault("productType", "tees")
  Session.setDefault("productsSortOrder", {productPrice: 1})
  Session.setDefault("productBrands", ["Everlane", "Neiman Marcus"])
  Session.set("productCategories", [
    {"active": "active", "productType": "tees", "displayName": "Tees"},
    {"active": "", "productType": "tops", "displayName": "Tops"},
    {"active": "", "productType": "sweaters", "displayName": "Sweaters"}
  ])

  Meteor.Router.add
    "/products/:id": (id) ->
      currentProduct = Products.findOne({"_id": id})
      Session.set("currentProduct", currentProduct)
      "single_product"
    "/:category": (category) ->
      Session.set("productType", category)
      "products"
    "*": ->
      "products"

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

  Deps.autorun ->
    productType = Session.get("productType")
    newCategories = _.map Session.get("productCategories"), (category) ->
      if category.productType == productType
        category.active = "active"
      else
        category.active = ""
      category

    Session.set("productCategories", newCategories)

  Template.banner_categories.categories = ->
    Session.get("productCategories")

  Template.single_product.product = ->
    Session.get("currentProduct")

  Template.products.rows = ->
    findGroup =
      productType: Session.get("productType")
      productPrice: {"$exists": true}
      productBrand: {"$in": Session.get("productBrands")}

    sort =
      sort: Session.get("productsSortOrder")

    allProducts = Products.find(findGroup, sort)
    createRows(allProducts, NUM_COLS)

  Template.products.helpers
    "displayPrice": (number) ->
      "$" + (number / 100).toFixed(0).toString()

  Template.single_product.helpers
    "displayPrice": (number) ->
      "$" + (number / 100).toFixed(2).toString()

  Template.sort_by_dropdown.events
    'click .price-lowest-first': (e) ->
      Session.set("productsSortOrder", {productPrice: 1})
      changeActiveStatus(e, "ul.dropdown-menu", "li")
    'click .price-highest-first': (e) ->
      Session.set("productsSortOrder", {productPrice: -1})
      changeActiveStatus(e, "ul.dropdown-menu", "li")

  Template.filter_dropdown.events
    "click .filter-dropdown": (e) ->
      e.stopPropagation()
    "click input": (e) ->
      brands = []
      $("input.brand-checkbox").each (index, element) ->
        if $(element).prop("checked")
          brands.push($(element).attr("name"))

      Session.set("productBrands", brands)

  Template.banner_categories.events
    "click .categories.tees": (e) ->
      Session.set("productType", "tees")
    "click .categories.sweaters": (e) ->
      Session.set("productType", "sweaters")
    "click .categories.tops": (e) ->
      Session.set("productType", "tops")

if Meteor.isServer

  insertResults = (filename) ->
    result = Assets.getText(filename)
    for product in JSON.parse(result)
      Products.insert(product)

  Meteor.startup ->
    Products.remove({})
    insertResults("data/everlane.json")
    insertResults("data/neiman_marcus.json")
