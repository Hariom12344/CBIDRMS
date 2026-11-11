const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { numberToIndianWords } = require('../src/utils/amount_in_words.utils');

async function seedQuotations() {
  console.log('Seeding initial ERP Quotations...');

  // 1. Clear existing quotations if any
  await prisma.quotationItem.deleteMany({});
  await prisma.quotation.deleteMany({});

  // Quote 1: ERP Software Development Fitout
  const q1Items = [
    { srNo: 1, description: 'Custom ERP Module Development & Integration', hsnSac: '998313', quantity: 1, uom: 'NOS', rate: 125000, discountPercent: 5, discountAmount: 6250, amount: 118750 },
    { srNo: 2, description: 'Cloud Infrastructure Setup & Security Audit', hsnSac: '998314', quantity: 1, uom: 'NOS', rate: 35000, discountPercent: 0, discountAmount: 0, amount: 35000 },
    { srNo: 3, description: 'UI/UX Interactive Dashboard Design (Material 3)', hsnSac: '998315', quantity: 1, uom: 'SET', rate: 45000, discountPercent: 10, discountAmount: 4500, amount: 40500 },
  ];
  const q1Sub = 194250;
  const q1Cgst = q1Sub * 0.09;
  const q1Sgst = q1Sub * 0.09;
  const q1TotalBefore = q1Sub + q1Cgst + q1Sgst;
  const q1Grand = Math.round(q1TotalBefore);
  const q1Round = Number((q1Grand - q1TotalBefore).toFixed(2));

  await prisma.quotation.create({
    data: {
      quotationNumber: 'TTPL/QTN/2026-27/001',
      revisionNumber: 0,
      date: '2026-08-01',
      validTill: '2026-08-31',
      refNumber: 'PO-REF-9021',
      termsOfDelivery: 'Immediate (Digital Handover)',

      companyName: 'TechSolutions & Trade Private Limited',
      companyAddress: 'Plot No. 42, Tech Park Phase 2, Hinjewadi, Pune, Maharashtra 411057',
      companyPhone: '+91 90116 94002',
      companyEmail: 'quotations@techsolutions.com',
      companyGstin: '27AAACT1234F1Z5',

      consigneeName: 'Apex Innovations Pvt Ltd (Data Center)',
      consigneeAddress: 'Building 4B, Cyber City, Magarpatta, Pune 411028',
      consigneeGstin: '27AABCA5678K1ZB',
      consigneeContact: 'Rajesh Sharma (IT Lead)',
      consigneeMobile: '+91 98220 11223',

      buyerName: 'Apex Innovations Pvt Ltd',
      buyerAddress: 'Unit 102, Commercial Hub, SB Road, Pune 411016',
      buyerGstin: '27AABCA5678K1ZB',
      buyerContact: 'Anita Roy (Finance Mgr)',
      buyerMobile: '+91 98220 44556',

      subtotal: q1Sub,
      discountTotal: 0,
      cgstRate: 9,
      cgstAmount: q1Cgst,
      sgstRate: 9,
      sgstAmount: q1Sgst,
      igstRate: 0,
      igstAmount: 0,
      roundOff: q1Round,
      grandTotal: q1Grand,
      amountInWords: numberToIndianWords(q1Grand),

      declarationText: `Not included:
- Domain Purchase & SSL Cert Renewal
- Third-party SMS/Payment Gateway Charges
- Annual Maintenance & Support beyond 60 days`,

      termsAndConditions: `1. 50% advance payment required upon purchase order confirmation.
2. 40% upon completion of development milestone.
3. 10% before final deployment & hand-over.`,

      status: 'APPROVED',
      revisionNotes: 'Approved by Client',

      items: { create: q1Items },
    },
  });

  // Quote 2: Interior Fitout Quotation
  const q2Items = [
    { srNo: 1, description: 'Modular Office Workstation Units (8 Seater)', hsnSac: '940330', quantity: 2, uom: 'SET', rate: 48000, discountPercent: 0, discountAmount: 0, amount: 96000 },
    { srNo: 2, description: 'Executive Conference Table with Cable Management', hsnSac: '940330', quantity: 1, uom: 'NOS', rate: 65000, discountPercent: 5, discountAmount: 3250, amount: 61750 },
    { srNo: 3, description: 'Acoustic Wall Paneling & Soft Board Installation', hsnSac: '391810', quantity: 450, uom: 'SQFT', rate: 180, discountPercent: 0, discountAmount: 0, amount: 81000 },
  ];
  const q2Sub = 238750;
  const q2Cgst = q2Sub * 0.09;
  const q2Sgst = q2Sub * 0.09;
  const q2TotalBefore = q2Sub + q2Cgst + q2Sgst;
  const q2Grand = Math.round(q2TotalBefore);
  const q2Round = Number((q2Grand - q2TotalBefore).toFixed(2));

  await prisma.quotation.create({
    data: {
      quotationNumber: 'TTPL/QTN/2026-27/002',
      revisionNumber: 1,
      date: '2026-08-05',
      validTill: '2026-09-05',
      refNumber: 'RF-INTERIOR-04',
      termsOfDelivery: 'Delivery within 14 business days',

      companyName: 'TechSolutions & Trade Private Limited',
      companyAddress: 'Plot No. 42, Tech Park Phase 2, Hinjewadi, Pune, Maharashtra 411057',
      companyPhone: '+91 90116 94002',
      companyEmail: 'quotations@techsolutions.com',
      companyGstin: '27AAACT1234F1Z5',

      consigneeName: 'Vance Residence Site',
      consigneeAddress: 'Villa 14, Royal Palms Estate, Baner, Pune 411045',
      consigneeGstin: '',
      consigneeContact: 'Robert Vance',
      consigneeMobile: '+91 98900 12345',

      buyerName: 'Robert Vance',
      buyerAddress: 'Villa 14, Royal Palms Estate, Baner, Pune 411045',
      buyerGstin: '',
      buyerContact: 'Robert Vance',
      buyerMobile: '+91 98900 12345',

      subtotal: q2Sub,
      discountTotal: 0,
      cgstRate: 9,
      cgstAmount: q2Cgst,
      sgstRate: 9,
      sgstAmount: q2Sgst,
      igstRate: 0,
      igstAmount: 0,
      roundOff: q2Round,
      grandTotal: q2Grand,
      amountInWords: numberToIndianWords(q2Grand),

      declarationText: `Not included:
- Civil dismantling of existing structural brickwork
- High voltage electrical meter enhancement`,

      termsAndConditions: `1. Payment mode: Bank transfer / Cheque.
2. Material transit insurance included.`,

      status: 'SENT',
      revisionNotes: 'Revised quantities for Conference Table',

      items: { create: q2Items },
    },
  });

  console.log('ERP Quotations Seeded Successfully!');
}

seedQuotations()
  .catch((e) => {
    console.error(e);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
