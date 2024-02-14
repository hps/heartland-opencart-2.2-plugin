<?php
  global $config;
  $securesubmit_public_key = $config->get('securesubmit_mode') == 'test'
      ? $config->get('securesubmit_test_public_key')
      : $config->get('securesubmit_live_public_key');
  $securesubmit_use_iframes = !!($config->get('securesubmit_use_iframes'));
?>
<link rel="stylesheet" type="text/css" href="catalog/view/stylesheet/securesubmit.css">

<?php if ($securesubmit_use_iframes): // help prevent flash of no fields ?>
  <link rel="dns-prefetch" href="https://hps.github.io" />
  <link rel="prefetch" href="https://hps.github.io" />
  <link rel="dns-prefetch" href="https://api.heartlandportico.com" />
  <link rel="prefetch" href="https://api.heartlandportico.com" />
<?php endif; ?>

<form class="form-horizontal">
  <fieldset id="payment">
    <legend><?php echo $text_credit_card; ?><br>

      <div class="ss-shield">  </div>
        <div class="visa-gray hidden-xs "></div>
        <div class="mc-gray hidden-xs"></div>
        <div class="amex-gray hidden-xs"></div>
        <div class="jcb-gray hidden-xs"></div>
        <div class="disc-gray hidden-xs"></div>

    </legend>

     <div class="form-group required col-md-10">

      <label class="control-label ss-label" for="input-cc-number"><?php echo $entry_cc_number; ?></label></br>

        <?php if ($securesubmit_use_iframes): ?>
          <div id="securesubmitIframeCardNumber" class="ss-frame-container"></div>
        <?php else: ?>
          <input type="tel" value="" placeholder="•••• •••• •••• ••••" id="input-cc-number" class="form-control ss-form-control card-type-icon" />
        <?php endif; ?>
         <p class="error-message" id="gps-card-error"></p>
    </div>

   <div class="form-group required col-md-5">
      <label class="control-label ss-label" for="input-cc-expire-date"><?php echo $entry_cc_expire_date; ?></label></br>

        <?php if ($securesubmit_use_iframes): ?>
          <div id="securesubmitIframeCardExpiration" class="ss-frame-container"></div>
        <?php else: ?>
          <input type="tel" name="cc_expire_date" id="input-cc-expire-date" class="form-control ss-form-control" placeholder="MM / YYYY" />
        <?php endif; ?>
        <p class="error-message" id="gps-expiry-error"></p>
    </div>
    <div class="form-group required col-md-5 col-md-offset-7">
        <label class="control-label ss-label cvv-label" for="input-cc-cvv2"><?php echo $entry_cc_cvv2; ?></label></br>

        <?php if ($securesubmit_use_iframes): ?>
          <div id="securesubmitIframeCardCvv" class="ss-frame-container"></div>
        <?php else: ?>
          <input type="tel" value="" placeholder="<?php echo $entry_cc_cvv2; ?>" id="input-cc-cvv2" class="form-control ss-form-control cvv-icon"  />
        <?php endif; ?>
        <p class="error-message" id="gps-cvv-error"></p>
    </div>
    <div class="form-group required ">
        <?php if ($securesubmit_use_iframes): ?>
          <div id="submit_button" class="ss-frame-container"></div>
        <?php else: ?>
          <input type="tel" value="" placeholder="<?php echo $entry_cc_cvv2; ?>" id="input-cc-cvv2" class="form-control ss-form-control cvv-icon"  />
        <?php endif; ?>
    </div>
  </fieldset>
</form>
<div class="buttons">
  <div class="pull-right">
    <input type="button" value="<?php echo $button_confirm; ?>" id="button-confirm" class="btn btn-primary" />
  </div>
