const prisma = require('../../config/db');
const { generateQuotationNumber } = require('../../utils/numbering.utils');
const { numberToIndianWords } = require('../../utils/amount_in_words.utils');
const { createQuotationSchema } = require('./quotation.validator');

// Helper to calculate totals
function calculateQuotationTotals(items, cgstRate = 9, sgstRate = 9, igstRate = 0, discountTotalInput = 0) {
  let subtotal = 0;
  const processedItems = items.map((item, idx) => {
    const qty = Number(item.quantity) || 0;
    const rate = Number(item.rate) || 0;
    const discPct = Number(item.discountPercent) || 0;
    const rawTotal = qty * rate;
    const discAmount = Number(item.discountAmount) || (rawTotal * (discPct / 100));
    const lineAmount = Math.max(0, rawTotal - discAmount);
    
    subtotal += lineAmount;

    return {
      srNo: item.srNo || (idx + 1),
      description: item.description,
      hsnSac: item.hsnSac || '',
      quantity: qty,
      uom: item.uom || 'NOS',
      rate: rate,
      discountPercent: discPct,
      discountAmount: discAmount,
      amount: lineAmount,
    };
  });

  const discountTotal = Number(discountTotalInput) || 0;
  const taxableAmount = Math.max(0, subtotal - discountTotal);

  const cgstAmount = (taxableAmount * (cgstRate / 100));
  const sgstAmount = (taxableAmount * (sgstRate / 100));
  const igstAmount = (taxableAmount * (igstRate / 100));

  const totalBeforeRound = taxableAmount + cgstAmount + sgstAmount + igstAmount;
  const grandTotal = Math.round(totalBeforeRound);
  const roundOff = Number((grandTotal - totalBeforeRound).toFixed(2));
  const amountInWords = numberToIndianWords(grandTotal);

  return {
    items: processedItems,
    subtotal,
    discountTotal,
    cgstRate,
    cgstAmount,
    sgstRate,
    sgstAmount,
    igstRate,
    igstAmount,
    roundOff,
    grandTotal,
    amountInWords,
  };
}

// 1. Create Quotation (Rev 0)
async function createQuotation(req, res) {
  try {
    const parsedData = createQuotationSchema.parse(req.body);
    const quoteNumber = await generateQuotationNumber(prisma);

    const calc = calculateQuotationTotals(
      parsedData.items,
      parsedData.cgstRate,
      parsedData.sgstRate,
      parsedData.igstRate,
      parsedData.discountTotal
    );

    const defaultDeclaration = parsedData.declarationText || `Not included:
- Domain & Hosting Renewal Fees
- Third-party API Subscriptions
- On-site Physical Support (Remote included)
- Annual Maintenance & Future Scope Modifications`;

    const defaultTerms = parsedData.termsAndConditions || `1. 50% advance payment required upon purchase order confirmation.
2. 40% upon completion of development milestone.
3. 10% before final deployment & hand-over.
4. Quotation valid for 30 days from date of issue.`;

    const newQuotation = await prisma.quotation.create({
      data: {
        quotationNumber: quoteNumber,
        revisionNumber: 0,
        date: parsedData.date,
        validTill: parsedData.validTill,
        refNumber: parsedData.refNumber,
        termsOfDelivery: parsedData.termsOfDelivery,

        companyName: parsedData.companyName,
        companyAddress: parsedData.companyAddress,
        companyPhone: parsedData.companyPhone,
        companyEmail: parsedData.companyEmail,
        companyGstin: parsedData.companyGstin,
        companyLogoUrl: parsedData.companyLogoUrl,

        consigneeName: parsedData.consigneeName,
        consigneeAddress: parsedData.consigneeAddress,
        consigneeGstin: parsedData.consigneeGstin,
        consigneeContact: parsedData.consigneeContact,
        consigneeMobile: parsedData.consigneeMobile,

        buyerName: parsedData.buyerName,
        buyerAddress: parsedData.buyerAddress,
        buyerGstin: parsedData.buyerGstin,
        buyerContact: parsedData.buyerContact,
        buyerMobile: parsedData.buyerMobile,

        subtotal: calc.subtotal,
        discountTotal: calc.discountTotal,
        cgstRate: calc.cgstRate,
        cgstAmount: calc.cgstAmount,
        sgstRate: calc.sgstRate,
        sgstAmount: calc.sgstAmount,
        igstRate: calc.igstRate,
        igstAmount: calc.igstAmount,
        roundOff: calc.roundOff,
        grandTotal: calc.grandTotal,
        amountInWords: calc.amountInWords,

        declarationText: defaultDeclaration,
        termsAndConditions: defaultTerms,
        status: parsedData.status || 'DRAFT',
        revisionNotes: 'Initial Quotation (Rev 0)',

        items: {
          create: calc.items,
        },
      },
      include: {
        items: true,
      },
    });

    return res.status(201).json({
      success: true,
      message: 'Quotation created successfully',
      data: newQuotation,
    });
  } catch (error) {
    console.error('Create Quotation Error:', error);
    return res.status(400).json({ success: false, error: error.message });
  }
}

