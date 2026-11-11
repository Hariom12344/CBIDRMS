const http = require("http");
const path = require("path");
const jwt = require(path.join(__dirname, "../backend/node_modules/jsonwebtoken"));

const JWT_SECRET = process.env.JWT_SECRET || "super-secret-jwt-key-idpms-2026";

function makeToken(user) {
    return jwt.sign(
        {
            id: user.id,
            email: user.email,
            role: user.role,
            fullName: user.fullName,
            companyId: user.companyId || 1
        },
        JWT_SECRET,
        { expiresIn: "1h" }
    );
}

const users = {
    admin: { id: 19, email: "test_super_admin@idpms.com", role: "SUPER_ADMIN", fullName: "Test SUPER_ADMIN", companyId: 1 },
    accountant: { id: 25, email: "test_accountant@idpms.com", role: "ACCOUNTANT", fullName: "Test ACCOUNTANT", companyId: 1 },
    pm: { id: 22, email: "test_project_manager@idpms.com", role: "PROJECT_MANAGER", fullName: "Test PROJECT_MANAGER", companyId: 1 },
    designer: { id: 24, email: "test_designer@idpms.com", role: "DESIGNER", fullName: "Test DESIGNER", companyId: 1 },
    vendor: { id: 26, email: "test_vendor@idpms.com", role: "VENDOR", fullName: "Test VENDOR", companyId: 1 }
};

function httpRequest({ method, path: reqPath, headers = {}, body = null }) {
    return new Promise((resolve, reject) => {
        const req = http.request(
            {
                host: "localhost",
                port: 5000,
                method,
                path: reqPath,
                headers
            },
            (res) => {
                let data = "";
                res.on("data", (chunk) => (data += chunk));
                res.on("end", () => {
                    try {
                        const parsed = JSON.parse(data);
                        resolve({ status: res.statusCode, body: parsed });
                    } catch (e) {
                        resolve({ status: res.statusCode, body: data });
                    }
                });
            }
        );
        req.on("error", reject);
        if (body) {
            req.write(body);
        }
        req.end();
    });
}

