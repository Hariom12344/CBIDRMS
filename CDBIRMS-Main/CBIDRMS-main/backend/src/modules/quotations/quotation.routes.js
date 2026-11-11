const express = require('express');
const router = express.Router();
const controller = require('./quotation.controller');

// CRUD & Operations
router.post('/', controller.createQuotation);
router.get('/', controller.getQuotations);
router.get('/:id', controller.getQuotationById);
router.put('/:id', controller.updateQuotation);
router.post('/:id/revise', controller.createRevision);
router.post('/:id/duplicate', controller.duplicateQuotation);
router.post('/:id/share', controller.shareQuotation);
router.post('/:id/convert', controller.convertToProject);
router.delete('/:id', controller.deleteQuotation);

// PDF / HTML Print View
router.get('/:id/pdf', controller.getQuotationPdfHtml);

module.exports = router;
