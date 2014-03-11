(function ($) {

  $(document).ready(function () {

    // init scrollspy
    $('body').scrollspy({ target: '#navbar', offset: 70 });

    // init scroll-to effect navigation, adjust the scroll speed in milliseconds
    $('#navbar').localScroll(1000);
    $('#header').localScroll(1000);

  });

})(jQuery);