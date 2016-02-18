export default {
  name: 'idnet_auto_login',
  initialize() {
    if (Discourse.SiteSettings.idnet_auto_login && !Discourse.User.current()) {
      // TODO: idnet_auto_login.js should be an ES6 module, imported
      window.idnetAutoLogin();
    }
  }
};
