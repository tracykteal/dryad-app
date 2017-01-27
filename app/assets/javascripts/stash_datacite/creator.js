// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
function loadCreators() {

  // this uses a namespace (.mycreators) to disconnect previous events (off) before attaching them again
  $( '.js-creator_first_name, .js-creator_last_name' )
    .off('.mycreators')
    .on('focus.mycreators', function () {
      previous_value = this.value;
    })
    .on('change.mycreators', function() {
      new_value = this.value;
      // Save when the new value is different from the previous value
      if(new_value != previous_value) {
        var form = $(this).parents('form');
        // $(form).trigger('submit.rails');
        queueAjaxFormSubmit(form);
      }
    });


  $('form.js-creator_form')
      .off('mycreator_forms')
      .on('ajax:beforeSend.mycreator_forms', function(event, xhr, status) {
        console.log('ajax:beforeSend');
      })
      .on('ajax:complete.mycreator_forms', function(event, xhr, status) {
        console.log('ajax:complete');
        ajaxInProgress = false;
        if(ajaxQueue.length > 0){
          console.log('submitting form for next queued request:' + ajaxQueue[ajaxQueue.length-1]);
          $(ajaxQueue.pop()).trigger('submit.rails');
        }
      });

  /*
  $('form.js-creator_form').on('ajax:beforeSend', function(event, xhr, settings) {
    console.log('ajax beforesend');
  }); */
};


function hideRemoveLinkCreators() {
  if($('.js-creator_first_name').length < 2)
  {
   $('.js-creator_first_name').first().parent().parent().find('.remove_record').hide();
  }
  else{
   $('.js-creator_first_name').first().parent().parent().find('.remove_record').show();
  }
};

var ajaxQueue = [];
var ajaxInProgress = false;
function queueAjaxFormSubmit(form){
  console.log('using queueAjaxFormSubmit');
  console.log("ajaxQueue.length " + ajaxQueue.length);
  if(ajaxQueue.length < 1 && !ajaxInProgress){
    ajaxInProgress = true;
    $(form).trigger('submit.rails');
  }else{
    ajaxQueue.push(form);
  }
}
