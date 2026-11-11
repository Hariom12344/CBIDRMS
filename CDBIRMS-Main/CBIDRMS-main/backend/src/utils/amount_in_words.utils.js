/**
 * Converts a number into Indian Currency Words.
 * Example: 125450.50 => "One Lakh Twenty-Five Thousand Four Hundred Fifty Rupees and Fifty Paise Only"
 */

const ones = [
  '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
  'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
  'Seventeen', 'Eighteen', 'Nineteen'
];

const tens = [
  '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
];

function convertLessThanThousand(n) {
  let str = '';
  if (n >= 100) {
    str += ones[Math.floor(n / 100)] + ' Hundred ';
    n %= 100;
  }
  if (n >= 20) {
    str += tens[Math.floor(n / 10)] + (n % 10 !== 0 ? '-' + ones[n % 10] : '') + ' ';
  } else if (n > 0) {
    str += ones[n] + ' ';
  }
  return str;
}

function numberToIndianWords(num) {
  if (num === null || num === undefined || isNaN(num)) return '';
  if (num === 0) return 'Zero Rupees Only';

  const parts = Number(num).toFixed(2).split('.');
  let rupees = parseInt(parts[0], 10);
  let paise = parseInt(parts[1], 10);

  let rupeesStr = '';

  if (rupees >= 10000000) {
    // Crores
    const crores = Math.floor(rupees / 10000000);
    rupeesStr += convertLessThanThousand(crores) + 'Crore ';
    rupees %= 10000000;
  }

  if (rupees >= 100000) {
    // Lakhs
    const lakhs = Math.floor(rupees / 100000);
    rupeesStr += convertLessThanThousand(lakhs) + 'Lakh ';
    rupees %= 100000;
  }

  if (rupees >= 1000) {
    // Thousands
    const thousands = Math.floor(rupees / 1000);
    rupeesStr += convertLessThanThousand(thousands) + 'Thousand ';
    rupees %= 1000;
  }

  if (rupees > 0) {
    rupeesStr += convertLessThanThousand(rupees);
  }

  rupeesStr = rupeesStr.trim();

  let finalWords = rupeesStr ? `${rupeesStr} Rupees` : '';

  if (paise > 0) {
    const paiseWords = convertLessThanThousand(paise).trim();
    if (finalWords) {
      finalWords += ` and ${paiseWords} Paise`;
    } else {
      finalWords = `${paiseWords} Paise`;
    }
  }

  return `${finalWords} Only`;
}

module.exports = {
  numberToIndianWords,
};