// 2. Get All Quotations with Search, Filter & Pagination
async function getQuotations(req, res) {
  try {
    const { search, status, page = 1, limit = 20 } = req.query;

    const where = {};

    if (status && status !== 'ALL') {
      where.status = status;
    }

    if (search) {
      where.OR = [
        { quotationNumber: { contains: search } },
        { buyerName: { contains: search } },
        { consigneeName: { contains: search } },
        { refNumber: { contains: search } },
      ];
    }

    const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);
    const take = parseInt(limit, 10);

    const [total, quotations] = await Promise.all([
      prisma.quotation.count({ where }),
      prisma.quotation.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        include: {
          items: true,
        },
      }),
    ]);

    return res.json({
      success: true,
      total,
      page: parseInt(page, 10),
      totalPages: Math.ceil(total / take),
      data: quotations,
    });
  } catch (error) {
    console.error('Get Quotations Error:', error);
    return res.status(500).json({ success: false, error: error.message });
  }
}

// 3. Get Single Quotation by ID (with Revision History)
async function getQuotationById(req, res) {
  try {
    const { id } = req.params;

    const quotation = await prisma.quotation.findUnique({
      where: { id },
      include: {
        items: {
          orderBy: { srNo: 'asc' },
        },
      },
    });

    if (!quotation) {
      return res.status(404).json({ success: false, error: 'Quotation not found' });
    }

    // Fetch related revisions
    const rootId = quotation.rootQuotationId || quotation.id;
    const revisions = await prisma.quotation.findMany({
      where: {
        OR: [
          { id: rootId },
          { rootQuotationId: rootId },
          { quotationNumber: quotation.quotationNumber },
        ],
      },
      orderBy: { revisionNumber: 'asc' },
      select: {
        id: true,
        quotationNumber: true,
        revisionNumber: true,
        grandTotal: true,
        status: true,
        revisionNotes: true,
        createdAt: true,
      },
    });

    return res.json({
      success: true,
      data: quotation,
      revisions,
    });
  } catch (error) {
    console.error('Get Quotation By ID Error:', error);
    return res.status(500).json({ success: false, error: error.message });
  }
}

