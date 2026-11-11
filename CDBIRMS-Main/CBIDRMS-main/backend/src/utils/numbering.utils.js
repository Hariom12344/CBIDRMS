/**
 * Utility to generate sequential quotation numbers formatted like:
 * TTPL/QTN/2026-27/001
 */
function getFinancialYearString(date = new Date()) {
  const currentMonth = date.getMonth(); // 0-indexed (0 = Jan, 3 = April)
  const currentYear = date.getFullYear();

  let startYear, endYear;
  if (currentMonth >= 3) {
    // April or later
    startYear = currentYear;
    endYear = currentYear + 1;
  } else {
    // Jan - March
    startYear = currentYear - 1;
    endYear = currentYear;
  }

  const endYearShort = String(endYear).slice(-2);
  return `${startYear}-${endYearShort}`;
}

async function generateQuotationNumber(prisma) {
  const fy = getFinancialYearString();
  const prefix = `TTPL/QTN/${fy}/`;

  // Find latest quotation with this prefix
  const latestQuote = await prisma.quotation.findFirst({
    where: {
      quotationNumber: {
        startsWith: prefix,
      },
    },
    orderBy: {
      createdAt: 'desc',
    },
    select: {
      quotationNumber: true,
    },
  });

  let nextSequence = 1;
  if (latestQuote && latestQuote.quotationNumber) {
    const parts = latestQuote.quotationNumber.split('/');
    const lastPart = parts[parts.length - 1];
    const parsedSeq = parseInt(lastPart, 10);
    if (!isNaN(parsedSeq)) {
      nextSequence = parsedSeq + 1;
    }
  }

  const paddedSeq = String(nextSequence).padStart(3, '0');
  return `${prefix}${paddedSeq}`;
}

module.exports = {
  getFinancialYearString,
  generateQuotationNumber,
};
