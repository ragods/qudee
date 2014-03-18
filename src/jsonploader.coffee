
#window['receive_asset'] = (asset) -> console.log 'window receive asset',asset

Floorplan = require './floorplan'
{maskFlip} = require './utils'
{Promise} = require 'es6-promise'

imageLoadedCounter = null
imageCounter = null
jsonpCounter = null
jsonCache = {}

drawAllInCache = ->
  scene = Floorplan.get()
  for k,v of PIXI.TextureCache
    sprite =  new PIXI.Sprite.fromImage(k)
    scene.assetContainer.addChild(sprite)

getJSON = (url, data, callback) ->
  head = document.getElementsByTagName("head")[0]
  newScript = document.createElement 'script'
  newScript.type = 'text/javascript'
  newScript.src = url
  head.appendChild newScript

onImageLoaded = ->
  imageLoadedCounter += 1
  if imageLoadedCounter >= imageCounter
    console.log 'done loading all assets'
    createShapesForAllColorAssets()

newJSONP2 = (url) ->
  getJSON url, {}, window.receive_asset = (asset) ->
    jsonCache[asset.id] = asset
    jsonpCounter -= 1

    if jsonpCounter <= 0
      console.log 'done with loading jsonp.'
      for k,v of jsonCache
        if v.under
          imageCounter += 1
          createImage v.under, k+".under", onImageLoaded
        if v.color
          imageCounter += 1
          createImage v.color, k+".color", onImageLoaded
        if v.over
          imageCounter += 1
          createImage v.over, k+".over", onImageLoaded

createImage = (data, id, onLoad) ->
  image = new Image()
  image.onload = ->
    #console.log id
    baseTexture = new PIXI.BaseTexture image
    texture = new PIXI.Texture baseTexture
    PIXI.Texture.addTextureToCache texture, id
    onLoad()
  image.src = data

createShapesForAllColorAssets = ->
  colorKeys = (k for k,v of PIXI.TextureCache when endsWith k, '.color')
  shapeCount = colorKeys.length
  count = 0
  for k in colorKeys
    shapeImage = maskFlip PIXI.TextureCache[k].baseTexture
    createImage shapeImage, k.replace('.color','.shape'), ->
      count += 1
      if count >= shapeCount
        console.log 'done creating shapes.'
        jsonCache = {}
        drawAllInCache()
        
endsWith = (str, suffix) ->
    str.indexOf(suffix, str.length - suffix.length) isnt -1

module.exports.loadJSONPAssets = (urlArray) ->
  jsonpCounter = urlArray.length
  urlArray.map newJSONP2
