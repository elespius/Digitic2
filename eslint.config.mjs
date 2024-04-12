import globals from "globals";
import js from "@eslint/js";

export default [
  js.configs.recommended,
  {
    "languageOptions": {
      "ecmaVersion": 2023,
      "sourceType": "module",
      "globals": {
        ...globals.browser,
        ...globals.jquery,
        "_": "readonly",
        "accounting": "readonly",
        "addVariantFromStockLocation": "writable",
        "adjustShipmentItems": "writable",
        "Backbone": "readonly",
        "error": "writable",
        "flatpickr": "readonly",
        "Handlebars": "readonly",
        "HandlebarsTemplates": "readonly",
        "json": "writable",
        "message": "writable",
        "Select2": "readonly",
        "shipments": "writable",
        "show_flash": "writable",
        "Sortable": "readonly",
        "Spree": "readonly",
        "Turbolinks": "readonly",
        "update_state": "writable",
      }
    },
    "rules": {
      "block-scoped-var": 0,
      "camelcase": 0,
      "comma-dangle": 0,
      "comma-spacing": 0,
      "computed-property-spacing": 0,
      "consistent-return": 0,
      "default-case": 0,
      "dot-notation": 0,
      "eqeqeq": 0,
      "func-names": 0,
      "guard-for-in": 0,
      "indent": 0,
      "key-spacing": 0,
      "keyword-spacing": 0,
      "linebreak-style": ["error", "unix"],
      "max-len": 0,
      "new-cap": 0,
      "no-alert": 0,
      "no-bitwise": 0,
      "no-console": ["warn", {
          "allow": ["warn"]
      }],
      "no-else-return": 0,
      "no-extra-semi": "error",
      "no-global-assign": ["error", {
          "exceptions": ["Tabs"]
      }],
      "no-multi-spaces": 0,
      "no-multi-str": 0,
      "no-new": 0,
      "no-param-reassign": 0,
      "no-plusplus": 0,
      "no-redeclare": "error",
      "no-restricted-globals": 0,
      "no-restricted-syntax": 0,
      "no-shadow": 0,
      "no-undef": "error",
      "no-underscore-dangle": ["error", {
          "allow": ["_sync", "_this", "_flatpickr"]
      }],
      "no-unused-vars": ["error", {
          "vars": "all", "args": "none"
      }],
      "no-use-before-define": 0,
      "no-unused-expressions": 0,
      "no-var": 0,
      "one-var": 0,
      "one-var-declaration-per-line": 0,
      "object-curly-newline": 0,
      "object-curly-spacing": 0,
      "object-shorthand": 0,
      "operator-linebreak": 0,
      "prefer-arrow-callback": 0,
      "prefer-destructuring": 0,
      "prefer-rest-params": 0,
      "prefer-template": 0,
      "quote-props": 0,
      "quotes": 0,
      "radix": 0,
      "semi": 0,
      "space-before-function-paren": 0,
      "space-before-blocks": 0,
      "space-infix-ops": 0,
      "space-unary-ops": 0,
      "spaced-comment": 0,
      "strict": 0,
      "vars-on-top": 0,
      "wrap-iife": 0
    },

  }
]