// 4. Create Revision (Clones current quotation as Rev N+1)
async function createRevision(req, res) {
  try {
    const { id } = req.params;
    const { revisionNotes, items, ...updateFields } = req.body;

    const parentQuote = await prisma.quotation.findUnique({
      where: { id },
      include: { items: true },
    });

    if (!parentQuote) {
      return res.status(404).json({ success: false, error: 'Parent quotation not found' });
    }

    const nextRevNumber = parentQuote.revisionNumber + 1;
    const rootId = parentQuote.rootQuotationId || parentQuote.id;

    // Use items passed in body or fall back to parent items
    const itemsToUse = items && items.length > 0 ? items : parentQuote.items;

    const calc = calculateQuotationTotals(
      itemsToUse,
      updateFields.cgstRate ?? parentQuote.cgstRate,
      updateFields.sgstRate ?? parentQuote.sgstRate,
      updateFields.igstRate ?? parentQuote.igstRate,
      updateFields.discountTotal ?? parentQuote.discountTotal
    );

    const revisedQuotation = await prisma.quotation.create({
      data: {
        quotationNumber: parentQuote.quotationNumber,
        revisionNumber: nextRevNumber,
        rootQuotationId: rootId,
        date: updateFields.date || new Date().toISOString().split('T')[0],
        validTill: updateFields.validTill || parentQuote.validTill,
        refNumber: updateFields.refNumber ?? parentQuote.refNumber,
        termsOfDelivery: updateFields.termsOfDelivery ?? parentQuote.termsOfDelivery,

        companyName: updateFields.companyName || parentQuote.companyName,
        companyAddress: updateFields.companyAddress || parentQuote.companyAddress,
        companyPhone: updateFields.companyPhone || parentQuote.companyPhone,
        companyEmail: updateFields.companyEmail || parentQuote.companyEmail,
        companyGstin: updateFields.companyGstin || parentQuote.companyGstin,
        companyLogoUrl: updateFields.companyLogoUrl || parentQuote.companyLogoUrl,

        consigneeName: updateFields.consigneeName || parentQuote.consigneeName,
        consigneeAddress: updateFields.consigneeAddress || parentQuote.consigneeAddress,
        consigneeGstin: updateFields.consigneeGstin || parentQuote.consigneeGstin,
        consigneeContact: updateFields.consigneeContact || parentQuote.consigneeContact,
        consigneeMobile: updateFields.consigneeMobile || parentQuote.consigneeMobile,

        buyerName: updateFields.buyerName || parentQuote.buyerName,
        buyerAddress: updateFields.buyerAddress || parentQuote.buyerAddress,
        buyerGstin: updateFields.buyerGstin || parentQuote.buyerGstin,
        buyerContact: updateFields.buyerContact || parentQuote.buyerContact,
        buyerMobile: updateFields.buyerMobile || parentQuote.buyerMobile,

        subtotal: calc.subtotal,
        discountTotal: calc.discountTotal,
        cgstRate: calc.cgstRate,
        cgstAmount: calc.cgstAmount,
        sgstRate: calc.sgstRate,
        sgstAmount: calc.sgstAmount,
        igstRate: calc.igstRate,
        igstAmount: calc.igstAmount,
        roundOff: calc.roundOff,
        grandTotal: calc.grandTotal,
        amountInWords: calc.amountInWords,

        declarationText: updateFields.declarationText || parentQuote.declarationText,
        termsAndConditions: updateFields.termsAndConditions || parentQuote.termsAndConditions,
        status: 'REVISED',
        revisionNotes: revisionNotes || `Revised from Rev ${parentQuote.revisionNumber}`,

        items: {
          create: calc.items,
        },
      },
      include: {
        items: true,
      },
    });

    // Mark previous quotation status as REVISED
    await prisma.quotation.update({
      where: { id },
      data: { status: 'REVISED' },
    });

    return res.status(201).json({
      success: true,
      message: `Revision Rev ${nextRevNumber} created successfully`,
      data: revisedQuotation,
    });
  } catch (error) {
    console.error('Create Revision Error:', error);
    return res.status(400).json({ success: false, error: error.message });
  }
}