</div>
<script type="text/javascript"><!--
$(document).ready(function () {
  $('#button-confirm').bind('click', secureSubmitFormHandler);
  $("#input-cc-number").keydown(function (e) {
    // Allow: backspace, delete, tab, escape, enter and .
    if ($.inArray(e.keyCode, [46, 8, 9, 27, 13, 110, 190]) !== -1 ||
       // Allow: Ctrl+A
      (e.keyCode == 65 && e.ctrlKey === true) ||
       // Allow: home, end, left, right
      (e.keyCode >= 35 && e.keyCode <= 39)) {
        // let it happen, don't do anything
        return;
    }
    // Ensure that it is a number and stop the keypress
    if ((e.shiftKey || (e.keyCode < 48 || e.keyCode > 57)) && (e.keyCode < 96 || e.keyCode > 105)) {
      e.preventDefault();
    }
  });

  function secureSubmitFormHandler() {
    var securesubmit_public_key = '<?php echo $securesubmit_public_key;?>';

    if ($('input.securesubmitToken').size() === 0) {
      if (<?php echo ($securesubmit_use_iframes ? 'true' : 'false');?>) {
        window.hps.Messages.post(
          {
            accumulateData: true,
            action: 'tokenize',
            message: securesubmit_public_key
          },
          'cardNumber'
        );
      } else {
        var card  = $('#input-cc-number').val().replace(/\D/g, '');
        var cvc   = $('#input-cc-cvv2').val();
        var exp   = $('#input-cc-expire-date').val().split(' / ');
        var month = exp[0];
        var year  = exp[1];
        (new Heartland.HPS({
          publicKey: securesubmit_public_key,
          cardNumber: card,
          cardCvv: cvc,
          cardExpMonth: month,
          cardExpYear: year,
          success: secureSubmitResponseHandler,
          error: secureSubmitResponseHandler
        })).tokenize();
        return false;
      }
    }

    return true;
  }

  function secureSubmitResponseHandler(response) {
    var bodyTag = $('body').first();
    if (response.message) {
      alert(response.message);
      $('#button-confirm').button('reset');
    } else {
      bodyTag.append("<input type='hidden' class='securesubmitToken' name='securesubmitToken' value='" + response.paymentReference + "'/>");
      form_submit();
    }
  }

  function form_submit() {
    var ret = [];
    $(':input').each(function (index) {
      ret.push(encodeURIComponent(this.name) + "=" + encodeURIComponent($(this).val()));
    });

    $.ajax({
      url: 'index.php?route=payment/securesubmit/send',
      type: 'post',
      data: ret.join("&").replace(/%20/g, "+"),
      dataType: 'json',
      cache: false,
      beforeSend: function () {
        $('#button-confirm').button('loading');
      },
      complete: function () {
        $('#button-confirm').button('reset');
         var submit_button = document.getElementById('submit_button');
         submit_button.classList.remove("disable-button");
      },
      success: function (json){
        if (json['error']) {
          alert(json['error']);
        }
        if (json['redirect']) {
          window.location = json['redirect'];
        }
      }
    });
  }

  function loadjsfile(filename, filetype, callback) {
    if (filetype === "js") { //if filename is a external JavaScript file
      var fileref = document.createElement('script');
      fileref.setAttribute("type","text/javascript");
      fileref.setAttribute("src", filename);
    }
    if (typeof fileref !== "undefined" && typeof callback !== 'undefined') {
      fileref.setAttribute('onload', callback);
    }
    if (typeof fileref !== "undefined") {
      document.getElementsByTagName("head")[0].appendChild(fileref);
    }
  }

  //dynamically load and add this .js file
  loadjsfile("https://js.globalpay.com/v1/globalpayments.js", "js", 'secureSubmitPrepareFields();');

  window.secureSubmitPrepareFields = function () {
    var securesubmit_public_key = '<?php echo $securesubmit_public_key;?>';
    var image_base = '<?php echo $base_url; ?>catalog/view/image';

    if (<?php echo ($securesubmit_use_iframes ? 'true' : 'false');?>) {

      GlobalPayments.configure({
        "publicApiKey": '<?php echo $securesubmit_public_key;?>'
      });

      // Create a new `HPS` object with the necessary configuration
      window.hps = GlobalPayments.ui.form({
        fields: {
          "card-number": {
            placeholder: "•••• •••• •••• ••••",
            target: "#securesubmitIframeCardNumber"
          },
          "card-expiration": {
            placeholder: "MM / YYYY",
            target: "#securesubmitIframeCardExpiration"
          },
          "card-cvv": {
            placeholder: "•••",
            target: "#securesubmitIframeCardCvv"
          },
          "submit": {
            target: "#submit_button",
            text: "Confirm Order"
          }
        },
        styles:  {
            'html' : {
              "-webkit-text-size-adjust": "100%"
            },
            'body' : {
              'width' : '100%'
            },
            '#secure-payment-field-wrapper' : {
              'position' : 'relative',
              'justify-content'  : 'flex-end',
              'margin': '0 12px'
            },
            '#secure-payment-field' : {
              'background-color' : '#fff',
              'border'           : '1px solid #ccc',
              'border-radius'    : '4px',
              'display'          : 'block',
              'font-size'        : '14px',
              'height'           : '35px',
              'padding'          : '6px 12px',
              'width'            : '100%',
            },
            '#secure-payment-field:focus' : {
              "border": "1px solid lightblue",
              "box-shadow": "0 1px 3px 0 #cecece",
              "outline": "none"
            },
            'button#secure-payment-field.submit' : {
                  'width': 'unset',
                  'flex': 'unset',
                  'float': 'right',
                  'color': '#fff',
                  'background': '#2e6da4',
                  'cursor': 'pointer'
            },
            '.card-number::-ms-clear' : {
              'display' : 'none'
            },
            'input[placeholder]' : {
              'letter-spacing' : '.5px',
            },
          }
      });

      window.hps.on('submit', 'click', function(){
        var submit_button = document.getElementById('submit_button');
         submit_button.classList.add("disable-button");
      });

      window.hps.ready(
        function () {
          document.getElementById("button-confirm").style.display = "none";
        }
      );

      window.hps.on("token-success", function(resp) {
        window.hps.errors();
        if(resp.details.cardSecurityCode == false){
            document.getElementById("gps-expiry-error").style.display = 'block';
            document.getElementById("gps-expiry-error").innerText = 'Invalid Card Details';
            var submit_button = document.getElementById('submit_button');
            submit_button.classList.remove("disable-button");
        }else{
            secureSubmitResponseHandler(resp);
        }
     });

      window.hps.on("token-error", function(resp) {
        if(resp.error){
          resp.reasons.forEach(function(v){
              if(v.code == "INVALID_CARD_NUMBER"){
                document.getElementById("gps-card-error").style.display = 'block';
                document.getElementById("gps-card-error").innerText = v.message;
              }else{
                alert(v.message);
              }
          })
        }
        var submit_button = document.getElementById('submit_button');
        submit_button.classList.remove("disable-button");
     });

      window.hps.errors = function(){
          var errorsDiv = document.getElementsByClassName("error-message");
          for(var i = 0; i < errorsDiv.length; i++){
              errorsDiv[i].style.display = "none";
          }
      }

      window.hps.stopConfirm = function(){
          var errorsDiv = document.getElementsByClassName("error-message");
          for(var i = 0; i < errorsDiv.length; i++){
              errorsDiv[i].style.display = "none";
          }
      }
    } else {
      Heartland.Card.attachNumberEvents('#input-cc-number');
      Heartland.Card.attachExpirationEvents('#input-cc-expire-date');
      Heartland.Card.attachCvvEvents('#input-cc-cvv2');
    }
  }
});
</script>
