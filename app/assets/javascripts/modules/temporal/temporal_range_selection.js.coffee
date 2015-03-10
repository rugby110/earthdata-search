do (document, $=jQuery, edsc_date=@edsc.util.date, temporalModel=@edsc.page.query.temporal, plugin=@edsc.util.plugin, page=@edsc.page) ->

  now = new Date()
  today = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate())
  current_year = new Date().getUTCFullYear()

  validateTemporalInputs = (root) ->
    start = root.find(".temporal-start:visible")
    end = root.find(".temporal-stop:visible")
    start_val = start.val()
    end_val = end.val()

    if start and end
      error = root.find(".tab-pane:visible .temporal-error")
      error.show()

      if start.hasClass("temporal-recurring-start")
        # Recurring start and stop must both be selected
        if start_val == "" ^ end_val == ""
          error.text("Start and End dates must both be selected")
        else if start_val > end_val
          error.text("Start must be no later than End")
        else
          error.hide()
      else
        if start_val == "" or end_val == "" or start_val <= end_val
          error.hide()
        else
          error.text("Start must be no later than End")


  # setMinMaxOptions = (root, datetimepicker, $input, temporal_type) ->
  #   min_date = false
  #   max_date = false
  #   format = if temporal_type == "range" then 'Y-m-d' else 'm-d'
  #
  #   start_val = root.find('input.temporal-' + temporal_type + '-start').val()
  #   stop_val = root.find('input.temporal-' + temporal_type + '-stop').val()
  #
  #   if $input.hasClass('temporal-' + temporal_type + '-start') and stop_val
  #     max_date = stop_val.split(' ')[0]
  #   else if $input.hasClass('temporal-' + temporal_type + '-stop') and start_val
  #     min_date = start_val.split(' ')[0]
  #
  #   datetimepicker.setOptions({
  #     minDate: min_date,
  #     maxDate: max_date,
  #     startDate: today,
  #     formatDate: format
  #   })

  # updateMonthButtons = (month_label) ->
  #   prev_button = month_label.siblings('button.xdsoft_prev')
  #   next_button = month_label.siblings('button.xdsoft_next')
  #   prev_button.show()
  #   next_button.show()
  #   month = month_label.find('span').text()
  #   if month == "January"
  #     prev_button.hide()
  #   else if month == "December"
  #     next_button.hide()

  originalSetDate = null

  $.fn.temporalSelectors = (options) ->
    root = this
    uiModel = options["uiModel"]
    uiModelPath = options["modelPath"]
    prefix = options["prefix"]

    # Sanity check
    console.error "Temporal selectors double initialization" if root.data('temporal-selectors')
    root.data('temporal-selectors', true)

    onChangeDateTime = (dp, $input) ->
      validateTemporalInputs(root)
      $input.trigger('change')

    root.find('.temporal-range-picker').datepicker
      format: "yyyy-mm-dd"
      startDate: "1960-01-01"
      endDate: new Date()
      startView: 2
      todayBtn: "linked"
      clearBtn: true
      autoclose: true
      todayHighlight: true
      forceParse: false
      keyboardNavigation: false

    root.find('.temporal-recurring-picker').datepicker
      format: "mm-dd"
      startDate: "1960-01-01"
      endDate: "1960-12-31"
      startView: 1
      todayBtn: "linked"
      clearBtn: true
      autoclose: true
      todayHighlight: true
      forceParse: false
      keyboardNavigation: false

    # Set end time to 23:59:59
    DatePickerProto = Object.getPrototypeOf($('.temporal').data('datepicker'))
    unless originalSetDate?
      originalSetDate = DatePickerProto._setDate
      DatePickerProto._setDate = (date, which) ->
        updatedDate = date
        if $(this.element).hasClass('temporal-range-stop')
          updatedDate.setSeconds(date.getSeconds() + 86399) # 23:59:59
        originalSetDate.call(this, updatedDate, which)

    # TODO hide year selection from recurring pickers

    # root.find('.temporal-recurring-picker').datetimepicker
    #   format: 'm-d H:i:s',
    #   allowBlank: true,
    #   closeOnDateSelect: true,
    #   lazyInit: true,
    #   className: prefix + '-datetimepicker recurring-datetimepicker',
    #   yearStart: 2007,
    #   yearEnd: 2007,
    #   startDate: today,
    #   onShow: (dp,$input) ->
    #     updateMonthButtons($(this).find('.xdsoft_month'))
    #     setMinMaxOptions(root, this, $input, 'recurring')
    #   onChangeDateTime: onChangeDateTime
    #   onChangeMonth: (dp,$input) ->
    #     updateMonthButtons($(this).find('.xdsoft_month'))
    #   onGenerate: (time, input) ->
    #     time.setHours(0)
    #     time.setMinutes(0)
    #     time.setSeconds(0)
    #     if input.hasClass('temporal-recurring-stop')
    #       time.setHours(23)
    #       time.setMinutes(59)
    #       time.setSeconds(59)

    root.find('.temporal-recurring-year-range').slider({
      min: 1960,
      max: current_year,
      value: [1960, current_year],
      tooltip: 'hide'
    }).on 'slide', (e) ->
      uiModel.pending.years(e.value)

    # Set the slider when the years change
    uiModel.pending.years.subscribe (years) ->
      root.find('.temporal-recurring-year-range').slider('setValue', years)

    # Initialize the slider to current value of years
    root.find('.temporal-recurring-year-range').slider('setValue', uiModel.pending.years())

    # Submit temporal range search
    updateTemporalRange = ->
      if root.find('#temporal-date-range .temporal-error').is(":hidden")
        uiModel.apply()
      else
        false

    # Submit temporal recurring search
    updateTemporalRecurring = ->
      if root.find('#temporal-recurring .temporal-error').is(":hidden")
        uiModel.apply()
      else
        false

    root.find('.temporal-submit').on 'click', ->
      visible = $(this).parent().siblings(".tab-pane:visible")
      if (visible.is(".temporal-date-range"))
        if updateTemporalRange()
          $(this).parents('.dropdown').removeClass('open')
      else if (visible.is(".temporal-recurring"))
        if updateTemporalRecurring()
          $(this).parents('.dropdown').removeClass('open')

    root.find('.temporal').on 'change paste keyup', ->
      validateTemporalInputs(root)
      event.stopPropagation()

  $(document).on 'click', '.clear-filters.button', ->
    validateTemporalInputs($('.dataset-temporal-filter'))

  $(document).on 'click', '.granule-filters-clear', ->
    validateTemporalInputs($('.granule-temporal-filter'))

  $(document).on 'click', '.temporal-filter .temporal-clear', ->
    validateTemporalInputs($(this).closest('.temporal-filter'))
    # Clear datepicker selection
    $('.temporal-range-start').datepicker('update')
    $('.temporal-range-stop').datepicker('update')

  # safe global stuff
  $(document).on 'click', '.xdsoft_today_button, button.xdsoft_prev, button.xdsoft_next', ->
    updateMonthButtons($(this).siblings('.xdsoft_month'))

  $(document).on 'click', 'input.day-of-year-input', ->
    # What does this even do?
    $(this).focus()


  $(document).ready ->
    $('.dataset-temporal-filter').temporalSelectors({
      uiModel: temporalModel,
      modelPath: "query.temporal.pending",
      prefix: 'dataset'
    })