// 5. Update Existing Draft Quotation
async function updateQuotation(req, res) {
  try {
    const { id } = req.params;
    const body = req.body;

    const existing = await prisma.quotation.findUnique({ where: { id } });
    if (!existing) {
      return res.status(404).json({ success: false, error: 'Quotation not found' });
    }

    let calcUpdates = {};
    if (body.items) {
      // Delete existing items and recreate
      await prisma.quotationItem.deleteMany({ where: { quotationId: id } });

      const calc = calculateQuotationTotals(
        body.items,
        body.cgstRate ?? existing.cgstRate,
        body.sgstRate ?? existing.sgstRate,
        body.igstRate ?? existing.igstRate,
        body.discountTotal ?? existing.discountTotal
      );

      calcUpdates = {
        subtotal: calc.subtotal,
        discountTotal: calc.discountTotal,
        cgstRate: calc.cgstRate,
        cgstAmount: calc.cgstAmount,
        sgstRate: calc.sgstRate,
        sgstAmount: calc.sgstAmount,
        igstRate: calc.igstRate,
        igstAmount: calc.igstAmount,
        roundOff: calc.roundOff,
        grandTotal: calc.grandTotal,
        amountInWords: calc.amountInWords,
        items: {
          create: calc.items,
        },
      };
    }

    const updated = await prisma.quotation.update({
      where: { id },
      data: {
        date: body.date ?? existing.date,
        validTill: body.validTill ?? existing.validTill,
        refNumber: body.refNumber ?? existing.refNumber,
        termsOfDelivery: body.termsOfDelivery ?? existing.termsOfDelivery,

        consigneeName: body.consigneeName ?? existing.consigneeName,
        consigneeAddress: body.consigneeAddress ?? existing.consigneeAddress,
        consigneeGstin: body.consigneeGstin ?? existing.consigneeGstin,
        consigneeContact: body.consigneeContact ?? existing.consigneeContact,
        consigneeMobile: body.consigneeMobile ?? existing.consigneeMobile,

        buyerName: body.buyerName ?? existing.buyerName,
        buyerAddress: body.buyerAddress ?? existing.buyerAddress,
        buyerGstin: body.buyerGstin ?? existing.buyerGstin,
        buyerContact: body.buyerContact ?? existing.buyerContact,
        buyerMobile: body.buyerMobile ?? existing.buyerMobile,

        declarationText: body.declarationText ?? existing.declarationText,
        termsAndConditions: body.termsAndConditions ?? existing.termsAndConditions,
        status: body.status ?? existing.status,
        revisionNotes: body.revisionNotes ?? existing.revisionNotes,
        ...calcUpdates,
      },
      include: { items: true },
    });

    return res.json({
      success: true,
      message: 'Quotation updated successfully',
      data: updated,
    });
  } catch (error) {
    console.error('Update Quotation Error:', error);
    return res.status(400).json({ success: false, error: error.message });
  }
}

// 6. Duplicate Quotation (As fresh Rev 0)
async function duplicateQuotation(req, res) {
  try {
    const { id } = req.params;
    const source = await prisma.quotation.findUnique({
      where: { id },
      include: { items: true },
    });

    if (!source) {
      return res.status(404).json({ success: false, error: 'Quotation not found' });
    }

    const newNumber = await generateQuotationNumber(prisma);
    const today = new Date().toISOString().split('T')[0];

    const duplicated = await prisma.quotation.create({
      data: {
        quotationNumber: newNumber,
        revisionNumber: 0,
        date: today,
        validTill: source.validTill,
        refNumber: source.refNumber ? `${source.refNumber}-COPY` : 'COPY',
        termsOfDelivery: source.termsOfDelivery,

        companyName: source.companyName,
        companyAddress: source.companyAddress,
        companyPhone: source.companyPhone,
        companyEmail: source.companyEmail,
        companyGstin: source.companyGstin,
        companyLogoUrl: source.companyLogoUrl,

        consigneeName: source.consigneeName,
        consigneeAddress: source.consigneeAddress,
        consigneeGstin: source.consigneeGstin,
        consigneeContact: source.consigneeContact,
        consigneeMobile: source.consigneeMobile,

        buyerName: source.buyerName,
        buyerAddress: source.buyerAddress,
        buyerGstin: source.buyerGstin,
        buyerContact: source.buyerContact,
        buyerMobile: source.buyerMobile,

        subtotal: source.subtotal,
        discountTotal: source.discountTotal,
        cgstRate: source.cgstRate,
        cgstAmount: source.cgstAmount,
        sgstRate: source.sgstRate,
        sgstAmount: source.sgstAmount,
        igstRate: source.igstRate,
        igstAmount: source.igstAmount,
        roundOff: source.roundOff,
        grandTotal: source.grandTotal,
        amountInWords: source.amountInWords,

        declarationText: source.declarationText,
        termsAndConditions: source.termsAndConditions,
        status: 'DRAFT',
        revisionNotes: `Duplicated from ${source.quotationNumber}`,

        items: {
          create: source.items.map((item) => ({
            srNo: item.srNo,
            description: item.description,
            hsnSac: item.hsnSac,
            quantity: item.quantity,
            uom: item.uom,
            rate: item.rate,
            discountPercent: item.discountPercent,
            discountAmount: item.discountAmount,
            amount: item.amount,
          })),
        },
      },
      include: { items: true },
    });

    return res.status(201).json({
      success: true,
      message: 'Quotation duplicated successfully',
      data: duplicated,
    });
  } catch (error) {
    console.error('Duplicate Quotation Error:', error);
    return res.status(400).json({ success: false, error: error.message });
  }
}

