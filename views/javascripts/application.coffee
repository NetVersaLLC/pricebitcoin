rates =
  mtgox: false
  bitstamp: false

timeouts_count = 0

refresh_rate = 1000 #ms

triggered_load_mtgox = false
load_mtgox = (after_load = false) ->
  if $('#currency_chooser').is(':visible') and !triggered_load_mtgox
    triggered_load_mtgox = true
    $.ajax $('#currency_chooser').val(),
      success: (data, textStatus) ->
        data_rate = parseFloat data['rate']
        rates['mtgox'] = data_rate unless isNaN(data_rate)
        if typeof after_load == 'function'
          after_load()
      complete:  ->
        setTimeout(load_mtgox, refresh_rate)
        redraw_result()
        triggered_load_mtgox = false

triggered_load_bitstamp = false
load_bitstamp = (after_load = false) ->
  unless triggered_load_bitstamp
    triggered_load_bitstamp = true
    $.ajax '/bitstamp.json',
      success: (data, textStatus, jqXhr) ->
        high = parseFloat data['high']
        low = parseFloat data['low']
        unless isNaN high or isNaN low
          rates['bitstamp'] = (high + low) / 2
        if typeof after_load == 'function'
          after_load()
      complete: ->
        setTimeout(load_bitstamp, refresh_rate)
        redraw_result()
        triggered_load_bitstamp = false


is_redrawing = false
redraw_result = () ->
  unless is_redrawing
    is_redrawing = true
    amount = parseFloat $('#btc_count').val()
    rate = rates[source_name()]
    $('#result').val(Math.round(amount * rate * 100) / 100) unless !amount or !rate
    is_redrawing = false

source_name = () ->
  $('footer input.source_chooser:checked').val()

form_disabled = (how) ->
  $('#main_form').find('input, select').prop('disabled', !!how)

update_form_class = (cls) ->
  $('#main_form').removeClass('bitstamp_chosen mtgox_chosen').addClass(cls + '_chosen')

$ ->
  form_disabled(true);
  load_mtgox ->
    form_disabled(false)
  $('#btc_count').on 'keypress', (evt) ->
    code = evt.which
    unless (code in [48..57]) or code == 46 #"0".."9" or "."
      evt.preventDefault()
    else
      redraw_result
  $('input.source_chooser').on 'change', (evt) ->
    val = $(this).val()
    redraw_result()
    update_form_class(val)
    setTimeout(load_mtgox, refresh_rate) if val == 'mtgox'
  to_handler =  ->
    load_bitstamp()
    load_mtgox()
  setTimeout to_handler, refresh_rate
