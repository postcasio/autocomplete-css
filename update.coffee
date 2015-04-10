# Run this to update the static list of properties stored in the properties.json
# file at the root of this repository.

path = require 'path'
fs = require 'fs'
request = require 'request'
_ = require 'lodash'

propertiesRequestOptions =
  url: 'https://raw.githubusercontent.com/adobe/brackets/master/src/extensions/default/CSSCodeHints/CSSProperties.json'
  json: true

popularityRequestOptions =
  url: 'https://www.chromestatus.com/data/csspopularity'
  json: true

request propertiesRequestOptions, (error, response, properties) ->
  if error?
    console.error(error.message)
    return process.exit(1)

  if response.statusCode isnt 200
    console.error("Request for CSSProperties.json failed: #{response.statusCode}")
    return process.exit(1)

  request popularityRequestOptions, (error, response, popularity) ->
    if error?
      console.error(error.message)
      return process.exit(1)

    if response.statusCode isnt 200
      console.error("Request for popularity JSON failed: #{response.statusCode}")
      return process.exit(1)

    sortedPopularity = _.pluck(_.sortByOrder(popularity, 'day_percentage', false), 'property_name')

    sortedPropertyNames = Object.keys(properties).sort (a, b) ->
      aIndex = sortedPopularity.indexOf(a)
      bIndex = sortedPopularity.indexOf(b)
      if aIndex < 0 and bIndex < 0
        return 0
      else if aIndex < 0 or aIndex > bIndex
        return 1
      else if bIndex < 0 or aIndex < bIndex
        return -1
      return 0

    sortedProperties = {}
    for propertyName in sortedPropertyNames
      sortedProperties[propertyName] = properties[propertyName]

    fs.writeFileSync(path.join(__dirname, 'properties.json'), "#{JSON.stringify(sortedProperties, null, 0)}\n")
