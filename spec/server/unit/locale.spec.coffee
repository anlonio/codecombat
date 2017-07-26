english = require("../../../app/locale/en")
langs = [
  require("../../../app/locale/en"),
  require("../../../app/locale/en-US"),
  require("../../../app/locale/en-GB"),
  require("../../../app/locale/ru"),
  require("../../../app/locale/de-DE"),
  require("../../../app/locale/de-AT"),
  require("../../../app/locale/de-CH"),
  require("../../../app/locale/es-419"),
  require("../../../app/locale/es-ES"),
  require("../../../app/locale/zh-HANS"),
  require("../../../app/locale/zh-HANT"),
  require("../../../app/locale/zh-WUU-HANS"),
  require("../../../app/locale/zh-WUU-HANT"),
  require("../../../app/locale/fr"),
  require("../../../app/locale/ja"),
  require("../../../app/locale/ar"),
  require("../../../app/locale/pt-BR"),
  require("../../../app/locale/pt-PT"),
  require("../../../app/locale/pl"),
  require("../../../app/locale/it"),
  require("../../../app/locale/tr"),
  require("../../../app/locale/nl"),
  require("../../../app/locale/nl-BE"),
  require("../../../app/locale/nl-NL"),
  require("../../../app/locale/fa"),
  require("../../../app/locale/cs"),
  require("../../../app/locale/sv"),
  require("../../../app/locale/id"),
  require("../../../app/locale/el"),
  require("../../../app/locale/ro"),
  require("../../../app/locale/vi"),
  require("../../../app/locale/hu"),
  require("../../../app/locale/th"),
  require("../../../app/locale/da"),
  require("../../../app/locale/ko"),
  require("../../../app/locale/sk"),
  require("../../../app/locale/sl"),
  require("../../../app/locale/fi"),
  require("../../../app/locale/fil"),
  require("../../../app/locale/bg"),
  require("../../../app/locale/nb"),
  require("../../../app/locale/nn"),
  require("../../../app/locale/he"),
  require("../../../app/locale/lt"),
  require("../../../app/locale/sr"),
  require("../../../app/locale/uk"),
  require("../../../app/locale/hi"),
  require("../../../app/locale/ur"),
  require("../../../app/locale/ms"),
  require("../../../app/locale/ca"),
  require("../../../app/locale/gl"),
  require("../../../app/locale/mk-MK"),
  require("../../../app/locale/eo"),
  require("../../../app/locale/uz"),
  require("../../../app/locale/my"),
  require("../../../app/locale/et"),
  require("../../../app/locale/hr"),
  require("../../../app/locale/mi"),
  require("../../../app/locale/haw"),
  require("../../../app/locale/kk"),
]

describe 'esper error messages', ->
  langs.forEach (language) =>
    describe "when language is #{language.englishDescription}", ->
      esper = language.translation.esper or {}
      englishEsper = english.translation.esper

      Object.keys(language.translation.esper or {}).forEach (key) ->
        describe "when key is #{key}", ->
          it 'should have numbered placeholders $1 through $N', ->
            placeholders = (esper[key].match(/\$\d/g) or []).sort()
            expectedPlaceholders = ("$#{index+1}" for val, index in placeholders)
            if not _.isEqual(placeholders, expectedPlaceholders)
              fail """
                Some placeholders were skipped: #{placeholders}
                Translated string: #{esper[key]}
              """

          it 'should have the same placeholders in each entry as in English', ->
            if not englishEsper[key]
              return fail("Expected English to have a corresponding key for #{key}")
            englishPlaceholders = (englishEsper[key].match(/\$\d/g) or []).sort()
            placeholders = (esper[key].match(/\$\d/g) or []).sort()
            if not _.isEqual(placeholders, englishPlaceholders)
              fail """
                Expected translated placeholders: [#{placeholders}] (#{esper[key]})
                To match English placeholders: [#{englishPlaceholders}] (#{englishEsper[key]})
              """
