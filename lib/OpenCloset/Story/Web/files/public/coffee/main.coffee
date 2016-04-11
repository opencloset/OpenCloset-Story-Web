$ ->
  $(".button-collapse").sideNav()
  $(".parallax").parallax()
  $(".show-search").on "click", ->
    $(".search-out").fadeToggle( "50", "linear" )
    if $(".search-out").is(":visible")
      $(".search-out-text").css( "display", "list-item" ).focus()
