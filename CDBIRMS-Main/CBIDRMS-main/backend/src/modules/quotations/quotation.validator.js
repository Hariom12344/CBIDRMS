const { z } = require('zod');

const quotationItemSchema = z.object({
  srNo: z.number().optional(),
  description: z.string().min(1, 'Description is required'),
  hsnSac: z.string().optional().nullable(),
  quantity: z.number().positive('Quantity must be greater than 0'),
  uom: z.string().default('NOS'),
  rate: z.number().min(0, 'Rate must be non-negative'),
  discountPercent: z.number().min(0).max(100).default(0),
  discountAmount: z.number().min(0).default(0),
  amount: z.number().optional(),
});

const createQuotationSchema = z.object({
  date: z.string().min(1, 'Date is required'),
  validTill: z.string().min(1, 'Valid till date is required'),
  refNumber: z.string().optional().nullable(),
  termsOfDelivery: z.string().optional().nullable(),

  companyName: z.string().default('TechSolutions & Trade Private Limited'),
  companyAddress: z.string().default('Plot No. 42, Tech Park Phase 2, Hinjewadi, Pune, Maharashtra 411057'),
  companyPhone: z.string().default('+91 90116 94002'),
  companyEmail: z.string().default('contact@techsolutions.com'),
  companyGstin: z.string().default('27AAACT1234F1Z5'),
  companyLogoUrl: z.string().optional().nullable(),

  consigneeName: z.string().min(1, 'Consignee name is required'),
  consigneeAddress: z.string().min(1, 'Consignee address is required'),
  consigneeGstin: z.string().optional().nullable(),
  consigneeContact: z.string().optional().nullable(),
  consigneeMobile: z.string().optional().nullable(),

  buyerName: z.string().min(1, 'Buyer name is required'),
  buyerAddress: z.string().min(1, 'Buyer address is required'),
  buyerGstin: z.string().optional().nullable(),
  buyerContact: z.string().optional().nullable(),
  buyerMobile: z.string().optional().nullable(),

  items: z.array(quotationItemSchema).min(1, 'At least one item is required'),

  discountTotal: z.number().min(0).default(0),
  cgstRate: z.number().min(0).default(9.0),
  sgstRate: z.number().min(0).default(9.0),
  igstRate: z.number().min(0).default(0.0),

  declarationText: z.string().optional().nullable(),
  termsAndConditions: z.string().optional().nullable(),
  status: z.enum(['DRAFT', 'SENT', 'REVISED', 'APPROVED', 'REJECTED', 'CONVERTED']).default('DRAFT'),
  revisionNotes: z.string().optional().nullable(),
});

module.exports = {
  createQuotationSchema,
  quotationItemSchema,
};
