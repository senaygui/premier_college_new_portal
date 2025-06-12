//= require jquery
//= require active_admin/base
//= require activeadmin_addons/all
//= require activestorage
//= require active_storage_drag_and_drop
//= require active_admin_scoped_collection_actions
//= require active_admin_sidebar
//= require chartkick
//= require Chart.bundle
//= require custom
//= require student_report
//= require online_student


$(document).ready(function () {
  // Add header banner
  if ($('#header').length) {
    $('#header').before("<div class='headline'><div class='banner-logo'></div> <h1 class='banner-title'> Premier College Registrar Portal</h1></div>");
  }

  function toggleFields() {
    var role = $('#admin_user_role').val();
  
    if (role === 'dean') {
      $('.faculty-select').closest('.input').show();
    } else {
      $('.faculty-select').closest('.input').hide();
    }
  
    if (role === 'instructor') {
      $('.position-select').closest('.input').show();
      $('.educational-level-select').closest('.input').show();
      $('.employee-type-select').closest('.input').show();
    } else {
      $('.position-select').closest('.input').hide();
      $('.educational-level-select').closest('.input').hide();
      $('.employee-type-select').closest('.input').hide();
    }
  }
  
  // Initial check
  toggleFields();
  
  // Check on role change
  $('#admin_user_role').change(function() {
    toggleFields();
  });

  
  $("#student_photo").change(function (data) {

    var imageFile = data.target.files[0];
    var reader = new FileReader();
    reader.readAsDataURL(imageFile);

    reader.onload = function (evt) {
      $('#imagePreview').attr('src', evt.target.result);
      $('#imagePreview').hide();
      $('#imagePreview').fadeIn(650);
    }

  });
  $("#payment_method_bank_logo").change(function (data) {

    var imageFile = data.target.files[0];
    var reader = new FileReader();
    reader.readAsDataURL(imageFile);

    reader.onload = function (evt) {
      $('#imagePreview').attr('src', evt.target.result);
      $('#imagePreview').hide();
      $('#imagePreview').fadeIn(650);
    }

  });

  if ($('#purchase_type_of_supplier').val() == "") {
    $('.grp1').hide();
    $('.grp2').hide();
  } else if ($('#purchase_type_of_supplier').val() == 'International Supplier') {
    $('.grp1').show();
    $('.grp2').hide();
  } else if ($('#purchase_type_of_supplier').val() == 'Local Vender') {
    $('.grp1').hide();
    $('.grp2').show();
  }



  $('#purchase_type_of_supplier').change(function () {
    var value;

    value = $(this).val();
    if (value === 'International Supplier') {
      $('.grp1').show();
      $('.grp2').hide();
    } else if (value === 'Local Vender') {
      $('.grp1').hide();
      $('.grp2').show();
    }
  });

  $('.link').on('click', function (e) {
    e.preventDefault();
    let $container = $(this).closest('.widgetContainer').first();
    if ($container.css('overflow') == "hidden") {
      $container.css({
        height: 'auto',
        overflow: 'visible'
      });
    } else {
      $container.css({
        height: '120px',
        overflow: 'hidden'
      });
    }


  })


});