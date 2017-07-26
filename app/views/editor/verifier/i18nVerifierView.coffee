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
    completeThreshold: 99
    countThreshold: 0
    totalCount: 0
    messageOrHint: 'message'
    me: me
    serverConfig: serverConfig
    # problems: []
    problemsByLevel: {}
    regexes: []
    otherRegexes: []
    displayMode: 'human-readable'
    showCampaigns: false
    showLevels: false
    campaigns: []
    selectedCampaign: null
    selectedLevelSlugs: [_.last(location.href.split('/'))]
  computed:
    exportList: ->
      _(@problems).filter((p) =>
        @percentDifference(p) < @completeThreshold and (p.count / @totalCount) >= (@countThreshold / 100))
      .uniq((p) -> p.trimmed)
      .value()
    problems: ->
      _.flatten(Object.values(@problemsByLevel), true)
  created: ->
    i18n.setLng(@language)
    @loadCampaigns()
    @setupRegexes()
    @getProblems(@levelSlug)
  watch:
    selectedLevelSlugs: ->
      for slug in @selectedLevelSlugs
        if not @problemsByLevel[slug]
          @getProblems(slug)
    messageOrHint: ->
      @compareStrings(@problems)
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
      otherLang = require('locale/en').translation
      translationKeys = Object.keys(en.esper)
      for translationKey in translationKeys
        englishString = en.esper[translationKey]
        regex = Problem.prototype.makeTranslationRegex(englishString)
        @regexes.push(regex)
      for translationKey in translationKeys
        otherString = otherLang.esper[translationKey] or ''
        otherRegex = Problem.prototype.makeTranslationRegex(otherString)
        @otherRegexes.push(otherRegex)
    percentDifference: (problem) ->
      ((1 - problem.trimmed.length / problem[@messageOrHint].length) * 100).toFixed(0)
    color: (problem) ->
      amountTranslated = @percentDifference(problem)
      if amountTranslated >= @completeThreshold
        return 'green'
      else if amountTranslated >= @partialThreshold
        return 'yellow'
      else
        return 'red'
    getProblems: (levelSlug) ->
      console.log "Fetching by slug", levelSlug
      $.post(
        '/db/user.code.problem/-/common_problems',
        {startDay: @startDay, endDay: @endDay, slug: levelSlug},
        (newProblems) =>
          for problem in newProblems
            problem.hint ?= ''
          Vue.set(@problemsByLevel, levelSlug, newProblems)
          @compareStrings(newProblems)
          @totalCount = _.reduce(_.map(@problems, (p)->p.count), (a,b)->a+b)
          console.log _.reduce(_.map(newProblems, (p)->p.count), (a,b)->a+b), @totalCount
      )
    compareStrings: (problems) ->
      problems.forEach (problem) =>
        original = problem[@messageOrHint]
        translated = Problem.prototype.translate(problem[@messageOrHint])
        # distance = Levenshtein.get(_.last(original.split(':')), _.last(translated.split(':')))
        # trimmed = original
        # for regex in @regexes
        #   trimmed = trimmed.replace(regex, '')
        trimmed = translated
        for regex in @otherRegexes
          if false and /TypeError:.*Cannot.*read.*property/.test(original)# and /Target.*an.*enemy.*variable/.test(regex.toString())
            console.log "===="
            console.log trimmed
            console.log trimmed.replace(regex, '').replace(/^\n/, '')
            debugger if trimmed isnt trimmed.replace(regex, '').replace(/^\n/, '')
          trimmed = trimmed.replace(regex, '').replace(/^\n/, '')
        Vue.set(problem, 'translated', translated)
        # Vue.set(problem, 'distance', distance)
        Vue.set(problem, 'trimmed', trimmed)
      # @problems.sort (a, b) -> a.distance - b.distance
    slugifyProblem: (problem) ->
      str = _.string.slugify(problem.trimmed)
      str.split('-').slice(0,4).join('_')

module.exports = class I18nVerifierView extends RootComponent
  id: 'i18n-verifier-view'
  template: require 'templates/base-flat'
  VueComponent: I18nVerifierComponent
  constructor: (options, @courseInstanceID) ->
    @propsData = { @courseInstanceID }
    super options
