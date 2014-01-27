if Meteor.isClient
  Products = new Meteor.Collection("products")
  Template.products.products = ->
    Products.find()

if Meteor.isServer
  Meteor.startup ->
    console.log("starting up")
