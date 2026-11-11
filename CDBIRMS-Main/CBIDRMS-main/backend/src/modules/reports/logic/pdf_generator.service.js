const fs = require("fs");
const path = require("path");

const ensureUploadsDirectory = () => {
    const dir = path.join(__dirname, "../../../../uploads/reports");
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
    return dir;
};

/**
 * Generate styled HTML report document and save to disk.
 */
const generateReportDocument = async ({ reportId, type, fromDate, toDate, data, companyName = "Interior Design PMS" }) => {
    const reportsDir = ensureUploadsDirectory();
    const filename = `${reportId}.html`;
    const filepath = path.join(reportsDir, filename);

    const titleMap = {
        PROJECT: "Project Timelines & Status Executive Report",
        EXPENSE: "Project Expenses & Costs Summary Report",
        PURCHASE: "Purchase Orders & Procurement Report",
        REVENUE: "Client Billing & Revenue Collection Report",
        VENDOR: "Supplier & Vendor Performance Report",
        TEAM: "Team Productivity & Site Activity Report"
    };

    const reportTitle = titleMap[type] || `${type} Report`;

    let bodyHtml = "";

    if (type === "PROJECT") {
        const projects = data || [];
        if (projects.length === 0) {
            bodyHtml = `<div class="no-data">No project data recorded for the selected period (${fromDate} to ${toDate}).</div>`;
        } else {
            const tableRows = projects.map(p => `
                <tr>
                    <td><strong>${p.id}</strong></td>
                    <td>${p.name}</td>
                    <td>${p.clientName}</td>
                    <td><span class="badge badge-${p.status.toLowerCase()}">${p.status}</span></td>
                    <td>${(p.progress * 100).toFixed(0)}%</td>
                    <td>₹${(p.budget || 0).toLocaleString('en-IN')}</td>
                    <td>${p.startDate} to ${p.endDate}</td>
                </tr>
            `).join("");

            bodyHtml = `
                <div class="stat-cards">
                    <div class="card"><div class="num">${projects.length}</div><div class="lbl">Total Projects</div></div>
                    <div class="card"><div class="num">${projects.filter(p => p.status === 'ONGOING').length}</div><div class="lbl">Ongoing</div></div>
                    <div class="card"><div class="num">${projects.filter(p => p.status === 'COMPLETED').length}</div><div class="lbl">Completed</div></div>
                </div>
                <table>
                    <thead>
                        <tr>
                            <th>Project ID</th>
                            <th>Project Name</th>
                            <th>Client</th>
                            <th>Status</th>
                            <th>Progress</th>
                            <th>Budget</th>
                            <th>Timeline</th>
                        </tr>
                    </thead>
                    <tbody>${tableRows}</tbody>
                </table>
            `;
        }
    } else if (type === "EXPENSE") {
        const expenses = data || [];
        if (expenses.length === 0) {
            bodyHtml = `<div class="no-data">No expenses recorded for the selected period (${fromDate} to ${toDate}).</div>`;
        } else {
            const totalAmount = expenses.reduce((sum, e) => sum + (e.amount || 0), 0);
            const tableRows = expenses.map(e => `
                <tr>
                    <td>${e.date}</td>
                    <td><strong>${e.projectId}</strong></td>
                    <td><span class="category-pill">${e.category}</span></td>
                    <td>₹${e.amount.toLocaleString('en-IN')}</td>
                    <td>${e.note || '-'}</td>
                </tr>
            `).join("");

            bodyHtml = `
                <div class="stat-cards">
                    <div class="card"><div class="num">${expenses.length}</div><div class="lbl">Expense Records</div></div>
                    <div class="card"><div class="num">₹${totalAmount.toLocaleString('en-IN')}</div><div class="lbl">Total Spent</div></div>
                </div>
                <table>
                    <thead>
                        <tr>
                            <th>Date</th>
                            <th>Project ID</th>
                            <th>Category</th>
                            <th>Amount</th>
                            <th>Notes</th>
                        </tr>
                    </thead>
                    <tbody>${tableRows}</tbody>
                </table>
            `;
        }
    } else if (type === "PURCHASE") {
        const pos = data || [];
        if (pos.length === 0) {
            bodyHtml = `<div class="no-data">No purchase orders recorded for the selected period (${fromDate} to ${toDate}).</div>`;
        } else {
            const totalAmount = pos.reduce((sum, p) => sum + (p.totalAmount || 0), 0);
            const tableRows = pos.map(p => `
                <tr>
                    <td><strong>${p.id}</strong></td>
                    <td>${p.vendorName || p.vendor?.companyName || '-'}</td>
                    <td>${p.projectName || p.projectId}</td>
                    <td><span class="badge badge-${p.status.toLowerCase()}">${p.status}</span></td>
                    <td>₹${(p.totalAmount || 0).toLocaleString('en-IN')}</td>
                </tr>
            `).join("");

            bodyHtml = `
                <div class="stat-cards">
                    <div class="card"><div class="num">${pos.length}</div><div class="lbl">Purchase Orders</div></div>
                    <div class="card"><div class="num">₹${totalAmount.toLocaleString('en-IN')}</div><div class="lbl">Total Order Value</div></div>
                </div>
                <table>
                    <thead>
                        <tr>
                            <th>PO ID</th>
                            <th>Vendor</th>
                            <th>Project</th>
                            <th>Status</th>
                            <th>Total Amount</th>
                        </tr>
                    </thead>
                    <tbody>${tableRows}</tbody>
                </table>
            `;
        }
    } else if (type === "REVENUE") {
        const { invoices = [], payments = [] } = data || {};
        const totalInvoiced = invoices.reduce((sum, i) => sum + (i.amount || 0), 0);
        const totalCollected = payments.reduce((sum, p) => sum + (p.amount || 0), 0);
        const totalPending = invoices.reduce((sum, i) => sum + (i.pendingAmount || 0), 0);

        const tableRows = invoices.map(i => `
            <tr>
                <td><strong>${i.id}</strong></td>
                <td>${i.clientName}</td>
                <td>${i.projectId}</td>
                <td>₹${i.amount.toLocaleString('en-IN')}</td>
                <td>₹${i.pendingAmount.toLocaleString('en-IN')}</td>
                <td><span class="badge badge-${i.status.toLowerCase()}">${i.status}</span></td>
                <td>${i.dueDate}</td>
            </tr>
        `).join("");

        bodyHtml = `
            <div class="stat-cards">
                <div class="card"><div class="num">₹${totalInvoiced.toLocaleString('en-IN')}</div><div class="lbl">Total Invoiced</div></div>
                <div class="card"><div class="num" style="color: #10B981;">₹${totalCollected.toLocaleString('en-IN')}</div><div class="lbl">Total Collected</div></div>
                <div class="card"><div class="num" style="color: #F59E0B;">₹${totalPending.toLocaleString('en-IN')}</div><div class="lbl">Total Pending</div></div>
            </div>
            <table>
                <thead>
                    <tr>
                        <th>Invoice ID</th>
                        <th>Client</th>
                        <th>Project</th>
                        <th>Amount</th>
                        <th>Pending</th>
                        <th>Status</th>
                        <th>Due Date</th>
                    </tr>
                </thead>
                <tbody>${tableRows}</tbody>
            </table>
        `;
    } else if (type === "VENDOR") {
        const vendors = data || [];
        if (vendors.length === 0) {
            bodyHtml = `<div class="no-data">No vendor data available.</div>`;
        } else {
            const tableRows = vendors.map(v => {
                const poCount = (v.purchaseOrders || []).length;
                const poTotal = (v.purchaseOrders || []).reduce((s, po) => s + (po.totalAmount || 0), 0);
                return `
                    <tr>
                        <td><strong>${v.companyName}</strong></td>
                        <td>${v.contactPerson}</td>
                        <td>${v.phone}<br/>${v.email}</td>
                        <td>${poCount} orders</td>
                        <td>₹${poTotal.toLocaleString('en-IN')}</td>
                    </tr>
                `;
            }).join("");

            bodyHtml = `
                <div class="stat-cards">
                    <div class="card"><div class="num">${vendors.length}</div><div class="lbl">Active Vendors</div></div>
                </div>
                <table>
                    <thead>
                        <tr>
                            <th>Company Name</th>
                            <th>Contact Person</th>
                            <th>Contact Info</th>
                            <th>Total POs</th>
                            <th>Total Business Value</th>
                        </tr>
                    </thead>
                    <tbody>${tableRows}</tbody>
                </table>
            `;
        }
    } else if (type === "TEAM") {
        const { users = [], tasks = [], siteUpdates = [] } = data || {};
        const tableRows = users.map(u => {
            const userTasks = tasks.filter(t => t.assignedTo === u.id);
            const doneTasks = userTasks.filter(t => t.status === 'DONE').length;
            return `
                <tr>
                    <td><strong>${u.fullName}</strong></td>
                    <td>${u.email}</td>
                    <td><span class="badge badge-info">${u.role}</span></td>
                    <td>${userTasks.length} assigned (${doneTasks} completed)</td>
                </tr>
            `;
        }).join("");

        bodyHtml = `
            <div class="stat-cards">
                <div class="card"><div class="num">${users.length}</div><div class="lbl">Team Members</div></div>
                <div class="card"><div class="num">${tasks.length}</div><div class="lbl">Total Tasks</div></div>
                <div class="card"><div class="num">${siteUpdates.length}</div><div class="lbl">Site Logged Updates</div></div>
            </div>
            <table>
                <thead>
                    <tr>
                        <th>Member Name</th>
                        <th>Email</th>
                        <th>Role</th>
                        <th>Site Tasks Summary</th>
                    </tr>
                </thead>
                <tbody>${tableRows}</tbody>
            </table>
        `;
    }

    const fullHtml = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${reportTitle} - ${reportId}</title>
    <style>
        * { box-sizing: border-box; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        body { background-color: #0d1117; color: #e6edf3; margin: 0; padding: 32px; }
        .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #30363d; padding-bottom: 20px; margin-bottom: 24px; }
        .logo { font-size: 24px; font-weight: bold; color: #6366f1; letter-spacing: 0.5px; }
        .meta { text-align: right; color: #8b949e; font-size: 13px; line-height: 1.5; }
        h1 { font-size: 22px; color: #ffffff; margin-top: 0; margin-bottom: 20px; }
        .stat-cards { display: flex; gap: 16px; margin-bottom: 28px; }
        .card { background-color: #161b22; border: 1px solid #30363d; border-radius: 12px; padding: 20px; flex: 1; text-align: center; }
        .card .num { font-size: 24px; font-weight: bold; color: #6366f1; }
        .card .lbl { font-size: 12px; color: #8b949e; margin-top: 4px; text-transform: uppercase; letter-spacing: 0.5px; }
        table { width: 100%; border-collapse: collapse; background-color: #161b22; border-radius: 12px; overflow: hidden; border: 1px solid #30363d; margin-bottom: 30px; }
        th, td { padding: 14px 16px; text-align: left; border-bottom: 1px solid #30363d; font-size: 13px; }
        th { background-color: #21262d; color: #8b949e; text-transform: uppercase; font-size: 11px; letter-spacing: 0.5px; }
        tr:last-child td { border-bottom: none; }
        .badge { padding: 4px 8px; border-radius: 6px; font-size: 11px; font-weight: bold; text-transform: uppercase; }
        .badge-ongoing { background-color: rgba(99, 102, 241, 0.2); color: #6366f1; }
        .badge-completed, .badge-paid { background-color: rgba(16, 185, 129, 0.2); color: #10b981; }
        .badge-pending, .badge-draft { background-color: rgba(245, 158, 11, 0.2); color: #f59e0b; }
        .badge-overdue { background-color: rgba(239, 68, 68, 0.2); color: #ef4444; }
        .badge-info { background-color: rgba(59, 130, 246, 0.2); color: #3b82f6; }
        .category-pill { background-color: rgba(236, 72, 153, 0.2); color: #ec4899; padding: 4px 8px; border-radius: 6px; font-size: 11px; font-weight: bold; }
        .no-data { background-color: #161b22; border: 1px dashed #30363d; border-radius: 12px; padding: 40px; text-align: center; color: #8b949e; }
        .footer { margin-top: 40px; padding-top: 16px; border-top: 1px solid #30363d; display: flex; justify-content: space-between; color: #8b949e; font-size: 12px; }
        @media print {
            body { background-color: #ffffff; color: #000000; padding: 0; }
            .card, table { border-color: #ddd; background-color: #ffffff; }
            th { background-color: #f3f4f6; color: #374151; }
            td { border-color: #eee; }
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="logo">🏢 ${companyName}</div>
        <div class="meta">
            <strong>Report ID:</strong> ${reportId}<br/>
            <strong>Date Range:</strong> ${fromDate} to ${toDate}<br/>
            <strong>Generated At:</strong> ${new Date().toLocaleString('en-IN')}
        </div>
    </div>

    <h1>${reportTitle}</h1>

    ${bodyHtml}

    <div class="footer">
        <div>Generated by IDPMS Executive Reporting Engine</div>
        <div>Page 1 of 1</div>
    </div>
</body>
</html>`;

    fs.writeFileSync(filepath, fullHtml, "utf8");

    // Return static URL
    return `/uploads/reports/${filename}`;
};

module.exports = {
    generateReportDocument
};
