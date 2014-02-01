Products = new Meteor.Collection("products")
Payments = new Meteor.Collection("payments")
NUM_COLS = 4
QUERY_LIMIT_BLOCK_SIZE = 12
AGGREGATES =
  sweaters: { '1': 3400, '2': 5900, '3': 7900 }
  tees: { '1': 1500, '2': 1500, '3': 2000 }
  tops: { '1': 2400, '2': 3900, '3': 5000 }
IMAGE_BASE_URL = "https://dl.dropboxusercontent.com/spa/lo1br4efvfb305a/dressly/public/"

if Meteor.isClient
  Session.setDefault("productType", "")
  Session.setDefault("productsSortOrder", [["numClicks", "desc"], "productPrice", "$natural"])
  Session.setDefault("productBrands", ["Banana Republic", "Calvin Klein", "Everlane", "Express", "H&M", "Neiman Marcus"])
  Session.setDefault("productPriceRanges", [1,2,3,4])
  Session.setDefault("queryLimit", QUERY_LIMIT_BLOCK_SIZE)
  Session.setDefault("productCategories", [
    {"productType": "sales", "displayName": "Sales"},
    {"productType": "tops", "displayName": "Tops"},
    {"productType": "sweaters", "displayName": "Sweaters"},
    {"productType": "tees", "displayName": "Tees"}
  ])
  Session.setDefault("loadComments", false)

  Meteor.Router.add
    "/products/:id": (id) ->
      currentProduct = Products.findOne({"_id": id})
      Session.set("currentProduct", currentProduct)
      "single_product"
    "/:category": (category) ->
      Session.set("productType", category)
      "products"
    "*": ->
      "landing_page"

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
    console.log("changing active status")
    $(e.currentTarget).closest(majorContainer).find(".active").removeClass("active")
    $(e.currentTarget).closest(minorContainer).addClass("active")

  activeProductClass = (productType) ->
    if productType == Session.get("productType") then "active" else ""

  getStoredImageUrl = (fileStub) ->
    IMAGE_BASE_URL + fileStub

  Deps.autorun ->
    if Session.get("loadComments") && !window.DISQUS
      disqus_shortname = "dressly"
      (->
        dsq = document.createElement("script")
        dsq.type = "text/javascript"
        dsq.async = true
        dsq.src = "//" + disqus_shortname + ".disqus.com/embed.js"
        (document.getElementsByTagName("head")[0] or document.getElementsByTagName("body")[0]).appendChild dsq
      )()

  Template.banner_categories.categories = ->
    categories = []
    _.each Session.get("productCategories"), (category) ->
      categories.push
        productType: category.productType
        displayName: category.displayName
        active: activeProductClass(category.productType)
    categories

  Template.banner.events
    "click .title-span": (e) ->
      window.location.href = "/"

  Template.single_product.product = ->
    Session.get("currentProduct")

  Template.products.rows = ->
    ptype = Session.get("productType")
    ranges = Session.get("productPriceRanges")

    findGroup =
      productType: ptype
      productPrice: {"$exists": true}
      productBrand: {"$in": Session.get("productBrands")}

    if ranges.length > 0
      if ranges.length < 4
        aggregates = AGGREGATES[ptype]
        priceRangeQuery = _.map ranges, (range) ->
          lower = if range > 1 then aggregates[range-1] else 0
          query = {"$gte": lower}
          if range < 4
            query["$lt"] = aggregates[range]
          { productPrice: query }
        findGroup["$or"] = priceRangeQuery

      secondaryGroup =
        sort: Session.get("productsSortOrder")
        limit: Session.get("queryLimit")

      allProducts = Products.find(findGroup, secondaryGroup)
      createRows(allProducts, NUM_COLS)
    else
      []

  Template.comments.rendered = ->
    Session.set("loadComments", true)
    DISQUS?.reset
      reload: true
      config: ->

  Template.products.created = ->
    didScroll = false
    $win = $(window)

    $win.scroll ->
      didScroll = true

    setInterval ->
      if didScroll
        didScroll = false
        if ($win.height() + $win.scrollTop() > ($(document).outerHeight()-300))
          Session.set("queryLimit", Session.get("queryLimit") + QUERY_LIMIT_BLOCK_SIZE)
    , 200

  Template.purchase_button.events
    "click .purchase": (e) ->
      e.preventDefault()
      target = $(e.currentTarget)

      productName = target.attr("data-product-name")
      price = target.attr("data-product-price")
      description = target.attr("data-product-description")
      image = target.attr("data-product-image")
      StripeCheckout.open
        key: "pk_live_V6R4efzM6kAcrgwq8rDti1Qs"
        amount: price
        name: productName
        image: image
        description: description
        shippingAddress: true
        billingAddress: true
        token: (res) ->
          Payments.insert(res)
          window.location.href = "/"

  Template.products.events
    "click .product-link": (e) ->
      productId = $(e.currentTarget).attr("data-target")
      Products.update({"_id": productId}, {$inc: {numClicks: 1}})

  Template.products.helpers
    "displayPrice": (number) ->
      "$" + (number / 100).toFixed(0).toString()
    "lowerCase": (string) ->
      string.toLowerCase()
    "getStoredImageUrl": (fileStub) ->
      getStoredImageUrl(fileStub)
    "productType": ->
      Session.get("productType")
    "showSaleBanner": ->
      Session.get("productType") == "sales"

  Template.google_analytics.rendered = ->
    if !window._gaq?
      window._gaq = []
      _gaq.push(['_setAccount', 'UA-34139010-4'])
      _gaq.push(['_trackPageview'])

      (->
        ga = document.createElement('script')
        ga.type = 'text/javascript'
        ga.async = true
        gajs = '.google-analytics.com/ga.js'
        ga.src = if 'https:' is document.location.protocol then 'https://ssl'+gajs else 'http://www'+gajs
        s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s)
      )()

  Template.single_product.helpers
    "displayPrice": (number) ->
      "$" + (number / 100).toFixed(2).toString()
    "getStoredImageUrl": (fileStub) ->
      getStoredImageUrl(fileStub)

  Template.sort_by_dropdown.events
    "click .most-popular": (e) ->
      Session.set("productsSortOrder", [["numClicks", "desc"], "productPrice", "$natural"])
      changeActiveStatus(e, "ul.dropdown-menu", "li")
    "click .price-lowest-first": (e) ->
      Session.set("productsSortOrder", ["productPrice", "$natural"])
      changeActiveStatus(e, "ul.dropdown-menu", "li")
    "click .price-highest-first": (e) ->
      Session.set("productsSortOrder", [["productPrice", "desc"], "$natural"])
      changeActiveStatus(e, "ul.dropdown-menu", "li")

  Template.filter_dropdown.events
    "click .filter-dropdown": (e) ->
      e.stopPropagation()
    "click input.brand-checkbox": (e) ->
      console.log("changing brands")
      brands = []
      $("input.brand-checkbox").each (index, element) ->
        if $(element).prop("checked")
          brands.push($(element).attr("name"))
      Session.set("productBrands", brands)
    "click input.price-checkbox": (e) ->
      console.log("changing prices")
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

  Meteor.startup ->
    Products.remove({})
    insertResults("data/all_products.json")


