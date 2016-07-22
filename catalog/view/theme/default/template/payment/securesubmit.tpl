<?php
  global $config;
  $securesubmit_public_key = $config->get('securesubmit_mode') == 'test'
      ? $config->get('securesubmit_test_public_key')
      : $config->get('securesubmit_live_public_key');
  $securesubmit_use_iframes = !!($config->get('securesubmit_use_iframes'));
?>
<link rel="stylesheet" type="text/css" href="catalog/view/stylesheet/securesubmit.css">
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

  <!--  <div class="form-group required col-md-10 ">

      <label class="control-label ss-label" for="input-cc-owner"><?php echo $entry_cc_owner; ?></label></br>

        <input type="text" name="cc_owner" value="" placeholder="<?php echo $entry_cc_owner; ?>" id="input-cc-owner" class="form-control ss-form-control" />

    </div> -->
     <div class="form-group required col-md-10">

      <label class="control-label ss-label" for="input-cc-number"><?php echo $entry_cc_number; ?></label></br>

        <?php if ($securesubmit_use_iframes): ?>
          <div id="securesubmitIframeCardNumber" class="form-control ss-form-control"></div>
        <?php else: ?>
          <input type="text" value="" placeholder="•••• •••• •••• ••••" id="input-cc-number" class="form-control ss-form-control card-type-icon" />
        <?php endif; ?>

    </div>

   <div class="form-group required col-md-5">
      <label class="control-label ss-label" for="input-cc-expire-date"><?php echo $entry_cc_expire_date; ?></label></br>

        <?php if ($securesubmit_use_iframes): ?>
          <div id="securesubmitIframeCardExpiration" class="form-control ss-form-control"></div>
        <?php else: ?>
          <input type="text" name="cc_expire_date" id="input-cc-expire-date" class="form-control ss-form-control" placeholder="MM / YYYY" />
        <?php endif; ?>

    </div>
    <div class="form-group required col-md-5 col-md-offset-7">
        <label class="control-label ss-label cvv-label" for="input-cc-cvv2"><?php echo $entry_cc_cvv2; ?></label></br>

        <?php if ($securesubmit_use_iframes): ?>
          <div id="securesubmitIframeCardCvv" class="form-control ss-form-control"></div>
        <?php else: ?>
          <input type="text" value="" placeholder="<?php echo $entry_cc_cvv2; ?>" id="input-cc-cvv2" class="form-control ss-form-control cvv-icon"  />
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
      bodyTag.append("<input type='hidden' class='securesubmitToken' name='securesubmitToken' value='" + response.token_value + "'/>");
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

  function loadjsfile(filename, filetype){
    if (filetype === "js") { //if filename is a external JavaScript file
      var fileref = document.createElement('script');
      fileref.setAttribute("type","text/javascript");
      fileref.setAttribute("src", filename);
    }
    if (typeof fileref !== "undefined") {
      document.getElementsByTagName("head")[0].appendChild(fileref);
    }
  }

  setTimeout(function () {
    loadjsfile("https://api.heartlandportico.com/SecureSubmit.v1/token/2.1/securesubmit.js", "js") //dynamically load and add this .js file
  }, 0);

  setTimeout(function () {
    var securesubmit_public_key = '<?php echo $securesubmit_public_key;?>';

    if (<?php echo ($securesubmit_use_iframes ? 'true' : 'false');?>) {
      // Create a new `HPS` object with the necessary configuration
      window.hps = new Heartland.HPS({
        publicKey: securesubmit_public_key,
        type:      'iframe',
        // Configure the iframe fields to tell the library where
        // the iframe should be inserted into the DOM and some
        // basic options
        fields: {
          cardNumber: {
            target:      'securesubmitIframeCardNumber',
            placeholder: '•••• •••• •••• ••••'
          },
          cardExpiration: {
            target:      'securesubmitIframeCardExpiration',
            placeholder: 'MM / YYYY'
          },
          cardCvv: {
            target:      'securesubmitIframeCardCvv',
            placeholder: 'CVV'
          }
        },
        // Collection of CSS to inject into the iframes.
        // These properties can match the site's styles
        // to create a seamless experience.
        style: {
          'input': {
            // 'background': '#fff',
            // 'border': '1px solid',
            // 'border-color': '#bbb3b9 #c7c1c6 #c7c1c6',
            // 'box-sizing': 'border-box',
            // 'font-family': 'serif',
            // 'font-size': '16px',
            // 'line-height': '1',
            // 'margin': '0 .5em 0 0',
            // 'max-width': '100%',
            // 'outline': '0',
            // 'padding': '0.5278em',
            // 'vertical-align': 'baseline',
            // 'width': '100%'
          }
        },
        // Callback when a token is received from the service
        onTokenSuccess: secureSubmitResponseHandler,
        // Callback when an error is received from the service
        onTokenError: secureSubmitResponseHandler
      });
    } else {
      Heartland.Card.attachNumberEvents('#input-cc-number');
      Heartland.Card.attachExpirationEvents('#input-cc-expire-date');
      Heartland.Card.attachCvvEvents('#input-cc-cvv2');
    }
  }, 1000);
});
</script>
