// @ts-check

import ServerError from '@/models/ServerError';

// Escape a string for HTML interpolation.
const escape = (string) => {
  // List of HTML entities for escaping.
  const htmlEscapes = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#x27;',
    '/': '&#x2F;',
  };

  // Regex containing the keys listed immediately above.
  const htmlEscaper = /[&<>"'/]/g;
  return (`${string}`).replace(htmlEscaper, (match) => htmlEscapes[match]);
};

// eslint-disable-next-line import/prefer-default-export
export const getErrorMessageAsHtml = (error, prependMessage = '') => {
  let errorMessage;

  if (error instanceof ServerError && error.errors.length > 0) {
    errorMessage = `<div class="mt-2">${error.errors.map((e) => escape(e)).join('</div><div class="mt-2">')}</div>`;
  } else if (error.message) {
    errorMessage = `<div class="mt-2">${escape(error.message)}</div>`;
  } else {
    errorMessage = '<div class="mt-2">An unknown error occurred!</div>';
  }

  if (prependMessage !== '') {
    errorMessage = `<div class="mt-2"><b>${escape(prependMessage)}</b></div>${errorMessage}`;
  }

  return errorMessage;
};
