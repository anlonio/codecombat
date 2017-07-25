RootComponent = require 'views/core/RootComponent'
Problem = require 'views/play/level/tome/Problem'

I18nVerifierComponent = Vue.extend
  template: require('templates/editor/verifier/i18n-verifier-view')()
  data: ->
    language: 'en'
    levelSlug: _.last(location.href.split('/'))
    startDay: '2017-05-01'
    endDay: '2017-07-30'
    partialThreshold: 1
    completeThreshold: 70
    countThreshold: 0
    totalCount: 0
    me: me
    serverConfig: serverConfig
    problems: []
    regexes: []
    otherRegexes: []
    displayMode: 'export'
    showCampaigns: false
    showLevels: false
    campaigns: []
    selectedCampaign: null
  computed:
    exportList: ->
      _(@problems).filter((p) =>
        @percentDifference(p) < @completeThreshold and not /\n/.test(p.trimmed) and (p.count / @totalCount) >= (@countThreshold / 100))
      .uniq((p) -> p.trimmed)
      .value()
  created: ->
    i18n.setLng(@language)
    @loadCampaigns()
    @setupRegexes()
    @getProblems()
  methods:
    loadCampaigns: ->
      $.get(
        '/db/campaign',
        (@campaigns) =>
          @selectedCampaign = _.find(@campaigns, (c) -> c.name is "Dungeon")
          for campaign in @campaigns
            Vue.set(campaign, 'levelsArray', Object.values(campaign.levels))
      )
    escapeRegExp: (str) ->
      # https://stackoverflow.com/questions/3446170/escape-string-for-use-in-javascript-regex
      return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")
    setupRegexes: ->
      en = require('locale/en').translation
      require('locale/de-DE')
      otherLang = require('locale/'+@language).translation
      translationKeys = Object.keys(en.esper)
      for translationKey in translationKeys
        englishString = en.esper[translationKey]
        regex = new RegExp(@escapeRegExp(englishString).replace(/\\\$\d|`\\\$\d`/g, '(`[\\d\\w.:\'" ]+`|[\\d\\w.:\'" ]+)').replace(/\s+/g, '\\s+'))
        @regexes.push(regex)
      for translationKey in translationKeys
        otherString = otherLang.esper[translationKey] or ''
        otherRegex = new RegExp(@escapeRegExp(otherString).replace(/\\\$\d|`\\\$\d`/g, '(`[\\d\\w.:\'" ]+`|[\\d\\w.:\'" ]+)').replace(/\s+/g, '\\s+'))
        @otherRegexes.push(otherRegex)
    percentDifference: (problem) ->
      ((1 - problem.trimmed.length / problem.message.length) * 100).toFixed(0)
    color: (problem) ->
      amountTranslated = @percentDifference(problem)
      if amountTranslated >= @completeThreshold
        return 'green'
      else if amountTranslated >= @partialThreshold
        return 'yellow'
      else
        return 'red'
    getProblems: ->
      $.post(
        '/db/user.code.problem/-/common_problems',
        {startDay: @startDay, endDay: @endDay, slug: @levelSlug},
        (@problems) =>
          @compareStrings()
          @totalCount = _.reduce(_.map(@problems, (p)->p.count), (a,b)->a+b)
      )
    compareStrings: ->
      @problems.forEach (problem) =>
        original = problem.message
        translated = Problem.prototype.translate(problem.message)
        distance = Levenshtein.get(_.last(original.split(':')), _.last(translated.split(':')))
        # trimmed = original
        # for regex in @regexes
        #   trimmed = trimmed.replace(regex, '')
        trimmed = translated
        for regex in @otherRegexes
          trimmed = trimmed.replace(regex, '').replace(/^\n/, '')
        Vue.set(problem, 'translated', translated)
        Vue.set(problem, 'distance', distance)
        Vue.set(problem, 'trimmed', trimmed)
      # @problems.sort (a, b) -> a.distance - b.distance

module.exports = class I18nVerifierView extends RootComponent
  id: 'i18n-verifier-view'
  template: require 'templates/base-flat'
  VueComponent: I18nVerifierComponent
  constructor: (options, @courseInstanceID) ->
    @propsData = { @courseInstanceID }
    super options
