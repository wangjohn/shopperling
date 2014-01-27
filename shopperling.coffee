Products = new Meteor.Collection("products")

if Meteor.isClient
  Template.products.products = ->
    Products.find()

if Meteor.isServer
  Meteor.startup ->
    sys = Npm.require("sys")
    console.log("HELLO")
    #sys.exec("casperjs test everlane.coffee")