// 7. Delete Quotation
async function deleteQuotation(req, res) {
  try {
    const { id } = req.params;
    await prisma.quotation.delete({ where: { id } });
    return res.json({ success: true, message: 'Quotation deleted successfully' });
  } catch (error) {
    console.error('Delete Quotation Error:', error);
    return res.status(400).json({ success: false, error: error.message });
  }
}

// 8. Generate Printable HTML / PDF View matching exact Vyapar / ERP template design
async function getQuotationPdfHtml(req, res) {
  try {
    const { id } = req.params;
    const quotation = await prisma.quotation.findUnique({
      where: { id },
      include: { items: { orderBy: { srNo: 'asc' } } },
    });

    if (!quotation) {
      return res.status(404).send('Quotation not found');
    }

    const html = `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Quotation - ${quotation.quotationNumber}</title>
  <style>
    @page { size: A4; margin: 10mm; }
    body { font-family: 'Arial', sans-serif; color: #000000; margin: 0; padding: 20px; font-size: 12px; background: #f8fafc; }
    .page-container { background: #ffffff; padding: 0; max-width: 800px; margin: 0 auto; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); }
    
    .doc-header-title { font-size: 16px; font-weight: bold; text-align: center; text-transform: capitalize; margin-bottom: 8px; letter-spacing: 0.5px; }
    
    .outer-table { width: 100%; border-collapse: collapse; border: 1.5px solid #000000; }
    .outer-table td, .outer-table th { border: 1px solid #000000; padding: 0; vertical-align: top; }
    
    .top-header-grid { display: flex; width: 100%; }
    .company-left { width: 55%; padding: 10px; border-right: 1px solid #000000; display: flex; gap: 10px; }
    .company-logo { width: 65px; text-align: center; }
    .company-logo img { width: 55px; }
    .company-details { flex: 1; }
    .company-name { font-size: 13px; font-weight: bold; margin-bottom: 4px; }
    .company-subtext { font-size: 10.5px; line-height: 1.35; color: #111111; }
    
    .meta-right { width: 45%; }
    .meta-table { width: 100%; border-collapse: collapse; }
    .meta-table td { border-bottom: 1px solid #000000; padding: 5px 8px; font-size: 11px; }
    .meta-table tr:last-child td { border-bottom: none; }
    .meta-label { font-weight: bold; width: 40%; border-right: 1px solid #000000; }
    .meta-value { width: 60%; }
    
    .party-box { padding: 8px 10px; font-size: 11px; }
    .party-title { font-weight: bold; font-size: 11px; margin-bottom: 3px; }
    .party-desc { line-height: 1.4; }
    
    .item-table { width: 100%; border-collapse: collapse; }
    .item-table th { border: 1px solid #000000; padding: 6px 4px; font-size: 10.5px; font-weight: bold; text-align: center; background: #ffffff; }
    .item-table td { border-left: 1px solid #000000; border-right: 1px solid #000000; padding: 6px 6px; font-size: 11px; vertical-align: top; }
    .item-table tr.total-row td { border-top: 1px solid #000000; font-weight: bold; }
    
    .amount-words-bar { padding: 6px 10px; font-size: 11px; display: flex; justify-content: space-between; align-items: center; }
    
    .declaration-grid { display: flex; width: 100%; min-height: 110px; }
    .declaration-left { width: 55%; padding: 8px 10px; border-right: 1px solid #000000; font-size: 10.5px; line-height: 1.4; }
    .declaration-title { font-weight: bold; margin-bottom: 4px; font-size: 11px; }
    .signatory-right { width: 45%; padding: 8px 10px; display: flex; flex-direction: column; justify-content: space-between; text-align: right; font-size: 11px; }
    
    .computer-gen-footer { text-align: center; font-weight: bold; font-size: 11px; padding: 6px; border-top: 1px solid #000000; }
    
    .sub-footer-text { display: flex; justify-content: space-between; font-size: 9.5px; color: #666666; margin-top: 6px; }

    @media print {
      body { background: white; padding: 0; }
      .page-container { box-shadow: none; }
      .no-print { display: none; }
    }
  </style>
</head>
<body>
  <div class="no-print" style="max-width: 800px; margin: 0 auto 12px auto; text-align: right;">
    <button onclick="window.print()" style="background: #0f172a; color: white; border: none; padding: 8px 18px; font-weight: bold; cursor: pointer; border-radius: 4px;">Print / Download PDF</button>
  </div>

  <div class="page-container">
    <div class="doc-header-title">Quotation</div>

    <table class="outer-table">
      <!-- Top Grid: Logo & Company vs Meta Table -->
      <tr>
        <td style="padding: 0;">
          <div class="top-header-grid">
            <div class="company-left">
              <div class="company-logo">
                <svg width="45" height="45" viewBox="0 0 100 100" fill="none">
                  <polygon points="50,5 95,90 5,90" stroke="#000000" stroke-width="6" fill="none"/>
                  <polygon points="50,22 80,80 20,80" stroke="#000000" stroke-width="4" fill="none"/>
                  <polygon points="50,38 65,70 35,70" stroke="#000000" stroke-width="3" fill="none"/>
                </svg>
                <div style="font-weight: bold; font-size: 9px; margin-top: 2px;">TRIROOP</div>
                <div style="font-size: 6px; color: #555;">Precision in every layer</div>
              </div>
              <div class="company-details">
                <div class="company-name">${quotation.companyName}</div>
                <div class="company-subtext">
                  ${quotation.companyAddress.replace('\n', '<br>')}<br>
                  Phone: ${quotation.companyPhone}
                </div>
              </div>
            </div>
            
            <div class="meta-right">
              <table class="meta-table">
                <tr>
                  <td class="meta-label">Quotation No.</td>
                  <td class="meta-value">${quotation.quotationNumber}</td>
                </tr>
                <tr>
                  <td class="meta-label">Dated</td>
                  <td class="meta-value">${quotation.date}</td>
                </tr>
                <tr>
                  <td class="meta-label">Valid Till</td>
                  <td class="meta-value">${quotation.validTill}</td>
                </tr>
                <tr>
                  <td class="meta-label">Reference No.</td>
                  <td class="meta-value">${quotation.refNumber || '—'}</td>
                </tr>
                <tr>
                  <td class="meta-label">Terms of Delivery</td>
                  <td class="meta-value">${quotation.termsOfDelivery || ''}</td>
                </tr>
              </table>
            </div>
          </div>
        </td>
      </tr>

      <!-- Consignee (Ship to) -->
      <tr>
        <td>
          <div class="party-box">
            <div class="party-title">Consignee (Ship to)</div>
            <div class="party-desc">
              <strong>${quotation.consigneeName}</strong><br>
              ${quotation.consigneeAddress}
            </div>
          </div>
        </td>
      </tr>

      <!-- Buyer (Bill to) -->
      <tr>
        <td>
          <div class="party-box">
            <div class="party-title">Buyer (Bill to)</div>
            <div class="party-desc">
              <strong>${quotation.buyerName}</strong><br>
              ${quotation.buyerAddress}
            </div>
          </div>
        </td>
      </tr>

      <!-- Items Table -->
      <tr>
        <td>
          <table class="item-table">
            <thead>
              <tr>
                <th style="width: 6%;">Sr.<br>No.</th>
                <th style="width: 32%; text-align: left; padding-left: 8px;">Description of Goods</th>
                <th style="width: 10%;">HSN /<br>SAC</th>
                <th style="width: 10%;">Quantity</th>
                <th style="width: 12%; text-align: right; padding-right: 8px;">Rate</th>
                <th style="width: 8%;">UOM</th>
                <th style="width: 8%;">Disc.</th>
                <th style="width: 14%; text-align: right; padding-right: 8px;">Amount</th>
              </tr>
            </thead>
            <tbody>
              ${quotation.items.map((item) => `
                <tr style="height: 28px;">
                  <td style="text-align: center;">${item.srNo}</td>
                  <td style="text-align: left; padding-left: 8px;">${item.description}</td>
                  <td style="text-align: center;">${item.hsnSac || ''}</td>
                  <td style="text-align: center;">${item.quantity}</td>
                  <td style="text-align: right; padding-right: 8px;">₹${item.rate.toLocaleString('en-IN')}</td>
                  <td style="text-align: center;">${item.uom}</td>
                  <td style="text-align: center;">${item.discountPercent > 0 ? item.discountPercent + '%' : ''}</td>
                  <td style="text-align: right; padding-right: 8px;">₹${item.amount.toLocaleString('en-IN')}</td>
                </tr>
              `).join('')}
              <!-- Fill min rows to keep layout balanced -->
              ${Array(Math.max(0, 5 - quotation.items.length)).fill(0).map(() => `
                <tr style="height: 28px;">
                  <td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td>
                </tr>
              `).join('')}

              <tr class="total-row">
                <td colspan="7" style="text-align: left; padding-left: 8px;">Subtotal</td>
                <td style="text-align: right; padding-right: 8px;">₹${quotation.subtotal.toLocaleString('en-IN')}</td>
              </tr>
              ${quotation.discountTotal > 0 ? `
              <tr class="total-row">
                <td colspan="7" style="text-align: left; padding-left: 8px;">Discount</td>
                <td style="text-align: right; padding-right: 8px;">- ₹${quotation.discountTotal.toLocaleString('en-IN')}</td>
              </tr>` : ''}
              <tr class="total-row">
                <td colspan="7" style="text-align: left; padding-left: 8px; font-size: 11.5px;">Grand Total</td>
                <td style="text-align: right; padding-right: 8px; font-size: 11.5px;">₹${quotation.grandTotal.toLocaleString('en-IN')}</td>
              </tr>
            </tbody>
          </table>
        </td>
      </tr>

      <!-- Amount in Words -->
      <tr>
        <td>
          <div class="amount-words-bar">
            <div>
              <span style="font-size: 10.5px;">Amount Chargeable (in words)</span><br>
              <strong style="font-size: 11.5px;">${quotation.amountInWords || 'INR Fourteen Thousand Only'}</strong>
            </div>
            <div style="font-weight: bold; font-size: 10.5px; align-self: flex-end;">E. & O.E</div>
          </div>
        </td>
      </tr>

      <!-- Declaration & Signature Box -->
      <tr>
        <td>
          <div class="declaration-grid">
            <div class="declaration-left">
              <div class="declaration-title">Declaration</div>
              <div style="white-space: pre-wrap;">${quotation.declarationText || `1. Not included (to be paid directly by the client):
1.1. Domain purchase.
1.2. Google Workspace subscription charges.
1.3. Future feature additions beyond the agreed scope.
1.4. Annual maintenance and support.`}</div>
            </div>
            
            <div class="signatory-right">
              <div>for ${quotation.companyName}</div>
              <div style="font-weight: bold; margin-top: 50px;">Authorised Signatory</div>
            </div>
          </div>
        </td>
      </tr>

      <!-- Footer Bar inside Box -->
      <tr>
        <td>
          <div class="computer-gen-footer">This is a Computer Generated Quotation</div>
        </td>
      </tr>
    </table>

    <div class="sub-footer-text">
      <div>Vyapar Book by ${quotation.companyName}</div>
      <div>Page | 1</div>
    </div>
  </div>
</body>
</html>`;

    res.setHeader('Content-Type', 'text/html');
    return res.send(html);
  } catch (error) {
    console.error('PDF HTML Error:', error);
    return res.status(500).send('Error generating PDF view');
  }
}