async function runTests() {
    console.log("==================================================");
    console.log("RUNNING FINANCE MANAGEMENT VERIFICATION TESTS");
    console.log("==================================================\n");

    let passed = 0;
    let failed = 0;

    function assert(condition, message) {
        if (condition) {
            console.log(`✅ PASS: ${message}`);
            passed++;
        } else {
            console.error(`❌ FAIL: ${message}`);
            failed++;
        }
    }

    try {
        const adminToken = makeToken(users.admin);
        const accountantToken = makeToken(users.accountant);
        const pmToken = makeToken(users.pm);
        const designerToken = makeToken(users.designer);
        const vendorToken = makeToken(users.vendor);

        // 1. Create a Test Project for Finance Operations
        const createPrjRes = await httpRequest({
            method: "POST",
            path: "/api/projects",
            headers: {
                "Authorization": `Bearer ${adminToken}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                name: "Test Finance Project 2026",
                clientName: "Acme Corp Finance",
                startDate: "2026-03-01",
                endDate: "2026-09-30",
                budget: 1000000
            })
        });

        const projectId = createPrjRes.body?.data?.id || "PRJ-999";
        console.log(`Using Project ID for Finance tests: ${projectId}`);

        // TEST 1: Get Finance Summary
        const summaryRes = await httpRequest({
            method: "GET",
            path: "/api/finance/summary",
            headers: { "Authorization": `Bearer ${accountantToken}` }
        });

        console.log("Summary Status:", summaryRes.status, "Body:", JSON.stringify(summaryRes.body));

        assert(summaryRes.status === 200, "Get finance summary returns 200 OK");
        assert(typeof summaryRes.body?.data?.received === "number", "Summary contains received amount");
        assert(typeof summaryRes.body?.data?.pending === "number", "Summary contains pending amount");
        assert(typeof summaryRes.body?.data?.overdue === "number", "Summary contains overdue amount");

        // TEST 2: Set Project Budget
        const setBudgetRes = await httpRequest({
            method: "POST",
            path: `/api/finance/projects/${projectId}/budget`,
            headers: {
                "Authorization": `Bearer ${accountantToken}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({ budget: 750000 })
        });

        assert(setBudgetRes.status === 200, "Accountant sets project budget (200 OK)");
        assert(setBudgetRes.body?.data?.budget === 750000, "Project budget updated to 750000");

        // TEST 3: Get Project Budget Summary
        const getBudgetRes = await httpRequest({
            method: "GET",
            path: `/api/finance/projects/${projectId}/budget`,
            headers: { "Authorization": `Bearer ${accountantToken}` }
        });

        assert(getBudgetRes.status === 200, "Get project budget summary returns 200 OK");
        assert(getBudgetRes.body?.data?.budget === 750000, "Budget value matches 750000");

        // TEST 4: Generate Invoice
        const createInvRes = await httpRequest({
            method: "POST",
            path: "/api/finance/invoices",
            headers: {
                "Authorization": `Bearer ${accountantToken}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                projectId,
                clientName: "Acme Corp Finance",
                amount: 250000,
                dueDate: "2026-12-31"
            })
        });

        assert(createInvRes.status === 201, "Accountant generates invoice (201 Created)");
        assert(Boolean(createInvRes.body?.data?.invoice?.id), "Invoice has an auto-generated ID");
        assert(createInvRes.body?.data?.invoice?.pendingAmount === 250000, "Initial pending amount equals invoice total");
        assert(createInvRes.body?.data?.invoice?.status === "PENDING", "Initial status is PENDING");

        const invoiceId = createInvRes.body?.data?.invoice?.id;

        // TEST 5: Record Partial Payment
        const payment1Res = await httpRequest({
            method: "POST",
            path: `/api/finance/invoices/${invoiceId}/payments`,
            headers: {
                "Authorization": `Bearer ${accountantToken}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                amount: 100000,
                method: "BANK_TRANSFER",
                note: "First installment payment"
            })
        });

        assert(payment1Res.status === 201, "Accountant records partial payment of ₹100,000 (201 Created)");
        assert(payment1Res.body?.data?.invoice?.pendingAmount === 150000, "Pending amount reduced to ₹150,000");
        assert(payment1Res.body?.data?.invoice?.status === "PENDING", "Invoice status remains PENDING");

        // TEST 6: Payment Exceeds Pending Balance Validation Error
        const paymentOverflowRes = await httpRequest({
            method: "POST",
            path: `/api/finance/invoices/${invoiceId}/payments`,
            headers: {
                "Authorization": `Bearer ${accountantToken}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                amount: 200000, // Exceeds pending 150,000
                method: "UPI"
            })
        });

        assert(paymentOverflowRes.status === 400, "Payment exceeding pending balance rejected with 400 Bad Request");

        // TEST 7: Record Remaining Payment (Complete Payment -> status = PAID)
        const payment2Res = await httpRequest({
            method: "POST",
            path: `/api/finance/invoices/${invoiceId}/payments`,
            headers: {
                "Authorization": `Bearer ${accountantToken}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                amount: 150000,
                method: "UPI",
                note: "Final payment"
            })
        });

        assert(payment2Res.status === 201, "Accountant records remaining payment of ₹150,000 (201 Created)");
        assert(payment2Res.body?.data?.invoice?.pendingAmount === 0, "Pending amount is 0");
        assert(payment2Res.body?.data?.invoice?.status === "PAID", "Invoice status updated to PAID");

        // TEST 8: Create Expenses
        const exp1Res = await httpRequest({
            method: "POST",
            path: "/api/finance/expenses",
            headers: {
                "Authorization": `Bearer ${accountantToken}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                projectId,
                category: "MATERIAL",
                amount: 50000,
                note: "Cement and steel materials"
            })
        });

        assert(exp1Res.status === 201, "Record material expense of ₹50,000 (201 Created)");

        const exp2Res = await httpRequest({
            method: "POST",
            path: "/api/finance/expenses",
            headers: {
                "Authorization": `Bearer ${accountantToken}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                projectId,
                category: "LABOR",
                amount: 30000,
                note: "Site labor weekly payout"
            })
        });

        assert(exp2Res.status === 201, "Record labor expense of ₹30,000 (201 Created)");

        // TEST 9: Verify Budget Calculation (spent = 80,000, remaining = 670,000)
        const checkBudgetRes = await httpRequest({
            method: "GET",
            path: `/api/finance/projects/${projectId}/budget`,
            headers: { "Authorization": `Bearer ${accountantToken}` }
        });

        assert(checkBudgetRes.body?.data?.spent === 80000, "Calculated spent is ₹80,000");
        assert(checkBudgetRes.body?.data?.remaining === 670000, "Calculated remaining budget is ₹670,000");

        // TEST 10: List Invoices with filter
        const listInvRes = await httpRequest({
            method: "GET",
            path: `/api/finance/invoices?projectId=${projectId}`,
            headers: { "Authorization": `Bearer ${accountantToken}` }
        });

        assert(listInvRes.status === 200, "List invoices returns 200 OK");
        assert(Array.isArray(listInvRes.body?.data?.invoices), "Invoices list is an array");

        // TEST 11: List Expenses with filter
        const listExpRes = await httpRequest({
            method: "GET",
            path: `/api/finance/expenses?projectId=${projectId}`,
            headers: { "Authorization": `Bearer ${accountantToken}` }
        });

        assert(listExpRes.status === 200, "List expenses returns 200 OK");
        assert(Array.isArray(listExpRes.body?.data?.expenses), "Expenses list is an array");

        // TEST 12: RBAC Unauthorized Attempts (Vendor trying to create invoice)
        const vendorInvoice = await httpRequest({
            method: "POST",
            path: "/api/finance/invoices",
            headers: {
                "Authorization": `Bearer ${vendorToken}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                projectId,
                clientName: "Unauthorized",
                amount: 100,
                dueDate: "2026-12-31"
            })
        });

        assert(vendorInvoice.status === 403, "Vendor attempt to create invoice rejected with 403 FORBIDDEN");

    } catch (err) {
        console.error("Test execution failed:", err);
    }

    console.log("\n==================================================");
    console.log(`TEST SUMMARY: ${passed} PASSED, ${failed} FAILED`);
    console.log("==================================================\n");

    if (failed > 0) {
        process.exit(1);
    }
}

runTests();
