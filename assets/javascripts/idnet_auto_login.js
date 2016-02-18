// TODO: convert to ES6

(function($, window) {
  'use strict';

  var document = window.document;

  function AuthRequest(code) {
    this.code = code;
    this.path = '/auth/idnet/callback'
  }

  AuthRequest.prototype.perform = function(callback) {
    $.ajax(this.path, { data: { code: this.code }, success: callback });
    return true;
  };

  function autoLogin() {
    ID.getLoginStatus(function(response) {
      try {
        var code = response.authResponse.code;

        if (code) {
          var request = new AuthRequest(code);
          request.perform(function() { document.location.reload(); });
        }
      } catch (e) {
        return false;
      }
    });
  }

  function idAsyncInit() {
    ID.Event.subscribe('id.init', autoLogin);

    ID.init({
      appId: Discourse.SiteSettings.idnet_client_id,
      redirectUri: document.location.origin,
      responseType: 'code'
    });
  };

  function loadIdnetSdk() {
    var idnet = document.createElement('script');

    idnet.type = 'text/javascript';
    idnet.async = true;
    idnet.src = 'https://scdn.id.net/api/sdk.js';

    document.getElementsByTagName('head')[0].appendChild(idnet);
  }

  window.idnetAutoLogin = function() {
    window.idAsyncInit = idAsyncInit;
    loadIdnetSdk();
  }
})(jQuery, window);
