Local (Kwaoo) features.

    Promise = require 'lie'
    request = require 'superagent-as-promised'
    debug = (require 'debug') 'local.coffee.md'

    @get_billing_data = (cfg,tel) ->
      prefix_id = destination_id = min_call_price = null
      request
      .get "#{cfg.si_url}/prefix/#{tel}"
      .then ({body}) ->
        doc = body
        debug doc
        prefix_id = doc.id
        min_call_price = doc.call_price ? 0
        {destination_id} = doc
        debug {prefix_id,min_call_price,destination_id}
        request
        .get "#{cfg.si_url}/tarif/#{cfg.si_period}/#{destination_id}"
      .then ({body}) ->
        doc = body
        {tarif} = doc
        tarif_id = doc.id
        illimite_france = doc.option_illimite_france ? 0
        illimite_monde = doc.option_illimite_monde ? 0
        mobile_fr = doc.option_mobile_fr ? 0
        [prefix_id,destination_id,tarif_id,tarif,min_call_price,illimite_france,illimite_monde,mobile_fr].join '_'
