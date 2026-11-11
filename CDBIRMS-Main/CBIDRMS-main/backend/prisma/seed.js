const { PrismaClient } = require("@prisma/client");
const bcrypt = require("bcrypt");

const prisma = new PrismaClient();

async function main() {
    console.log("Starting seeding...");

    // Clean existing data
    await prisma.auditLog.deleteMany({});
    await prisma.project.deleteMany({});
    await prisma.lead.deleteMany({});
    await prisma.user.deleteMany({});

    // Hash password
    const hashedPassword = await bcrypt.hash("Password123", 10);

    // Create Users
    const rolesToSeed = [
        { fullName: "Super Admin", email: "superadmin@idpms.com", role: "SUPER_ADMIN", phone: "9876543210" },
        { fullName: "Sarah Admin", email: "admin@idpms.com", role: "COMPANY_ADMIN", phone: "9876543211" },
        { fullName: "System Admin", email: "sysadmin@idpms.com", role: "ADMIN", phone: "9876543212" },
        { fullName: "Project Manager", email: "pm@idpms.com", role: "PROJECT_MANAGER", phone: "9876543213" },
        { fullName: "Site Supervisor", email: "supervisor@idpms.com", role: "SITE_SUPERVISOR", phone: "9876543214" },
        { fullName: "Michael Designer", email: "designer@idpms.com", role: "DESIGNER", phone: "9876543215" },
        { fullName: "IDPMS Design User", email: "idpmsdesign@gmail.com", role: "DESIGNER", phone: "9876543219" },
        { fullName: "Accountant User", email: "accountant@idpms.com", role: "ACCOUNTANT", phone: "9876543216" },
        { fullName: "Vendor User", email: "vendor@idpms.com", role: "VENDOR", phone: "9876543217" },
        { fullName: "Client User", email: "client@idpms.com", role: "CLIENT", phone: "9876543218" }
    ];

    const seededUsers = {};
    for (const acc of rolesToSeed) {
        const u = await prisma.user.create({
            data: {
                fullName: acc.fullName,
                email: acc.email,
                phone: acc.phone,
                password: hashedPassword,
                role: acc.role,
                isActive: true,
                passwordSet: true
            }
        });
        seededUsers[acc.role] = u;
    }

    const companyAdminUser = seededUsers["COMPANY_ADMIN"];
    const designerUser = seededUsers["DESIGNER"];

    console.log(`Seeded all 9 role login accounts with password 'Password123'`);

    // Create Leads
    const lead1 = await prisma.lead.create({
        data: {
            id: "LD-101",
            clientName: "John Doe",
            email: "john@example.com",
            phone: "+1 555-0101",
            status: "New",
            propertyType: "3BHK Modern Apartment",
            estimatedBudget: 45000,
            assignedToId: designerUser.id
        }
    });

    const lead2 = await prisma.lead.create({
        data: {
            id: "LD-102",
            clientName: "Jane Smith",
            email: "jane@example.com",
            phone: "+1 555-0102",
            status: "Contacted",
            propertyType: "Luxury Penthouse",
            estimatedBudget: 120000,
            assignedToId: designerUser.id
        }
    });

    const lead3 = await prisma.lead.create({
        data: {
            id: "LD-103",
            clientName: "Acme Office Corp",
            email: "office@acme.com",
            phone: "+1 555-0103",
            status: "Meeting Scheduled",
            propertyType: "Commercial Office Lobby",
            estimatedBudget: 85000,
            assignedToId: null // Unassigned
        }
    });

    const lead4 = await prisma.lead.create({
        data: {
            id: "LD-104",
            clientName: "Robert Vance",
            email: "robert@vancecorp.com",
            phone: "+1 555-0104",
            status: "Proposal Sent",
            propertyType: "Villa Renovation",
            estimatedBudget: 250000,
            assignedToId: companyAdminUser.id // Assigned to Company Admin
        }
    });

    console.log(`Seeded 4 leads:
      - John Doe (Assigned to Designer, Status: New)
      - Jane Smith (Assigned to Designer, Status: Contacted)
      - Acme Office Corp (Unassigned, Status: Meeting Scheduled)
      - Robert Vance (Assigned to Admin, Status: Proposal Sent)`);

    // Clean and Seed Projects
    await prisma.siteTask.deleteMany({});
    await prisma.siteUpdate.deleteMany({});
    await prisma.projectTeamMember.deleteMany({});
    await prisma.projectStage.deleteMany({});

    const prj1 = await prisma.project.create({
        data: {
            id: "PRJ-101",
            name: "Villa Royale Interior Renovation",
            clientName: "John Doe",
            designerName: designerUser.fullName,
            startDate: "2026-03-01",
            endDate: "2026-08-30",
            budget: 1500000.0,
            status: "ONGOING",
            progress: 0.35
        }
    });

    const prj2 = await prisma.project.create({
        data: {
            id: "PRJ-102",
            name: "TechHub Open Plan Office",
            clientName: "Acme Office Corp",
            designerName: designerUser.fullName,
            startDate: "2026-02-15",
            endDate: "2026-07-15",
            budget: 2800000.0,
            status: "ONGOING",
            progress: 0.60
        }
    });

    const supervisorUser = seededUsers["SITE_SUPERVISOR"];

    // Seed Site Updates
    const su1 = await prisma.siteUpdate.create({
        data: {
            id: "SU-501",
            projectId: prj1.id,
            supervisorId: supervisorUser.id,
            updateDate: "2026-03-12",
            description: "Completed Italian Marble flooring installation in Living Room. Drywall prep ongoing.",
            issueReported: null,
            issueSeverity: null,
            photoUrls: JSON.stringify([
                "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600",
                "https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?w=600"
            ])
        }
    });

    const su2 = await prisma.siteUpdate.create({
        data: {
            id: "SU-502",
            projectId: prj2.id,
            supervisorId: supervisorUser.id,
            updateDate: "2026-03-10",
            description: "Ceiling wiring finished. Awaiting acoustic panel shipment.",
            issueReported: "Minor delay in panel delivery from vendor.",
            issueSeverity: "MEDIUM",
            photoUrls: JSON.stringify([
                "https://images.unsplash.com/photo-1541888946425-d0fbb186a5b3?w=600"
            ])
        }
    });

    // Seed Site Tasks
    await prisma.siteTask.create({
        data: {
            id: "ST-801",
            projectId: prj1.id,
            title: "Living Room Italian Marble Polishing",
            assignedTo: supervisorUser.id,
            status: "IN_PROGRESS",
            dueDate: "2026-03-25",
            linkedSiteUpdateId: su1.id
        }
    });

    await prisma.siteTask.create({
        data: {
            id: "ST-802",
            projectId: prj1.id,
            title: "Kitchen Modular Cabinet Frame Mounting",
            assignedTo: supervisorUser.id,
            status: "PENDING",
            dueDate: "2026-03-30"
        }
    });

    await prisma.siteTask.create({
        data: {
            id: "ST-803",
            projectId: prj2.id,
            title: "Acoustic Panel Installation - Main Bay",
            assignedTo: supervisorUser.id,
            status: "PENDING",
            dueDate: "2026-03-22",
            linkedSiteUpdateId: su2.id
        }
    });

    // Clean and Seed Quotations
    await prisma.quotationItem.deleteMany({});
    await prisma.quotation.deleteMany({});

    const q1 = await prisma.quotation.create({
        data: {
            quotationNumber: 'TTPL/QTN/2026-27/002',
            revisionNumber: 0,
            date: '16-Jul-2026',
            validTill: '15-Aug-2026',
            refNumber: '—',
            termsOfDelivery: 'Immediate Handover',

            companyName: 'Triroop Techconsult Private Limited',
            companyAddress: 'C/O VINAYAK WALKE, CHAMUNDA DEVI ROAD TALUKA, Washim\nWashim - 444505, Maharashtra',
            companyPhone: '+91 90116 94002',
            companyEmail: 'contact@triroop.com',
            companyGstin: '27AAACT1234F1Z5',

            consigneeName: 'The Space Decore',
            consigneeAddress: 'Guruvista phase 2, Kharadi, Pune – 411014',
            consigneeGstin: '27AABCA5678K1ZB',
            consigneeContact: 'Project Manager',
            consigneeMobile: '+91 90116 94002',

            buyerName: 'The Space Decore',
            buyerAddress: 'Guruvista phase 2, Kharadi, Pune – 411014',
            buyerGstin: '27AABCA5678K1ZB',
            buyerContact: 'Accounts Lead',
            buyerMobile: '+91 90116 94002',

            subtotal: 18000,
            discountTotal: 4000,
            cgstRate: 0,
            cgstAmount: 0,
            sgstRate: 0,
            sgstAmount: 0,
            igstRate: 0,
            igstAmount: 0,
            roundOff: 0,
            grandTotal: 14000,
            amountInWords: 'INR Fourteen Thousand Only',

            declarationText: `1. Not included (to be paid directly by the client):
1.1. Domain purchase.
1.2. Google Workspace subscription charges.
1.3. Future feature additions beyond the agreed scope.
1.4. Annual maintenance and support.`,

            termsAndConditions: '1. Quotation valid until date mentioned above.\n2. Payment terms as agreed.',
            status: 'APPROVED',
            revisionNotes: 'Initial Approved Proposal',

            items: {
                create: [
                    { srNo: 1, description: 'Website page development', hsnSac: '', quantity: 5, uom: 'Nos', rate: 2000, discountPercent: 0, discountAmount: 0, amount: 10000 },
                    { srNo: 2, description: 'Admin panel feature', hsnSac: '', quantity: 1, uom: 'Nos', rate: 3000, discountPercent: 0, discountAmount: 0, amount: 3000 },
                    { srNo: 3, description: 'WhatsApp integration', hsnSac: '', quantity: 1, uom: 'Nos', rate: 2000, discountPercent: 0, discountAmount: 0, amount: 2000 },
                    { srNo: 4, description: 'Reports and analytics dashboard', hsnSac: '', quantity: 1, uom: 'Nos', rate: 3000, discountPercent: 0, discountAmount: 0, amount: 3000 },
                    { srNo: 5, description: 'Deployment and handover', hsnSac: '', quantity: 1, uom: 'Nos', rate: 0, discountPercent: 0, discountAmount: 0, amount: 0 },
                ]
            }
        }
    });

    console.log(`Seeded ERP Quotation: ${q1.quotationNumber} (Grand Total: ₹${q1.grandTotal})`);

    // Seed Finance Data (FC-013)
    await prisma.invoice.deleteMany({});
    await prisma.payment.deleteMany({});
    await prisma.expense.deleteMany({});
    await prisma.projectBudget.deleteMany({});

    await prisma.projectBudget.create({
        data: {
            projectId: "PRJ-101",
            budget: 500000.0,
            setBy: companyAdminUser.id
        }
    });

    await prisma.expense.createMany({
        data: [
            { projectId: "PRJ-101", category: "MATERIAL", amount: 45000.0, date: "2026-02-01", note: "Plywood and laminate sheets", recordedBy: companyAdminUser.id },
            { projectId: "PRJ-101", category: "LABOR", amount: 18000.0, date: "2026-02-05", note: "Carpentry team advance", recordedBy: companyAdminUser.id },
            { projectId: "PRJ-101", category: "VENDOR_PAYMENT", amount: 25000.0, date: "2026-02-10", note: "Hardware vendor settlement", recordedBy: companyAdminUser.id }
        ]
    });

    const inv1 = await prisma.invoice.create({
        data: {
            id: "INV-2026-001",
            projectId: "PRJ-101",
            clientName: "Robert Vance",
            amount: 45000.0,
            pendingAmount: 0.0,
            dueDate: "2026-03-01",
            status: "PAID",
            createdBy: companyAdminUser.id
        }
    });

    await prisma.payment.create({
        data: {
            invoiceId: inv1.id,
            amount: 45000.0,
            date: "2026-02-15",
            method: "BANK_TRANSFER",
            note: "Full settlement via NEFT",
            recordedBy: companyAdminUser.id
        }
    });

    const inv2 = await prisma.invoice.create({
        data: {
            id: "INV-2026-002",
            projectId: "PRJ-101",
            clientName: "Apex Innovations",
            amount: 25000.0,
            pendingAmount: 15000.0,
            dueDate: "2026-03-15",
            status: "PENDING",
            createdBy: companyAdminUser.id
        }
    });

    await prisma.payment.create({
        data: {
            invoiceId: inv2.id,
            amount: 10000.0,
            date: "2026-02-18",
            method: "UPI",
            note: "Partial advance payment",
            recordedBy: companyAdminUser.id
        }
    });

    await prisma.invoice.create({
        data: {
            id: "INV-2026-003",
            projectId: "PRJ-101",
            clientName: "Elena Rostova",
            amount: 75000.0,
            pendingAmount: 75000.0,
            dueDate: "2026-02-10",
            status: "OVERDUE",
            createdBy: companyAdminUser.id
        }
    });

    console.log("Seeded sample Finance Invoices, Payments, Expenses & Budgets successfully!");
    console.log("Seeding complete!");
}

main()
    .catch((e) => {
        console.error("Error seeding database:", e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
