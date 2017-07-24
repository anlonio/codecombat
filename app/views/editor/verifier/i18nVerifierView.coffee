RootComponent = require 'views/core/RootComponent'
Problem = require 'views/play/level/tome/Problem'

I18nVerifierComponent = Vue.extend
  template: require('templates/editor/verifier/i18n-verifier-view')()
  data: ->
    language: 'de-DE'
    levelSlug: 'dungeons-of-kithgard'
    startDay: '2017-05-01'
    endDay: '2017-07-30'
    partialThreshold: 0.01
    completeThreshold: 0.34
    me: me
    serverConfig: serverConfig
    problems: []
  created: ->
    @getProblems()
  methods:
    percentDifference: (problem) ->
      (problem.distance / problem.message.length * 100).toFixed(0)
    color: (problem) ->
      diff = problem.distance / problem.message.length
      if diff > @completeThreshold
        return 'green'
      else if diff > @partialThreshold
        return 'yellow'
      else
        return 'red'
    getProblems: ->
      $.post(
        '/db/user.code.problem/-/common_problems',
        {startDay: @startDay, endDay: @endDay, slug: @levelSlug},
        (@problems) =>
          @compareStrings()
      )
    compareStrings: ->
      @problems.forEach (problem) =>
        original = problem.message
        translated = Problem.prototype.translate(problem.message)
        distance = Levenshtein.get(original, translated)
        Vue.set(problem, 'translated', translated)
        Vue.set(problem, 'distance', distance)
      # @problems.sort (a, b) -> a.distance - b.distance

module.exports = class I18nVerifierView extends RootComponent
  id: 'i18n-verifier-view'
  template: require 'templates/base-flat'
  VueComponent: I18nVerifierComponent
  constructor: (options, @courseInstanceID) ->
    @propsData = { @courseInstanceID }
    super options