// 9. Share Quotation (FC-016)
async function shareQuotation(req, res) {
  try {
    const { id } = req.params;
    const { channel = 'LINK' } = req.body || {};

    const quotation = await prisma.quotation.findUnique({ where: { id } });
    if (!quotation) {
      return res.status(404).json({ success: false, message: 'Quotation not found', code: 'QUOTATION_NOT_FOUND' });
    }

    if (quotation.status === 'CONVERTED') {
      return res.status(409).json({ success: false, message: 'Cannot share converted quotation', code: 'ALREADY_CONVERTED' });
    }

    let history = [];
    try {
      history = JSON.parse(quotation.shareHistory || '[]');
    } catch (e) {
      history = [];
    }

    history.push({
      channel,
      sharedAt: new Date().toISOString(),
      sharedBy: req.user?.id || 'system',
    });

    const newStatus = quotation.status === 'DRAFT' ? 'SENT' : quotation.status;

    const updated = await prisma.quotation.update({
      where: { id },
      data: {
        status: newStatus,
        shareHistory: JSON.stringify(history),
      },
    });

    const host = req.headers.host || 'localhost:5000';
    const protocol = req.protocol || 'http';
    const shareUrl = `${protocol}://${host}/api/quotations/${id}/pdf`;

    return res.status(200).json({
      success: true,
      message: 'Quotation shared successfully',
      data: {
        shareUrl,
        quotation: updated,
      },
    });
  } catch (error) {
    console.error('Share Quotation Error:', error);
    return res.status(500).json({ success: false, message: 'Error sharing quotation', error: error.message });
  }
}

