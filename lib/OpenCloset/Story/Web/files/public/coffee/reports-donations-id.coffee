$ ->
  $(".btn-order-message").on "click", (e) ->
    orderMessageIndex = $(this).data("order-message-index")
    return unless 0 <= orderMessageIndex && orderMessageIndex < orderMessages.length
    $("#order-message").html( orderMessages[orderMessageIndex] )
    $(".btn-order-message-next").data("order-message-index", orderMessageIndex + 1)
    $(".btn-order-message-prev").data("order-message-index", orderMessageIndex - 1)
