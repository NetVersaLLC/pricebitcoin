rates =
  mtgox: {}
  bitstamp: {}
  btce: {}

timeouts_count = 0

refresh_rate = 1000 #ms

rate_handlers =
  mtgox: (data) ->
    dr = parseFloat(data['rate'])
    isNaN(dr) || dr
  bitstamp: (data) ->
    hi = parseFloat data['high']
    lo = parseFloat data['low']
    isNaN(hi) || isNaN(lo) || ((hi + lo) / 2)
  btce: (data) ->
    data['rate']

current_source = ->
  $('input.source_chooser:checked')
selected_currency = ->
  $('#currency_chooser:visible').val() || 'USD' #default one

load_rate = (source, currency) ->
  source_name = source.val()
  url_mask = source.data('source-uri-mask')
  url = url_mask.replace('%s', currency)
  $.ajax url,
    success: (data) ->
      res = rate_handlers[source_name](data)
      rates[source_name][currency] = res if res #do not update rate if result handler returned false

update_currency_list = () ->
  active_currencies = current_source().data('currency-filter')
  switch active_currencies.split(' ').length #how much currencies does that list have
    when 0
      console.error("WTF?")
    when 1
      $('#currency_chooser').val(active_currencies).hide()
      $('#single_currency_label').text(active_currencies).show()
    else
      opts = $('#currency_chooser option')
        .each (i, el) ->
          if active_currencies.indexOf($(this).val()) != -1
            $(this).show()
          else
            $(this).hide()
      if opts.filter( -> $(this).css('display') == 'none').length > 0 #if selected currency is hidden
        opts.filter( -> $(this).css('display') != 'none').first().prop('selected', true) #let's choose first visible
      $('#single_currency_label').hide()
      $('#currency_chooser').show()

calculate_result = ->
  amount = parseFloat $('#btc_count').val()
  Math.round(amount * rates[current_source().val()][selected_currency()] * 100) / 100 if amount?

is_redrawing = false
redraw_result = () ->
  unless is_redrawing
    is_redrawing = true
    $('#result').val(calculate_result())
    is_redrawing = false

form_disabled = (how = true) ->
  $('#main_form').find('input, select').prop('disabled', !!how)

bootstrap_tickers = ->
  $('input.source_chooser').map( -> {currencies: $(this).data('currency-filter'), src: $(this)}).each (i, el) ->
    jQuery.each el['currencies'].split(' '), (k, v) ->
      load_rate(el['src'], v)
$ ->
  form_disabled()
  bootstrap_tickers()
  form_disabled(false)
  $('#btc_count').on 'keypress', (evt) ->
    code = evt.which
    unless (code in [48..57]) or code == 46 #"0".."9" or "."
      evt.preventDefault()
      false
    else
      redraw_result()
      true
  $('input.source_chooser').on 'change', (evt) ->
    update_currency_list()
    redraw_result()
  $('#currency_chooser').on 'change', ->
    redraw_result()
  timeout_handler =  ->
    load_rate(current_source(), selected_currency())
    redraw_result()
    setTimeout timeout_handler, refresh_rate
  setTimeout timeout_handler, refresh_rate
  update_currency_list()