const crypto = require('crypto');

// 10. Convert Quotation to Project & Seed BOQ (FC-016)
async function convertToProject(req, res) {
  try {
    const { id } = req.params;

    const quotation = await prisma.quotation.findUnique({
      where: { id },
      include: { items: true },
    });

    if (!quotation) {
      return res.status(404).json({ success: false, message: 'Quotation not found', code: 'QUOTATION_NOT_FOUND' });
    }

    if (quotation.status === 'CONVERTED' || quotation.convertedProjectId) {
      return res.status(409).json({
        success: false,
        message: 'This quotation has already been converted into a project',
        code: 'ALREADY_CONVERTED',
      });
    }

    // Run atomic transaction across Project, BOQ, Quotation, and ActivityLog
    const result = await prisma.$transaction(async (tx) => {
      // 1. Create Project
      const projectId = crypto.randomUUID();
      const project = await tx.project.create({
        data: {
          id: projectId,
          name: `${quotation.buyerName} Project`,
          clientName: quotation.buyerName || 'Client',
          designerName: quotation.companyName || 'Lead Designer',
          startDate: quotation.date || new Date().toISOString().split('T')[0],
          endDate: quotation.validTill || new Date().toISOString().split('T')[0],
          budget: quotation.grandTotal || 0,
          status: 'PLANNING',
          customerId: quotation.customerId || null,
          companyId: req.user?.companyId || null,
          createdBy: req.user?.id ? String(req.user.id) : null,
        },
      });

      // 2. Seed BOQ
      const boq = await tx.boq.create({
        data: {
          projectId: project.id,
          projectName: project.name,
          totalCost: quotation.grandTotal,
          companyId: req.user?.companyId || null,
          createdBy: req.user?.id ? String(req.user.id) : null,
          items: {
            create: quotation.items.map((item) => ({
              itemName: item.description,
              unit: item.uom || 'NOS',
              quantity: item.quantity,
              unitPrice: item.rate,
              totalAmount: item.amount,
              sortOrder: item.srNo,
            })),
          },
        },
      });

      // 3. Update Quotation status to CONVERTED
      const updatedQuotation = await tx.quotation.update({
        where: { id },
        data: {
          status: 'CONVERTED',
          convertedProjectId: project.id,
        },
      });

      // 4. Log Activity
      await tx.activityLog.create({
        data: {
          type: 'QUOTATION_CONVERTED',
          message: `Converted Quotation ${quotation.quotationNumber} into Project ${project.name}`,
          actorId: req.user?.id || null,
          companyId: req.user?.companyId || null,
          relatedEntityType: 'QUOTATION',
          relatedEntityId: quotation.id,
        },
      });

      return { project, boq, quotation: updatedQuotation };
    });

    return res.status(201).json({
      success: true,
      message: 'Quotation successfully converted into project and BOQ seeded',
      data: result,
    });
  } catch (error) {
    console.error('Convert Quotation Error:', error);
    return res.status(500).json({ success: false, message: 'Error converting quotation to project', error: error.message });
  }
}

module.exports = {
  createQuotation,
  getQuotations,
  getQuotationById,
  createRevision,
  updateQuotation,
  duplicateQuotation,
  deleteQuotation,
  getQuotationPdfHtml,
  shareQuotation,
  convertToProject,
};
