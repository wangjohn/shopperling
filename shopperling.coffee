Products = new Meteor.Collection("products")
Aggregates = new Meteor.Collection("aggregates")
NUM_COLS = 4

if Meteor.isClient
  Session.setDefault("productType", "tops")
  Session.setDefault("productsSortOrder", {numClicks: -1})
  Session.setDefault("productBrands", ["Banana Republic", "Calvin Klein", "Everlane", "Express", "H&M", "Neiman Marcus"])
  Session.setDefault("productPriceRanges", [1,2,3,4])
  Session.setDefault("queryLimit", 20)
  Session.setDefault("productCategories", [
    {"active": "active", "productType": "tops", "displayName": "Tops"},
    {"active": "", "productType": "sweaters", "displayName": "Sweaters"},
    {"active": "", "productType": "tees", "displayName": "Tees"}
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
    Session.set("queryLimit", 20)
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
    ptype = Session.get("productType")
    aggregates = Aggregates.findOne({"productType": ptype})

    priceRangeQuery = _.map Session.get("productPriceRanges"), (range) ->
      lower = if range > 1 then aggregates[range-1] else 0
      query = {"$gte": lower}
      if range < 4
        query["$lt"] = aggregates[range]
      { productPrice: query }

    if priceRangeQuery.length > 0
      findGroup =
        productType: ptype
        productPrice: {"$exists": true}
        productBrand: {"$in": Session.get("productBrands")}
        $or: priceRangeQuery

      secondaryGroup =
        sort: Session.get("productsSortOrder")
        limit: Session.get("queryLimit")

      allProducts = Products.find(findGroup, secondaryGroup)
      createRows(allProducts, NUM_COLS)
    else
      []

  Template.products.created = ->
    didScroll = false
    $win = $(window)

    $win.scroll ->
      didScroll = true

    setInterval ->
      if didScroll
        didScroll = false
        if ($win.height() + $win.scrollTop() > ($(document).outerHeight()-500))
          Session.set("queryLimit", Session.get("queryLimit") + 20)
    , 200

  Template.products.events
    "click .product-link": (e) ->
      productId = $(e.currentTarget).attr("data-target")
      Products.update({"_id": productId}, {$inc: {numClicks: 1}})

  Template.products.helpers
    "displayPrice": (number) ->
      "$" + (number / 100).toFixed(0).toString()
    "lowerCase": (string) ->
      string.toLowerCase()

  Template.single_product.helpers
    "displayPrice": (number) ->
      "$" + (number / 100).toFixed(2).toString()

  Template.sort_by_dropdown.events
    "click .most-popular": (e) ->
      Session.set("productsSortOrder", {numClicks: -1})
      changeActiveStatus(e, "ul.dropdown-menu", "li")
    "click .price-lowest-first": (e) ->
      Session.set("productsSortOrder", {productPrice: 1})
      changeActiveStatus(e, "ul.dropdown-menu", "li")
    "click .price-highest-first": (e) ->
      Session.set("productsSortOrder", {productPrice: -1})
      changeActiveStatus(e, "ul.dropdown-menu", "li")

  Template.filter_dropdown.events
    "click .filter-dropdown": (e) ->
      e.stopPropagation()
    "click input.brand-checkbox": (e) ->
      brands = []
      $("input.brand-checkbox").each (index, element) ->
        if $(element).prop("checked")
          brands.push($(element).attr("name"))
      Session.set("productBrands", brands)
    "click input.price-checkbox": (e) ->
      ranges = []
      $("input.price-checkbox").each (index, element) ->
        if $(element).prop("checked")
          range = parseInt($(element).attr("range"), 10)
          ranges.push(range)
      Session.set("productPriceRanges", ranges)

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
      product.numClicks = 0
      Products.insert(product)

  computeAggregates = ->
    groupedProducts = {}
    Aggregates.remove({})
    Products.find({}, {sort: {productType: 1, producePrice: 1}}).forEach (product) ->
      groupedProducts[product.productType] ?= []
      groupedProducts[product.productType].push(product.productPrice)

    _.each _.keys(groupedProducts), (key) ->
      currentGroup = groupedProducts[key]
      currentGroup = _.sortBy(currentGroup, (num) -> num)
      count = currentGroup.length

      aggregates =
        productType: key
        1: currentGroup[Math.floor(0.25*count)]
        2: currentGroup[Math.floor(0.5*count)]
        3: currentGroup[Math.floor(0.75*count)]
      console.log(aggregates)
      Aggregates.insert(aggregates)

  Meteor.startup ->
    #Products.remove({})
    #insertResults("data/all_products.json")
    #computeAggregates()


